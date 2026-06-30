#!/usr/bin/env bash
#
# SessionStart hook: (re)register the atlassian MCP server with the token
# BuilderOS injects as ATLASSIAN_MCP_AUTHORIZATION.
#
# Why a SessionStart hook rather than the personalisation install script:
# personalisation runs BEFORE the agent launches, and the platform registers
# its own atlassian (at .../v1/mcp/authv2, interactive-OAuth, unauthenticated)
# AFTER that — clobbering anything we set during personalisation. A SessionStart
# hook fires after provisioning, so our header-authenticated registration wins.
#
# Idempotent and guarded: no-op if the token isn't present; tolerant of whether
# the injected value already carries the "Bearer " prefix. No secret is stored
# in this repo — the value is read from the VM's runtime env at session start.
set -euo pipefail

if [ -z "${ATLASSIAN_MCP_AUTHORIZATION:-}" ]; then
  # No injected token (Jira not connected, or running off-VM) — leave whatever
  # is registered alone and emit a no-op continue.
  echo '{"continue": true}'
  exit 0
fi

auth="$ATLASSIAN_MCP_AUTHORIZATION"
case "$auth" in
  [Bb]earer\ *) ;;            # already prefixed
  *) auth="Bearer $auth" ;;   # add the prefix
esac

# Reconcile: remove whatever is registered (the platform's unauthenticated
# authv2 entry, or a stale one of ours) and add ours. Remove-then-add is
# idempotent; both calls tolerate the server being absent.
claude mcp remove atlassian --scope user >/dev/null 2>&1 || true
claude mcp add --scope user atlassian --transport http https://mcp.atlassian.com/v1/mcp \
  --header "Authorization: $auth" >/dev/null 2>&1 || true

echo '{"continue": true}'
