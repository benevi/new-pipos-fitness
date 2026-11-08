# Recorridos críticos de usuario (CUJ) de v1

Cada CUJ tiene un criterio de éxito medible y el test que lo verifica. Un CUJ solo cuenta como hecho cuando ese test corre en CI.

| ID | Recorrido | Criterio de éxito | Verificación |
|---|---|---|---|
| CUJ-1 | **Onboarding → primer plan** | En menos de 3 minutos el usuario completa el cuestionario (objetivo, nivel, días, minutos, material, limitaciones con consentimiento, preferencias) y recibe un plan válido para sus restricciones, con explicación legible del split y de cada ejercicio. | e2e API (registro → perfil → generar plan → invariantes); widget test del cuestionario |
| CUJ-2 | **Entrenar hoy** | Abre la sesión de hoy, ve calentamiento, series objetivo (reps, RIR, descanso) y registra cada serie con 2 toques o menos (valores precargados), con temporizador de descanso. Funciona en modo avión; al recuperar red no se pierde ni se duplica ninguna serie. | Integration test «completar una sesión»; widget test offline → sync; e2e de idempotencia |
| CUJ-3 | **Progresión semanal** | Si en una sesión completa el techo del rango de reps con el RIR objetivo, la siguiente sesión de ese ejercicio sube la carga con el incremento configurado y lo explica. Si reps o RIR caen dos sesiones seguidas, se propone deload. | Tests unitarios y de propiedades del motor; e2e de dos sesiones encadenadas |
| CUJ-4 | **Cambiar un ejercicio** | Desde la sesión, ve 3 alternativas ordenadas que respetan patrón, músculos, material y limitaciones, y cambia en menos de 10 s. El cambio se refleja en la sesión y en el historial. | Tests de propiedades de sustitución; e2e |
| CUJ-5 | **Faltar y volver** | Si se salta sesiones, el plan sigue por la siguiente sesión pendiente sin romper la progresión. Tras 14 días o más sin entrenar, la primera sesión baja la carga y lo explica. | Tests unitarios del motor; e2e con fechas simuladas |
| CUJ-6 | **Cambiar perfil** | Al cambiar material, días, minutos o limitaciones, se genera una nueva versión del plan que conserva historial y e1RM; la versión anterior sigue consultable. | e2e (nueva versión, historial intacto) |
| CUJ-7 | **Ver progreso** | Ve e1RM por ejercicio y series semanales por grupo muscular frente a su rango objetivo, y su adherencia (sesiones hechas / planificadas). | e2e de analytics on-write; widget test |
| CUJ-8 | **Exportar o borrar cuenta** | Exporta todos sus datos en JSON. Al borrar la cuenta, desaparecen todos sus datos, incluidos los de salud, y sus tokens dejan de funcionar. | e2e (export completo; tras borrar, 0 filas del usuario y 401) |

## No-objetivos de v1
Chat de IA, generación de comidas, catálogo de alimentos, red social, notificaciones push del servidor, wearables, iOS publicado, panel web de administración (ver ADR-0005), planes para menores de edad, embarazo o rehabilitación.
