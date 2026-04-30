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
