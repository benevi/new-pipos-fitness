import 'reflect-metadata';
import { RequestMethod } from '@nestjs/common';
import { METHOD_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import * as contracts from '@pipos/contracts';
import { ZodEffects, ZodObject, ZodType, type ZodRawShape, type ZodTypeAny } from 'zod';
import { zodToJsonSchema } from 'zod-to-json-schema';
import { CONTRACT_KEY, type ContractSpec } from '../common/contract';

/* eslint-disable @typescript-eslint/no-explicit-any */
type Json = Record<string, any>;

export interface RouteContract {
  method: string;
  path: string;
  operationId: string;
  spec: ContractSpec | undefined;
}

const METHOD_NAMES: Record<number, string> = {
  [RequestMethod.GET]: 'get',
  [RequestMethod.POST]: 'post',
  [RequestMethod.PUT]: 'put',
  [RequestMethod.PATCH]: 'patch',
  [RequestMethod.DELETE]: 'delete',
};

function joinPath(...parts: (string | undefined)[]): string {
  const p = parts
    .flatMap((x) => (x ?? '').split('/'))
    .filter(Boolean)
    .join('/');
  return `/${p}`;
}

/** Recorre los controladores de los módulos y devuelve cada ruta con su contrato. */
export function collectRoutes(modules: readonly unknown[]): RouteContract[] {
  const routes: RouteContract[] = [];
  for (const mod of modules) {
    const controllers: (new (...args: never[]) => unknown)[] = Reflect.getMetadata('controllers', mod as object) ?? [];
    for (const controller of controllers) {
      const base: string | undefined = Reflect.getMetadata(PATH_METADATA, controller);
      const proto = controller.prototype as Record<string, unknown>;
      for (const name of Object.getOwnPropertyNames(proto)) {
        const handler = proto[name];
        if (name === 'constructor' || typeof handler !== 'function') continue;
        const method = Reflect.getMetadata(METHOD_METADATA, handler);
        if (method === undefined) continue;
        const sub: string | undefined = Reflect.getMetadata(PATH_METADATA, handler);
        routes.push({
          method: METHOD_NAMES[method as number] ?? String(method),
          path: joinPath(base, sub),
          operationId: `${controller.name.replace(/Controller$/, '')}_${name}`,
          spec: Reflect.getMetadata(CONTRACT_KEY, handler),
        });
      }
    }
  }
  return routes.sort((a, b) => (a.path + a.method < b.path + b.method ? -1 : 1));
}

/** Nombre exportado de cada esquema de @pipos/contracts (para $ref en components). */
function schemaNames(): Map<ZodTypeAny, string> {
  const names = new Map<ZodTypeAny, string>();
  for (const [key, value] of Object.entries(contracts)) {
    if (value instanceof ZodType && key.endsWith('Schema') && !names.has(value)) {
      names.set(value, key.replace(/Schema$/, ''));
    }
  }
  return names;
}

function toJsonSchema(schema: ZodTypeAny, io: 'input' | 'output'): Json {
  const out = zodToJsonSchema(schema, {
    target: 'openApi3',
    $refStrategy: 'none',
    effectStrategy: io === 'input' ? 'input' : 'any',
    pipeStrategy: io,
  }) as Json;
  delete out.$schema;
  return out;
}

function objectShape(schema: ZodTypeAny): ZodRawShape {
  let s: ZodTypeAny = schema;
  while (s instanceof ZodEffects) s = s.innerType();
  if (!(s instanceof ZodObject)) throw new Error('params/query contracts must be Zod objects');
  return s.shape;
}

function parameters(schema: ZodTypeAny | undefined, where: 'path' | 'query'): Json[] {
  if (!schema) return [];
  return Object.entries(objectShape(schema)).map(([name, field]) => ({
    name,
    in: where,
    required: where === 'path' || !(field as ZodTypeAny).isOptional(),
    schema: toJsonSchema(field as ZodTypeAny, 'input'),
  }));
}

const STATUS_TEXT: Record<number, string> = {
  200: 'OK',
  201: 'Created',
  204: 'No Content',
  400: 'Validation failed (VALIDATION_FAILED, con issues por campo)',
  401: 'Unauthorized',
  403: 'Forbidden',
  404: 'Not found',
  409: 'Conflict (ver code)',
  422: 'Unprocessable (ver code e issues)',
  429: 'Rate limited',
  500: 'Internal error',
  503: 'Service unavailable',
};

export interface OpenApiOptions {
  version: string;
}

/**
 * Documento OpenAPI 3.0 generado SOLO desde los contratos Zod de los endpoints
 * (`@Contract`). Lo sirve Swagger fuera de producción y se versiona en apps/api/openapi.json
 * (CI comprueba que está al día) para que el móvil genere su cliente.
 */
export function buildOpenApiDocument(modules: readonly unknown[], options: OpenApiOptions): Json {
  const names = schemaNames();
  const components: Record<string, Json> = {};
  const ref = (schema: ZodTypeAny, io: 'input' | 'output'): Json => {
    const name = names.get(schema);
    if (!name) return toJsonSchema(schema, io);
    // Cada esquema con nombre se usa en un único sentido (petición o respuesta).
    if (!components[name]) components[name] = toJsonSchema(schema, io);
    return { $ref: `#/components/schemas/${name}` };
  };
  const errorRef = ref(contracts.ErrorResponseSchema, 'output');

  const paths: Record<string, Json> = {};
  for (const route of collectRoutes(modules)) {
    const spec = route.spec;
    if (!spec) throw new Error(`Route without @Contract: ${route.method.toUpperCase()} ${route.path}`);
    const oaPath = route.path.replace(/:([A-Za-z0-9_]+)/g, '{$1}');
    const success = spec.status ?? 200;
    const responses: Record<string, Json> = {};
    for (const status of [success, ...(spec.alternateStatuses ?? [])]) {
      responses[String(status)] =
        spec.response === null
          ? { description: STATUS_TEXT[status] ?? 'OK' }
          : { description: STATUS_TEXT[status] ?? 'OK', content: { 'application/json': { schema: ref(spec.response, 'output') } } };
    }
    const errors = new Set<number>([400, 429, 500, ...(spec.auth === false ? [] : [401]), ...(spec.errors ?? [])]);
    for (const status of [...errors].sort()) {
      responses[String(status)] = {
        description: STATUS_TEXT[status] ?? 'Error',
        content: { 'application/json': { schema: errorRef } },
      };
    }
    const operation: Json = {
      operationId: route.operationId,
      tags: [spec.tag],
      summary: spec.summary,
      ...(spec.description ? { description: spec.description } : {}),
      ...(spec.auth === false ? { security: [] } : { security: [{ bearer: [] }] }),
      parameters: [...parameters(spec.params, 'path'), ...parameters(spec.query, 'query')],
      ...(spec.body
        ? { requestBody: { required: true, content: { 'application/json': { schema: ref(spec.body, 'input') } } } }
        : {}),
      responses,
    };
    paths[oaPath] = { ...(paths[oaPath] ?? {}), [route.method]: operation };
  }

  return {
    openapi: '3.0.3',
    info: {
      title: 'Pipos Fitness API',
      version: options.version,
      description:
        'API v1 de Pipos Fitness. Generado desde los contratos Zod de @pipos/contracts (no editar a mano: ' +
        '`pnpm --filter @pipos/api openapi:generate`). Errores: ErrorResponse con `code` estable.',
    },
    components: {
      securitySchemes: { bearer: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' } },
      schemas: Object.fromEntries(Object.entries(components).sort(([a], [b]) => (a < b ? -1 : 1))),
    },
    paths: Object.fromEntries(Object.entries(paths).sort(([a], [b]) => (a < b ? -1 : 1))),
  };
}
