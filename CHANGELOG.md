# claude-kit changelog

Versioning is `MAJOR.MINOR.PATCH`. Bumps:

- **Major** — breaking changes to file layout, sync policy, or skill
  contracts that require projects to re-init or migrate.
- **Minor** — additive changes (new files, new skills, new policies)
  that existing projects can pull via `/sync` without breakage.
- **Patch** — bugfixes, doc edits, no behavior change.

Tags: `vX.Y.Z`, annotated. Projects pin to a tag in their
`.claude/foundation.json` (or to a SHA, but tags are preferred for
human-readable rollback).

---

## v0.5.0 — 2026-05-01

Bundles four post-v0.4.0 merges that shipped without a version bump
(`/wrangle`, the 10-skill batch, `/lessons`+`/retro`, the primitive
layer). The kit goes from 21 to 36 universal skills + 1 platform skill,
and gains a new "primitives" tier of bootstrap templates. Also
reconciles the README skills table, which had drifted since v0.3.0
(missing `/spec-phase`, `/prototype`, `/mvp` even at v0.4.0).

### Added

#### Skills — read & assess
- **`/wrangle`** — two-phase: read-only audit producing durable refs
  under `docs/wrangle/` plus a Claude-targeted `.claude/context/project-map.md`,
  followed by a consent-gated cleanup plan. For inheriting an unfamiliar
  codebase.
- **`/blast-radius`** — pre-mortem a destructive change. Scans direct
  references, indirect references, tests, docs, deploys, external
  surfaces; saves a confidence-tagged report to `docs/blast-radius/`.
- **`/scope-check`** — counter to estimate optimism. Measures actual
  file/test/consumer surface area of a planned change vs the user's
  stated size. Saves to `docs/scope/`.
- **`/glossary`** — generate or sync `docs/glossary.md` from README,
  CLAUDE.md, schema files, and prevalent code identifiers.
- **`/export-project`** — single beautifully-formatted markdown export
  summarizing identity, stack, architecture, data model, current
  phase, in-flight work. Saves to `docs/exports/`.

#### Skills — capture & reflect
- **`/handoff`** — snapshot in-flight context. Writes to
  `docs/handoff/<date>.md` AND a tight ~15-line summary at
  `.claude/welcome.md` (the file Claude reads on session start).
- **`/lessons`** — per-task introspective sub-agent. Extracts durable
  learnings, writes to `docs/notes/<date>-<slug>.md`, appends a
  one-liner to `docs/notes/INDEX.md`. CLAUDE.md @-imports INDEX.md so
  prior notes load on every session start.
- **`/retro`** — longitudinal retrospective over a date window
  (default 2w). Synthesizes across `docs/notes/`, `tasks/done/`,
  `docs/decisions/`, `docs/postmortems/`, `docs/regrets/`,
  `docs/audits/`, and the git log. Pairs with `/loop` for cadence.
- **`/regret`** — architectural hindsight on a *choice*, distinct
  from `/postmortem` (incident-focused). Saves to `docs/regrets/`.
- **`/codify`** — capture a rule that emerged in conversation into
  project `CLAUDE.md` or kit `task-rules.md` (via `/contribute` PR).
  Confirms wording and scope before applying.

#### Skills — coordination
- **`/inbox`** — multi-dev messaging plus personal scratchpad.
  Identity from `git config user.name`. Recipients pick up messages
  on their next `git pull` + `/inbox`. Lower bar than `/task`,
  higher coordination value than a private TODO.
- **`/brainstorm`** — open or resume a tradeoff session at
  `.claude/tradeoffs/<topic>.md`. Living markdown that accumulates
  ideas, options, pros/cons, dated session logs. When a brainstorm
  converges, routes to `/decision` for the durable record.

#### Skills — kit-level meta
- **`/new-skill`** — scaffold a new skill with the kit's canonical
  shape (frontmatter triggers, behavior contract, output structure,
  what-NOT-to-do, when-NOT-to-use, "done" definition).
- **`/contribute`** — package a local edit to a kit-managed file
  into a PR back to claude-kit. Detects drift, classifies portable
  vs project-specific, drafts PR title + body. Closes the kit ↔
  project loop.
- **`/rule-promote`** — find rules that have crystallized in two or
  more projects' `CLAUDE.md` files; propose them for graduation to
  kit-level `task-rules.md`. Routes through `/contribute` for the
  PR.

#### Bootstrap templates — the primitive layer
Five small files that change how the project feels without bloating
the skill catalog. All `skip-if-exists` (user owns them after init).

- **`pact.md`** — personal working-relationship contract with Claude.
  Distinct from CLAUDE.md (project facts vs personal contract).
  Portable across repos.
- **`welcome.md`** — first-thing-on-session-start file. Auto-updated
  by `/handoff`.
- **`wont-do.md`** — anti-feature list. Closed conversations the
  project has decided against.
- **`playlists.md`** — curated skill chains for routine moments
  (morning ritual, end-of-day, weekly, pre-release).
- **`bookmarks.md`** — curated path:line treasure map for fast
  orientation.

#### Scaffold dirs
Init now scaffolds the durable-output destinations every new skill
writes to: `docs/notes/`, `docs/audits/`, `docs/handoff/`,
`docs/regrets/`, `docs/retros/`, `docs/blast-radius/`, `docs/scope/`,
`docs/exports/`, `docs/proto/`, `docs/mvp/`, `.claude/tradeoffs/`,
`.claude/inbox/`.

### Changed

- **`/audit`** — now persists each report to
  `docs/audits/<date>-<slug>.md` so audits accumulate as durable
  project history future sessions can reference (rather than living
  only in chat).
- **`/wrangle`** Phase 1 — additionally writes
  `.claude/context/project-map.md` (tight Claude-targeted index into
  `docs/wrangle/`) and offers, with consent, to draft `CLAUDE.md`
  from audit findings when missing or stub. Future Claude sessions
  land cold with project context already loaded.
- **`/handoff`** — also rewrites `.claude/welcome.md` (~15 lines) on
  every run. Makes the "auto-updated on handoff" promise real.
- **`bootstrap/CLAUDE.md.template`** — added an "Auto-loaded
  primitives" section with `@`-imports for `welcome.md`, `pact.md`,
  `bookmarks.md`, `wont-do.md`, and `docs/notes/INDEX.md`. Fresh
  projects load the primitive layer on every session by default.
- **`MANIFEST.json`** version `0.4.0` → `0.5.0`. Bootstrap entries
  added for the 5 primitive templates; scaffold list expanded for
  the new docs/ subdirs and `.claude/{tradeoffs,inbox}/`.

- **`bin/init`** — three classes of drift fixed:
  - **Kit `.md` files now iterated** (`for f in kit/*.md`) instead
    of hardcoded. Picks up `task-rules.md`, `task-template.md`,
    `ios-task-rules.md`, `web-task-rules.md`, `ios-conventions.md`,
    and any future `<platform>-*.md` the kit ships. Fixes a
    v0.2.0-era bug where the platform extension files were
    declared in MANIFEST but never installed by init.
  - **Primitive templates copied** (`pact.md`, `welcome.md`,
    `wont-do.md`, `playlists.md`, `bookmarks.md`). Fixes a v0.5.0
    gap where the primitive layer was added to MANIFEST in commit
    `507d057` but the init script wasn't updated.
  - **Scaffold dirs extended** to all 17 declared in MANIFEST
    (was 5). Adds the 10 skill-output dirs from v0.5.0
    (`docs/notes/`, `docs/audits/`, `docs/handoff/`, `docs/regrets/`,
    `docs/retros/`, `docs/blast-radius/`, `docs/scope/`,
    `docs/exports/`, `.claude/tradeoffs/`, `.claude/inbox/`) plus
    the 2 from v0.4.0 (`docs/proto/`, `docs/mvp/`).

  Existing projects were unaffected by the prior gaps — kit-managed
  files already existed or are user-owned via `skip-if-exists`. The
  script remains intentionally simple: pure `cp + mkdir`, no
  `MANIFEST.json` parsing, no network. Bootstrap templates and
  scaffold dirs are still hardcoded (additions require a script
  edit); only the kit `.md` files self-maintain via the glob loop.

### Did not change

- `kit/task-rules.md`, `kit/ios-task-rules.md`, `kit/web-task-rules.md`,
  `kit/ios-conventions.md`, `kit/task-template.md`. Untouched.
- Bootstrap `CLAUDE.md.template` apart from the auto-loaded
  primitives section. `PHASES.md`, `ROADMAP.md`, `AUDIT.md`,
  `foundation.json` templates are unchanged.

### Counts

| | v0.4.0 | v0.5.0 |
|---|---|---|
| Universal skills | 21 | 36 |
| Platform skills | 1 | 1 |
| Bootstrap templates | 5 | 10 |
| Scaffold dirs (declared in MANIFEST) | 7 | 17 |
| Scaffold dirs (actually installed by `bin/init`) | 5 | 17 |

---

## v0.4.0 — 2026-04-30

### Added

- **`kit/skills/prototype/`** — new skill for rapid R&D mode.
  Isolates the work into a `proto/<slug>` branch off the user's
  current branch, ignores ROADMAP / PHASES / backlog entirely,
  and runs a four-step loop: gather → plan → do (one task if
  possible) → present for review. Speed-optimized: no tests by
  default, light code review, reuse over new code, no new
  dependencies without naming the alternative. Always leaves a
  `docs/proto/<slug>.md` doc behind so the throwaway has a
  paper trail even if shelved. Surfaces the
  speed-over-discipline tradeoff at session start so the user
  enters with eyes open. Pairs with `/task` (graduate path
  when a prototype proves out).
- **`kit/skills/mvp/`** — new skill for product-level MVP
  scoping. Slow, deliberate planning mode for greenfield apps
  or major features. Five-step flow: gather (product, user,
  problem, shippable / marketable definition, constraints) →
  define MVP boundary (in / deferred / anti-features) → phase
  the work → bootstrap the full planning bundle (`docs/mvp/<slug>.md`,
  populated `tasks/ROADMAP.md` and `tasks/PHASES.md`, stub
  task files in `tasks/backlog/`, optional `CLAUDE.md` /
  rule-update proposals) → iterate or close. Sits above
  `/plan` (which assumes phases exist) and `/spec-phase`
  (which assumes stubs exist). Push-back built in for
  vague users, padded scope, or "shippable = doesn't crash."
- **Scaffold dirs**: `docs/proto/` and `docs/mvp/` added to
  `MANIFEST.json` so existing projects pick them up via
  `/sync` and new projects get them at init.

### Changed

- `MANIFEST.json` version `0.3.0` → `0.4.0`. No structural
  changes — the `kit.files` directory-mirror on `kit/skills/`
  picks up both new skills automatically; only the scaffold
  list grew.

### Did not change

- Bootstrap files. CLAUDE.md / PHASES.md / ROADMAP.md /
  AUDIT.md templates are unaffected.
- `bin/init`. New skills come along with the existing
  `kit/skills/` mirror.
- Existing skills. `/prototype` and `/mvp` are additive and
  don't modify any sibling skill's behavior.

---

## v0.3.0 — 2026-04-28

### Added

- **`kit/skills/spec-phase/`** — new skill for phase-scoped batch
  prep. Walks every stub in a named phase, expands each into a
  full spec via the same template `/task` Operation 3 uses, then
  proposes a working order with dependency analysis and a
  release strategy. Companion to `/task` (single-task scope) and
  `/plan` (phase-shaping scope). Surfaces the "speccing too far
  ahead" tradeoff at session start so the user enters with eyes
  open — invoking this is consciously trading JIT-spec-
  flexibility for batch coherence.
- **Vocabulary section** in `kit/task-rules.md`. Two operational
  terms now have hard, unambiguous definitions:
  - **batch** = a phase of tasks (not "any group of PRs," not
    "a sprint")
  - **tag and bag** = the full release pipeline on whatever's
    ready right now (merge → build → deploy → annotated tag →
    push tag → AUDIT entry)
  Inserted between the platform-extensions note and "Scope
  discipline" so the rest of the doc and the skills can lean on
  the terms without ambiguity.

### Changed

- `MANIFEST.json` version `0.2.0` → `0.3.0`. No structural
  changes — `kit.files` already mirrors `kit/skills/` as a
  directory, so the new skill is picked up by `/sync`
  automatically.

### Did not change

- Bootstrap files. CLAUDE.md / PHASES.md / ROADMAP.md / AUDIT.md
  templates are unaffected.
- `bin/init`. New skills come along with the existing
  `kit/skills/` mirror.

### Origin

Both additions originated in vsi-web during a release session,
got dogfooded on Phase 3 batch prep, then upstreamed here. The
project-specific version of the skill had a few VSI-specific
illustrations baked in (e.g., a `TASK-018a/b/c` example);
genericized for the kit.

---

## v0.2.0 — 2026-04-28

### Added

- **Filename-prefix platform-scoping convention.** `ios-*`, `web-*`,
  `python-*`, `android-*` prefix files extend the universal kit with
  platform-specific rules. The prefix is a discovery hint, not a gate
  — every project pulls everything; each work session reads the
  prefix files relevant to the work at hand. Multi-platform projects
  (iOS + Python backend, web + native, monorepos) work without
  install-time flags. Documented in `README.md` and at the top of
  `kit/task-rules.md`.
- `kit/ios-task-rules.md` — iOS platform extensions: verification
  gate (xcodebuild), iOS-specific protected files, Realm schema
  migration rule (when applicable), Apple build-number monotonic
  constraint, code-signing assumptions, common iOS gotchas.
- `kit/ios-conventions.md` — generic iOS architectural reference for
  any iOS project (app entry points, config file inventory,
  versioning, dep managers, SwiftUI state ownership patterns,
  Realm/Firebase usage, testing, Apple-specific gotchas).
- `kit/skills/ios-release/SKILL.md` — iOS-specific release
  orchestrator: archive → export → validate → upload to App Store
  Connect via `xcodebuild` + `xcrun altool`. Production deploys are
  user-confirmed every time.
- `kit/web-task-rules.md` — placeholder, mirrors ios-task-rules
  structure. Will populate when first real web project (e.g.
  vsi-web) integrates with the kit.
- Universal `/release` skill now detects platform and proposes
  delegation to `<platform>-release` when a matching skill exists.
  Detection rules: explicit `## Platform` declaration in `CLAUDE.md`
  wins; otherwise inferred from manifest files (`*.xcodeproj` →
  iOS, `pyproject.toml` → python, etc.).
- `bootstrap/CLAUDE.md.template` — new `## Platform` section so
  fresh projects declare their platform and the right
  `<platform>-*.md` files apply.
- `bin/init` next-steps output now mentions platform declaration.

### Changed

- `MANIFEST.json` version `0.1.0` → `0.2.0`. Added
  `naming_convention` block with examples and rationale. New file
  entries for the iOS prefix files and the web placeholder.
- `kit/task-rules.md` — added "Platform extensions" paragraph at
  the top so every Claude session is aware of the prefix convention
  on first read.
- `README.md` — updated tree showing prefix examples; new
  "Platform-prefix naming convention" section; skills table split
  into Universal vs Platform-specific.

### Did not change

- `bin/init` already copied everything in `kit/`, so no
  `--platform` flag was needed. Left the discovery logic alone.
- `/sync` skill — same reason. Kit's existing sync policy mirrors
  every kit/ file; the new prefix files are pulled correctly.
- `bootstrap/` templates other than `CLAUDE.md.template` —
  `PHASES.md`, `ROADMAP.md`, `AUDIT.md`, `foundation.json` are
  universal already.

---

## v0.1.0 — 2026-04-28

Initial release.

- 18 universal skills: `/audit`, `/backlog`, `/build`, `/decision`,
  `/onboard`, `/plan`, `/postmortem`, `/release`, `/review`,
  `/roadmap`, `/run`, `/schema-check`, `/skills`, `/status`,
  `/stuck`, `/sync`, `/task`, `/update-docs`.
- Generic `kit/task-rules.md` (project-specific commands referenced
  via `CLAUDE.md`).
- `kit/task-template.md` — task-spec template.
- `bootstrap/` templates: `CLAUDE.md`, `PHASES.md`, `ROADMAP.md`,
  `AUDIT.md`, `foundation.json`.
- `bin/init` — bootstrap script (copies kit files into target's
  `.claude/`, scaffolds `tasks/{backlog,active,done}` and
  `docs/{decisions,postmortems}`).
- `MANIFEST.json` — file-level sync policy (`directory-mirror`,
  `file-replace`, `skip-if-exists`, `init-only-with-sha`).
- `README.md` — onboarding doc with greenfield + existing-project
  instructions, iteration patterns, design principles.
