# Pipos Fitness

AI-powered fitness and nutrition mobile application. Personalized training and nutrition plans, workout and body metrics tracking, analytics, and AI assistant.

## Tech Stack

- **Mobile**: Flutter (iOS + Android)
- **Backend**: Node.js, TypeScript, NestJS
- **Database**: PostgreSQL, Prisma
- **Queues**: Redis, BullMQ
- **Contracts**: Zod (shared in `packages/contracts`)
- **Business logic**: Pure functions in `packages/engine-rules`

## Repository Structure

```
apps/
  api       # NestJS API
  worker    # BullMQ worker
  mobile    # Flutter app (Phase 13)
packages/
  contracts # Zod schemas
  engine-rules # Business logic (pure functions)
docs/
scripts/
```

## Prerequisites

- Node.js >= 20
- pnpm 9+
- PostgreSQL
- Redis

## Commands

```bash
pnpm install
pnpm build
pnpm lint
pnpm typecheck
pnpm test
```

## Bootstrap GitHub Repository

1. Set environment variables:
   - `REPO_NAME` (required): e.g. `pipos-fitness`
   - `GITHUB_OWNER` (optional): GitHub org or user

2. Run from repo root (Git Bash or WSL on Windows):

```bash
bash scripts/bootstrap_github_repo.sh
```

Requires: `git`, `gh` (GitHub CLI), and `gh auth login` completed.

## Project Phases

Phases and scope are defined in [docs/PHASES.md](docs/PHASES.md). Only one phase is implemented at a time; each phase ends with a git tag.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Coding Rules](docs/CODING_RULES.md)
- [Engine Rules](docs/ENGINE_RULES.md)
- [Phases](docs/PHASES.md)
- [Decisions](docs/DECISIONS.md)

## Git Workflow

- `main` → production
- `develop` → staging
- Feature branches → development
- Phases tagged (e.g. `phase-1-foundations`)
