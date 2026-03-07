# Project Phases

| Phase | Name                 | Definition |
|-------|----------------------|------------|
| 1     | Foundations          | Repo structure, docs, CI, backend/worker/contracts/engine scaffolding, GitHub bootstrap |
| 2     | Authentication & User Core | User model, auth, sessions |
| 3     | Exercise Catalog    | Exercise data, catalog API |
| 4     | Training Engine     | Training plan generation (engine-rules) |
| 5     | Plan Versioning     | Immutable, versioned plans |
| 6     | Workout Tracking    | Log workouts, progress |
| 7     | Nutrition Engine    | Nutrition plan generation |
| 8     | Analytics           | Dashboards, metrics |
| 9     | AI Assistant        | AI explainability, Q&A |
| 10    | Notifications       | Push and in-app notifications |
| 11    | Billing             | Subscriptions, payments |
| 12    | Observability       | Sentry, monitoring |
| 13    | Flutter Application  | Mobile UI and integration |
| 14    | Production Release  | Launch and ops |

Only one phase is implemented at a time. Each phase ends with a git tag (e.g. `phase-1-foundations`).
