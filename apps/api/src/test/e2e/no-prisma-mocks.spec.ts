import { describe, it, expect } from 'vitest';
import { readdirSync, readFileSync, statSync } from 'fs';
import { join, relative, resolve } from 'path';

/**
 * Salvaguarda: los e2e deben ejecutarse contra Postgres real. Falla si algún
 * *.e2e-spec.ts sobrescribe o mockea PrismaService (patrón que ocultaba bugs reales).
 */
const SRC = resolve(__dirname, '../..');

function findE2eSpecs(dir: string): string[] {
  return readdirSync(dir).flatMap((entry) => {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) return entry === 'node_modules' ? [] : findE2eSpecs(full);
    return entry.endsWith('.e2e-spec.ts') ? [full] : [];
  });
}

const FORBIDDEN: Array<{ pattern: RegExp; reason: string }> = [
  { pattern: /overrideProvider\(\s*PrismaService/, reason: 'overrideProvider(PrismaService)' },
  { pattern: /provide:\s*PrismaService/, reason: '{ provide: PrismaService, ... }' },
  { pattern: /vi\.mock\([^)]*prisma/i, reason: 'vi.mock(...prisma...)' },
  { pattern: /vi\.mock\([^)]*@prisma\/client/, reason: "vi.mock('@prisma/client')" },
];

describe('e2e specs use a real database', () => {
  const specs = findE2eSpecs(SRC);

  it('there are e2e specs to check', () => {
    expect(specs.length).toBeGreaterThan(0);
  });

  it.each(specs.map((s) => [relative(SRC, s), s]))('%s does not mock PrismaService', (_name, file) => {
    const content = readFileSync(file, 'utf8');
    const violations = FORBIDDEN.filter((f) => f.pattern.test(content)).map((f) => f.reason);
    expect(violations).toEqual([]);
  });
});
