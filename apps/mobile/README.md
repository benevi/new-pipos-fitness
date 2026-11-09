# Pipos Fitness Mobile

App Flutter de Pipos Fitness (Riverpod, Dio, go_router, freezed, drift).

Versión de Flutter fijada en `.fvmrc` (3.38.10).

## Setup

```bash
cd apps/mobile
flutter pub get
```

El código generado (`*.freezed.dart`, `*.g.dart`, `lib/core/offline/app_database.g.dart`
y `lib/l10n/app_localizations*.dart`) está versionado: CI no necesita codegen.
Si cambias modelos, tablas de drift o ARB:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## Configurar la API

`API_BASE_URL` se pasa con `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

- **Release/profile**: obligatoria. Sin ella la app muestra una pantalla de
  error de configuración. Android release solo permite HTTPS.
- **Debug**: si falta se usa `http://10.0.2.2:3000` (emulador Android → host).
  El tráfico HTTP en claro solo está permitido en builds debug.

## Arquitectura base (Fase 4a)

- `lib/app/app.dart`: `PiposRoot` monta la app en un `ProviderScope` que se
  recrea en logout / sesión expirada (reset total del estado).
- `lib/core/api/`: Dio público (login/registro/refresh/logout) y Dio
  autenticado con `AuthInterceptor` (un reintento por petición, refresh
  deduplicado).
- `lib/core/offline/`: cola drift `pending_set_logs` + `SyncService`
  (offline-first, ADR-0007).
- `lib/l10n/`: i18n (`app_es.arb` principal, `app_en.arb`).
- `lib/app/tokens.dart`: design tokens y contrastes verificados.
