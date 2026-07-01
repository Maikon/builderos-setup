# builderos-setup

Personal [BuilderOS](https://app.notion.com/p/getsona/BuilderOS-Platform-Guide-35f1bb77bbde81e8844cd5a7584079cf) personalisation repo. BuilderOS clones this onto every task/session VM and applies `.builderos/personalisation.yaml` after repo checkout, before the agent launches — so each fresh VM comes up with my Claude plugins, settings, and MCP servers.

## Layout

```
.builderos/personalisation.yaml   # manifest: ordered apply: list (runs every launch)
claude/settings.json              # merged into /home/dev/.claude/settings.json
claude/hooks/                     # hook scripts (silent bash, elixir auto-format, atlassian fix)
skills/                           # personal skills + sona-pre-pr-checks, copied to ~/.claude/skills/
setup/install-hooks.sh            # copies claude/hooks/ to /home/dev/.claude/hooks/
setup/install-skills.sh           # copies skills/ to /home/dev/.claude/skills/
setup/install-mcps.sh             # registers MCP servers (sentry, notion, tidewave) at user scope
```

The silent-bash hook (from Henry's `hl/claude`) makes `mix compile/test/format/credo/dialyzer`
print only a one-line summary on success (full output on failure). The auto-format
hook runs `mix format` on edited `.ex`/`.exs` files **only when a local `mix`
exists** — so it works on your laptop and cleanly no-ops on BuilderOS VMs (which
have no local Elixir toolchain).

**Passing CI from a BuilderOS session:** VMs have no local Elixir toolchain, so
`mix format`/`credo`/etc. must run through Docker. The `sona-pre-pr-checks` skill
runs the exact gates `backend-ci.yml` enforces (format, credo, translations,
missing indexes, dialyzer) via `docker compose run --rm backend mix ...` before
you open a PR — so the PR doesn't fail CI on them. Invoke it by intent
("check this passes CI before I open the PR") or before any `gh pr create`.

## Wiring it up (one-time)

1. Push this repo somewhere BuilderOS can clone it (personal GitHub, or under `sona-is`).
2. Point your BuilderOS user at it:
   ```bash
   fv personalisation set --url https://github.com/Maikon/builderos-setup --required
   fv personalisation show   # verify
   ```
   This repo is **public**, so it clones over HTTPS with no credential — the
   path every working BuilderOS personalisation repo uses. (There is no
   deploy-key credential UI in BuilderOS; private repos would instead need the
   GitHub App installed on the owning account/org so `GH_TOKEN` can reach them.)
3. **Marketplace plugins** (`doc-ticket-solver`, `code-reviewer`, etc.) are cloned by the platform from `sona-is/marketplace` using your `GH_TOKEN`. Make sure your BuilderOS GitHub App grants access to `sona-is/marketplace`, or the clone 404s silently and the plugins are absent.

## Caveats

- **Keep this repo public-safe.** No secrets in tracked files — the MCP servers authenticate in-VM (below), never from committed credentials. `.gitignore` guards against accidentally committing `~/.claude` runtime state.
- **`sentry` / `notion` need one-time `/mcp` OAuth in-VM** (interactive browser flow; local tokens don't carry over).
- **`atlassian` is different — and has a known per-session gotcha.** It's authenticated automatically from the platform-injected `ATLASSIAN_MCP_AUTHORIZATION` token (by both `install-mcps.sh` and the `fix_atlassian_mcp.sh` SessionStart hook). The on-disk config ends up `✔ Connected` with all the Jira tools. **But** BuilderOS launches the agent with `claude --continue`, which resumes the prior session's MCP connection state — so a fresh/resumed agent often still shows atlassian as "needs authentication" even though the config is correct.
  - **Fix:** in the session, `/mcp → atlassian → reconnect`. This forces the agent to re-read the (correct) config. **Do NOT paste the OAuth/localhost URL** — that's the wrong path (the localhost callback can't reach the VM) and atlassian is already authenticated in config.
  - Root cause is platform-side (token not attached to the platform's own registration + `--continue` resuming stale connections), not this repo. Reported to `#dev-builder-os`.
- **`merge_config` target must be absolute.** Use `/home/dev/.claude/settings.json`, never `~/...` — `~` isn't expanded on the VM, the merge is silently dropped, and your plugins show up disabled on a fresh VM.
- **`tidewave` needs the app running.** VMs boot clone-only; start Phoenix on :4000 in-VM first.
- Per-launch overrides: `fv task --no-personalisation ...` or `fv task --personalisation <ref> ...`.

## Updating

Edit, commit, push. Pin a branch/commit with `fv personalisation set --ref <ref>` if you don't want VMs tracking `main` automatically.
