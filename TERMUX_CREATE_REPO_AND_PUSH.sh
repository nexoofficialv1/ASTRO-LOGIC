#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO_NAME="${1:-ASTRO-LOGIC}"

if [[ ! "$REPO_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Invalid repository name: $REPO_NAME"
  exit 2
fi

for command_name in git gh python; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$command_name is missing. Run: pkg install -y git gh python"
    exit 3
  fi
done

gh auth status >/dev/null
GH_USER="$(gh api user --jq .login)"

if gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
  echo "Repository already exists: $GH_USER/$REPO_NAME"
  echo "Run again with another name, for example:"
  echo "bash TERMUX_CREATE_REPO_AND_PUSH.sh ASTRO-LOGIC-APP"
  exit 4
fi

if [[ ! -f pubspec.yaml || ! -f .github/workflows/android-apk.yml || ! -f .github/workflows/windows-desktop.yml ]]; then
  echo "Run this script from the extracted ASTRO_LOGIC project folder."
  exit 5
fi

python tool/static_build_readiness_audit.py

git init
git branch -M main
git config user.name "$(git config user.name || echo "$GH_USER")"
git config user.email "$(git config user.email || echo "$GH_USER@users.noreply.github.com")"
git add .
git commit -m "Initial ASTRO LOGIC source baseline"

gh repo create "$GH_USER/$REPO_NAME" \
  --private \
  --source=. \
  --remote=origin \
  --push

echo
echo "Private repository created and source pushed:"
echo "https://github.com/$GH_USER/$REPO_NAME"
echo
echo "GitHub Actions Android + Windows build gates have started. Check them with:"
echo "gh run list --repo $GH_USER/$REPO_NAME --limit 3"
