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

## Unreleased

(no entries yet)

---

## v0.16.0 — 2026-05-11

### Auditor agent + `.claude/clouds/` structure

Two structural changes worth flagging:

1. **`/audit` becomes script-driven + uniform output.** `audit.sh`
   handles deterministic scaffolding (header, library table, section
   headers, severity scheme). The new `auditor` agent (`kit/agents/auditor.md`,
   replaces the retired `code-reviewer` agent) handles judgment.
   Same output shape every invocation.
2. **`.claude/clouds/` directory** — one file per cloud / deployment
   surface. Existing projects with cloud info in `CLAUDE.md` should
   migrate; see the migration section below.

#### Added

- **`kit/agents/auditor.md`** — broader-scope auditor with lens
  parameter (`code` / `docs` / `config` / `architecture` / `security` /
  `mixed`). Read-only (Read/Glob/Grep/Bash diagnostic). Returns a
  uniform structured audit body for the calling skill to wrap +
  persist.

- **`kit/skills/audit/audit.sh`** — scaffolding + persistence script
  for `/audit`. Subcommands: `resolve` (scope info), `scaffold` (markdown
  skeleton with `<to-fill>` placeholders), `validate` (sections + no
  unfilled placeholders), `save` (writes to `docs/audits/<date>-<slug>.md`
  with collision suffix), `lenses` (list). Top-of-script arrays
  declare sections, severity tiers, lenses, manifest parsers, and
  ignored paths — extend by editing the array.

- **`bootstrap/cloud.md.template`** — per-cloud template. Each
  surface gets a file at `.claude/clouds/<name>.md` with frontmatter
  (name, provider, kind, environments, pulls_from) + body sections
  (auth, commands, config files, gotchas, references). One template,
  many surfaces. Frontmatter is machine-parseable for future skill
  integration.

- **`.claude/clouds/` scaffold directory** — added to MANIFEST so
  fresh bootstraps get the dir.

#### Changed

- **`kit/skills/audit/SKILL.md`** — overhauled. The skill now
  orchestrates: `audit.sh resolve` → invoke `auditor` agent →
  `audit.sh validate` → `audit.sh save`. Adds an explicit
  **Output policy** section (same load-bearing rule as `/status`'s):
  AI passes the assembled audit to the user verbatim, no summary,
  no preamble, no closing chat.

- **`bootstrap/CLAUDE.md.template` `## Deploy` section** — now a
  short overview + pointer to `.claude/clouds/`, not a prose blob.
  This affects FRESH bootstraps only; existing projects keep their
  old `## Deploy` content because the template is `skip-if-exists`.
  Migration to the new structure is opt-in (see below).

- **MANIFEST.json**:
  - New bootstrap entry: `cloud.md.template` → `.claude/clouds/_template.md`
    (skip-if-exists; the `_` prefix marks it as a template, not a
    real cloud entry).
  - New scaffold directory: `.claude/clouds/`.

#### Removed

- **`kit/agents/code-reviewer.md`** — retired. Its PR-review use case
  folds into `auditor` invoked with `--lens code`. Severity scheme
  unified on CRITICAL/HIGH/MEDIUM/LOW (was BLOCKER/WARN/NIT in
  code-reviewer). If your skills called `code-reviewer` directly,
  switch them to `auditor` with appropriate lens.

#### Migrating cloud info from `CLAUDE.md` `## Deploy` → `.claude/clouds/`

If your project has cloud / deploy details in CLAUDE.md, the new
structure is strictly cleaner — especially for multi-cloud setups.
**No skill is forcing this migration in v0.16.0** — `/release` and
`/status` continue to read from CLAUDE.md as before. Migrate when
ready.

**Steps:**

1. After `/sync` pulls v0.16.0, you'll have `.claude/clouds/_template.md`
   and the empty `.claude/clouds/` directory. Verify with
   `ls .claude/clouds/`.

2. **For each cloud / deployment surface** mentioned in your CLAUDE.md
   `## Deploy` (or scattered in Commands / Tech stack), create a
   per-resource file at `.claude/clouds/<name>.md` following the
   template. Naming convention: `<provider>-<service>[-<env>].md`,
   e.g. `firebase-hosting.md`, `azure-acr.md`, `azure-aks-prod.md`.

3. **Granularity:** one file per RESOURCE, not per provider. ACR
   and AKS are distinct surfaces with distinct commands — separate
   files, cross-referenced via the `pulls_from` frontmatter:

   ```yaml
   # In .claude/clouds/azure-aks-prod.md:
   pulls_from: [azure-acr]
   ```

4. **Copy the relevant prose** from CLAUDE.md into each new file's
   sections (Auth, Commands, Config files, Gotchas). The frontmatter
   captures the machine-readable bits (project ID, region, environments).

5. **Once everything has moved**, replace your CLAUDE.md `## Deploy`
   section with a short overview + pointer to `.claude/clouds/`:

   ```markdown
   ## Deploy

   Deploy targets and cloud surfaces are documented per-resource at
   `.claude/clouds/<name>.md`. Run `ls .claude/clouds/` to see them.

   <one-line overview of what this project deploys>
   ```

6. **Update `.claude/settings.json`** if you want auto-allow on
   cloud CLI commands you use frequently (e.g. `firebase deploy:*`,
   `az aks:*`, `kubectl rollout:*`). Distinct from cloud docs —
   `settings.json` configures the *harness*; cloud files document
   the *surfaces*.

7. **Verify nothing's lost** — git diff your CLAUDE.md to confirm
   what you trimmed lives in `.claude/clouds/` now.

The kit does NOT automate this migration in v0.16.0. Future versions
may ship a `/migrate-clouds` skill if the pattern proves valuable.

#### Compatibility

- **`/audit` output shape changes** — existing audits in `docs/audits/`
  are unaffected (they're just files). New audits use the locked
  structure. Anyone scripting against `/audit`'s output format
  should review the new shape.
- **`code-reviewer` agent removed** — `/sync` will surface this as
  a "removed in kit" file. Confirm the deletion if no project
  skills call it directly. If they do, switch the call to `auditor`.
- **`.claude/clouds/` migration is opt-in** — existing CLAUDE.md
  `## Deploy` sections continue to work in v0.16.0. v0.17.0+ may
  start integrating `.claude/clouds/` into `/release` and `/status`.

---

## v0.15.0 — 2026-05-10

### /status becomes script-driven + inbox surfaced

Structural change worth flagging: **`/status` is now Cat 1F per
`script-craft.md` — the entire user-facing report is rendered by
`kit/skills/status/status.sh`, not synthesized by the AI per
invocation.** Same project state → same output, every time.

Plus: status now surfaces unread inbox messages addressed to you,
so they're visible alongside production / branch / tasks state
instead of waiting for a separate `/inbox` run.

#### Added

- **`kit/skills/status/status.sh`** — deterministic project
  snapshot renderer. Subcommands:
  - `dashboard` (default) — full markdown report including §2
    box, recent commits, open PRs (via `gh`), in-flight tasks,
    top of roadmap, and inbox.
  - `data` — raw `key=value` lines for composition / debug.
  - Exit codes 0 / 1 (not in git repo) / 2 (usage error).

- **Inbox section in /status output** — counts and lists up to 5
  unread messages from `.claude/inbox/<your-handle>.md` (identity
  from `git config user.name`). Silently skipped if the project
  has no `.claude/inbox/` directory.

#### Changed

- **`kit/skills/status/SKILL.md`** — gains a "**Output policy
  (the load-bearing rule)**" section with explicit MUST /
  MUST NOT / MAY language. The AI's job is to pass the script's
  stdout to the user verbatim — no summary, no preamble, no
  closing remarks, no section reordering. This is the load-bearing
  contract for every script-driven skill going forward.

- **`/status` output shape** — values in the §2 dashboard now use
  ASCII separators (`|`, `/`, `-`) instead of `·` and `—`. Reason:
  bash `${#var}` is locale-dependent (bytes vs chars), so values
  with multi-byte chars broke padding math. Box-drawing chars in
  borders stay Unicode (those aren't padded). Net effect: rock-solid
  alignment, slightly less ornate values.

#### Deferred to a later release

- §23 Activity timeline (was sourced from `tasks/AUDIT.md`)
- §25 Alert variants ("anything off" section)

Both are conditional sections in the original spec; the v1 script
covers the core ~90% of snapshot value. They can land in v0.15.x
or v0.16.x once we know the core is stable.

#### Compatibility

Pure additive at the file-layout level. Existing projects pull via
`/sync` without breakage. The script-driven render is a behavior
change for `/status`, but the skill's *purpose* (read-only project
snapshot) is unchanged. Anyone who built habits around the
free-form prior output will notice a tighter, more predictable
shape.

---

## v0.14.0 — 2026-05-10

### /load skill + user-global save state + branch tracking

Structural change worth flagging: **`/save` no longer writes to
`docs/saved/` inside the project repo.** Saves now live in
user-global space at `~/.claude/projects/<mangled-repo-key>/saves/`,
matching the existing memory-directory convention.

The bigger picture: claude-kit is starting to push toward
user-separation where it makes sense. Personal continuity (saves,
working memory, "where I left off") goes user-global; team-shared
project context (decisions, postmortems, audits, handoffs) stays
project-local. `/save` is the first feature to land in this
direction; `/handoff` is its team-shared counterpart.

#### Added

- **`/load` skill** — read-side companion to `/save`. Reads
  `SAVED.md`, scans recent TIMELINE entries, and surfaces `git log`
  activity since the save was written so the AI can flag mismatches
  ("you said X was open, but commit Y closed it"). Includes
  `load.sh` script with subcommands `status` / `orient` / `branch` /
  `checkout`. Exit codes 0/1/2/3 per `script-craft.md`.

- **Branch tracking in `/save`** — `save.sh write` auto-injects
  `> **Branch.** <name>` into SAVED.md's header block if not
  already present. Captured via `git symbolic-ref --short HEAD` —
  records "None" for detached HEAD or repos with no commits.
  Idempotent: won't overwrite an existing Branch line, so users can
  manually mark a save as branch-agnostic (`> **Branch.** None`).

- **`load.sh checkout` subcommand** — checks out the branch
  recorded in SAVED.md. Strict refusals: dirty working tree
  (untracked counts), branch doesn't exist locally, branch is in
  use by another worktree, or saved branch is "None"/unrecorded.

- **`save.sh current-branch` subcommand** — exposed for `/load`
  and external readers. Echoes current branch or "None".

#### Changed

- **`/save` storage location** moved from project-tracked
  `docs/saved/` to user-global
  `~/.claude/projects/<key>/saves/`. Three concrete benefits:
  1. **Survives `git checkout`.** Saves visible from any branch.
     `/load` can read a save and offer to switch back to the saved
     branch from anywhere.
  2. **Unified across worktrees.** `git rev-parse --git-common-dir`
     resolves to the *main* repo path; `cd -P` / `pwd -P` follows
     symlinks (critical on macOS where `/tmp → /private/tmp`
     would otherwise fragment keys). All worktrees of one project
     share one save state.
  3. **Cross-project trajectory.** `ls ~/.claude/projects/*/saves/SAVED.md`
     gives a one-shot "what have I been working on lately" view.

- **`MANIFEST.json`** — `docs/saved` removed from the scaffold
  directories array. The kit no longer creates that path; saves
  initialize lazily under `~/.claude/projects/<key>/saves/` on
  first `/save`.

#### Compatibility

If you ran `/save` between v0.12.0 and v0.13.0, your old saves
are still at `<project>/docs/saved/`. They aren't readable by
the new `/load` (which looks only in user-global space). To
migrate, manually move them:

```sh
mkdir -p ~/.claude/projects/$(pwd -P | tr / -)/saves/
mv docs/saved/* ~/.claude/projects/$(pwd -P | tr / -)/saves/
rmdir docs/saved/
```

In practice the migration burden is near-zero — `/save` only
shipped 12 hours ago in v0.12.0 and isn't yet in active use.

---

## v0.13.0 — 2026-05-10

### Subagent foundation + settings scaffold

Two additive pieces that bring claude-kit closer to the Claude Code
feature surface projects already have access to but the kit didn't
yet template:

1. **Subagent definitions** — `kit/agents/` directory with three
   canonical agents (code-reviewer, doc-scanner, spec-expander).
   Kit-shipped agents synced to `.claude/agents/` per project.
2. **Settings scaffold** — `bootstrap/settings.json.template` so
   every project bootstrapped from the kit gets a Claude Code
   `settings.json` shape it can extend (permissions, env, hooks).

#### Added

- **`kit/agents/code-reviewer.md`** — restricted to Read/Glob/Grep/Bash
  (diagnostic). Opus default. Critical-review agent for `/review`,
  `/audit`'s deep pass, pre-merge verification. Returns a structured
  review with severity-tagged concerns (BLOCKER / WARN / NIT) and a
  ship / fix-first / needs-discussion verdict.

- **`kit/agents/doc-scanner.md`** — restricted to Read/Glob/Grep.
  Sonnet default. Multi-file markdown scanner for `/update-docs`,
  `/retro`, `/rule-promote`, `/lessons`. Returns findings grouped by
  theme with `path:line` citations and verbatim quotes.

- **`kit/agents/spec-expander.md`** — Read/Glob/Grep/Bash. Opus default.
  Expands task stubs into full specs (purpose, acceptance criteria,
  files expected to change, out-of-scope, test plan, risks). For
  `/spec-phase`, `/task`, `/mvp`. Grounds specs in actual codebase
  paths via Read/Glob — no fabricated file references.

- **`bootstrap/settings.json.template`** — minimal Claude Code
  settings scaffold with `permissions` / `env` / `hooks` keys ready
  for the project to extend. Empty values — kit doesn't ship
  opinionated defaults that might conflict with project preferences.
  Use `/fewer-permission-prompts` after bootstrap to auto-populate
  read-only auto-allows.

#### MANIFEST changes

- **Sync entry** added: `kit/agents/` → `.claude/agents/`
  (`directory-mirror` policy, same as `kit/skills/` and `kit/modes/`).
- **Bootstrap entry** added: `bootstrap/settings.json.template` →
  `.claude/settings.json` (`skip-if-exists` policy — project owns it
  after bootstrap).

#### Compatibility

Pure additive. Existing projects pull via `/sync`:

- New `.claude/agents/` directory appears with three canonical agents.
  Existing skills don't currently call named agents (only
  `general-purpose` and `Explore`); the new agents are available for
  skill authors to start using.
- Existing projects that already have a `.claude/settings.json` are
  untouched (skip-if-exists). Projects without one will receive the
  scaffold on next bootstrap.

#### Note on prior calibration

A bug was floated and retracted during this release. The
`/handoff` skill's "welcome.md auto-loads via @-import" contract
was claimed to be violated; on re-verification, the bootstrap
`CLAUDE.md.template` already ships the full `@-import` block
including `@.claude/welcome.md`. No fix needed — contract honored.

---

## v0.12.0 — 2026-05-10

### Save skill + script-craft doctrine — script-driven skill foundation

Introduces the **script-driven skill pattern**: skills whose mechanics
live in a versioned bash script that ships alongside the SKILL.md.
The script owns deterministic plumbing (file moves, archive policy,
timestamps); the AI owns synthesis and choice routing. Same outcome
every run — no AI re-interpretation of mechanics.

`/save` is the canonical example and the first user-facing skill in
this pattern. It's distinct from `/handoff`: thread-of-work
checkpoint (lightweight, frequent) vs project-leave snapshot
(heavyweight, occasional).

#### Added

- **`kit/skills/save/SKILL.md`** + **`kit/skills/save/save.sh`** —
  mid-session state-save. Snapshot what we did, worked out, and
  what's open. Script handles `docs/saved/SAVED.md` (current),
  archived snapshots at `docs/saved/<YYYY-MM-DD-HHMM>.md`, and
  newest-first index at `docs/saved/TIMELINE.md`. Subcommands:
  `status`, `write <file> [--mode auto|archive|replace]`, `archive`.
  Exit codes: 0/1/2/3 per script-craft.md.

- **`kit/script-craft.md`** — doctrine for create/update/run. Covers
  when a script is appropriate (deterministic mechanics) vs when
  not (synthesis/judgment), folder structure, language policy
  (bash default), the canonical skeleton, exit-code contract, I/O
  discipline, and portability boundary (BSD/macOS + GNU/Linux;
  Windows out of scope). Synced to projects as
  `.claude/script-craft.md` (file-replace).

- **`docs/saved/`** added to MANIFEST scaffold — projects get the
  directory at init.

#### Changed

- **`kit/skills/sync/SKILL.md`** Step 6 — added explicit "Preserve
  exec bit on script files" rule. Every copy operation chmod +x's
  files under `kit/skills/**/*.{sh,py,ts,js,mjs}` and `bin/`.
  Belt-and-suspenders with the SKILL.md `bash <script>` invocation
  convention that script-driven skills use.

- **`kit/skills/new-skill/SKILL.md`** — sixth input added to the
  scaffold question block: "Script mechanics — none / partial /
  full?" Picks a script-mode clause for the behavior contract.
  If partial or full, scaffolds `<name>.sh` skeleton alongside
  SKILL.md, following script-craft.md conventions. Pushback rule
  fires when the script answer mismatches the purpose (e.g.
  "partial" for a pure-synthesis skill).

- **`kit/task-rules.md`** — added blockquote pointer to
  `script-craft.md` in the doctrine-references section, alongside
  the existing Craft / Output / Git / Release / Batch / Vocabulary
  pointers.

#### Compatibility

Pure additive. Existing projects pull via `/sync` without breakage.
The new SKILL.md questions in `/new-skill` only fire when
scaffolding a new skill; existing skills are unaffected. The chmod
rule in `/sync` only chmod's files the sync was already copying.

---

## v0.11.0 — 2026-05-08

### Orchestrator integration — read-side hooks for cross-repo notices

Closes the loop with [claude-orchestrator](https://github.com/ChazzCoin/claude-orchestrator).
Without this, the orchestrator could drop coordination signals into a
sub-repo (`<repo>/.claude/active-migrations.md`, etc.) and the sub-kit
wouldn't know to read them on session start.

Generic enough to work with any orchestrator that writes `.claude/active-*.md`
into a sub-repo — the v1 active concern is migrations, but `active-adrs.md`,
`active-contract-changes.md`, and other future variants plug in without
further kit changes.

#### Added

- **`bootstrap/CLAUDE.md.template`** grows a `## Macro architecture (orchestrator)`
  section after `## Platform`. Declares the orchestrator repo path
  (`{{ABSOLUTE_PATH_TO_COMPANY_ORCHESTRATOR or "n/a — solo project"}}`),
  points at the orchestrator's macro-state files (`stack/`, `contracts/`,
  `conventions/`, `features/`) for cross-repo context, and points at the
  active-orchestrator-notices rule below for session-start reads.

- **`kit/task-rules.md`** grows an `## Active orchestrator notices` section
  between Schema discipline and Files-that-require-explicit-permission.
  Defines the discipline for any `.claude/active-*.md` files dropped by an
  upstream orchestrator: read on session start and at task start, treat as
  authoritative cross-repo state, never edit or delete by hand, don't mirror
  into project files. Falls open if the orchestrator path is `n/a — solo project`.

#### Behavior

When a sub-kit'd project is registered with an orchestrator:
1. Sub-repo's CLAUDE.md declares the orchestrator path
2. Orchestrator's `/migration` skill drops `<sub>/.claude/active-migrations.md`
3. Sub-kit reads it on session start (per the new task-rules.md section)
4. Sub-kit surfaces open migrations to the user in initial orientation
5. Sub-kit treats the file as read-only — orchestrator regenerates it
   wholesale; hand edits get overwritten

#### Compatibility

Pure additive change. Existing projects can pull via `/sync` without
breakage. The orchestrator-integration sections are no-ops if the
project doesn't declare an orchestrator path (`n/a — solo project`).

---

## v0.10.0 — 2026-05-07

### Craft rules + web stack defaults

Two structural additions and one expansion of the platform-conventions
pattern.

#### Added

- **`kit/craft-rules.md`** — universal code-quality discipline. Sits
  alongside `git-flow-rules.md`, `release-rules.md`, `output-rules.md`
  in the rule-decomposition pattern. Covers: build it right the first
  time, modular by default, reusable / dynamic / composable, naming,
  comments, error handling, dead code, premature abstraction. Applies
  to every project, every language. Referenced via blockquote pointer
  from `task-rules.md`.
- **`kit/web-conventions.md`** — platform reference for web projects,
  mirroring `kit/ios-conventions.md`. Includes a **`## Default stack`**
  section at the top stating the kit's opinionated default for new
  browser SPAs:
  - Vite 6+ (ESM) · React 18 (JSX) · Tailwind 3+ + PostCSS · lucide-react
  - Firebase (Auth + DB + Hosting) with cache-discipline headers
  - Playwright (chromium-only, headless gate, headed `:watch`)
  - No state-management library by default
  - **Secondary default for paired Node backends:** Node ≥20 ESM,
    strict TypeScript, `tsx watch` / `tsc`, Express 4 + better-sqlite3
    + dotenv (the `claude-messages` / Galt shape).

#### Changed

- **`kit/ios-conventions.md`** — added a `## Default stack` section
  near the top so the convention is consistent across platforms
  (SwiftUI · Swift 5.9+ · SPM · Realm · Firebase · XCTest+XCUITest ·
  TestFlight via `/ios-release`).
- **`kit/web-task-rules.md`** — replaced the `STATUS: PLACEHOLDER`
  contents with the real defaults pulled from the chosen web stack:
  concrete verification gate (`npm run build` + `npm run test:e2e`),
  protected files list (build/test/hosting config, security rules,
  `paths.js`), Firebase schema discipline rules, gotchas tied to the
  verification gate.
- **`kit/task-rules.md`** — added a blockquote pointer to
  `craft-rules.md` in the existing rule-pointer list.

#### Architecture and navigation discipline

- **`kit/craft-rules.md`** — two new sections:
  - **Architecture from day one.** Separate business logic from UI
    views. Decide the architectural shape before file three. Cleanup-
    as-you-grow doesn't work — by the time the seams hurt, they're
    load-bearing.
  - **Navigation discipline.** Set up real navigation from the first
    commit. View-state app routers (`useState("landing")` /
    `setView("dashboard")`) are the explicit anti-pattern. Web
    default: React Router. iOS default: `NavigationStack` with typed
    path.
- **`kit/web-conventions.md`** — two new sections:
  - **Architecture — separation of concerns.** Layer model table:
    `firebase/` + `models/` + `lib/` are leaves; `hooks/` own
    business logic; `components/ui/` are render primitives;
    `components/<area>/` are feature views; `pages/` compose. Rules:
    components don't call Firebase directly, hooks don't render,
    pages compose-don't-compute.
  - **Routing.** React Router v6+ from the first commit. Mount
    `BrowserRouter` at `main.jsx`; define routes in `App.jsx` or
    `src/routes.jsx`. `<Navigate>` redirects for auth gating.
    Deep-link aware.
- **`kit/ios-conventions.md`** — two new sections:
  - **Navigation.** `NavigationStack` with typed `NavigationPath`
    (or enum-driven path). One navigator per tab / per main flow.
    Sheet-vs-push semantics. State restoration via `@SceneStorage`.
  - **Architecture — ViewModels (separation of concerns).** iOS 17
    `@Observable` and pre-17 `ObservableObject` patterns. Views
    render + dispatch intents; ViewModels own state, derived data,
    and data-access calls. Stores / Repositories injected into
    ViewModels.

#### Naming + type discipline

- **`kit/craft-rules.md`** — three sections changed:
  - **Naming.** New casing table — kit-wide and overrides language
    idioms where they conflict. Classes / types / structs / enums /
    protocols → **PascalCase**. Variables / properties / fields →
    **camelCase**. Functions / methods → **camelCase**. React hooks
    → camelCase prefixed `use…`. Constants → UPPER_SNAKE_CASE.
    Python in this kit uses camelCase, not PEP 8 snake_case —
    consistency across the kit beats deference to per-language
    style guides.
  - **Type strictness (new section).** The kit declares types
    everywhere, regardless of whether the language requires them.
    Per-language mechanism: JSDoc on JS / JSX (web kit default,
    validated by `tsconfig.json` with `checkJs: true`); type hints
    on Python; explicit annotations on Swift; native types on
    Go / Rust / Java / Kotlin / C#. No `any` / `unknown` /
    dynamic-type escape hatches. Section includes JSDoc patterns
    for component props, hooks, and type-only utilities.
  - **Comments (rewritten).** Three reasons to comment: types
    (JSDoc / docstrings — part of the contract, not commentary),
    why (hidden constraints, workarounds), and future-dev
    orientation. JSDoc blocks are explicitly NOT what "comment
    noise" means. Still excluded: what the code already says,
    references to current task / fix / callers, decorative
    banners, filler.
- **`kit/web-conventions.md`** — language re-anchored on **JSX +
  JSDoc** (not TypeScript). File extensions stay `.jsx` / `.js`;
  type discipline is carried via JSDoc annotations and validated by
  a `tsconfig.json` with `checkJs: true, strict: true, noEmit: true,
  allowJs: true` for IDE-only type checking. TypeScript itself is a
  per-project opt-in. Updated samples: `App.jsx` and `main.jsx` use
  the explicit `getElementById`-throws-if-null pattern; `App.jsx`
  has `@returns {JSX.Element}` JSDoc; architecture-layer table
  describes the JSDoc-on-JS expectations per layer.

#### Follow the pattern (don't recreate the wheel)

- **`kit/craft-rules.md`** — new section as the second section in
  the file (after "Build it right the first time", before "Modular
  by default"):
  - **Look for the pattern first.** Before adding a feature, scan
    how similar features are done elsewhere; if a precedent exists,
    follow it.
  - **Follow even if you'd have done it differently.** Disagreeing
    is fine; *silently forking* is not. If a pattern is wrong,
    migrate everywhere — don't let divergence rot.
  - **No pattern? Set the precedent deliberately** and document the
    decision in `CLAUDE.md`.
  - **Cascade of fallbacks.** Match the file → match the codebase →
    fall back to kit conventions (`web-conventions.md`,
    `ios-conventions.md`) when no project-local pattern exists.
- **`kit/craft-rules.md`** — "When in doubt" trimmed to one bullet
  ("Ask before guessing"). The "Match the file you're editing"
  bullet moved up into "Follow the pattern" as part of the cascade
  of fallbacks.

---

## v0.9.1 — 2026-05-02

### Catalogue applies to conversational asks too

The structured-outputs catalogue's scope was implicitly
"skill deliverables only" — `task-rules.md` invokes a skill,
the skill renders catalogue. Free-form chat asks like
*"what's the status?"* or *"what's deployed?"* fell back to
prose because they didn't go through `/status` or `/release`.

That carve was wrong. The right line is **structured ask →
structured response, open-ended dialogue → prose**, regardless
of whether a skill is invoked. A direct chat ask of the same
type gets the same catalogue template the skill would produce.

#### Changed

- **`kit/output-rules.md`** — restructured the "What this file
  governs" / "What this file does NOT govern" sections:
  - **What governs:** output TYPES (status, deployment, audit,
    backlog, decision, alert, etc.) — applies whether the
    output comes from a skill or from a direct chat ask.
  - **New section: "Conversational (in-chat) use is included"**
    with a 10-row table mapping common chat asks to catalogue
    entries (e.g. *"what's the status?"* → §2 inline; *"any
    issues?"* → §6 or §26; *"how does X compare to Y?"* → §24).
  - **What does NOT govern:** narrowed to genuinely
    open-ended dialogue (mid-task narration, free-form Q&A
    about HOW something works, brainstorming, multi-turn
    clarification, one-line affirmations).
  - **Closing rule:** "When uncertain, default to prose. A
    wrong catalogue use is heavier than a missed one."

No skill changes — wired skills (/status, /release, /audit)
still pin their specific § entries. The shift only affects
free-form chat responses where no skill was invoked.

---

## v0.9.0 — 2026-05-02

### Modes — integrated and shipping

The `feat/modes` branch (originally drafted against a parked
v0.6.0 slot that was reserved during v0.7.0 release but never
claimed) integrated into the kit, plus a new third mode
(`project-manager`) added on top. Adds a new tier alongside
skills and primitives: **modes** — prose drives that prime
Claude's appetite for the work at hand, distinct from
skill-routing or permission-gating.

#### Added — modes tier

- **`kit/modes/`** — directory mirror, synced via `/sync` like
  `kit/skills/`. Each `*.md` is a mode definition.
  - `kit/modes/README.md` — concept doc + voice rules.
  - `kit/modes/task.md` — drive prose for task mode (clear
    backlog, pull batches, count tasks closed).
  - `kit/modes/cleanup.md` — drive prose for cleanup mode
    (improve in place, push back on new features, time-only
    counter).
  - `kit/modes/project-manager.md` (NEW on this branch) — drive
    prose for project-manager mode. Walk the backlog phase by
    phase, push every stub through `/task` Op 3's full recon
    flow, surface phase-level shape questions, log the session
    to `docs/refinement/<date>.md`. Counts stubs refined
    (delta of files containing `STATUS: STUB`).
- **`kit/skills/mode/SKILL.md`** — `/mode` skill. Activate,
  switch, end, or report current mode + cross-activation stats.
  Extended on this branch to detect the new
  `stubs_remaining_count` unit type for project-manager mode.
- **`MANIFEST.json`** — new `kit.files` entry: `kit/modes/` →
  `.claude/modes/` (directory-mirror).
- **`bootstrap/CLAUDE.md.template`** — adds `@.claude/mode.md`
  to the auto-loaded primitives section. The `@`-import is a
  no-op when no mode is active (file absent), so projects that
  never use modes pay nothing.
- **`bin/init`** — new mirror loop for `kit/modes/*.md`. Plus
  scaffold for `docs/refinement/` (project-manager mode's
  durable session log directory).
- **`MANIFEST.json`** scaffold list — adds `docs/refinement/`.
- **`README.md`** — adds modes tree, a "Universal — drive"
  section in the skills catalog with `/mode`, and entries for
  `.claude/modes/`, `.claude/mode.md`, `.claude/mode-stats.md`
  in the existing-project install table.

#### How modes work

- Mode = a *drive* (priming Claude's appetite), not a permission
  filter or skill router. Universal rules from `task-rules.md`
  (verification gate, gated files, never auto-commit) always win
  inside any mode.
- Activation writes `.claude/mode.md` (small frontmatter +
  `@`-import of the chosen mode definition). `CLAUDE.md`
  `@`-imports `.claude/mode.md`, so the active drive prose loads
  on every session start.
- Switching between modes finalizes the prior mode's deltas to
  `.claude/mode-stats.md` before activating the new one.
- `/mode normal` is the off-switch — removes `.claude/mode.md`;
  the file's absence is the "no mode" signal.

#### Integration notes

- `feat/modes`'s original v0.6.0 CHANGELOG entry was dropped —
  that version slot was reserved during v0.7.0 release and never
  claimed. Modes ship under whatever version this branch lands
  as (likely v0.9.0).
- Smart-merge: 7 of 9 files merged cleanly; CHANGELOG and
  MANIFEST resolved by hand (kept v0.8.0 baseline + grafted in
  modes additions).
- All 4 mode files (`kit/modes/*.md`, `kit/skills/mode/SKILL.md`)
  integrated verbatim from `feat/modes`.

---

## v0.8.0 — 2026-05-01

A self-discipline release. Five interlocking issues raised against
v0.7.0, all addressed:

1. **No self-audit** — nothing enforced the platform-prefix
   convention. iOS rules were drifting into universal files. Now
   there's a linter.
2. **`task-rules.md` was a kitchen sink** — four concerns in one
   ~700-line file. Split into focused, separately-loadable files.
3. **No CHANGELOG delta on sync** — projects upgrading kit versions
   had to `git log --oneline` to see what changed. `/sync` now
   surfaces the delta as a §23 timeline.
4. **No kit-vs-project overlap detection** — when the kit ships
   content that overlaps with project-elaborated files, /sync now
   flags it and offers four reconcile paths.
5. **Hardcoded vocabulary** — `patch / minor / major` semver
   semantics, "batch", "tag and bag", etc. were universal across
   the kit. iOS build-number constraints distort them in practice.
   Now there's a configurable vocabulary layer with project
   overrides.

### Added

#### Kit linter (`bin/lint` + `/lint-kit` skill)

- **`bin/lint`** (~490 LOC, pure bash + awk, no Python). Greps
  every universal kit file (any `kit/*.md` without a platform
  prefix, plus `kit/skills/<name>/SKILL.md` where `<name>` lacks
  a platform prefix, plus `bootstrap/*.template`) for
  platform-specific keywords:
  - **iOS:** `xcodebuild`, `xcrun`, `altool`, `fastlane`, `AVKit`,
    `SwiftUI`, `UIKit`, `SwiftData`, `Combine`, `.xcodeproj`,
    `.xcworkspace`, `Package.swift`, `Podfile`, `Realm`,
    `Kingfisher`, `Cocoapods`, `TestFlight`
  - **Android:** `gradle`, `build.gradle`, `Jetpack Compose`,
    `Kotlin`, `Room`, `Hilt`, `Coroutines`, `CameraX`, `Coil`,
    `AndroidX`
  - **Web:** `package.json`, `npm`, `yarn`, `pnpm`, `react`,
    `vue`, `next`, `svelte`, `nuxt`, `vite`, `webpack`, `tailwind`
  - **Python:** `pyproject.toml`, `requirements.txt`, `pip`,
    `poetry`, `flask`, `fastapi`, `django`, `pandas`, `numpy`,
    `pytest`
  - **Go / Ruby:** `go.mod`, `go.sum`, `gin`, `Gemfile`, `rails`,
    etc.

  Output is rendered in §6 Severity audit format (per
  `kit/output-styles.md`). Severity tiering:
  - **HIGH** — keyword in a non-cross-platform context (e.g.
    `xcodebuild test` as a literal command).
  - **MEDIUM** — likely platform-specific reference but ambiguous.
  - **LOW** — keyword appears alongside cross-platform peers
    (e.g. a list mentioning iOS, Android, web). Suppressed by
    default; `VERBOSE=1` to show.

  Exit code: non-zero on any HIGH findings (CI-friendly).

- **`kit/skills/lint-kit/SKILL.md`** — wraps `bin/lint`. `/lint-kit`
  bare runs the lint and renders output. `/lint-kit fix` walks
  HIGH findings and offers per-finding moves to the right
  platform file (with consent).

  Pins §6 Severity audit as the catalogue entry.

- **First-run drift fixed:** four HIGH findings caught in the
  initial run, all fixed:
  - `kit/task-template.md` — replaced `npm run build clean` with
    "the project's build command (per CLAUDE.md / `/build`)".
  - `kit/skills/update-docs/SKILL.md` — three `package.json`
    references generalized to "the project's package manifest"
    with examples across platforms.
  - `kit/skills/task/SKILL.md` — AVPlayer/AVKit example in the
    external-recon section rephrased to be platform-neutral
    (per-platform examples now live in `<platform>-task-rules.md`).

  Three MEDIUM findings retained as intentional cross-platform
  references (`Realm` in `/schema-check`'s "iOS / Android Realm
  or Core Data models" line; `vite.config.ts` and `package.json`
  in templates and skill copy that legitimately cite the project's
  manifest).

#### Vocabulary layer

- **`kit/vocabulary.md`** (~270 lines) — canonical kit term
  definitions. Sections:
  - **Versioning** — `Patch` / `Minor` / `Major` with iOS
    `CFBundleVersion` monotonic constraint surfaced as a known
    override case.
  - **Tasks** — `Batch` / `Tag and bag` (extracted canonically
    from `task-rules.md`).
  - **Lifecycle states** — `Backlog` / `Active` / `Done`.
  - **Stub vs. spec** — task spec maturity levels.
  - **Phase** — first-class organizational unit.
  - **Verification gate** — the headless test contract.
  - **Gated file** — files needing explicit modification consent.
  - **Hotfix** — emergency patch path.
  - **Closing report** — mandatory PR-opens completion artifact.

  Each section ends with an "Override in
  `.claude/vocabulary-overrides.md`" pointer.

- **`bootstrap/vocabulary.md.template`** (~120 lines) — project
  override seed. Bootstrap-only, `skip-if-exists`. Lands at
  `.claude/vocabulary-overrides.md` (different filename to avoid
  collision with the kit-managed defaults file). Includes the iOS
  build-number worked example.

- **`kit/task-rules.md`** — old inline `## Vocabulary` section
  removed; replaced with a top-of-file pointer block (parallel to
  "Platform extensions" and "Output styles") pointing at the new
  vocabulary files.

- **`bootstrap/CLAUDE.md.template`** — one-line reference to
  `.claude/vocabulary-overrides.md` added near the auto-loaded
  primitives block.

#### `/sync` — CHANGELOG delta + overlap reconcile

- **Capability A — CHANGELOG delta surfacing.** When the project's
  pinned SHA differs from kit HEAD, /sync now parses
  `CHANGELOG.md` and renders a §23 Activity timeline of every
  release between the pin and HEAD. Headline + version + date
  per entry. Reserved-version markers (e.g. parked v0.6.0)
  rendered with a special glyph.

  When a release between pin and HEAD has structural / breaking
  signals (e.g. v0.7.0's `/audit` 3-bucket → 2-section change),
  emits a §25 WARNING alert above the timeline pointing at the
  CHANGELOG section.

- **Capability B — Overlap detection + reconcile.** Two
  heuristics fire before installing kit files:
  - **Filename topic match** — project `.claude/<name>.md`
    shares a 5+ char substring (excluding stop-words) with a
    kit file's basename.
  - **Bold-claim phrase overlap** — kit file's `**...**`
    phrases overlap >30% (and ≥3 phrases) with an existing
    project file.

  For every flagged pair, /sync renders a §25 INFO alert + four
  reconcile options:
  1. **Keep project version** — record as override; kit version
     installed at `.claude/.kit-shadow/<name>` for comparison.
  2. **Replace project version with kit** — backup to
     `.claude/_archive/<name>.<YYYY-MM-DD>` first.
  3. **Merge** — render diff, defer for manual reconciliation.
  4. **Delete project version** — backup first.

  Backup discipline is non-negotiable: any deletion or
  replacement first writes the original to `.claude/_archive/`.
  Per Rule 4 (protect main like prod) and Rule 2 (no
  unauthorized destructive ops).

  Schema addition documented in /sync's SKILL.md: optional
  `shadows` array in `foundation.json` for tracking kit-version
  comparisons under Option 1 overrides. Lazily written; the
  bootstrap template stays minimal.

### Changed

#### Split `kit/task-rules.md` into focused files

The kitchen sink is gone. `task-rules.md` (was ~800 lines) keeps
the always-applicable execution core (Scope, Schema, Gated files,
Branch + PR rules, Verification gates, Honest reporting, State
machine, Closing report, Audit log, Phase structure, Adding
tasks, Postmortem, Final review). Three new files split out:

- **`kit/git-flow-rules.md`** (~115 lines) — the five git flow
  rules added in v0.7.0. Read before any task touching branches,
  merges, or deploys.
- **`kit/release-rules.md`** (~190 lines) — production deploy
  tagging format, version-bump heuristic, hotfix path,
  dependency hygiene. Read when shipping or auditing deps.
- **`kit/batch-handoff.md`** (~75 lines) — the multi-task
  integration flow, post-handoff standby state, and the
  merge-to-main confirmation gate. Read when wrapping a phase /
  batch.

`task-rules.md` retains a top-of-file pointer block for each
(parallel to existing "Platform extensions" / "Output styles"
notes). Readers load only what's relevant to the work at hand.

The split is move-and-rename — no content rewriting. Diffable
section-by-section.

#### `MANIFEST.json` — version bump + new sync entries

- Version `0.7.0` → `0.8.0`.
- Four new kit-file sync entries: `git-flow-rules.md`,
  `release-rules.md`, `batch-handoff.md`, `vocabulary.md`.
- One new bootstrap entry: `vocabulary.md.template` →
  `.claude/vocabulary-overrides.md` (skip-if-exists).
- `bin/init`'s `kit/*.md` glob (added in v0.5.0) picks up the
  three new top-level kit files automatically — no init script
  edit needed.

### Notes

- **The vocabulary layer is opt-in for projects to use.** Existing
  projects that sync to v0.8.0 get the new files installed, but
  nothing breaks if they don't fill in `.claude/vocabulary-overrides.md`.
  Skills fall back to kit defaults silently.
- **The split is non-breaking but visible.** Every project that
  syncs to v0.8.0 will see three new files appear in `.claude/`.
  Existing references to "task-rules.md" sections that moved (git
  flow, release, batch handoff) need to be re-pointed to the new
  files. The `/sync` CHANGELOG delta surfaces this on upgrade.
- **The linter is information, not a gate (yet).** `bin/lint`
  exits non-zero on HIGH findings, which makes it CI-suitable, but
  no CI is wired up. Run manually for now.
- **Three MEDIUM lint findings remain** as intentional
  cross-platform references (Realm in /schema-check, vite.config
  in bookmarks template, package.json in /run skill). Not drift
  — documentation features. Documented in the lint output for
  future triage.

---

## v0.7.0 — 2026-05-01

A foundational release. Five interlocking pieces:

1. **Structured outputs catalogue + selection rules** — a shared
   design language for kit deliverables (status reports, deploy
   reports, audits, etc.), with 3 high-leverage skills wired as
   proof-of-concept.
2. **Live HTML dashboard** — opt-in browser-rendered companion
   that visualizes kit state in real time, with environment-aware
   start (auto-opens browser locally; prints SSH tunnel command on
   remote; points at platform port-forwarding for cloud editors).
3. **Git flow safety rules** — five non-negotiable rules in
   `task-rules.md` that protect `main` from unauthorized merges,
   require version-tagging on every deploy, and route all
   releases through `/release`.
4. **`/prototype` rewrite** — replaced the rapid-R&D 4-step loop
   with a mini task manager scoped to `tasks/proto/<slug>/`, fully
   isolated from main backlog/roadmap.
5. **`/task` Operation 3 refinement** — added internal +
   external reconnaissance steps before drafting full specs.
   The task-builder→task-developer interface gets thorough
   research up front so implementation runs without re-asking
   questions.

### Added

#### Structured outputs

- **`kit/output-styles.md`** — catalogue of 34 visual templates
  (hero cards, dashboards, roadmaps, deployment reports, severity
  audits, kanban boards, etc.) with consistent glyph vocabulary
  (`● ◐ ○ ✓ ✗ ▲ ▼ ═ ▌ ★ ▶`) and semantic color palette. Designed
  for monospace + ANSI color, with a "two encodings beat one"
  principle so output stays readable when color is stripped.
- **`kit/output-rules.md`** — selection / composition / discipline
  layer. Defines what counts as a "structured output" (status,
  deploy, audit, backlog, etc.) vs. conversational reply; maps
  each kit scenario to a catalogue §; sets composition rules;
  pins glyph and color semantics; states rendering constraints
  (monospace + code fences); documents fallback behavior when
  no entry fits.

#### Live HTML dashboard (opt-in)

- **`kit/dashboard/`** — opt-in, NOT installed by `bin/init`,
  NOT synced by default. Single-file Python server + single-file
  HTML page. Zero runtime deps beyond Python 3.9+ stdlib.
  - **`dashboard.py`** (~410 LOC) — server + state gatherer +
    environment detection. Subcommands: `start [--port]
    [--no-open]`, `stop`, `status`, `refresh`. Auto-detects
    local / SSH / Codespaces / Gitpod / dev container and tailors
    output. Locally auto-opens the browser; on SSH prints a
    ready-to-paste `ssh -L PORT:localhost:PORT user@host` tunnel
    command; on cloud editors points at the platform's port
    forwarding UI.
  - **`index.html`** (~700 LOC) — vanilla JS, inline CSS, no
    build. Dark theme. Polls `/state.json` every 3s.
  - **`README.md`** — opt-in install + architecture + environment
    matrix.
  - **`.gitignore`** — runtime artifacts (`state.json`,
    `.dashboard.pid`, `.dashboard.log`, `__pycache__/`).
- **`kit/skills/dashboard/SKILL.md`** — `/dashboard start | stop
  | status | refresh | restart`. Detects installation; surfaces
  opt-in step if missing. §25 Alert variants for status messages.

  **Dashboard panels (single "kit" view):**

  | Panel | Source | Catalogue § |
  |---|---|---|
  | Production | `git describe --tags`, deploy frequency strip | §2 + §28 |
  | Git state | branch, dirty/clean, ahead/behind, worktrees | §2 + §17 |
  | Activity | `tasks/AUDIT.md` (or `CHANGELOG.md` fallback) | §23 |
  | Open PRs | `gh pr list` (graceful degrade) | tabular |
  | In flight | `tasks/active/*.md` | tabular |
  | Inbox | `.claude/inbox/*` | tabular |
  | Backlog | `tasks/ROADMAP.md` phases | §3 / §4 |
  | Recent commits | `git log -10 origin/main` | §16 |
  | Anything off | derived warnings (stale PR, dirty main) | §25 |

  Bound to `127.0.0.1` only — never LAN-exposed. SSH tunnel is
  the only way in for remote setups.

### Changed

#### `kit/task-rules.md` — Git flow discipline (5 new rules)

New top-level section between "Vocabulary" and "Scope discipline."
Five non-negotiable rules:

1. **Always branch.** Every change starts on a new branch. Never
   edit code on `main` directly. Naming table for `task/`,
   `chore/`, `hotfix/`, `feat/`, `proto/`, `integration/` prefixes.
2. **Never merge to `main` without explicit user confirmation.**
   No skill auto-merges. No agent runs `git push origin main`
   without a confirm in chat.
3. **Tag every deploy ("tag and bag").** Every deploy from `main`
   is annotated-tagged with a semver version. No exceptions.
4. **Protect `main` like prod.** Never force-push to `main`. Any
   action touching `main` (merge, rebase, push, force) is
   user-confirmed.
5. **Deploys route through `/release`.** Never run deploy
   commands directly bypassing the skill. The skill is the gate
   that enforces pre-flight, version, deploy, tag, audit.

Plus an "Output styles" reference paragraph at the top of
`task-rules.md` (parallel to "Platform extensions"), pointing
to `output-rules.md` and `output-styles.md`.

#### `/prototype` — full rewrite

Replaced the rapid-R&D 4-step loop (gather → plan → do → present)
with a mini task manager scoped to `tasks/proto/<slug>/`. The
prototype is its own complete bubble:

- Branch `proto/<slug>` (off `main` by default).
- Directory `tasks/proto/<slug>/{PHASES.md, ROADMAP.md, backlog/,
  active/, done/}` mirroring the kit's task structure but kept
  totally isolated.
- Brief at `docs/proto/<slug>.md`.

Subcommands: `start <slug>`, `resume <slug>`, `add <title>`,
`spec <id>`, `move <id> active|done`, `status`, `list`,
`graduate`, `shelve`, `drop`. Graduation moves prototype tasks
into main `tasks/` (explicit user action only). Per the new
git-flow Rule 2, no path in `/prototype` ever auto-merges to
`main`.

#### `/task` Operation 3 — major refinement (the spec-drafting flow)

Added two reconnaissance phases before drafting:

- **Internal recon** — read `CLAUDE.md`, the stub, referenced
  files, grep / glob for existing patterns matching the task's
  domain, identify likely-touched files. Every claim in "Files
  expected to change" must be grounded in code actually read.
- **External recon** — fetch current official documentation for
  the frameworks involved. LLM training cutoffs lag the real
  state of frameworks; the spec must feed accurate, current
  context to whoever implements. Concrete doc-source examples
  per stack:
  - iOS / macOS — `developer.apple.com/documentation/<framework>/<symbol>`
  - Android — `developer.android.com/{jetpack,reference}/...`
  - React / Vue / Next — `react.dev`, `vuejs.org`, `nextjs.org` refs
  - Flask / FastAPI / Django — official framework docs
  - Plus generic guidance for any stack.
  Use `WebFetch`, targeted to the specific symbols this task
  touches.
- **Synthesize a recon report** — show the user what you found
  (existing patterns, integration points, current docs say,
  open questions) **before drafting the spec**. The user can
  correct your read of the territory.

Then sharpened requirements drilling (concrete observable
behavior, named edge cases, MUST-NOT-change constraints,
specific test scenarios), per-file rationale (WHAT changes
WHERE and WHY for every file), and the spec draft itself.

A new behavior-contract bullet — *"Don't draft from memory"* —
makes the rule explicit: framework code goes through WebFetch,
not LLM memory.

#### `/spec-phase` — inherits refined Op 3

Step 3 now delegates to the full `/task` Operation 3 recon flow
(internal + external + synthesize + drill + draft). Surfaces
the cost upfront when phases are large: *"7 stubs × ~10–20 min
recon each = an hour or two. Spec all 7 or pick a subset?"*

#### `/task` Operation 3 — Step 3.8 user-context check (added)

After drafting the spec, before showing for sign-off, the skill
now scans for **judgment calls only the user can make** —
business / product decisions, UX preferences, equally-valid
technical paths, real-world edge cases, outside-the-codebase
constraints. Surfaces them as explicit questions before
finalizing, so the implementing developer doesn't have to
re-ask later. *"No user-context questions"* is a valid answer
when the spec is fully grounded in code + docs.

Old Step 3.8 (show / sign-off / write) renumbered to Step 3.9.

#### `/wrangle` — dependency inventory (new area #13)

Phase 1 now produces `docs/wrangle/13-dependencies.md` — every
external library, SDK, package, and third-party service the
project uses, parsed from every manifest in the repo
(`package.json`, `Package.swift`, `Podfile.lock`,
`requirements.txt`, `pyproject.toml`, `build.gradle*`,
`Gemfile.lock`, `go.mod`, `Cargo.lock`, etc.). Three sections:
libraries (vendored code), third-party services (runtime
integrations), dev/build/CI tools. Each row carries the
official doc URL.

This file becomes the **starting list** for `/task` Operation
3's external reconnaissance — when speccing a task that
touches Realm or Kingfisher or AVKit, /task knows where to
WebFetch from without re-discovering.

`.claude/context/project-map.md` tech stack section now also
includes per-entry doc URLs and links to the full inventory.

#### `/audit` — external libraries section (added to Part 1)

Audit reports now include an "External libraries used in this
slice" table — every external library / SDK / service used in
the audited code, with version + purpose + doc URL. Per-slice
scope (not the whole project — that's `/wrangle`'s job).

#### `/skills/new-skill/SKILL.md`

Skeleton requires future skills to pin a catalogue §-entry from
the `output-rules.md` selection table.

#### `MANIFEST.json`

- Version bumped 0.5.0 → 0.6.0.
- Registers `output-rules.md` and `output-styles.md` for sync.
  `bin/init`'s `kit/*.md` glob (added in v0.5.0) picks them up
  automatically — no init script edit needed.

### Wired skills (catalogue proof-of-concept)

- **`/status`** — pins §2 Live status dashboard (project state
  row) + §23 Activity timeline (AUDIT log). Markdown tables
  retained for commits and PRs (legitimate tabular data). §25
  Alert variants for the "anything off" section. Section emoji
  (🚀 🌿 📦 🔀 🛠 🗺 📜 ⚠️) dropped from headings — the
  catalogue's typographic glyphs (`● ◐ ○ ◆`) carry the visual
  weight inside catalogue blocks.
- **`/release`** — pins §5 Deployment report for the closing
  artifact, §2 Live dashboard for the pre-flight check, §25
  Alert variants for failure conditions at any step. The prior
  closing-report markdown table replaced by the catalogue's
  two-column key/value rows below the deployment box.
- **`/audit`** — pins §6 Severity audit for the Findings
  section. **Structural change worth flagging:** the prior 3
  buckets (✅ working / ⚠️ shaky / 🚧 gaps) collapse into 2
  sections — "What's working" (praise, plain bullets) and
  "Findings" (§6 severity tiers: CRITICAL / HIGH / MEDIUM /
  LOW). Severity calibrates honesty better than category.

Remaining ~30 skills wire to the catalogue in a future release.

### Notes

- **Retroactive tags.** v0.3.0, v0.4.0, v0.5.0 are now
  annotated-tagged retroactively on their respective merge
  commits — closing the audit-log drift surfaced by the
  `/status` simulation. Tag history matches release history
  going forward, per Rule 3.
- **Aesthetic shift in 3 wired skills.** Output from `/status`,
  `/release`, `/audit` now looks distinctly different —
  denser, more terminal-app in feel. Other skills follow in a
  future release.
- **Dashboard is opt-in.** Not in `MANIFEST.json` default sync.
  Users copy `kit/dashboard/` into `.claude/dashboard/` when
  they want it. The `/dashboard` skill itself ships universally
  (just markdown) and surfaces the install step on first use.
- **Backwards compatible.** Skills not yet wired to the
  catalogue continue rendering in their prior style — nothing
  breaks.

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
