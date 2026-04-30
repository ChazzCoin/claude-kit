---
name: prototype
description: Rapid R&D mode. Isolate a feature into its own `proto/<slug>` branch, ignore the roadmap and task pipeline, and move from idea to demoable code as fast as possible. Four steps — gather, plan, do, present — optimized for speed and minimal code. Triggered when the user wants to "prototype", "play with", "spike", "test out", or "rapid-build" a feature — e.g. "/prototype", "let's prototype X", "spike Y", "I want to try out Z fast".
---

# /prototype — Rapid R&D mode

You become a prototype engineer. Forget the roadmap. Forget the
backlog. Forget the phase structure. The goal is the **fastest
path from idea to a thing the user can poke at**, on an isolated
branch that won't pollute mainline work.

This is research and development mode. Speed > polish. Reuse >
new code. One file > many files. Whatever gets to a runnable
demo soonest, without making a mess of the rest of the repo.

## The honest tradeoff

This skill **deliberately loosens the kit's normal discipline**:

- No spec file in `tasks/backlog/`.
- No ROADMAP entry.
- No PHASES update.
- No tests by default.
- Lighter code review than `/task` would do.

That tradeoff is the point. Prototypes are throwaway-friendly by
design — the cost of speccing, planning, and testing isn't worth
paying until the idea has been *seen and felt*.

**Surface this to the user at session start.** Confirm that
prototype mode is what they actually want. If they describe
something that's clearly production-bound or already on the
roadmap, push back once: "this sounds like a real feature — do
you want `/task` instead?" Then do what they say.

When the prototype proves out, **graduate it via `/task`** so the
real version goes through the normal discipline (spec, tests,
review, commit, ship). This skill produces sketches, not
products.

## Behavior contract

- **Branch is required.** Every prototype lives on its own
  `proto/<slug>` branch off the user's current working branch
  (usually `main`). Never prototype on `main` or on a feature
  branch with unrelated work in flight.
- **Roadmap and tasks are ignored.** Do not read or write
  `tasks/ROADMAP.md`, `tasks/PHASES.md`, `tasks/backlog/`, or
  any other task-tracking file during a prototype session. The
  prototype doesn't exist in those structures by design.
- **Speed over polish.** Pick the shortest path. Reuse existing
  utilities, components, and patterns. Don't introduce new
  dependencies if an existing one will do. Don't refactor on
  the way through.
- **No tests by default.** Skip unit and integration tests
  unless the user explicitly asks for one. A quick smoke check
  in chat is fine.
- **Quick code review only.** A glance for obvious bugs and
  security smells before handing off. Not a full audit.
- **One commit at the end.** All prototype changes go in a
  single commit on the proto branch. Don't commit incrementally
  unless the user asks.
- **Always leave a doc behind.** Write `docs/proto/<slug>.md`
  describing what was built, why, and how to run it — even if
  the user shelves the work. Future-you (or future-them) needs
  the breadcrumb.
- **No production wiring.** Don't add the prototype to app
  routing, navigation, build pipelines, deploy scripts, or any
  other surface that could ship to users. The point is
  isolation.

## The flow

### Step 1 — Gather

Open the session with the tradeoff (above), then collect:

- **What's the feature?** One-paragraph description in the user's
  own words.
- **Why prototype it?** Are they exploring a UX idea? Validating
  a technical approach? Comparing two options? The "why" shapes
  what "good enough to demo" means.
- **What does success look like?** What needs to work for the
  prototype to be worth showing? Don't accept "it should work" —
  push for a concrete acceptance bar (e.g. "I can drag a node
  and the edges follow", "an HTTP request returns the model's
  output").
- **What's out of scope?** Explicitly. Auth, persistence,
  error handling, polish, mobile responsiveness — most of these
  should be out for a prototype.
- **Any constraints?** Stack, libraries to use or avoid, files
  that mustn't be touched, time budget.

End the gather with a tight reflect-back:

```
You want to prototype: <feature, one sentence>
Acceptance: <one-line bar>
Out of scope: <comma list>
Constraints: <comma list, or "none">

Sound right?
```

Wait for confirmation before moving on.

### Step 2 — Plan

A short plan, surfaced in chat (not written to disk):

1. **The ask in one sentence.**
2. **Acceptance criteria** — bullet list, ≤5 items, each
   independently verifiable.
3. **Minimal architecture** — sketch the moving parts. What's
   new, what's reused, what's the data/control flow. Pseudocode
   is fine. ASCII diagram if helpful.
4. **Reuse audit** — explicitly call out: *what existing code
   does this lean on, and where does it live?* Read enough of
   the repo to make this real, not invented.
5. **New files / changed files** — exhaustive list, with the
   reason for each.
6. **Quickest route** — name the path you're picking. Mention
   one alternative you considered and why you skipped it. Speed
   is the tiebreaker.

Show the plan. Wait for sign-off. Iterate if the user pushes
back. Don't start implementing before the user says go.

### Step 3 — Do

Default: **one task**, executed end-to-end in the same session.

If the scope genuinely can't fit in one pass (the user agrees,
not your guess), break it into the **smallest number of tasks
possible** — typically 2, rarely 3, never more. Each task is:

- A 1-line title.
- A 1-paragraph "what + acceptance".
- Done immediately, in sequence.

Execution rules:

- **Code first, polish never.** Write the code that makes the
  acceptance bar pass. No premature abstraction. No defensive
  validation beyond what's needed for the demo to not crash.
- **Reuse aggressively.** If you find existing code that does
  80% of the job, use it and patch the 20%. Don't rewrite for
  cleanliness.
- **No new dependencies** unless absolutely required. If you
  add one, name it and the alternative you considered.
- **Quick code review at the end.** Walk the diff yourself.
  Flag: obvious bugs, security smells (injection, secret leaks,
  unbounded loops), accidental edits to unrelated files. Fix in
  place. Skip stylistic polish.
- **Commit once.** One commit on the `proto/<slug>` branch with
  message:
  ```
  prototype: <feature> — <one-line what>

  Built via /prototype. Acceptance: <bar>.
  See docs/proto/<slug>.md for the full breakdown.
  ```

If the user's plan changed mid-session, that's fine — note the
shift in the chat and proceed. Don't go back and re-plan
formally.

### Step 4 — Present

Hand the prototype off for testing. Output:

```markdown
# /prototype — <feature> ready for review

**Branch**: `proto/<slug>`
**Commit**: <sha-short> — "<commit-title>"
**Doc**: `docs/proto/<slug>.md`

## How to run it

<concrete steps. Commands. URLs. Any setup needed. "It just
works on `main` after checkout" if true.>

## What it does

<1-2 paragraph walkthrough of the user-visible behavior.>

## What it does NOT do

<bullet list of out-of-scope items the user might assume work
but don't.>

## What I'd want to revisit if this graduates

<bullet list — places where speed beat correctness, missing
tests, hardcoded values, etc. Be specific. This is the input
to a real /task spec if the prototype proves out.>

## Next move

Pick one:
- **Iterate.** Keep me here for another round on this branch.
- **Graduate.** Hand off to /task to spec a real version.
- **Shelve.** Branch stays. I move on.
- **Drop.** Delete the branch and the doc.
```

### After Step 4 — Iteration mode

If the user says "iterate", stay in `/prototype` mode on the
same branch. Skip Step 1 (already scoped). Re-do Step 2 lightly
(what's the next change?), then Step 3, then Step 4 again.

Each iteration is its own commit on the proto branch. Keep the
`docs/proto/<slug>.md` doc updated with each round.

If the user says "shelve" or "drop", state the consequence
clearly and confirm before deleting anything:

- **Shelve** = branch and doc remain; you exit the skill.
- **Drop** = `git branch -D proto/<slug>` and `rm
  docs/proto/<slug>.md` — irreversible without recovery from
  reflog. Confirm explicitly before doing this.

## The proto doc shape

`docs/proto/<slug>.md` is written at the end of Step 3 (before
Step 4 runs). It exists so a future session — yours, the user's,
or someone else's — can pick up the prototype cold.

```markdown
# Prototype: <feature title>

**Date**: YYYY-MM-DD
**Branch**: proto/<slug>
**Status**: <Open · Iterating · Shelved · Graduated · Dropped>

## What it is

<1-paragraph description.>

## Why it was built

<1-paragraph motivation. What question was being explored?>

## How to run it

<concrete steps.>

## Acceptance bar

<bullet list — what counts as "the prototype works".>

## What's out of scope

<bullet list of intentional omissions.>

## Architecture sketch

<short — files touched, key data flows, dependencies.>

## Reused from the existing codebase

<bullet list of existing files / utilities / components leaned
on. Cite path:line.>

## Known sharp edges

<bullet list — places where speed beat correctness. Each is a
candidate for a real /task spec if this graduates.>

## Iteration log

- YYYY-MM-DD — initial build. <one line>
- YYYY-MM-DD — iteration 1. <one line>
```

## What you must NOT do

- **Don't touch `tasks/`.** No ROADMAP entries. No backlog
  files. No PHASES updates. The prototype is invisible to the
  task system by design.
- **Don't merge to `main`** during a prototype session. Even if
  the user asks. Push back: "graduate via `/task` first so it
  gets a real spec and review." If they insist on merging
  prototype-grade code, that's their call — but state the
  consequence clearly.
- **Don't add tests** unless the user explicitly asks. This is
  not a polish skill.
- **Don't refactor adjacent code** that the prototype touches.
  Note the smell in the doc's "sharp edges" section, leave the
  code alone.
- **Don't introduce a new dependency silently.** Always name
  it, the alternative considered, and why you picked it.
- **Don't skip the doc.** Even on a one-hour throwaway. Even
  if the user says "I'll just delete it." The doc costs five
  minutes and pays back the first time anyone (you included)
  comes back to the branch.
- **Don't drift into production wiring.** Routing, navigation,
  build pipeline, deploy scripts, env config — all out. The
  prototype must not be reachable in any shipped surface.
- **Don't claim it's done before running it once.** A
  prototype that hasn't been executed at least once is not a
  prototype. Smoke-check before Step 4.

## When NOT to use this skill

- **The feature is real and going to ship.** Use `/task`. The
  spec, tests, and review discipline exist for a reason.
- **You're exploring an architecture decision** without writing
  code. Use `/brainstorm` (tradeoff session) or `/decision`
  (record a choice).
- **The codebase is unfamiliar and you need to understand it
  first.** Use `/wrangle` to map the territory before
  prototyping in it.
- **The work spans more than ~2 days of focused effort.** That's
  not a prototype anymore — it's a feature. Spec it via `/task`
  or, if the scope is genuinely product-shaping, `/mvp`.
- **The user wants the prototype to immediately become
  production code.** Push back: that defeats the purpose. Either
  prototype properly (and graduate later) or skip the prototype
  and use `/task`.

## What "done" looks like for a /prototype session

- A `proto/<slug>` branch exists with one commit (or a small,
  ordered series of commits if iterations happened).
- `docs/proto/<slug>.md` exists and accurately describes what
  was built, why, how to run it, and what the sharp edges are.
- The user has a concrete next move on the table: iterate,
  graduate, shelve, or drop.
- Mainline (`main` and any active feature branches) is
  unchanged and unaffected.
- No `tasks/` files were touched.
