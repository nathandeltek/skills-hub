#!/usr/bin/env bash
# Lists every skill currently available in this hub (vendor + custom),
# reading name/description straight out of each SKILL.md's frontmatter.
# This is what a "list skills" step in an n8n workflow shells out to.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for f in skills/vendor/*/SKILL.md skills/custom/*/SKILL.md; do
  [ -f "$f" ] || continue
  dir="$(basename "$(dirname "$f")")"
  name="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -n1)"
  desc="$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -n1)"
  printf '%-32s %s\n' "${name:-$dir}" "${desc:-(no description)}"
done
