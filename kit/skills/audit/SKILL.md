---
name: audit
description: Audit a section of the codebase and produce a two-part report — (1) architectural breakdown with code snippets and (2) honest pros/cons assessment. The report is rendered in chat AND saved to `docs/audits/<YYYY-MM-DD>-<target-slug>.md` so audits accumulate as durable project history future sessions can reference. Triggered when the user wants a code review on a slice of the repo — e.g. "/audit src/firebase", "audit the inspection detail flow", "audit what we have for work orders", "give me a read on the auth code".
---

# /audit — Codebase audit

Take a target (a directory, a feature, a module, a file) and produce
a single readable report with two parts: how it's built, and how it
holds up. No marketing voice. No soft-pedaling. Per CLAUDE.md: blunt
resonant honesty, calibrated confidence, no narratives.

The report is rendered in chat **and** persisted to disk under
`docs/audits/`. Past audits are durable context — future Claude
sessions can read them directly when they need the historical read
on a slice without re-doing the work.

## Behavior contract

- **Resolve the target.** If the user gives a vague target ("audit the
  inspection stuff"), do a quick `Glob`/`Grep` pass to enumerate
  candidate files, then state in one sentence what you're auditing
  before diving in. If the scope is genuinely ambiguous, ask once.
- **Read before opining.** Read every file in scope before writing
  Part 2. Don't assess from filenames. If the audit target is large
  (>~15 files or >~2k lines), spawn an `Explore` agent to map it,
  then read the highest-leverage files yourself.
- **Honest confidence.** If a concern is a guess, say "I think" or
  "likely". If it's verified by reading the code, state it flat. Don't
  pad uncertain claims with hedging adverbs to feel safer.
- **Persist the report.** Write the same report rendered in chat to
  `docs/audits/<YYYY-MM-DD>-<target-slug>.md` (create `docs/audits/`
  if missing). Slug from the audit target — `src-firebase`,
  `auth-flow`, `work-orders`. If a same-day audit on the same
  target already exists, suffix with `-2`, `-3`. Add a one-line
  frontmatter block at the top of the saved file: `**Target.** …
  **Scope.** … **Date.** YYYY-MM-DD`. The chat response is the
  same content; the disk file is the durable record.
- **No fix work.** This skill produces a report only. Do not edit
  code, do not file tasks, do not propose patches. If the user wants
  follow-ups, they'll route them through `/task` after reading.
- **Code snippets are evidence, not decoration.** Include a snippet
  only when it makes a point — a key abstraction, a smell, a
  surprising contract. Cite `file_path:line_number` so it's clickable.
- **Stay in scope.** If something out-of-scope catches your eye,
  mention it in a one-line "Adjacent observations" footer at most.
  Don't expand the audit unilaterally.

## Output structure

Render exactly this shape. The whole report is the response — no
preamble like "Here's the audit", no closing "let me know if you
want…". The first heading is the deliverable.

```markdown
# 🔍 Audit — <target>

> **TL;DR.** <one sentence on the overall read. Not "looks good" —
> something specific. e.g. "Solid read-side, write-side is half-built
> and inconsistent across modules.">

**Scope.** <files / directories actually read, comma-separated or
short list>
**Lines audited.** <approximate count>

---

## Part 1 — Architectural breakdown

### <Subsystem or layer name>

<2–4 sentences describing what this layer does and how it fits.>

```<lang>
// file_path:line_number
<minimal snippet illustrating the pattern>
```

<One sentence on why this snippet matters.>

### <Next subsystem>
…

*(Repeat for each meaningful layer. Typical layers: data/model,
firebase/IO, hooks, components, routing, styling. Skip layers that
aren't present.)*

---

## Part 2 — Honest assessment

### ✅ What's working

- **<short claim>** — <one-line why it's good, ideally with a file
  reference>
- …

### ⚠️ What's shaky

- **<short claim>** — <one-line why, with file reference. Be specific:
  "duplicates X across 3 files" beats "could be cleaner">
- …

### 🚧 Gaps / missing pieces

- **<thing that isn't there but probably should be>** — <why it
  matters>
- …

### Tradeoffs worth naming

<2–5 sentences on the genuine tradeoffs the current design makes.
Not "pros and cons" theatre — the real ones. e.g. "Choosing RTDB
over Firestore costs you query power but buys you cheaper real-time
fan-out, which matches the iOS app's pattern.">

---

## Bottom line

<2–4 sentences. What would you do next if this were yours? Be
direct. If the answer is "leave it alone, it's fine", say that.
If the answer is "this needs a rewrite before adding more", say
that too — and say why.>

*(Optional)* **Adjacent observations.** <one or two lines on stuff
just outside the audit scope that the reader should know about.>
```

## Style rules

- **Visual rhythm matters.** Use the horizontal rules (`---`) between
  Part 1, Part 2, and Bottom line. They make the report scannable.
- **Emoji are load-bearing here, not decoration.** 🔍 marks the
  report, ✅/⚠️/🚧 mark the assessment buckets. Don't sprinkle
  others.
- **Bold the claim, then dash, then the reason.** It reads like a
  bullet list of headlines. `- **Claim** — reason.`
- **No tables in Part 2.** Lists scan faster for opinions; tables
  imply false uniformity.
- **Code snippets ≤ 15 lines.** If you need more, link with
  `file_path:line_start-line_end` and summarize in prose.
- **Cite files as `path:line`.** Renders as a click-through link in
  the chat.
- **No trailing "hope this helps".** End on the Bottom line (or the
  Adjacent observations footer).

## What "honest" looks like in Part 2

Per CLAUDE.md: no narratives, no soft no's, no soft yes's.

- "The hooks are clean." — fine if they are.
- "There's a real bug here: `useInspections` joins notes by
  `inspectionFormId` but writes them under `inspectionFormField`.
  This will silently lose every note." — fine, that's a verified
  claim about the code.
- "This could potentially be improved by considering a refactor in
  the future." — **don't write this.** It says nothing. Either
  there's a concrete improvement worth naming or there isn't.
- "I don't know how this handles offline state — couldn't verify
  from the code." — **good.** Saying I-don't-know is part of the
  contract.

## When NOT to use this skill

- **Architecture planning for new work** → use `/plan`. Audit looks
  at what exists; plan looks at what should.
- **Filing follow-up tasks from an audit** → use `/task` after the
  audit, not inside it.
- **Reviewing a single small file** (< ~50 lines) → just read it
  inline; the two-part structure is overkill.
- **Reviewing a PR or diff** → that's `/ultrareview` or a normal
  review request, not this.
- **Listing what skills exist** → use `/skills`.

## What "done" looks like for a /audit session

A single rendered report following the structure above, displayed
in chat **and** saved to `docs/audits/<YYYY-MM-DD>-<target-slug>.md`
uncommitted. No source-code edits, no commits, no task filings.
The user reads it, decides what (if anything) to act on next, and
can `git diff` + commit the saved audit when ready. Past audits
under `docs/audits/` are durable context for future sessions.
