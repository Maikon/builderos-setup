#!/usr/bin/env bash
#
# Install the personal skills bundled in this repo (skills/) into
# /home/dev/.claude/skills on the VM. (Pattern from ruimfernandes/personalization.)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$REPO_ROOT/skills"
DEST="/home/dev/.claude/skills"

if [ ! -d "$SRC" ]; then
  echo "[install-skills] no skills/ dir at $SRC — nothing to do." >&2
  exit 0
fi

mkdir -p "$DEST"
cp -a "$SRC/." "$DEST/"

# Drop any macOS cruft that may have been committed.
find "$DEST" -name '.DS_Store' -delete 2>/dev/null || true

echo "[install-skills] installed:"; ls -1 "$DEST"
