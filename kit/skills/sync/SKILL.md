---
name: sync
description: Reconcile this project's `.claude/` against the upstream claude-kit foundation repo. Fetches the kit at HEAD, diffs every kit-managed file (skills, task-rules, task-template), classifies drift (kit-only updates / both changed / local override / new file / removed file), and proposes per-file pulls. Never auto-commits, never overwrites local overrides without approval, never touches project-content files (CLAUDE.md, PHASES.md, ROADMAP.md, AUDIT.md). Triggered when the user wants to pull foundation updates — e.g. "/sync", "pull latest from claude-kit", "are my skills up to date", "sync the foundation".
---

# /sync — claude-kit foundation sync

Reconcile this project's `.claude/` directory against the upstream
claude-kit repo. Pull updates the user wants; preserve local overrides
the user has intentionally diverged on.

This is a **one-way** sync: kit → project. Pushing changes back to
the kit is a manual git operation by design — improvements get
reviewed before they propagate.

Per CLAUDE.md ethos: honest about conflicts. Surface drift; don't
silently merge.

## Behavior contract

- **Read `.claude/foundation.json` first.** It tells you the kit
  repo URL, the branch to track, the last-synced commit SHA, and the
  list of files this project has intentionally overridden. If
  `foundation.json` is missing, this project wasn't bootstrapped
  from claude-kit — stop and explain.
- **Fetch the kit fresh.** Clone (or shallow-clone) the kit repo at
  the tracked branch's HEAD into a temp directory. Never assume a
  cached copy is current.
- **Diff every kit-managed file** (per the kit's `MANIFEST.json`)
  against the local copy. Classify:
  - **Kit changed, local unchanged** → safe pull, propose.
  - **Kit unchanged, local changed** → local override; respect it.
    Surface for awareness only.
  - **Kit changed AND local changed** → conflict; show both diffs,
    let user choose.
  - **New file in kit** → propose adding.
  - **File removed from kit** → propose removing (deletes are
    destructive — confirm explicitly).
- **Bootstrap files are off-limits.** Files listed in the kit's
  `bootstrap/` section (CLAUDE.md, PHASES.md, ROADMAP.md, AUDIT.md,
  foundation.json) are project-content; this skill never touches
  them. They're listed here for clarity:
  - `CLAUDE.md` — project-specific by definition.
  - `tasks/PHASES.md`, `tasks/ROADMAP.md`, `tasks/AUDIT.md` — the
    project's own history.
  - `.claude/foundation.json` — only updated to bump the
    `pinned_sha` and `last_synced` after a successful sync.
- **Propose, don't apply by default.** First pass produces a report.
  User approves which changes to apply. Only then does the skill
  copy files.
- **Never auto-commit.** Apply edits to the working tree; let the
  user review with `git diff` and commit when ready.
- **Bump the pin on success.** After applying any updates, write the
  fresh kit SHA into `.claude/foundation.json` and update
  `last_synced` to today's date.
- **Honest about overrides.** When applying an update to a file the
  project had marked as override, ask explicitly — "this was on
  your overrides list; pulling would discard your local edits.
  Confirm?"

## Process

### Step 1 — Verify configuration

Read `.claude/foundation.json`. Required fields:

```json
{
  "kit": { "repo": "<url>", "branch": "<branch>" },
  "pinned_sha": "<sha or 'unpinned'>",
  "last_synced": "<YYYY-MM-DD>",
  "overrides": ["<relative path>", ...]
}
```

If the file is missing, malformed, or doesn't have a `kit.repo`
URL, **stop**. Explain the project doesn't appear to be bootstrapped
from claude-kit and offer two paths:
1. Bootstrap from kit: clone the kit, run its `bin/init`.
2. Manual pin: write a foundation.json by hand if the user knows
   what they're doing.

### Step 2 — Fetch the kit

```sh
TMP=$(mktemp -d)
git clone --depth 1 --branch <branch> <kit.repo> "$TMP/claude-kit"
KIT_SHA=$(git -C "$TMP/claude-kit" rev-parse HEAD)
KIT_SHA_SHORT="${KIT_SHA:0:12}"
```

If the clone fails (network, auth, repo gone), surface the error
and stop. Don't fall back to anything.

### Step 3 — Read the kit's manifest

Read `$TMP/claude-kit/MANIFEST.json`. The `kit.files` array tells
this skill what files are kit-managed. Any policy other than
`directory-mirror` or `file-replace` is treated as "skip — not in
sync scope" (bootstrap files have other policies).

### Step 4 — Diff each kit file against local

For each kit-managed file:

1. Compute the kit version's hash and the local version's hash.
2. Determine the previous-kit version: if `pinned_sha` is set, fetch
   that commit's version of the same file via `git show
   <sha>:<path>`. If `pinned_sha` is `"unpinned"` or unreachable,
   treat as "unknown previous" — fall back to two-way diff (kit
   vs local) instead of three-way.
3. Classify:
   - **kit_only_changed**: kit ≠ pinned, local == pinned.
   - **local_only_changed**: kit == pinned, local ≠ pinned.
   - **both_changed**: kit ≠ pinned, local ≠ pinned, kit ≠ local.
   - **converged**: kit ≠ pinned, local ≠ pinned, kit == local.
   - **unchanged**: kit == pinned == local.
   - **new_in_kit**: kit has it, local doesn't, pinned didn't.
   - **removed_in_kit**: pinned had it, kit doesn't.
4. If the file is in `overrides`, mark it `local_only_changed` even
   if the hashes match — the user has declared this file
   project-specific.

### Step 5 — Render the report

```markdown
# 🔁 claude-kit sync — <project name>

> **Headline.** <one sentence — e.g. "Kit moved from <pinned-sha> →
> <head-sha>; 3 skills updated, 1 conflict in task-rules.md, 0
> files removed.">

**Source.** <repo url> @ <branch>
**Pinned at.** `<pinned-sha>` (last synced <date>)
**Kit HEAD.** `<head-sha>` (<N commits ahead>)

---

## ⬇️ Updates available *(safe pulls)*

Files where the kit has new content and your local copy hasn't
been touched. These are the easy wins.

- **`.claude/skills/<name>/SKILL.md`**
  ```diff
  <truncated diff — first 10 lines, "…" for the rest>
  ```
  → Full diff: <link or "ask to expand">

*(group by file, list all)*

---

## ⚠️ Conflicts *(both changed)*

Files where the kit AND your local copy diverged from the pin. You
have to choose.

### `<path>`

**Your local change** *(diff from pin):*
```diff
<your local diff>
```

**Kit's change** *(diff from pin):*
```diff
<kit's diff>
```

**Options:**
1. Take kit's version (discard local)
2. Keep local (mark as override; never overwrite)
3. Manually merge (open both files; sync skips this one)

---

## 🛡 Local overrides *(no action needed)*

Files this project has intentionally diverged on. The kit's version
is shown for awareness only — it won't be applied unless you remove
the override.

- `<path>` — overridden since `<sha>` *(or "since bootstrap" if
  no record)*

---

## ➕ New in kit

Files the kit added since your pin. Propose adding.

- `<path>` — <one-line description from frontmatter or first
  heading>

---

## ➖ Removed from kit

Files the kit removed since your pin. Propose deleting locally.
**Destructive — confirm before applying.**

- `<path>` *(was: <sha-where-removed>)*

---

## Bottom line

<2–3 sentences. What's the recommended action? "Apply all 3 safe
pulls; defer the conflict in task-rules.md until you've reviewed
both diffs" or "All current; no action".>

**To apply changes**: tell me which to take — e.g. "all safe
pulls", "skip the conflict", "take kit on task-rules.md", "add the
new skill", "remove the deleted one". I'll apply, bump the pin,
and stop. Commit when you're ready.
```

### Step 6 — Apply approved changes

Only after the user picks what to apply:

1. **Safe pulls**: copy kit version → local.
2. **Conflict resolutions**: per the user's choice.
   - "take kit" → copy kit version, remove from `overrides` if
     present.
   - "keep local" → no file change; **add to `overrides` list**.
   - "manual merge" → no file change; flag for the user; don't
     touch overrides.
3. **New files**: copy from kit.
4. **Removed files**: `git rm` (or just `rm` if not yet tracked).

After all approved changes are applied:

- Write the new `pinned_sha` and `last_synced` into
  `.claude/foundation.json`.
- Update the `overrides` list per any conflict choices.

### Step 7 — Closing summary

Render a tight summary of what was applied, what was skipped, and
where the pin is now:

```markdown
## ✅ Sync applied

- 3 files updated: `<paths>`
- 1 file added: `<path>`
- 1 conflict deferred: `<path>` (you chose: keep local; added to overrides)
- Pin bumped: `<old>` → `<new>`

`.claude/foundation.json` updated. Run `git diff` to review,
commit when ready.
```

## What you must NOT do

- **Don't auto-commit.** Same rule as every other skill that
  modifies files.
- **Don't touch project-content files.** CLAUDE.md, PHASES.md,
  ROADMAP.md, AUDIT.md, the project's own task specs in
  `tasks/{backlog,active,done}/` — never. Overwriting any of these
  is a bug in the skill.
- **Don't merge in the conflict case.** Three-way merge tooling
  (git merge-file, etc.) is tempting but produces wrong answers
  often enough that the safer policy is "show both, let the user
  decide." If the user wants automated merging, they can use
  `git merge-file` themselves.
- **Don't push.** This is a one-way sync. If the user wants to push
  improvements back to the kit, they do it manually with normal
  git.
- **Don't bypass the override list.** A file marked as overridden
  stays put unless the user explicitly removes the override.

## Edge cases

- **No network / repo unreachable.** Fail loudly. Don't fall back
  to a stale cache.
- **Kit branch doesn't exist.** Fail. Tell the user to fix the
  branch reference in `foundation.json`.
- **Local working tree dirty.** Warn the user before applying —
  they might lose track of which changes came from where if
  unrelated edits are mixed in. Offer to abort.
- **First sync after migrating to claude-kit** (no `pinned_sha`):
  treat every file as "new pin" — show what kit currently has,
  ask the user to confirm wholesale adoption, then stamp the pin.
- **Kit changed file moved or renamed.** Treat as remove + add.
  This is rare and the kit should avoid renames.

## When NOT to use this skill

- **Bootstrapping a new project** → use the kit's `bin/init` script.
- **Pushing improvements upstream** → manual git operation in the
  kit repo.
- **Reviewing what changed in the kit historically** → `git log`
  in the kit repo.
- **Doc reconciliation within the project** → `/update-docs`.
- **Schema reconciliation** → `/schema-check`.

## What "done" looks like for a /sync session

- A clear report of kit drift, classified.
- The user picks what to take.
- Approved files are applied to the working tree, uncommitted.
- The pin in `.claude/foundation.json` is bumped to the kit's
  current HEAD.
- A closing summary tells the user what was applied and what to do
  next (typically: `git diff` + commit).
