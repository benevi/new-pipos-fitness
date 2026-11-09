# Pipos Fitness Mobile

App Flutter de Pipos Fitness v1 (Riverpod, Dio, go_router, drift).

Versión de Flutter fijada en `.fvmrc` (3.38.10).

## Setup y verificación

```bash
cd apps/mobile
flutter pub get
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter test -d flutter-tester integration_test   # headless, sin dispositivo
```

`flutter test integration_test` a secas pide un dispositivo (emulador o
Android). Con `-d flutter-tester` el integration test «completar una sesión»
corre en el mismo motor que `flutter test`; así lo lanza el CI.

El código generado (`lib/core/offline/app_database.g.dart` y
`lib/l10n/app_localizations*.dart`) está versionado: CI no necesita codegen.
Si cambias tablas de drift o ARB:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## Contratos de la API v1

Los DTOs (`lib/models/`) están escritos a mano y replican 1:1 los esquemas Zod
de `packages/contracts/src/schemas` (no hay un generador OpenAPI → Dart que
funcione sin red y dé código idiomático). Dos redes de seguridad:

1. `test/fixtures/api_v1/*.json` se validan contra Zod:
   ```bash
   pnpm install --filter @pipos/contracts --frozen-lockfile
   pnpm --filter @pipos/contracts build
   node apps/mobile/tool/validate_fixtures.mjs
   ```
2. `test/contract/contract_fixtures_test.dart` parsea cada fixture y comprueba
   que `toJson()` reproduce exactamente el JSON: un campo añadido, quitado o
   renombrado en la API rompe el test.

## Configurar la API

`API_BASE_URL` se pasa con `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

- **Release/profile**: obligatoria. Sin ella la app muestra una pantalla de
  error de configuración. Android release solo permite HTTPS.
- **Debug**: si falta se usa `http://10.0.2.2:3000` (emulador Android → host).

## Arquitectura

- `lib/app/`: `PiposRoot` (scope que se recrea en logout), router con
  `StatefulShellRoute` (Hoy, Plan, Progreso, Ajustes) y puerta de onboarding,
  tokens y tema.
- `lib/core/api/`: Dio público y autenticado (`AuthInterceptor`; `401
  AUTH_REFRESH_RACE` no cierra sesión). `ApiFailure` con `code` e `issues`.
- `lib/data/pipos_api.dart`: interfaces de la capa de datos (las pantallas no
  ven Dio) y su implementación Dio. Los tests usan `test/helpers/fake_backend.dart`.
- `lib/core/offline/`: drift (entrenamientos locales, series con estado de
  sync, caché de la sesión de hoy y del plan) y `SyncService` (ADR-0007).
- `lib/features/`: `onboarding`, `today`, `plan`, `progress`, `settings`,
  `setup` (puerta), `auth`.
- `lib/l10n/`: castellano (principal) e inglés completos.

Decisiones de UX, estados y accesibilidad: `docs/UX_MOVIL.md`.
