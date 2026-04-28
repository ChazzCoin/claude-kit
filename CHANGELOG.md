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
