#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-$HOME/apps/nextjs-mysql-example}"
REPO_URL="${REPO_URL:-}"
BRANCH="${BRANCH:-main}"

if [[ -z "$REPO_URL" ]]; then
  echo "REPO_URL is required"
  exit 1
fi

mkdir -p "$(dirname "$APP_DIR")"

if [[ ! -d "$APP_DIR/.git" ]]; then
  git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git reset --hard "origin/$BRANCH"

if [[ ! -f ".env" ]]; then
  echo "Missing .env in $APP_DIR"
  exit 1
fi

docker compose pull
docker compose up -d --build
docker compose ps
