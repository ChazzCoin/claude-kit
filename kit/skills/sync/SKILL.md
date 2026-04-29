---
name: sync
description: Reconcile this project's `.claude/` against the upstream claude-kit foundation repo. Two phases — (1) the synced kit layer (skills, task-rules, templates) where drift is diff'd and pulls proposed; (2) the bootstrap layer where any new bootstrap templates the kit has shipped that don't exist locally yet are surfaced as installable. Existing project-content (CLAUDE.md, PHASES.md, etc.) is never overwritten. When `bootstrap/CLAUDE.md.template` has gained sections the project's CLAUDE.md is missing, surfaces a heads-up with the block to insert. Never auto-commits, never overwrites local overrides without approval. Triggered when the user wants to pull foundation updates — e.g. "/sync", "pull latest from claude-kit", "are my skills up to date", "sync the foundation".
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
- **Bootstrap files are off-limits *for overwrite*.** Files listed
  in the kit's `bootstrap/` section are project-content once they
  exist; this skill never overwrites them. But the kit can grow
  *new* bootstrap templates over time (e.g. `pact.md.template`,
  `welcome.md.template`, `bookmarks.md.template`). For those:
  - **Bootstrap file exists locally** → leave it. Project owns it.
  - **Bootstrap file missing locally, kit ships a template** →
    surface as **installable**. User says yes, the template is
    copied to the project (preserving `{{PLACEHOLDER}}` markers
    for the user to fill in).
  - This makes `/sync` the one-stop command for keeping a project
    current with the kit, without ever risking project-content
    overwrites.

  Files always preserved as-is when they already exist:
  - `CLAUDE.md` — project-specific by definition.
  - `tasks/PHASES.md`, `tasks/ROADMAP.md`, `tasks/AUDIT.md` — the
    project's own history.
  - `.claude/foundation.json` — only updated to bump the
    `pinned_sha` and `last_synced` after a successful sync.

- **CLAUDE.md heads-up only — never edit.** When the kit's
  `CLAUDE.md.template` has gained sections (e.g. the
  "Auto-loaded primitives" `@`-import block) that the project's
  CLAUDE.md doesn't have, this skill **surfaces a heads-up** with
  the suggested block — but does not edit CLAUDE.md. The user
  inserts manually or routes through `/codify`.
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

Read `$TMP/claude-kit/MANIFEST.json`. Two relevant arrays:

- **`kit.files`** — synced files. Drift here is reconciled in
  Step 4 (Phase 1).
- **`bootstrap.files`** — one-time files. Reconciled in Step 4b
  (Phase 2, install-only).

### Step 4 — Phase 1: Diff each kit file against local

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

### Step 4b — Phase 2: Bootstrap reconciliation (install-only)

For each entry in `bootstrap.files`:

1. Read the `to` path (where the file lands in the project).
2. Check if the target file exists in the project.
3. Classify:
   - **bootstrap_present** → file exists locally. Skip. Project
     owns it. Don't surface.
   - **bootstrap_installable** → file is missing locally; the kit
     ships a template for it. Surface as installable.

This is one-way — bootstrap files are only ever *installed* by
`/sync` if missing. Existing project content is never touched.

**Special case: `CLAUDE.md`.** Beyond the file-existence check,
also detect *block drift*:

1. Read the kit's `bootstrap/CLAUDE.md.template`.
2. Read the project's `CLAUDE.md` if present.
3. Look for known anchor sections in the template that *aren't*
   in the project. Current anchors to check:
   - `## 🪡 Auto-loaded primitives` — the `@`-import block for
     `welcome.md`, `pact.md`, `bookmarks.md`, `wont-do.md`,
     `docs/notes/INDEX.md`.
4. If an anchor section is missing in the project, surface as a
   **CLAUDE.md heads-up** (not an installable). The skill
   *prints* the block to insert; never edits CLAUDE.md.

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

## 📦 Bootstrap files installable *(missing locally; safe to install)*

Bootstrap templates the kit ships that aren't in this project yet.
Install copies the template to the project; placeholders stay as
`{{...}}` for you to fill in. Once installed, the file is yours
— `/sync` never touches it again.

- **`.claude/<file>`** ← `bootstrap/<template>` *(<one-line
  description from MANIFEST.json `note`)*
- …

*(Section omitted if no installables found.)*

---

## 📝 CLAUDE.md heads-up *(no edits made)*

The kit's `CLAUDE.md.template` has sections your project's
`CLAUDE.md` is missing. **This skill never edits CLAUDE.md** —
the block is shown for you to insert manually (or route through
`/codify`).

### Missing section: `<anchor heading>`

```markdown
<the literal block from the template, ready to paste>
```

**Where it goes:** typically near the top of `CLAUDE.md`, right
after the project description.

*(Section omitted if no drift detected.)*

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
5. **Bootstrap installs** (Phase 2): copy `bootstrap/<template>`
   → the project's `to` path. Preserve `{{PLACEHOLDER}}` markers
   verbatim — the user fills them in afterward. **Never** install
   if the target file already exists.
6. **CLAUDE.md heads-up:** never auto-applied. Just printed in
   the report. The user inserts the block manually or runs
   `/codify` with the block as input.

After all approved changes are applied:

- Write the new `pinned_sha` and `last_synced` into
  `.claude/foundation.json`.
- Update the `overrides` list per any conflict choices.

### Step 7 — Closing summary

Render a tight summary of what was applied, what was skipped, and
where the pin is now:

```markdown
## ✅ Sync applied

**Phase 1 (synced kit):**
- 3 files updated: `<paths>`
- 1 file added: `<path>`
- 1 conflict deferred: `<path>` (you chose: keep local; added to overrides)

**Phase 2 (bootstrap):**
- 2 templates installed: `<paths>` *(placeholders left for you to fill)*
- *(or "no installable bootstrap files this round")*

**CLAUDE.md heads-up:**
- 1 missing section flagged: `<anchor>` — block printed above for
  manual insertion, or run `/codify` to land it.
- *(or "CLAUDE.md is up to date with the template")*

**Pin bumped:** `<old>` → `<new>`

`.claude/foundation.json` updated. Run `git diff` to review,
commit when ready.
```

## What you must NOT do

- **Don't auto-commit.** Same rule as every other skill that
  modifies files.
- **Don't overwrite existing bootstrap files.** Phase 2 only
  *installs* missing ones. If the target file exists, leave it.
- **Don't edit CLAUDE.md.** Even when the kit's template has
  drifted ahead of the project's CLAUDE.md, this skill never
  edits CLAUDE.md — it surfaces a heads-up with the block to
  insert manually.
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
- **Bootstrap upgrade after the kit's first /sync that ships an
  upgraded /sync skill.** Chicken-and-egg case: the user's
  current `/sync` doesn't know about Phase 2 yet. After the
  first Phase 1 pull (which updates the `/sync` skill itself),
  ask the user to run `/sync` again to pick up the new
  bootstrap reconciliation behavior. One time only.

## When NOT to use this skill

- **Bootstrapping a new project** → use the kit's `bin/init` script.
- **Pushing improvements upstream** → manual git operation in the
  kit repo.
- **Reviewing what changed in the kit historically** → `git log`
  in the kit repo.
- **Doc reconciliation within the project** → `/update-docs`.
- **Schema reconciliation** → `/schema-check`.

## What "done" looks like for a /sync session

- A two-phase report: kit drift (Phase 1) classified; bootstrap
  installables and CLAUDE.md heads-up (Phase 2) listed.
- The user picks what to take. Approved Phase 1 changes are
  applied; approved Phase 2 installs land template content
  (placeholders preserved); CLAUDE.md heads-up is printed for
  manual insertion (never auto-edited).
- The pin in `.claude/foundation.json` is bumped to the kit's
  current HEAD.
- A closing summary tells the user what was applied across both
  phases and what to do next (typically: fill in any
  `{{PLACEHOLDER}}` markers in installed templates, optionally
  insert any flagged CLAUDE.md sections, then `git diff` +
  commit).
