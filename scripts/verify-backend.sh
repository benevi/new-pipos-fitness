#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/apps/api"

echo "Installing backend dependencies..."
pnpm install

echo "Running lint..."
pnpm lint

echo "Running typecheck..."
pnpm typecheck

echo "Running tests..."
pnpm test

echo "Checking Prisma migrate status..."
pnpm exec prisma migrate status

echo "Backend verification completed."

