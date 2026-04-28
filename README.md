# claude-kit

A portable foundation for Claude Code projects — skills, rules, and
templates that work across any repo, any language, any platform.

> **Why this exists.** Iteration never stops. When a skill or process
> rule gets better in one project, every project should benefit.
> claude-kit is the central source of truth; projects pull from it
> via the `/sync` skill or bootstrap from it via `bin/init`.

---

## What's in the kit

```
claude-kit/
├── kit/                          # synced into target's .claude/
│   ├── skills/                   # slash commands
│   │   ├── audit/                #   universal
│   │   ├── …                     #   (more universal)
│   │   └── ios-release/          #   iOS-specific (prefix marks scope)
│   ├── task-rules.md             # universal execution rules
│   ├── ios-task-rules.md         # iOS platform extensions
│   ├── web-task-rules.md         # web platform extensions (placeholder)
│   ├── ios-conventions.md        # iOS architectural reference
│   └── task-template.md          # spec template for new tasks
├── bootstrap/                    # one-time files (init only, never synced)
│   ├── CLAUDE.md.template
│   ├── PHASES.md.template
│   ├── ROADMAP.md.template
│   ├── AUDIT.md.template
│   └── foundation.json           # initial sync-tracking file
├── bin/
│   └── init                      # bootstrap a target project
├── MANIFEST.json                 # what files this kit ships
└── README.md                     # this file
```

**`kit/`** = synced files. Improvements here propagate to every
project that runs `/sync`.

**`bootstrap/`** = one-time files. Init copies them once if they
don't exist; they belong to the project after that and never get
overwritten.

### Platform-prefix naming convention

The kit uses **filename prefixes** to mark platform scope:

| Pattern | Scope | Example |
|---|---|---|
| no prefix | Universal — every project | `task-rules.md`, `skills/audit/` |
| `ios-*` | iOS-specific | `ios-task-rules.md`, `skills/ios-release/` |
| `web-*` | Web-specific | `web-task-rules.md`, `skills/web-deploy/` |
| `python-*` | Python-specific (future) | `python-task-rules.md` |
| `android-*` | Android-specific (future) | `android-task-rules.md` |

**Important:** the prefix is a **discovery hint, not a gate.** Every
project that runs `bin/init` pulls *everything* — universal files
plus all platform-prefix files. The prefix tells Claude which files
are relevant to the current work. So an iOS project where Claude is
working on the HTTP layer can naturally read `python-task-rules.md`
to understand the API conventions on the other end.

This makes multi-platform projects (e.g., a monorepo with iOS + web,
or an iOS app talking to a Python backend) work without `--platform`
flags — every project installs everything; each work session reads
the prefix files that apply.

The universal `task-rules.md` documents this convention at the top
so every Claude session is aware of it.

---

## Skills shipped

Run `/skills` inside any project after init to see the live list.
Current set:

### Universal (apply to every project)

| Skill | Purpose |
|---|---|
| `/audit` | High-altitude two-part architectural read |
| `/backlog` | Forward-looking task list, grouped by phase |
| `/build` | Toolchain-detecting "does it build?" |
| `/decision` | ADR drafter for real architectural calls |
| `/onboard` | Guided onboarding for new contributors |
| `/plan` | Socratic roadmap-planning partner |
| `/postmortem` | Incident postmortem drafter |
| `/release` | End-to-end production release orchestrator (delegates to platform skills) |
| `/review` | Senior line-by-line peer review |
| `/roadmap` | Full per-phase view including completed work |
| `/run` | Toolchain-detecting launcher |
| `/schema-check` | Cross-platform schema mirror reconciliation |
| `/skills` | Lists all locally-defined skills |
| `/status` | Read-only project snapshot |
| `/stuck` | Socratic unblock-the-human partner |
| `/sync` | Reconcile this project's `.claude/` with claude-kit |
| `/task` | Per-task action skill (file, move, expand) |
| `/update-docs` | Reconcile docs against reality |

### Platform-specific

| Skill | Scope | Purpose |
|---|---|---|
| `/ios-release` | iOS | Archive + export + validate + upload to TestFlight via xcodebuild + altool |

---

## Bootstrapping a new project

### Greenfield (new repo)

```sh
git clone https://github.com/ChazzCoin/claude-kit /tmp/claude-kit
/tmp/claude-kit/bin/init /path/to/your/new/project
cd /path/to/your/new/project
```

The init script:

1. Creates `.claude/skills/`, `.claude/task-rules.md`, `.claude/task-template.md` from `kit/`
2. Drops bootstrap templates (CLAUDE.md, PHASES.md, ROADMAP.md, AUDIT.md) into the project — **only if they don't already exist**
3. Creates `tasks/{backlog,active,done}/` with `.gitkeep` files
4. Writes `.claude/foundation.json` with the kit's commit SHA so `/sync` knows what to compare against
5. Prints next steps (mostly: fill in the placeholders in CLAUDE.md)

### Existing project

Same command — `bin/init` is safe on existing projects because it
preserves any file that already exists. After running, run `/sync` to
diff your local `.claude/` against the kit and pull the parts you want.

```sh
/tmp/claude-kit/bin/init .
# review what changed
git diff
# fill in CLAUDE.md placeholders
# commit
```

---

## Integrating into an existing project (agent-friendly)

If you're a Claude agent already working in a project that has its
own `.claude/`, `tasks/`, and `CLAUDE.md` — and you want to bring
the kit in without losing project-specific work — follow this exact
flow. Designed to be runnable on a single read of this section, no
prior kit knowledge required.

### What `bin/init` will do to an existing project

| File / dir | Policy | What you should know |
|---|---|---|
| `.claude/skills/` | additive — overlays kit skills, doesn't delete project-only ones | If a kit skill name collides with a project-only skill, the kit wins. **Rename project-only skills with a `local-` prefix BEFORE init** if they share a name with a kit skill. |
| `.claude/task-rules.md` | **OVERWRITE** with kit version | If your project has elaborated this file with project-specific content (gated files, verification commands, baselines, project trust modes), **back it up first** — see "Save your work" below. |
| `.claude/task-template.md` | **OVERWRITE** with kit version | Same — back it up first if project-customized. |
| `.claude/<platform>-*.md` (e.g. `ios-task-rules.md`) | added | New file — won't collide unless you happen to already have one with a matching name. |
| `.claude/foundation.json` | created if missing | Skipped if exists — your existing pin stays. |
| `tasks/{backlog,active,done}/` | scaffolded if missing/empty | Existing task files preserved. |
| `tasks/PHASES.md`, `tasks/ROADMAP.md`, `tasks/AUDIT.md` | `skip-if-exists` | Existing project-specific versions stay. |
| `CLAUDE.md` | `skip-if-exists` | Existing CLAUDE.md stays. **You'll edit it after init** to add the new `## Platform` section and migrate any project-specific content from the old task-rules.md. |
| `docs/decisions/`, `docs/postmortems/` | scaffolded if missing | Empty `.gitkeep` only. |

### Save your work BEFORE running init

If your project has elaborated `.claude/task-rules.md` or
`.claude/task-template.md` beyond the kit's defaults, save them
first:

```sh
cp .claude/task-rules.md /tmp/_pre-kit-task-rules.bak
cp .claude/task-template.md /tmp/_pre-kit-task-template.bak
```

These will be overwritten by `bin/init`. After init, you'll diff
the backups to identify project-specific content and move it to
`CLAUDE.md` (where the kit's design says project-specifics belong).

### The integration sequence

```sh
# 1. Branch off main (or your equivalent default).
git checkout main && git pull
git checkout -b chore/integrate-claude-kit

# 2. Save your project-elaborated kit files.
cp .claude/task-rules.md /tmp/_pre-kit-task-rules.bak 2>/dev/null || true
cp .claude/task-template.md /tmp/_pre-kit-task-template.bak 2>/dev/null || true

# 3. Clone the kit.
git clone https://github.com/ChazzCoin/claude-kit /tmp/claude-kit

# 4. Run init.
/tmp/claude-kit/bin/init .

# 5. Inspect what changed.
git status
git diff .claude/

# 6. Reconcile. Diff the backup against the new kit version.
diff /tmp/_pre-kit-task-rules.bak .claude/task-rules.md

# Identify content that's:
#   - Project-specific (move to CLAUDE.md)
#   - Generic improvement (consider PR'ing back to claude-kit)
#   - Already covered by the kit (drop)

# 7. Edit CLAUDE.md:
#    - Add the new "## Platform" section (right after "## What this is")
#      and declare your project's platform.
#    - Move project-specific gated files from old task-rules.md into
#      the "Gated files" section.
#    - Move project-specific verification baselines (e.g. warning count)
#      into the "Commands" section or a verification subsection.
#    - Move project trust modes (e.g. "approval gate", "stabilization
#      mode") into a "Phase" section in CLAUDE.md.

# 8. Verify nothing important was lost.
diff /tmp/_pre-kit-task-rules.bak .claude/task-rules.md | grep "^<"
# Anything starting with "<" was in your original but not in the kit.
# It either landed in CLAUDE.md (good), is now redundant (good), or
# was lost (fix).

# 9. Run the project's verification gate (build/test).
# 10. Open an integration PR.
```

### What goes where (the kit's design)

The kit's principle: **`task-rules.md` and prefix files are generic;
project-specifics live in `CLAUDE.md`.**

| Project-specific content | Goes in |
|---|---|
| This project's actual scheme name, baseline warning count | `CLAUDE.md` "Commands" |
| Specific Realm models / data classes that exist in this app | `CLAUDE.md` "Schema ownership" |
| Bundle ID, team ID, version | `CLAUDE.md` (top metadata or "Tech stack") |
| This project's phase state (stabilization, alpha, etc.) | `CLAUDE.md` "Phase" |
| Trust modes specific to this project (e.g. "every change requires per-change approval") | `CLAUDE.md` "Phase" or a dedicated section |
| Project-specific gated files beyond the kit defaults | `CLAUDE.md` "Gated files" |

| Generic platform content | Goes in |
|---|---|
| iOS verification gate command shape (`xcodebuild …`) | `kit/ios-task-rules.md` (already there) |
| iOS protected files (`*.xcodeproj/`, etc.) | `kit/ios-task-rules.md` (already there) |
| Apple build-number monotonic constraint | `kit/ios-task-rules.md` (already there) |
| Universal build/test/release patterns | `kit/task-rules.md` (already there) |

If during reconciliation you find your project had a generic
improvement that the kit lacks (e.g. a workflow pattern that would
help every project), open a PR against `claude-kit` to push it
upstream. That's how the kit gets better.

### What to do if you're unsure

Use `/sync` after init. The skill reads `.claude/foundation.json`
and shows a diff of every kit-managed file vs the local version.
You can accept changes file-by-file or mark a file as a "local
override" so future syncs respect it.

### Rollback

`bin/init` is non-destructive of bootstrap files (CLAUDE.md, etc.),
but it does overwrite `task-rules.md` and `task-template.md`. If
something went wrong, the integration branch can be deleted and the
project reverts to its pre-init state (you didn't merge the
branch yet — you were on `chore/integrate-claude-kit`, right?).

---

## Iterating

### "I improved a skill in project A — get it into the kit"

1. In project A, edit the skill in `.claude/skills/<name>/SKILL.md`.
2. When ready, copy that change into the claude-kit repo's
   `kit/skills/<name>/SKILL.md`.
3. Commit + push to claude-kit.
4. In project B (and every other project), run `/sync` and accept the
   skill update.

The `/sync` skill is the one-way valve. It reads from the kit, never
writes back. Pushing improvements back to the kit is a manual git
operation — that's intentional, so changes are reviewed.

### "I want to override a kit file in one project only"

Just edit the file locally. `/sync` will detect the divergence as a
"local override" and **not** overwrite it without your approval. The
override is recorded in `.claude/foundation.json` so future syncs
respect it.

### "The kit shipped a bad change — I want to roll back"

```sh
# In claude-kit:
git revert <bad-commit>
git push
# Then in each project:
/sync   # picks up the revert
```

Or pin to an older commit by editing `.claude/foundation.json`'s
`pinned_sha` field manually.

---

## Design principles

- **Generic where possible, specific where it matters.** Skills detect
  toolchains; rules reference `CLAUDE.md` for project-specific commands;
  templates use `{{PLACEHOLDER}}` markers.
- **Honest reporting both ways.** Same ethos as [Anthropic's CLAUDE.md
  conventions]. Skills report failures plainly; sync surfaces conflicts
  rather than silently merging.
- **Never auto-commit.** Every skill that modifies files leaves changes
  staged or unstaged for the human to review.
- **Solo-dev-friendly first.** No team-mode features (codeowners,
  required reviewers, multi-author workflows) until they're actually
  needed.

---

## License

MIT. Copy, fork, hack on it. If you make it better, send a PR.
