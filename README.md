# builderos-setup

Personal [BuilderOS](https://app.notion.com/p/getsona/BuilderOS-Platform-Guide-35f1bb77bbde81e8844cd5a7584079cf) personalisation repo. BuilderOS clones this onto every task/session VM and applies `.builderos/personalisation.yaml` after repo checkout, before the agent launches — so each fresh VM comes up with my Claude plugins, settings, and MCP servers.

## Layout

```
.builderos/personalisation.yaml   # manifest: ordered apply: list (runs every launch)
claude/settings.json              # merged into /home/dev/.claude/settings.json
claude/hooks/                     # hook scripts (silent bash + auto mix-format), from hl/claude
setup/install-hooks.sh            # copies claude/hooks/ to /home/dev/.claude/hooks/
setup/install-mcps.sh             # registers MCP servers (sentry, notion, tidewave) at user scope
```

The hooks (sourced from Henry's `hl/claude`) make `mix compile/test/format/credo/dialyzer`
print only a one-line summary on success (full output on failure), and auto-run
`mix format` on every edited `.ex`/`.exs`.

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
- **OAuth MCP servers don't carry your local session.** `sentry`, `atlassian`, `notion` need `/mcp` auth inside the VM on first use. Local OAuth tokens can't be copied over.
- **`merge_config` target must be absolute.** Use `/home/dev/.claude/settings.json`, never `~/...` — `~` isn't expanded on the VM, the merge is silently dropped, and your plugins show up disabled on a fresh VM.
- **`tidewave` needs the app running.** VMs boot clone-only; start Phoenix on :4000 in-VM first.
- Per-launch overrides: `fv task --no-personalisation ...` or `fv task --personalisation <ref> ...`.

## Updating

Edit, commit, push. Pin a branch/commit with `fv personalisation set --ref <ref>` if you don't want VMs tracking `main` automatically.
