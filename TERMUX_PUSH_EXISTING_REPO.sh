#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO_NAME="${1:-ASTRO-LOGIC}"
if [[ ! "$REPO_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Invalid repository name: $REPO_NAME" >&2
  exit 2
fi

for command_name in git gh python; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$command_name is missing. Run: pkg install -y git gh python" >&2
    exit 3
  fi
done

gh auth status >/dev/null
# Configure git to reuse the authenticated GitHub CLI credential helper.
gh auth setup-git >/dev/null
GH_USER="$(gh api user --jq .login)"
REPO="$GH_USER/$REPO_NAME"
REMOTE="https://github.com/$REPO.git"

if ! gh repo view "$REPO" >/dev/null 2>&1; then
  echo "Repository not found or inaccessible: $REPO" >&2
  exit 4
fi

if [[ ! -f pubspec.yaml || ! -f .github/workflows/android-apk.yml || ! -f tool/validate_v082_western_modern.py ]]; then
  echo "Run this script from the extracted ASTRO LOGIC v082 project folder." >&2
  exit 5
fi

python tool/static_build_readiness_audit.py
python tool/validate_v082_western_modern.py

# The first import is intentionally non-destructive. Refuse to overwrite an existing remote history.
remote_refs="$(git ls-remote --heads --tags "$REMOTE" 2>/dev/null || true)"
if [[ -n "$remote_refs" ]]; then
  echo "Remote repository is not empty: $REPO" >&2
  echo "For safety this first-push script will not overwrite existing history." >&2
  exit 6
fi

if [[ -d .git ]]; then
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "Local folder already contains Git history. Use a clean extraction of the push-ready ZIP." >&2
    exit 7
  fi
else
  git init
fi

git branch -M main
if [[ -z "$(git config user.name || true)" ]]; then
  git config user.name "$GH_USER"
fi
if [[ -z "$(git config user.email || true)" ]]; then
  git config user.email "$GH_USER@users.noreply.github.com"
fi

git add .
git commit -m "ASTRO LOGIC v082 Android CI checkpoint"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE"
else
  git remote add origin "$REMOTE"
fi
git push -u origin main

echo
echo "✅ ASTRO LOGIC v082 pushed to: https://github.com/$REPO"
echo "Android GitHub Actions workflow is now triggered."
echo "Check status with: gh run list --repo $REPO --workflow android-apk.yml --limit 5"
echo "Watch latest run with: gh run watch --repo $REPO"
