# Planes de ejemplo del motor v2

Generados con `pnpm --filter @pipos/engine-rules examples` (10 perfiles que cubren todos los objetivos, niveles, 2-6 días, casa y gimnasio, y lesiones de hombro, rodilla y lumbar). La revisión como entrenador está en [REVISION.md](REVISION.md).

| Perfil | Split | Score | Avisos |
|---|---|---|---|
| [Principiante, salud general, 2 días × 30 min, sin material](01-principiante-salud-2dias-casa.md) | full_body | 0.6787 | PATTERN_UNCOVERED, PATTERN_UNCOVERED, PATTERN_UNCOVERED, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, FREQUENCY_BELOW_MIN, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, FREQUENCY_BELOW_MIN, VOLUME_BELOW_FLOOR, PUSH_PULL_IMBALANCE |
| [Principiante, hipertrofia, 3 días × 45 min, mancuernas y banco en casa](02-principiante-hipertrofia-3dias-mancuernas.md) | full_body | 0.9335 | PATTERN_UNCOVERED, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR |
| [Intermedio, hipertrofia, 4 días × 60 min, gimnasio, prioridad glúteos](03-intermedio-hipertrofia-4dias-gimnasio-gluteos.md) | upper_lower | 0.9990 | — |
| [Intermedio, fuerza, 3 días × 75 min, gimnasio, con historial](04-intermedio-fuerza-3dias-gimnasio-historial.md) | full_body | 0.9631 | TIME_UNDERUSED, TIME_UNDERUSED, TIME_UNDERUSED, PUSH_PULL_IMBALANCE |
| [Avanzado, fuerza, 4 días × 90 min, gimnasio, historial largo](05-avanzado-fuerza-4dias-gimnasio-historial-largo.md) | upper_lower | 0.9591 | TIME_UNDERUSED, TIME_UNDERUSED, TIME_UNDERUSED, TIME_UNDERUSED |
| [Avanzado, hipertrofia, 6 días × 90 min, gimnasio, prioridad deltoides lateral y bíceps](06-avanzado-hipertrofia-6dias-gimnasio-hombros-biceps.md) | push_pull_legs | 0.9380 | TIME_UNDERUSED, TIME_UNDERUSED, TIME_UNDERUSED, TIME_UNDERUSED, TIME_UNDERUSED, TIME_UNDERUSED |
| [Intermedio, pérdida de grasa, 5 días × 45 min, gimnasio, lesión de hombro](07-intermedio-perdida-grasa-5dias-gimnasio-hombro.md) | hybrid_ul_ppl | 0.9618 | VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, DAYS_ABOVE_LEVEL_GUIDE |
| [Principiante, resistencia muscular, 3 días × 40 min, bandas y barra de dominadas](08-principiante-resistencia-3dias-bandas.md) | full_body | 0.9106 | VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR |
| [Intermedio, hipertrofia, 4 días × 50 min, casa (mancuernas, banco, banda), lesión de rodilla](09-intermedio-hipertrofia-4dias-casa-rodilla.md) | upper_lower | 0.9395 | VOLUME_BELOW_FLOOR, VOLUME_BELOW_FLOOR, PUSH_PULL_IMBALANCE |
| [Avanzado, salud general, 2 días × 60 min, kettlebell, TRX y bandas](10-avanzado-salud-2dias-kettlebell-trx.md) | full_body | 0.9481 | VOLUME_BELOW_FLOOR, PUSH_PULL_IMBALANCE |

La búsqueda local se retiró tras medir su aportación en estos 10 perfiles (+1,83 % medio, umbral 2 %; ADR-0006): el plan es la solución determinista por reglas.
