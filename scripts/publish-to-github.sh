#!/usr/bin/env bash
# Publish apnic62-workshop to GitHub (run from repo root)
set -euo pipefail

REPO="thcorre/apnic62-workshop"

if ! command -v git >/dev/null; then
  echo "ERROR: git is required"
  exit 1
fi

if [[ ! -d .git ]]; then
  git init
  git branch -M main
fi

git add -A
git status

git commit -m "Initial APNIC62 WAN workshop repository" || true

if command -v gh >/dev/null; then
  if ! git remote get-url origin >/dev/null 2>&1; then
    gh repo create "$REPO" --public --source=. --remote=origin --push
  else
    git push -u origin main
  fi
  echo "Published: https://github.com/$REPO"
else
  echo "gh CLI not found. After creating the repo manually:"
  echo "  git remote add origin https://github.com/$REPO.git"
  echo "  git push -u origin main"
fi
