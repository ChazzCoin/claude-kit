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
├── kit/                    # synced into target's .claude/
│   ├── skills/             # all the slash commands
│   ├── task-rules.md       # generic execution rules
│   └── task-template.md    # spec template for new tasks
├── bootstrap/              # one-time files (init only, never synced)
│   ├── CLAUDE.md.template
│   ├── PHASES.md.template
│   ├── ROADMAP.md.template
│   ├── AUDIT.md.template
│   └── foundation.json     # initial sync-tracking file
├── bin/
│   └── init                # bootstrap a target project
├── MANIFEST.json           # what files this kit ships
└── README.md               # this file
```

**`kit/`** = synced files. Improvements here propagate to every project
that runs `/sync`.

**`bootstrap/`** = one-time files. Init copies them once if they don't
exist; they belong to the project after that and never get overwritten.

---

## Skills shipped

Run `/skills` inside any project after init to see the live list.
Current set:

| Skill | Purpose |
|---|---|
| `/audit` | High-altitude two-part architectural read |
| `/backlog` | Forward-looking task list, grouped by phase |
| `/build` | Toolchain-detecting "does it build?" |
| `/decision` | ADR drafter for real architectural calls |
| `/onboard` | Guided onboarding for new contributors |
| `/plan` | Socratic roadmap-planning partner |
| `/postmortem` | Incident postmortem drafter |
| `/release` | End-to-end production release orchestrator |
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
