#!/usr/bin/env bash
#
# Register MCP servers on a fresh BuilderOS VM, mirroring the local Sona
# backend project-scoped setup.
#
# Run as the `dev` user (see .builderos/personalisation.yaml). Scoped to the
# Sona repo checkout so these match a local `cd sona && claude` session.
#
# AUTH NOTE: the remote servers below (sentry, atlassian, notion) use OAuth.
# Registering them does NOT log you in — on first use inside the VM you must
# run `/mcp` in Claude Code and complete the browser auth flow. There is no way
# to copy your local OAuth session onto the VM.
set -euo pipefail

# Where the Sona repo is checked out on the VM. Adjust if BuilderOS clones it
# somewhere other than the dev home directory.
REPO_DIR="${SONA_REPO_DIR:-$HOME/sona}"

if [ ! -d "$REPO_DIR" ]; then
  echo "[install-mcps] repo dir $REPO_DIR not found; registering at user scope instead" >&2
  REPO_DIR="$HOME"
fi

cd "$REPO_DIR"

add() {
  # add <name> <transport> <url-or-cmd...>
  # Idempotent: remove any existing registration first, ignore failure.
  local name="$1"; shift
  claude mcp remove "$name" >/dev/null 2>&1 || true
  echo "[install-mcps] adding $name"
  claude mcp add "$name" "$@"
}

# --- Remote OAuth servers (need /mcp auth in-VM on first use) ---------------
add sentry    --transport http https://mcp.sentry.dev/mcp

# Atlassian (Jira/Confluence) and Notion — remote OAuth.
add atlassian --transport http https://mcp.atlassian.com/v1/mcp
add notion    --transport http https://mcp.notion.com/mcp

# --- Local servers ----------------------------------------------------------
# Tidewave talks to the running Phoenix app. Only works if the app is started
# inside the VM on port 4000 (VMs boot clone-only; nothing auto-starts).
add tidewave  --transport http http://localhost:4000/tidewave/mcp

# Postgres MCP — point at the VM's local dev DB. Override via DATABASE_URL.
# Local config uses the sona_export DB. Uncomment if you want it on every VM.
# add postgres  -- npx -y @modelcontextprotocol/server-postgres "${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/sona_export}"

# Context7 (docs lookup), Honeycomb, Taskmaster — uncomment if you want them on
# every VM. They were project-scoped locally; left off by default to keep VMs lean.
# add context7     --transport sse  https://mcp.context7.com/sse
# add honeycomb    --transport http https://mcp.honeycomb.io/mcp
# add taskmaster-ai -- npx -y task-master-ai

echo "[install-mcps] done. Run /mcp inside Claude Code to authenticate OAuth servers."
