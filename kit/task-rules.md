# Task Execution Rules

These rules apply to **every** task in `tasks/`. They extend
`CLAUDE.md` (which owns project-specific conventions, tech-stack
specifics, schema ownership, and concrete commands). Read both before
starting work.

> **Note on commands.** This file is generic by design. Specific
> commands (build, test, run, deploy) are documented in `CLAUDE.md`
> for each project. Where this file says "the project's verification
> command," see `CLAUDE.md` for the actual string.

> **Platform extensions.** Files in `.claude/` named with a platform
> prefix — e.g. `ios-task-rules.md`, `web-task-rules.md`,
> `python-task-rules.md` — extend this file for platform-specific
> work. **Read the relevant prefix files based on the work at hand**:
>
> - Working on iOS code or anything affecting the iOS app → read
>   `ios-task-rules.md`
> - Working on web code → read `web-task-rules.md`
> - Working on Python code → read `python-task-rules.md`
> - Cross-boundary work (e.g. iOS HTTP client to a Python API) →
>   read both relevant prefix files
> - Pure cross-platform work → just this file
>
> Same convention applies across the whole `.claude/` tree:
> `ios-conventions.md`, `web-deploy.md`, etc., and skills like
> `ios-release/`, `web-deploy/`. The prefix is a discovery hint, not
> a gate — every project pulls all files; each work session reads the
> ones that apply.

> **Output styles reference.** When a skill renders structured
> output, consult `.claude/output-styles.md` — a catalog of named
> visual patterns (roadmap timeline, status dashboard, tree
> breakdown, confidence-tagged findings, two-part report, etc.) with
> when-to-use / when-not-to-use guidance. Skills cite styles by
> name; this file is where the pattern lives. Match shape to data,
> not aesthetic preference. Plain markdown is fine when no catalog
> style fits.

## Scope discipline

- One task = one PR. Do not bundle unrelated changes.
- Touch only the files listed in the task's "Files expected to change"
  section. If you need to touch something outside that list, **add it
  to the task file with a one-line justification before editing.**
- Do not refactor adjacent code "while you're in there." Out of scope.
- Do not add features, abstractions, or config not required by the
  acceptance criteria.

## Schema discipline (extends CLAUDE.md)

Some projects mirror schemas owned by another team or platform (iOS
Realm models, backend protobufs, OpenAPI specs, partner API contracts,
etc.). When that's true:

- **The canonical source owns the schema.** Field names are
  byte-identical to the canonical definition.
- **Never invent, rename, or "correct" a field.** If a field name
  isn't in the project's mirror models or referenced in the task's
  source, **stop and write a blocker note** — do not guess.
- **Never modify the project's schema-registry file** (the file that
  `CLAUDE.md` identifies as the canonical mapping — typically a
  `paths.js` / `types.ts` / `schema.go` / similar) without a referenced
  source-of-truth.

If the project does not have an externally-owned schema, this section
is informational only. `CLAUDE.md` should state explicitly whether the
project owns its schema or mirrors one.

## Files that require explicit permission to modify

Touching any of these = blocker, not autonomous work. The exact list
varies per project — `CLAUDE.md` should enumerate the gated files for
this project. Common categories:

- **Infrastructure / deploy config** (e.g. `firebase.json`, `*.tf`,
  CI workflow files, `Dockerfile`, hosting config)
- **Security / secrets** (`.env`, `.env.example`, security-rules
  files, IAM config)
- **Dependency manifests** (`package.json`, `Cargo.toml`, `go.mod`,
  `Gemfile`, `pyproject.toml`, `Package.swift`) — adding, upgrading,
  or removing
- **Build / runtime config** (e.g. `vite.config.*`, `webpack.*`,
  `tsconfig*.json`, `babel.config.*`)
- **Process / kit files** (`CLAUDE.md`, `.claude/task-rules.md`,
  `.claude/task-template.md`, `.claude/skills/`, `.github/`, `.git/`)

If a task requires one of these, surface it in the task file's blocker
section and stop.

## Branch and PR rules

- Branch name: `task/TASK-XXX-short-slug` (or `hotfix/HOTFIX-NNN-slug`,
  or `chore/<slug>` for non-task work).
- Commit style: matches existing repo style — typically a one-line
  summary, blank line, prose body explaining the *why*, blank line,
  `Co-Authored-By` trailer. Check recent `git log` to confirm.
- PR title: `TASK-XXX: <task title>` (or the equivalent for other
  branch types).
- PR body must include:
  - Link or path reference to the task file
  - Checklist copy of the acceptance criteria with ☑/☐
  - "Files changed" matching the task's expected list (call out
    deviations explicitly)
  - "How I verified" — manual steps + test command output

## Verification gates (must pass before opening PR)

The specific commands come from `CLAUDE.md`. The contract is the same
across projects:

1. **Build** — the project's build command (per `CLAUDE.md` or
   `/build`) must succeed with no new warnings.
2. **Verification suite** — the project's contract test command (per
   `CLAUDE.md`) must pass headless / non-interactive. **This is the
   gate**, not the watched/headed variant. Agents must run the
   non-interactive version because there is no display.
3. **Local run check** — the project's run command (per `CLAUDE.md`
   or `/run`) boots and the implemented flow works.
4. **No console / log errors** on the affected screens or paths.

Every new feature task should pair with a test artifact per the
project's convention (e.g. an E2E spec named after the task, a unit
test file, a scenario in a feature spec). `CLAUDE.md` documents the
project's test-pairing convention.

**Iteration vs. gate:** while working a task, run only that task's
test (using the project's filtering/watched mode per `CLAUDE.md`).
Re-running the full suite on every edit wastes time. Before opening
the PR, run the unfiltered verification command once to confirm the
gate is green.

If any gate fails and you can't fix it in scope, **stop and write a
blocker note**. Do not disable tests. Do not bypass hooks
(`--no-verify` and equivalents).

## Honest reporting

- If acceptance criteria can't all be met, the task is **not done**.
  Open the PR as draft, mark unchecked criteria, write a blocker.
- If you discover the task's premise is wrong (e.g., an upstream
  source doesn't behave the way the task assumes), stop and write a
  blocker. Do not silently redesign the feature.
- Never mark a checklist item complete that you didn't actually verify.
- "Tests pass" means you ran them and saw green, not "the code looks
  like it should pass."

## State machine

```
tasks/backlog/  →  tasks/active/  →  tasks/done/
```

- Move the task file with `git mv` as you transition states.
- `active/` should hold at most one task at a time per agent.
- `done/` only after PR is merged. Open-but-unmerged PRs stay in
  `active/`.

## Closing report (mandatory)

When a task's PR is opened, the closer **must** post a completion
report in chat with this exact shape. The point is one-glance
status — the reviewer scans the table in 5 seconds and decides
whether to dig in. The "What you need to do next" section is
non-negotiable; every task tells the reviewer exactly what action
to take.

```markdown
## TASK-XXX completion report

| | |
|---|---|
| **Name** | <descriptive name from the task spec> |
| **Status** | ✅ Ready for review / ⚠️ Blocked / ❌ Failed |
| **Branch** | `task/TASK-XXX-slug` |
| **PR** | [#N](url) |

**Tests**
- Full headless gate: <count> green · <time>
- TASK-XXX focused run: ✅/❌ · <time>

**Build**: clean / <warnings if any>

**What changed**
- One-line bullets, the actual deltas

**What you need to do next** (in order)
1. Concrete action
2. Concrete action

**Things I noticed** (not blockers — can be empty)
- ...
```

Rules:
- **Status** is one of three states. Never "almost ready" or
  "mostly done." If acceptance criteria aren't met, status is
  ⚠️ Blocked or ❌ Failed and the report explains why.
- **Test results are real numbers**, not "tests pass." Cite the
  actual count and the actual time from the run output.
- **Don't tick boxes you didn't verify.** Same rule as the rest
  of this file.
- Optionally include the same block in the PR body so it's also
  visible on GitHub. The chat report is the contract; the PR
  embed is convenience.

**Chore PRs follow the same shape.** A chore is any PR that isn't
a feature task — process docs, scaffolding, dependency upgrades,
config tweaks. The closing report is identical except:

- The status states are the same. ✅ / ⚠️ / ❌. No middle ground.
- "Tests" cites the verification gate result. **Even a docs-only
  chore runs the project's verification command before opening the
  PR** — proves the change didn't accidentally break anything. If
  you skip it, say so explicitly with a one-line reason.
- "What changed" can be terse — one line is fine.

## Audit log (mandatory)

`tasks/AUDIT.md` is the curated, append-only chronological record of
meaningful actions taken on the project — releases, task ships, rule
changes, scaffolding events. Git log is the ground truth; this file is
the human-readable layer on top.

### What to log

- 🚀 **Production deploys.** Every tagged release gets an entry.
  Include the version, the tag's commit SHA, and the integration PR
  number.
- 📦 **Task ships** (PR merged to `main`). One line per task.
- 📜 **Rule / process changes** in `task-rules.md`. One line
  describing the rule.
- 🏗 **Major scaffolding** (new doc, new convention, new tooling that
  affects everyone).
- 🔥 **Hotfixes.** One line per hotfix release, with link to the
  postmortem.
- ⚠️ **Incidents** and **honest tradeoff calls** that future readers
  will need to understand. Receipts matter.

### What NOT to log

- Every commit. Git log already has those.
- Routine refactors that don't change behavior.
- Drafts that don't ship.
- Per-line code review feedback.

### How to write entries

- **Newest entries on top** within their date section.
- ISO date headers (`## YYYY-MM-DD`).
- One to a few lines per entry. Bullet form. Lead with the *what*
  and end with the receipts (PR number, tag, commit SHA).
- Use the emoji set sparingly: 🚀 for releases, 📦 for task ships,
  📜 for rules, 🏗 for scaffolding, 🔥 for hotfixes, ⚠️ for incidents
  / tradeoffs.
- Don't backdate. If you forgot to log something, log it today with
  `(retroactive)` in the entry.

### Maintenance trigger

Every batch's closing report is the prompt to update `AUDIT.md`.
Specifically:

- When a task PR merges → append a "task shipped" entry.
- When a deploy completes → append a "🚀 Released vX.Y.Z" entry.
- When `task-rules.md` changes → append a "📜 rule added/changed"
  entry.
- When a hotfix ships → append a "🔥 Hotfix" entry with link to the
  postmortem.

If a batch ships multiple things in one chat turn, append all the
entries together. If more than one date is involved, split across
the date headers.

## Phase structure (mandatory)

Phases are first-class. Every task belongs to exactly one phase — no
orphans, no "we'll figure out where this fits later." This keeps work
scoped and the backlog navigable.

### Each phase has three things

1. **A name.** "Phase N: <short noun-phrase>". The name should
   communicate the scope at a glance — e.g. "Phase 3: Core module
   CRUD", "Phase 8: Code cleanup".
2. **A scope paragraph.** 2–4 sentences in `tasks/ROADMAP.md`
   directly under the phase heading. Says what's in, what's out, and
   (when useful) what success looks like. The scope is the *contract*
   — if a task doesn't fit it, the task belongs in a different phase.
3. **An ordered list of tasks.** Bulleted under the scope paragraph
   in ROADMAP. Each entry is `- TASK-NNN — <title>`. Order matters —
   top-down implies suggested ship order.

### `tasks/ROADMAP.md` is the registry

Phase membership lives in ROADMAP.md, nowhere else. Tasks don't
declare their phase in their own spec file (that would drift). The
skills (`/roadmap`, `/backlog`) parse ROADMAP to build the task→phase
map.

### Adding a task

1. Decide the phase first. If unclear, ask the user.
2. Add the task line under that phase's bulleted list in `ROADMAP.md`.
3. Create the spec file in `tasks/backlog/` (per the priority rule).

If a task doesn't fit any existing phase, **propose a new phase**
rather than dumping it into "cross-cutting" or fudging the fit.

### Creating a new phase

1. Pick a name.
2. Write the scope paragraph (2–4 sentences). Make in/out explicit.
3. Add the phase section to `ROADMAP.md` in its sequence position.
4. Then file tasks under it.

Don't create empty phases speculatively. A phase exists because it
has work in it.

### Moving a task between phases

Single edit to `ROADMAP.md`: remove the task line from the old phase's
list, add it to the new phase's list. The spec file itself doesn't
move (it stays in `backlog/active/done` based on state, not phase).

### Cross-cutting tasks

Reserved for genuinely orthogonal work that doesn't belong to a named
phase — typically infrastructure that any phase might depend on. Use
sparingly. If two or more cross-cutting items accumulate that share a
theme, that's a signal to lift them into a named phase.

## Adding tasks to the backlog (priority rule)

When the user says "add a task" without specifying urgency, **append
to `tasks/backlog/` as a minimal stub and stop there.** Don't:

- Promote it ahead of other tasks in the roadmap.
- Draft a full spec when a stub will do — full specs are expanded
  *close to implementation*, not at filing time.
- Reshuffle phase ordering, sequence diagrams, or roadmap prose to
  "make room."
- Subdivide the task into siblings unless the user explicitly asks.
  Filing one task means filing one task, not five.

A minimal stub is title + 1-line user story + 1-line "why" +
`STATUS: STUB — full spec drafted before implementation`.
Anything more is speculative work.

The user controls priority. They will say so explicitly when they
want it. Common signals:

- **"Emergency / do it now"** → halt current work; this jumps to the
  front of the active queue.
- **"Needs to ship before X"** → place ahead of X in the roadmap and
  flag any sibling tasks that depend on it.
- **"X needs to ship first, then this can come next"** → place
  immediately after X.
- **"For a future phase"** / **"later"** → backlog only, no
  re-sequencing.
- *No qualifier given* → backlog only, no re-sequencing. Default
  behavior. Cheaper to ask later than re-task now.

When unsure, ask: *"backlog only, or should this jump the queue?"* —
one round trip beats a wrong placement.

## Batch handoff (mandatory)

When a task or batch of tasks reaches "all closing reports posted,
all PRs open, all gates green," **do not stop and wait**. The loop
has more steps. Run them automatically:

### Step 1 — Merge approved tasks into a temp integration branch

Create `integration/<lowest-id>-to-<highest-id>` (or
`integration/<short-name>` if the batch isn't a contiguous range).
Branch off latest `origin/main`. Merge each task branch into it
with `git merge --no-ff`. Resolve conflicts (shared helper files
are typical offenders — keep the canonical version, drop duplicates).

Push the integration branch. **Do not merge to main yet.**

### Step 2 — Spin up the local run

Use `/run` (or the project's run command per `CLAUDE.md`) to bring
up the local environment so the reviewer sees the integration build
the moment the closing report finishes posting. No manual setup, no
clicking through tabs to find a URL.

### Step 3 — Enter "notes & task creation standby"

Wait for the reviewer's verdict. While waiting:

- **Do** accept new task ideas, bug reports, or notes the reviewer
  surfaces during testing. Draft full task specs into
  `tasks/backlog/` **without committing** — keep the worktree clean
  for their session. Same pattern used during the prior review window.
- **Do** answer questions about what's in the integration branch.
- **Do not** start new feature work. Don't speculatively merge more
  PRs. Don't auto-deploy. Don't kill the running process.
- **Do** keep the local run going until the reviewer signals done.

This is a behavioral state, not a blocking wait — the reviewer may
take minutes or hours.

### Step 4a — On approval ("merge", "ship it", "looks good")

- Merge integration → main with `gh pr merge --merge --delete-branch`
- Verify the child PRs auto-close as merged
- Clean up local + remote stale branches and pull main fresh
- **Ask** explicitly: "Deploy now, or hold? If yes, I'll tag the
  release as `vX.Y.Z` — confirm the version." Do not auto-deploy.
  Production deploys are user-confirmed every time. See "Production
  deploy tagging" below for version semantics.

### Step 4b — On rejection ("no", "wait", "broken")

Halt. Do not merge. Do not deploy. Propose a triage plan with two
options:

1. **Scrap the whole batch.** Close the integration branch and the
   offending PRs, leave main as it was. Re-task as needed.
2. **Per-task isolation.** Identify which specific task(s) failed
   verification. Drop those PRs from the integration merge, keep the
   passing ones. Re-build the integration branch from the passing
   subset. Re-task only the failing ones with the reviewer's feedback
   baked into the new spec.

Recommend (2) by default — it salvages the work that did pass.
Recommend (1) only if the failure is structural (e.g., a shared
foundation task is broken and everything depending on it is suspect).

Wait for the reviewer's decision before doing anything.

## Production deploy tagging (mandatory)

Every successful production deploy from `main` is tagged. Tags are
the version-controlled record of what shipped to users and when —
`git log --tags` becomes the deploy history.

### Format

Semver: `vMAJOR.MINOR.PATCH` — e.g. `v1.0.0`, `v1.2.3`. Always
prefixed with lowercase `v`. Lightweight tags are not allowed — use
**annotated** tags so the message can carry release notes.

### Bootstrap

The first tagged release is **`v1.0.0`**. If the project has been
deployed before this rule existed, that history is "pre-versioning"
and is not retroactively tagged. Versioning starts forward from the
first invocation of this rule.

### Version-bump heuristic

The closer proposes a version with reasoning; the reviewer confirms
or overrides. Do not deploy without an agreed version.

- **Patch** (`vX.Y.Z+1`) — bug fixes, copy / styling tweaks, no new
  user-visible features.
- **Minor** (`vX.Y+1.0`) — new user-visible features, additive
  changes. The default for most batches.
- **Major** (`vX+1.0.0`) — breaking changes (route changes users had
  bookmarked, removed features, schema migrations that affect
  existing users). Rare. Always paired with a user-facing note.

### Deploy + tag flow (after "yes, deploy")

The deploy command is project-specific. See `CLAUDE.md` for the
exact command, or use `/release` which orchestrates the full
sequence. The shape:

```sh
<project's deploy command per CLAUDE.md>     # e.g. npm run deploy, fastlane release, etc.
# After deploy succeeds:
git tag -a vX.Y.Z -m "<release notes>"       # on main HEAD
git push origin vX.Y.Z
```

Release-note message format (annotated tag body, multi-line):

```
vX.Y.Z — <one-line summary>

Tasks shipped:
- TASK-NNN — <name>
- TASK-NNN — <name>

Deployed: <YYYY-MM-DD HH:MM UTC>
Integration PR: #N
```

### Closing report after deploy

Include in the deploy completion report:

- The tag (`vX.Y.Z`) with a clickable link to its GitHub page
  (`https://github.com/<owner>/<repo>/releases/tag/<tag>`)
- Confirmation the tag was pushed to origin
- The merge-commit SHA that the tag points to

### Rollback semantics

The project's rollback command (per `CLAUDE.md`) reverts the live
build but does **not** move git tags. If a tagged release is rolled
back, the tag stays in place as a historical record of what was
deployed, and a new tag (typically a patch bump or `vX.Y.Z-rollback`)
marks the restored version. Document the rollback in the new tag's
message.

## Hotfix path (emergencies)

The Batch Handoff and deploy flow assume the happy path: a batch
of features stabilized, integration-tested, then shipped. When
production is broken, that flow is too slow. The hotfix path
exists for "fix is needed *now*, the queue can wait."

### When to invoke

- Production is bricked or in a clearly-bad state.
- A deployed bug is causing data loss, security exposure, or
  user-blocking errors.
- A regression caught in stage that would block the next deploy
  if shipped.

If the bug is annoying-but-not-urgent, **don't hotfix.** File a
normal task and ship in the next batch. Hotfix is a privilege
that costs queue discipline; spend it carefully.

### Flow

1. **Branch from `main`.** `hotfix/HOTFIX-NNN-slug` (HOTFIX
   numbering is independent of TASK numbering — restart at 001
   for the project, increment per incident).
2. **Single concern.** A hotfix branch fixes exactly one thing.
   Don't bundle a "while I'm here" change. Bundling defeats the
   speed argument.
3. **Verification gate is still required.** The full test gate (per
   `CLAUDE.md`) must be green. Hotfix does not mean "skip tests."
   If the test gate is broken because of the bug, surface that —
   repair it as part of the hotfix, don't bypass.
4. **PR opens with title `HOTFIX-NNN: <summary>`** and a body
   explaining the symptom, root cause, fix, and verification.
   Closing report uses the same shape as a task PR.
5. **Deploy is patch-bump only.** `vX.Y.Z` → `vX.Y.Z+1`. Major or
   minor bumps imply scope; hotfixes are scope-disciplined patches.
6. **Tag with 🔥 in the AUDIT entry** so future readers can find
   the incident chain at a glance:
   ```
   - 🔥 **Hotfix HOTFIX-NNN — <summary>.** Released vX.Y.Z+1.
     Postmortem at docs/postmortems/YYYY-MM-DD-….md.
   ```
7. **Postmortem follows.** Per the postmortem rule below, every
   hotfix triggers a postmortem within 48 hours. The point is
   the lesson, not the absolution.

### What hotfix does NOT change

- The verification gate is still the contract.
- The deploy-tagging rule still applies (annotated tag, pushed to
  origin, AUDIT entry).
- The user still confirms the deploy. "Hotfix" doesn't mean
  "auto-ship" — it means "skip the integration-batch buffer and go
  straight to a tagged release after the user confirms."

## Postmortem rule (incidents get captured)

The audit log records what shipped. The postmortem doc records
what *broke* and what we changed to prevent recurrence.

### When to write a postmortem

- Any production outage or rollback.
- Any hotfix (per the rule above — every 🔥 entry pairs with a
  postmortem).
- Any data loss / corruption / mis-stamp event.
- Any regression caught in production rather than pre-deploy.
- Near-misses that revealed a real gap, even if the user wasn't
  affected.

Bugs caught in code review or normal test runs do **not** need
postmortems — those are the system working.

### Where it lives

`docs/postmortems/YYYY-MM-DD-short-slug.md`. Create the directory
on first use. Use the `/postmortem` skill to draft.

### Linkage to AUDIT

Every postmortem appends an entry to `tasks/AUDIT.md` with the ⚠️
emoji and a link to the postmortem file. Hotfix-driven postmortems
also link to the 🔥 entry that triggered them.

### Action items become tasks

A postmortem with no action items isn't done — it's a story. Real
postmortems end with concrete, owned, linked tasks. File them via
`/task` immediately after the postmortem is drafted. "Pending
discussion" is acceptable for genuinely-unresolved items, but not
as a default.

## Dependency hygiene

Dependencies drift. Drift becomes vulnerabilities. This rule keeps
the project honest about its dependency surface without turning
dependency management into a daily chore.

### Adding / upgrading / removing dependencies

- Touching the project's manifest file(s) (`package.json`,
  `Cargo.toml`, `go.mod`, `Gemfile`, `pyproject.toml`,
  `Package.swift`, etc.) is a **gated file** per the existing
  permission rule. The user approves any add/upgrade/remove.
- The PR that touches the manifest also commits the lockfile
  update (`package-lock.json`, `Cargo.lock`, `go.sum`,
  `Gemfile.lock`, etc.). Lockfile out of sync with manifest is a
  blocker.
- Major-version upgrades require explicit acknowledgment — they
  often ship breaking changes that need a release-notes scan.

### Audit cadence

- **On every release** (every `/release` invocation): run the
  project's audit command (`npm audit`, `cargo audit`,
  `bundle audit`, `pip-audit`, `gradle dependencyCheck`, etc.).
  Surface any HIGH or CRITICAL findings in the deploy closing
  report. Don't auto-block on advisories — the user decides
  whether to ship-then-patch or fix-first.
- **Quarterly sweep** — once per quarter, run a full dependency
  audit + targeted upgrade pass. File the work as a task so it's
  tracked, not done as a side-effect of other work.

### What this rule does NOT require

- Daily / weekly auto-PRs from Renovate / Dependabot (fine to have,
  not required).
- Pinning every transitive dependency (rely on lockfile).
- Upgrading on every release (cadence is quarterly, with
  release-time advisory awareness).

### Linkage to AUDIT

Significant dependency events get an AUDIT entry:

- Major-version upgrades of a foundation dependency (framework,
  build tool, language runtime).
- Security patches for HIGH/CRITICAL advisories.
- Switching out a dependency for an alternative.

Routine patch-level upgrades don't need their own AUDIT entry —
they ride on the release entry.

## Final review run (the parade)

When the reviewer is ready to manually test a stack of merged or
about-to-be-merged tasks, they will run the project's full
verification suite in its watched/headed/observable mode (per
`CLAUDE.md`). Without filters, this runs every test in sequence
so the reviewer can spot anything that looks off and use it as the
lead-in to their own manual testing.

Don't redirect them to "just run the new test." The whole-suite
parade run is the contract — it's how regressions across tasks
get caught. The single-test focused mode is for inner-loop
iteration, not final review.
