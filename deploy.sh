#!/usr/bin/env bash
# Ghar Ka Menu — one-shot deploy to DigitalOcean App Platform
# Run this from inside the ghar-ka-menu folder:  bash deploy.sh
set -euo pipefail

say() { printf "\n\033[1m» %s\033[0m\n" "$*"; }

command -v git >/dev/null || { echo "git not found"; exit 1; }
command -v doctl >/dev/null || { echo "doctl not found — install: https://docs.digitalocean.com/reference/doctl/how-to/install/"; exit 1; }

# --- 0. sanity: doctl authenticated? ---
if ! doctl account get >/dev/null 2>&1; then
  say "doctl isn't authenticated yet. Run:  doctl auth init   (then re-run this script)"
  exit 1
fi

# --- 1. figure out GitHub repo ---
if git remote get-url origin >/dev/null 2>&1; then
  REPO_URL=$(git remote get-url origin)
  say "Using existing remote: $REPO_URL"
else
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    say "Creating GitHub repo with gh..."
    gh repo create ghar-ka-menu --public --source=. --remote=origin
    REPO_URL=$(git remote get-url origin)
  else
    say "No git remote set. Create an empty repo named 'ghar-ka-menu' on github.com, then:"
    echo "    git remote add origin https://github.com/YOUR_USERNAME/ghar-ka-menu.git"
    echo "    bash deploy.sh"
    exit 1
  fi
fi

# --- 2. push ---
say "Pushing to GitHub..."
git push -u origin main

# --- 3. patch app spec with the real repo slug ---
SLUG=$(echo "$REPO_URL" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')
say "Setting repo in .do/app.yaml → $SLUG"
sed -i.bak "s#repo: .*#repo: $SLUG#" .do/app.yaml && rm -f .do/app.yaml.bak
git add .do/app.yaml && git -c user.name="deploy" -c user.email="deploy@local" commit -qm "set repo slug" --allow-empty && git push -q

# --- 4. create the app ---
say "Creating App Platform app..."
if ! CREATE_OUT=$(doctl apps create --spec .do/app.yaml 2>&1); then
  echo "$CREATE_OUT"
  if echo "$CREATE_OUT" | grep -qi "github"; then
    say "DigitalOcean needs one-time GitHub authorization."
    echo "Open https://cloud.digitalocean.com/apps → Create App → GitHub → authorize,"
    echo "then re-run:  bash deploy.sh"
  fi
  exit 1
fi
echo "$CREATE_OUT"
APP_ID=$(echo "$CREATE_OUT" | awk 'NR==2 {print $1}')

# --- 5. wait for URL ---
say "Waiting for deployment (this takes a minute or two)..."
for i in $(seq 1 30); do
  URL=$(doctl apps get "$APP_ID" --format DefaultIngress --no-header 2>/dev/null || true)
  PHASE=$(doctl apps list-deployments "$APP_ID" --format Phase --no-header 2>/dev/null | head -1 || true)
  [ -n "$URL" ] && [ "$PHASE" = "ACTIVE" ] && break
  sleep 10
done

if [ -n "${URL:-}" ]; then
  say "Live! → $URL"
  echo "Open it on your phone → browser menu → 'Add to Home Screen'."
  echo "Every future 'git push' auto-deploys."
else
  say "App created (id: $APP_ID). Check status with:  doctl apps list"
fi
