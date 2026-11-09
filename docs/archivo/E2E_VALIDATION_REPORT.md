# E2E Validation Report (pre-Phase 14)

## BACKEND
- **Swagger:** OK
- **Prisma tables visible:** OK (migrate deploy OK; Prisma Studio no ejecutado en automático)
- **Auth flow:** OK
- **Training plan generation:** OK
- **Workout tracking:** OK (start, finish, history, getById, wrong workoutExerciseId rechazado). Add exercise a sesión falla si catálogo de ejercicios está vacío (sin seed).
- **Analytics:** OK
- **Nutrition plan generation:** FAIL (POST generate falla en entorno de prueba; posible dependencia de catálogo/engine)
- **Nutrition current/versions:** nutritionCurrent FAIL, nutritionVersions OK
- **AI Coach backend:** FAIL (aiNormal y aiProposal false en script; aiInvalid OK)

## MOBILE
- **flutter analyze:** FAIL (1 warning: unused_import en auth_session_coordinator; 82 issues info/warning, 0 errors tras arreglo de widget_test)
- **flutter test:** OK (102 tests passed)
- **Login/register:** No ejecutado en dispositivo/emulador (solo backend validado)
- **Workout flow:** No ejecutado en dispositivo (backend OK)
- **Resume workout:** No ejecutado en dispositivo
- **Dashboard:** No ejecutado en dispositivo
- **Nutrition screen:** No ejecutado en dispositivo
- **AI Coach screen:** No ejecutado en dispositivo
- **Logout/session consistency:** No ejecutado en dispositivo

## ISSUES FOUND
- **Backend:** Catálogo sin seed: `GET /exercises` devuelve `items: []`, por tanto `POST /workouts/:id/exercises` falla al añadir ejercicio (exerciseId no existe). Ejecutar `pnpm prisma:seed` en apps/api si se quieren ejercicios/alimentos de prueba.
- **Backend:** Nutrition plan generate falla (posible mismo motivo: catálogo vacío o restricciones del engine).
- **Backend:** AI Coach: en el script las llamadas a `/ai-coach/ask` devolvieron error o respuesta sin `responseType` esperado; revisar en Swagger con token válido.
- **Mobile:** `test/widget_test.dart` corregido (MyApp → PiposApp + ProviderScope); sin este cambio flutter test fallaba.
- **Mobile:** Flutter analyze sigue con 1 warning (unused_import) y varias infos (deprecated withOpacity, prefer_const_constructors, etc.).
- **Manual:** Prisma Studio, flujo completo en app (pasos 9–11) y pruebas de robustez (resume workout, session expiry, dashboard parcial, nutrition fallback) no ejecutados en esta validación automatizada.

---

## Mini resumen (post seed + correcciones)

| Item | Estado |
|------|--------|
| Exercises catalog | OK |
| Foods catalog | FAIL (seed no inserta Food) |
| Nutrition generate | FAIL (Food/MealTemplate vacíos) |
| AI coach | OK |
| Workout start + sets + finish | OK |
| Dashboard updates | No probado en app |
| Flutter run | No ejecutado en emulador |

**Hecho:** seed ejecutado; script E2E corregido (exercise id desde `.items`); unused_import eliminado en auth_session_coordinator.

---

## POST-SEED VALIDATION

GET /foods: OK  
POST /nutrition-plans/generate: OK  
GET /nutrition-plans/current: OK  
POST /ai-coach/ask: OK  

flutter run: OK  
Nutrition screen in app: Manual (verify in browser)  
AI Coach screen reachable: Manual (verify in browser)  

ISSUES:
- Nutrition screen and AI Coach screen not automated; confirm in running Chrome app.
