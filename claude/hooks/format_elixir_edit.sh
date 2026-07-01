#!/usr/bin/env bash
#
# PostToolUse hook: auto-run `mix format` on an edited .ex/.exs file.
#
# Guarded so it's safe everywhere:
#  - Only acts on .ex/.exs files.
#  - Only runs if a local `mix` toolchain exists. On BuilderOS VMs there is NO
#    local Elixir toolchain (the project runs via Docker), so this cleanly
#    no-ops there instead of erroring per-edit. Formatting on BuilderOS is
#    handled at PR time via the sona-pre-pr-checks skill (docker compose run).
#
# Reads the hook JSON on stdin; extracts .tool_input.file_path.
set -euo pipefail

command -v mix >/dev/null 2>&1 || exit 0   # no local mix (e.g. BuilderOS VM) -> no-op

file="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -n "$file" ] || exit 0
case "$file" in
  *.ex|*.exs) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

mix format "$file" >/dev/null 2>&1 || true
