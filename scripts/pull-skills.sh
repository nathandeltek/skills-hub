#!/usr/bin/env bash
# Pulls every skill listed in skills.manifest.json from GitHub and lands it
# in skills/vendor/<skill-name>/SKILL.md — the folder n8n mounts.
#
# Uses the `skills` CLI (https://github.com/vercel-labs/skills), installed
# on demand via `npx`. Each skill is fetched with --agent universal --copy,
# which is the only agent target in that CLI that doesn't tie the output to
# a specific coding assistant (it lands in .agents/skills/), then relocated
# into our own canonical skills/vendor/ directory.
#
# Usage:
#   bash scripts/pull-skills.sh            # pull everything in the manifest
#   bash scripts/pull-skills.sh find-skills  # pull just one skill by name

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MANIFEST="skills.manifest.json"
VENDOR_DIR="skills/vendor"
STAGING_DIR=".agents/skills"

if [ ! -f "$MANIFEST" ]; then
  echo "error: $MANIFEST not found (run from repo root)" >&2
  exit 1
fi

command -v node >/dev/null 2>&1 || { echo "error: node is required" >&2; exit 1; }

ONLY_SKILL="${1:-}"

mkdir -p "$VENDOR_DIR"

# Extract "repo skill" pairs from the manifest without needing a JSON CLI dependency.
PAIRS="$(node -e '
  const fs = require("fs");
  const manifest = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  for (const entry of manifest.skills) {
    console.log(`${entry.repo}\t${entry.skill}`);
  }
' "$MANIFEST")"

if [ -z "$PAIRS" ]; then
  echo "warning: no skills listed in $MANIFEST"
  exit 0
fi

while IFS=$'\t' read -r REPO SKILL; do
  [ -z "$REPO" ] && continue
  if [ -n "$ONLY_SKILL" ] && [ "$SKILL" != "$ONLY_SKILL" ]; then
    continue
  fi

  echo "==> Pulling '$SKILL' from $REPO"
  rm -rf "$STAGING_DIR"

  # --copy avoids symlinks so the files are portable into a Docker volume mount.
  # -y skips interactive prompts (CI/CD-friendly, per the `skills` CLI docs).
  npx --yes skills add "$REPO" --skill "$SKILL" --agent universal --copy -y

  if [ ! -d "$STAGING_DIR/$SKILL" ]; then
    echo "    warning: expected $STAGING_DIR/$SKILL after install, but it's missing — skipping relocation" >&2
    continue
  fi

  rm -rf "$VENDOR_DIR/$SKILL"
  mv "$STAGING_DIR/$SKILL" "$VENDOR_DIR/$SKILL"
  echo "    -> $VENDOR_DIR/$SKILL/SKILL.md"
done <<< "$PAIRS"

rm -rf ".agents"

echo "==> Done. Vendor skills live in $VENDOR_DIR/"
echo "==> Run 'npm run validate' to sanity-check SKILL.md frontmatter, then 'npm run n8n:up' to mount them."
