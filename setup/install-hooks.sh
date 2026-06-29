#!/usr/bin/env bash
#
# Install Claude Code hook scripts onto the VM at /home/dev/.claude/hooks/.
#
# settings.json references these as ~/.claude/hooks/wrap_bash_silent.sh, and
# wrap_bash_silent.sh in turn invokes $HOME/.claude/hooks/run_silent_wrapper.sh
# — so both must live at that absolute path. (Hooks sourced from hl/claude.)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$REPO_ROOT/claude/hooks"
DEST="/home/dev/.claude/hooks"

if [ ! -d "$SRC" ]; then
  echo "[install-hooks] no hooks dir at $SRC — nothing to do." >&2
  exit 0
fi

mkdir -p "$DEST"
cp -a "$SRC/." "$DEST/"
chmod +x "$DEST"/*.sh 2>/dev/null || true
echo "[install-hooks] installed:"; ls -1 "$DEST"
