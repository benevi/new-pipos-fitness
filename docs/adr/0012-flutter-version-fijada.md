# ADR-0012: Versión de Flutter fijada en un único sitio; Android como objetivo primario

**Estado**: Propuesto · **Fecha**: 2026-11-09

## Contexto
El CI usa Flutter 3.16.0, `pubspec.lock` exige ≥3.38.4 y el código usa APIs de ≥3.22. No existen `android/` ni `ios/`.

## Decisión
- Versión de Flutter fijada en **`.fvmrc`** (3.38.10, la última 3.38 estable; compatible con el `pubspec.lock` actual, que exige ≥3.38.4); `pubspec.yaml` (`environment.flutter`) y el CI la leen o la igualan, y un paso de CI comprueba que coinciden.
- `flutter create . --platforms=android,ios` para generar las plataformas. **Android es el objetivo primario**: CI construye un APK de debug. iOS se genera y compila en local, pero su QA y su publicación quedan para después de v1.
- Se elimina `apps/mobile/package.json`; los comandos de Flutter se ejecutan en su propio job de CI.

## Consecuencias
- **Más fácil:** una sola fuente de verdad de versión; APK instalable.
- **Más difícil:** actualizar Flutter es un PR explícito.

## Alternativas
- **Bajar el lock a 3.16.** Contra: versión de 2023 sin las APIs usadas. Rechazada.
- **Android e iOS a la par en v1.** Contra: duplica QA y requiere macOS en CI. Pospuesto.
