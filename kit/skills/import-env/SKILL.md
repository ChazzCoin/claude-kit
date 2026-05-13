---
name: import-env
description: Parse an existing .env file into env-var stamps under env/stamps/. Walks each KEY=value line, drafts a stamp for any var without one, asks for required/optional/group/purpose interactively. Never reads values into stamps — only metadata. Triggered when the user wants to register their env vars — e.g. "/import-env", "import my .env file into stamps", "register env vars", "parse .env-local into stamps".
---

# /import-env — Parse a `.env*` file into env-var stamps

Brings an existing project's env vars under the kit's env-stamp system. Reads a `.env*` file line by line, drafts a stamp for any var that doesn't have one yet, and asks the user to confirm the metadata. Values are **never** stored in stamps — only `var_name`, `group`, `required`, `purpose`, etc.

Pairs with `env-rules.md` (the stamp model and folder convention).

## Behavior contract

### Discover, don't assume

Read in this order:

1. `.claude/env-rules.md` — confirm the stamp model and conventions you're using.
2. `env/stamps/` — list existing stamps so this run knows what's already registered.
3. The target `.env*` file (path from user, or auto-detect — see below).
4. `env/ENV.md` if it exists — to know existing group taxonomy.
5. Project's runtime stamps (`.claude/runtimes/*.md`) — to know which runtimes might use a var (suggest `used_by.runtimes` from `env.required` arrays).

### Pick the source file

Ask the user, with auto-detection as suggestions:

> Which `.env*` file should I import from?
>
> Detected files at project root:
> - `.env-template` (committed reference) — 24 entries
> - `.env` (local profile, gitignored) — 26 entries
> - `.env.production` (production profile, gitignored) — 28 entries
>
> Pick one, or paste a path.

If the user picks a profile-specific file (e.g. `.env.production`), record that profile in each parsed stamp's `environments:` field. Multiple profiles can be imported in sequence — re-running on a different profile appends that profile name to existing stamps' `environments:` arrays.

### Parse safely

Parse line by line. Skip:
- Empty lines
- Comment lines starting with `#`
- Lines without `=`
- Values (just read keys — never log or commit values)

For each `KEY=value`:
- If `env/stamps/<kebab-name>.md` exists (or any stamp with `var_name: KEY`), this var is already registered → only update `environments:` if needed
- Else, draft a new stamp

**Never echo values to the user or to logs.** The skill should never display the right-hand side of `=`. If a screen reader / accessibility helper might catch it, mask with `***`.

### Ask one question per var

For new vars, walk one at a time:

```
Var 3 of 12: POSTGRES_HOST

  Detected: var_name=POSTGRES_HOST
  Runtime hint: used by `api` runtime (from .claude/runtimes/api.md env.required)
  Profile: .env.production → environments includes 'production'

  Required?           [yes (won't boot without it) / no (optional feature)]
  Group?              [database/postgres (suggested) / other]
  Purpose?            [connection / credential / feature-flag / config / secret / url / derived]
  Type?               [string / int / bool / url / list / json]
  Description?        (one line — what is this var for?)
```

Suggest defaults based on the var name:
- `*_HOST`, `*_PORT`, `*_URL`, `*_ENDPOINT` → `purpose: connection`
- `*_USER`, `*_USERNAME` → `purpose: credential`
- `*_PASSWORD`, `*_TOKEN`, `*_SECRET`, `*_KEY`, `*_API_KEY` → `purpose: secret`
- Starts with `FEATURE_`, `ENABLE_`, `DISABLE_` → `purpose: feature-flag`, `type: bool`
- `LOG_*`, `DEBUG_*` → `purpose: config`
- Default to `required: true` unless the user explicitly says optional

Group suggestions:
- `POSTGRES_*` → `database/postgres`
- `MYSQL_*`, `MARIADB_*` → `database/mysql`
- `MONGO*` → `database/mongodb`
- `REDIS_*` → `database/redis`
- `CHROMA_*` → `database/chromadb`
- `OPENAI_*`, `ANTHROPIC_*`, `STRIPE_*`, `TWILIO_*` → `external-apis/<provider>`
- `JWT_*`, `OAUTH_*`, `AUTH_*`, `SESSION_*` → `auth/<scheme>`
- `AWS_*`, `AZURE_*`, `GCP_*`, `GOOGLE_*` → `cloud/<provider>`
- `FEATURE_*`, `ENABLE_*`, `DISABLE_*` → `feature-flags`
- `LOG_*`, `SENTRY_*`, `DATADOG_*`, `OTEL_*` → `logging`
- Anything else → ask the user

Always confirm — never auto-write a stamp without user assent.

### Bulk mode

For large `.env` files, offer:

> 47 new vars to register. Want to:
>   (1) Go one by one (recommended for the first pass)
>   (2) Bulk-confirm groups (I'll show 8 detected groups, you accept/edit each batch)
>   (3) Accept all suggestions (fast, generates drafts you can edit after)

Bulk mode still generates per-var stamps; it just trusts the heuristic defaults more.

### Write incrementally

After each var is confirmed:

1. Write `env/stamps/<kebab-name>.md` with the YAML frontmatter and a body stub
2. `git add` the new stamp
3. Move to the next var

**Never auto-commit.** Kit convention: leave changes staged for human review.

### Update ENV.md (optional)

After all vars are processed, offer:

> Update `env/ENV.md` with new entries grouped by their `group:` field? [yes / no / show-me-first]

If yes: re-render `ENV.md` from all stamps, preserving any project-authored body text outside the auto-generated groups.

### Resume gracefully

If `/import-env` is invoked again later (e.g. after adding new vars to `.env`), the skill:
- Re-parses the file
- Skips vars that already have stamps
- Adds the current profile name to existing stamps' `environments:` if not already listed
- Walks the user through any new vars only

### Surface unknowns honestly

If a var name doesn't match any heuristic and the user can't articulate the purpose:
- Don't make one up
- Set `purpose: config` (the most neutral)
- Write `description: TODO — figure out what this is for`
- Flag it in the final report ("3 vars marked TODO — investigate before relying on these stamps")

## Output structure

When the skill finishes, render:

```markdown
## ✓ Env vars imported from .env.production

**Source:** `.env.production`
**Profile recorded:** production

### Stamps created (12)

- `env/stamps/postgres-host.md` (required, connection)
- `env/stamps/postgres-password.md` (required, **secret**)
- `env/stamps/chromadb-host.md` (required, connection)
- `env/stamps/openai-api-key.md` (required, **secret**)
- `env/stamps/log-level.md` (optional, config — default `info`)
- ...

### Stamps updated (3)

Existing stamps with `production` added to their `environments:` array:
- `env/stamps/jwt-secret.md`
- `env/stamps/sentry-dsn.md`
- `env/stamps/feature-new-checkout.md`

### Skipped (2)

Lines that couldn't be parsed:
- Line 14: malformed (missing `=`)
- Line 31: comment

### Next steps

1. Review the diff: `git diff --staged env/stamps/`
2. Inspect TODO descriptions: `grep -l 'TODO' env/stamps/*.md`
3. Update `env/ENV.md` to reflect new groupings (re-run with `--update-env-md` or edit by hand)
4. Commit: `git commit -m "chore: import env vars from .env.production into stamps"`
```

## What this skill does NOT do

- **Never reads values into stamps.** Only var names and metadata.
- **Never echoes values.** Even in error messages.
- **Never auto-commits.** Stages stamps for human review.
- **Doesn't write the `.env*` files.** Only reads them.
- **Doesn't enforce stamp model schema.** Drafts a best-effort stamp; user reviews and edits.

## When to invoke this skill

- New project, has existing `.env` files, no stamps yet — bulk import all at once
- Existing project, added a few new vars to `.env`, want to register them — incremental run
- Migrating from another env-management system to the kit's stamp model
- Auditing — running on `.env.production` to see what's been added since the last run

If a project has no `.env*` files at all, this skill has nothing to import. Write stamps by hand (see `env-rules.md` for the template).

---

**See also:** `env-rules.md` (full stamp model and conventions), `stamps.md` (universal stamp pattern), `setup-deploy` (related interactive setup skill).
