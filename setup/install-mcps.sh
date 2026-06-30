#!/usr/bin/env bash
#
# Register MCP servers on a fresh BuilderOS VM, mirroring the local Sona
# backend project-scoped setup.
#
# Run as the `dev` user (see .builderos/personalisation.yaml).
#
# Registered at USER scope (--scope user) so the servers are visible to the
# agent regardless of which directory it launches from. `claude mcp add`
# defaults to `local` (project) scope, which is keyed to the current working
# dir and would be invisible if the agent runs elsewhere.
#
# AUTH NOTE: sentry and notion use OAuth — registering them does NOT log you
# in; run `/mcp` in Claude Code and complete the browser flow on first use.
# atlassian is different: it's wired from the platform-injected token (below).
set -euo pipefail

add() {
  # add <name> <transport> <url-or-cmd...>
  # Idempotent: remove any existing registration first, ignore failure.
  local name="$1"; shift
  claude mcp remove "$name" --scope user >/dev/null 2>&1 || true
  echo "[install-mcps] adding $name (user scope)"
  claude mcp add --scope user "$name" "$@"
}

# --- Remote OAuth servers (need /mcp auth in-VM on first use) ---------------
add sentry    --transport http https://mcp.sentry.dev/mcp

# Notion — remote OAuth.
add notion    --transport http https://mcp.notion.com/mcp

# Atlassian is NOT registered here — the platform handles it natively. As of the
# 2026-06-29 BuilderOS release (#408), atlassian is registered against the token
# endpoint with the injected ATLASSIAN_MCP_AUTHORIZATION credential and connects
# without any in-VM login. (Earlier this needed a SessionStart-hook workaround;
# that's now removed.) Just connect Jira in the BuilderOS dashboard.

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
