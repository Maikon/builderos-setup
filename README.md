# builderos-setup

Personal [BuilderOS](https://app.notion.com/p/getsona/BuilderOS-Platform-Guide-35f1bb77bbde81e8844cd5a7584079cf) personalisation repo. BuilderOS clones this onto every task/session VM and applies `.builderos/personalisation.yaml` after repo checkout, before the agent launches — so each fresh VM comes up with my Claude plugins, settings, and MCP servers.

## Layout

```
.builderos/personalisation.yaml   # manifest: ordered apply: list (runs every launch)
claude/settings.json              # merged into /home/dev/.claude/settings.json
setup/install-mcps.sh             # registers MCP servers (sentry, tidewave, ...)
```

## Wiring it up (one-time)

1. Push this repo somewhere BuilderOS can clone it (personal GitHub, or under `sona-is`).
2. Point your BuilderOS user at it:
   ```bash
   fv personalisation set --url <git-url> --required
   # private repo: add --deploy-key <connected-deploy-key-id>
   fv personalisation show   # verify
   ```
3. **Marketplace plugins** (`doc-ticket-solver`, `code-reviewer`, etc.) are cloned by the platform from `sona-is/marketplace` using your `GH_TOKEN`. Make sure your BuilderOS GitHub App grants access to `sona-is/marketplace`, or the clone 404s silently and the plugins are absent.

## Caveats

- **OAuth MCP servers don't carry your local session.** `sentry`, `atlassian`, `notion` need `/mcp` auth inside the VM on first use. Local OAuth tokens can't be copied over.
- **`tidewave` needs the app running.** VMs boot clone-only; start Phoenix on :4000 in-VM first.
- Per-launch overrides: `fv task --no-personalisation ...` or `fv task --personalisation <ref> ...`.

## Updating

Edit, commit, push. Pin a branch/commit with `fv personalisation set --ref <ref>` if you don't want VMs tracking `main` automatically.
