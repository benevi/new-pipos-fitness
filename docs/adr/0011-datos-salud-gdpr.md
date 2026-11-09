# ADR-0011: Datos de salud como categoría especial (GDPR art. 9)

**Estado**: Aceptado; implementado en la API (Fase 3: consentimiento, exportar, borrar). DPIA y revisión legal pendientes · **Fecha**: 2026-11-09

## Contexto
Peso, altura, edad, sexo y sobre todo las limitaciones o lesiones por zona son datos relativos a la salud. El art. 9 del RGPD exige consentimiento explícito (u otra base del art. 9.2) para tratarlos. La app no es un producto sanitario y no diagnostica.

## Decisión
- **Consentimiento explícito y separado** para datos de salud en el onboarding, con texto versionado; se guarda `HealthConsent(version, grantedAt, revokedAt)`. Sin consentimiento, el usuario puede usar la app con un plan sin limitaciones ni datos corporales, y se le explica.
- Retirar el consentimiento borra los datos de salud y regenera el plan sin ellos.
- **Exportar** (`GET /me/export`, JSON) y **borrar cuenta** (`DELETE /me`, borrado real en cascada de todos los datos del usuario), ambos cubiertos por e2e.
- Minimización: no se guarda nada que el motor no use; los logs nunca incluyen datos de salud.
- Aviso visible: la app no da consejo médico; ante dolor o lesión, consultar con un profesional.
- Antes del lanzamiento público: evaluación de impacto (DPIA) y revisión legal. Queda fuera de lo que este equipo puede cerrar.

## Consecuencias
- **Más fácil:** cumplir desde el diseño en vez de corregir después.
- **Más difícil:** un paso más en el onboarding; la retirada del consentimiento debe estar bien probada.

## Alternativas
- **Tratar todo como dato ordinario.** Contra: incumple el art. 9. Rechazada.
- **No pedir limitaciones.** Contra: el motor pierde una restricción de seguridad clave. Rechazada.
