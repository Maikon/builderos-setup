---
name: sona-pre-pr-checks
description: Run the Sona backend CI quality gates locally before opening a PR, so the PR does not fail CI on formatting, credo, translations, missing indexes, or dialyzer. Use before running `gh pr create` from a BuilderOS session, or whenever the user asks to check that changes will pass CI. Runs everything through Docker (Dockerfile.dev) since BuilderOS VMs have no local Elixir toolchain.
---

# Sona pre-PR CI checks

BuilderOS VMs have **no local Elixir/mix toolchain** — this is intentional; the
project runs through Docker. So a bare `mix format` will fail or silently no-op.
Every `mix` command below MUST go through the `backend` docker-compose service,
which builds from `backend/Dockerfile.dev` (this carries the Oban Pro Hex
credential and the CI-matching Elixir version, currently `1.19.5-otp-28`).

Run these from the **repo root** (`/home/dev/project`), where `docker-compose.yml`
lives. Bring the stack up first if it isn't already:

```bash
docker compose up -d --scale clickhouse=0 backend
```

## What CI enforces (backend-ci.yml → "Code Quality" + build job)

Run each of these and fix any failure BEFORE `gh pr create`. These mirror the CI
steps exactly, so passing them locally means the PR won't fail on them.

```bash
# 1. Formatting — CI runs `mix format --check-formatted`.
#    Fix by running format (writes changes), then re-check.
docker compose run --rm backend mix format
docker compose run --rm backend mix format --check-formatted

# 2. Credo (strict).
docker compose run --rm backend mix credo --strict

# 3. Translations up to date — CI extracts and fails on any git diff under
#    priv/gettext/. Always run this after touching user-facing strings.
docker compose run --rm backend mix translations.extract
git diff --exit-code -- priv/gettext/ \
  || echo "translations changed — commit the priv/gettext/ changes"

# 4. Missing indexes — CI runs ecto.gen.missing_indexes --print.
docker compose run --rm backend mix do ecto.create --quiet + ecto.migrate --quiet + ecto.gen.missing_indexes --print

# 5. Dialyzer (runs in the CI build job). Slow (builds PLT first time).
docker compose run --rm backend mix dialyzer
```

## Fast path

If you only touched a few files and want the common gates quickly, the first
three (format, credo, translations) catch the overwhelming majority of CI
failures. Dialyzer and missing-indexes are worth running when you changed
types/specs or added DB columns/queries respectively.

There is also a bundled alias that runs format-check + credo + tests together:

```bash
docker compose run --rm backend mix quality.ci
```

## Rules

- **Never run `mix ...` directly** on the VM — it has no toolchain. Always
  `docker compose run --rm backend mix ...`.
- If `mix deps.get` / a build step fails with `Unknown repository "oban"`, the
  wrong Dockerfile is being used — the `backend` service must build from
  `Dockerfile.dev` (which has the Oban Pro key), not `Dockerfile`.
- After `mix format` or `mix translations.extract` modify files, **commit those
  changes** — CI checks the committed tree, not your working copy.
- Only after all relevant checks pass should you open the PR (and fill in the
  repo's PR template).
