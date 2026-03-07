#!/usr/bin/env bash
set -euo pipefail

# Bootstrap GitHub repository for Pipos Fitness.
# Requires: REPO_NAME (required), GITHUB_OWNER (optional)
# Usage: bash scripts/bootstrap_github_repo.sh

if ! command -v git &>/dev/null; then
  echo "Error: git is not installed"
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "Error: GitHub CLI (gh) is not installed. Install from https://cli.github.com/"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "Error: Not logged in to GitHub. Run: gh auth login"
  exit 1
fi

REPO_NAME="${REPO_NAME:-}"
if [[ -z "$REPO_NAME" ]]; then
  echo "Error: REPO_NAME environment variable is required (e.g. pipos-fitness)"
  exit 1
fi

GITHUB_OWNER="${GITHUB_OWNER:-}"
REPO_ARG="$REPO_NAME"
if [[ -n "$GITHUB_OWNER" ]]; then
  REPO_ARG="$GITHUB_OWNER/$REPO_NAME"
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -d .git ]]; then
  echo "Git already initialized"
else
  git init
  git branch -M main
fi

if [[ -z "$(git status --porcelain)" ]]; then
  echo "Working tree clean"
else
  git add -A
  git commit -m "chore: phase 1 foundations"
fi

if ! gh repo view "$REPO_ARG" &>/dev/null; then
  gh repo create "$REPO_ARG" --private --source=. --remote=origin --push
else
  if ! git remote get-url origin &>/dev/null; then
    git remote add origin "https://github.com/$REPO_ARG.git"
  fi
fi

if ! git show-ref --verify --quiet refs/heads/develop; then
  git checkout -b develop
  git push -u origin develop
  git checkout main
fi

echo "Done. Repo: https://github.com/$REPO_ARG"
echo "Branches: main (production), develop (staging)"
