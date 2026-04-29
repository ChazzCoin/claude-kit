# 🎨 Output styles catalog

A reference of visual patterns Claude should use when rendering
structured output. Pick the style that matches the **shape of the
data** and the **information goal** — not the longest one
available.

Skills cite styles by name. When a skill's "Output structure" says
*"render using the **roadmap timeline** style"*, pull the pattern
from this file.

---

## How to use this file

- **Match shape to data, not aesthetic preference.** A list of
  unrelated items is never a tree; a single value is never a
  dashboard.
- **One style per output, usually.** Mixing two styles in one
  response dilutes both. Pick the load-bearing one.
- **Emoji are load-bearing in styles that include them.** Don't
  swap the conventional emoji for "prettier" alternatives — the
  catalog's emoji are part of the visual vocabulary.
- **Don't wrap a style in extra prose.** The style *is* the
  output. Render → stop.

If a skill's needs don't match any catalog style, render plain
markdown. Don't force-fit a style.

---

## Index

| # | Style | Best for |
|---|---|---|
| 1 | [Headline + 3-things-to-know](#1-headline--3-things-to-know) | Wrap-up summaries; first-glance reads |
| 2 | [Roadmap timeline](#2-roadmap-timeline) | Multi-phase project view + active phase detail |
| 3 | [Status dashboard](#3-status-dashboard) | At-a-glance KPI grid |
| 4 | [Tree breakdown](#4-tree-breakdown) | Hierarchical task or section state |
| 5 | [Confidence-tagged findings](#5-confidence-tagged-findings) | Verified vs inferred claims |
| 6 | [Two-part report](#6-two-part-report) | Objective description + honest assessment |
| 7 | [Decision matrix](#7-decision-matrix) | Options × criteria comparison |
| 8 | [Drift classification](#8-drift-classification) | Reconcile two states (kit ↔ project, etc.) |
| 9 | [Pull-quote rule of thumb](#9-pull-quote-rule-of-thumb) | Single durable lesson worth remembering |
| 10 | [Branching options menu](#10-branching-options-menu) | Consent gate; user picks a path |

---

## 1. Headline + 3-things-to-know

**Use when.** A skill just produced a multi-section artifact and
the user needs a fast read. The full content lives elsewhere
(file on disk, deep section); this is the executive summary.

**Don't use when.** The content fits in 2-3 sentences total —
just say it.

**Pattern.**

```markdown
# <emoji> <Title>

> **Headline.** <one sentence — specific, not "looks good">

**The three things most worth knowing right now:**
1. <terse, specific>
2. <terse, specific>
3. <terse, specific>

<one-line pointer to the full artifact>
```

**Used by.** `/wrangle`, `/handoff`, `/lessons`, `/retro`.

**Notes.** "Three" is load-bearing — forces ranking. Two reads
as incomplete; four reads as a list. Headline is one
specific sentence, never "things look fine".

---

## 2. Roadmap timeline

**Use when.** Multi-phase project view where macro state
(phases) and micro state (tasks within current phase) both
matter.

**Don't use when.** Single-phase work; or when the timeline is
implied by linear sentences and would be visual noise.

**Pattern.**

```
ROADMAP ▏ <quarter or label>


●━━━━━━━━━━●━━━━━━━━━━●─ ─ ─ ─ ─ ─ ○
phase 1     phase 2     phase 3      phase 4
done        done        active      planned


Phase 3  ·  <phase name>

├─  ✓  <completed item>
├─  ✓  <completed item>
├─  ◐  <in-progress item>        ← in progress
├─  ○  <todo item>
└─  ○  <todo item>
```

**State markers:**
- `●` filled circle — phase done
- `●` (with `━━━` after) — phase active
- `○` empty circle — phase planned
- `─ ─ ─` dashed connector — uncommitted future
- `━━━` solid connector — committed past or active
- `✓` task done
- `◐` task in progress
- `○` task todo
- `←` current-focus pointer (load-bearing — beats bold)

**Used by.** `/roadmap`. `/status` may use a compressed variant.

**Notes.** Horizontal bar carries macro state; tree below carries
micro state. The `←` pointer marks "you are here" better than
any amount of bolding. Don't use a table — tables imply uniform
fields; phases are sequential, not parallel.

---

## 3. Status dashboard

**Use when.** Project-level "where things stand" snapshot. Reader
wants to scan a few key metrics in one glance.

**Don't use when.** Single-data-point queries; or narratives
where the metrics aren't comparable.

**Pattern.**

```markdown
## 🎯 At a glance

| | |
|---|---|
| **What it is** | <one-line purpose> |
| **Current phase** | <Phase N — name> |
| **Active tasks** | <count> in flight, <count> in backlog |
| **Last shipped** | <date> — <one-line item> |
| **Pinned to kit** | `<sha>` *(<N> commits behind)* |
```

**Used by.** `/status`, `/export-project` (the "At a glance"
section).

**Notes.** Two-column table forces tight summaries. Bold key on
left, value on right. No third column — it implies categorization
that doesn't apply.

---

## 4. Tree breakdown

**Use when.** Hierarchical content — directory listing,
component tree, task subtree, taxonomy. Each item has state.

**Don't use when.** Flat lists (just use bullets) or content
where the hierarchy is incidental.

**Pattern.**

```
<root>
├─ <branch-a>
│  ├─ ✓  <leaf — done>
│  ├─ ◐  <leaf — in progress>
│  └─ ○  <leaf — todo>
├─ <branch-b>
│  └─ ✓  <leaf>
└─ <branch-c>
   ├─ ⚠  <leaf — warning>
   └─ ✗  <leaf — failed>
```

**State markers (when applicable):** `✓` done, `◐` in progress,
`○` todo, `⚠` warning, `✗` failed/error, `●` active.

**Used by.** `/wrangle` (when surfacing repo shape), `/roadmap`
(within a phase), file-listing displays.

**Notes.** Use the `├─`, `│`, `└─` box-drawing characters — not
hyphens. Indent with two spaces under the connector. State
markers (when used) align in a column.

---

## 5. Confidence-tagged findings

**Use when.** Audits, scans, or reports where some claims are
verified and others are inferred. Reader needs to know which is
which.

**Don't use when.** All claims are equally certain (just list
them) or the distinction would feel performative.

**Pattern.**

```markdown
**Confidence legend:** ✅ Verified — read in code. ⚠️ Likely — strong inference. ❓ Possible — pattern match only.

### ✅ Verified

- [`<path>:<line>`](<link>) — <one-line claim>
- [`<path>:<line>`](<link>) — <one-line claim>

### ⚠️ Likely

- [`<path>:<line>`](<link>) — <claim with uncertainty>

### ❓ Possible

- <surface that needs human verification>
```

**Used by.** `/blast-radius`, `/audit` (where applicable),
`/scope-check`.

**Notes.** Confidence is a heading, not a parenthetical. The
emoji is part of the vocabulary — don't substitute. Cite a
file + line for every Verified/Likely; Possible items cite a
broader area.

---

## 6. Two-part report

**Use when.** A review that needs separation between *what
exists* (objective description) and *what to think of it*
(honest assessment).

**Don't use when.** Pure description (Part 1 only), pure
opinion (Part 2 only), or when blending them serves the reader
better.

**Pattern.**

```markdown
# 🔍 <Title> — <target>

> **TL;DR.** <one specific sentence>

**Scope.** <files / area>

---

## Part 1 — Architectural breakdown

### <Subsystem>

<2-4 sentences. What it is. How it fits.>

```<lang>
// path:line
<minimal snippet>
```

<one-line on why this matters>

---

## Part 2 — Honest assessment

### ✅ What's working
- **<short claim>** — <one-line why>

### ⚠️ What's shaky
- **<short claim>** — <one-line why, with cite>

### 🚧 Gaps / missing pieces
- **<thing missing>** — <why it matters>

### Tradeoffs worth naming
<2-5 sentences on real tradeoffs the design makes>

---

## Bottom line

<2-4 sentences — what would you do next>
```

**Used by.** `/audit`, `/review`.

**Notes.** Horizontal rules between the parts are visual rhythm
— don't omit them. Don't put opinions in Part 1 or facts in
Part 2.

---

## 7. Decision matrix

**Use when.** Comparing 2-5 options across 3-7 criteria. Reader
needs to see them side by side.

**Don't use when.** Two options with one clear differentiator
(write a sentence), or so many criteria the table becomes
unscannable.

**Pattern.**

```markdown
| Criterion | Option A | Option B | Option C |
|---|---|---|---|
| **<criterion>** | ✓ <terse> | ⚠ <terse> | ✗ <terse> |
| **<criterion>** | <terse> | <terse> | <terse> |
| **Cost to switch later** | low | medium | high |

**Read.** <2-3 sentences synthesizing the matrix. Not "Option B
is best"; surface the tradeoff.>
```

**Used by.** `/decision`, `/brainstorm` (when options crystallize).

**Notes.** Bold the criterion column. Use ✓ / ⚠ / ✗ glyphs
sparingly — only where the value is genuinely binary-ish.
Always include a "read" paragraph below the matrix; matrices
without synthesis just push the work onto the reader.

---

## 8. Drift classification

**Use when.** Reconciling two states — local vs upstream, kit vs
project, plan vs reality. Each item falls into a category that
implies an action.

**Don't use when.** Simple diff display (use a `diff` block) or
when categories aren't actionable.

**Pattern.**

```markdown
## ⬇️ Updates available *(safe pulls)*
- `<path>` — <one-line>

## ⚠️ Conflicts *(both changed)*
- `<path>` — <one-line>

## 🛡 Local overrides *(no action needed)*
- `<path>` — <one-line>

## ➕ New
- `<path>` — <one-line>

## ➖ Removed
- `<path>` — <one-line>
```

**Used by.** `/sync`, `/contribute`, `/schema-check`.

**Notes.** Each category gets its own emoji from the
established vocabulary (⬇️ ⚠️ 🛡 ➕ ➖). The category header
implies the action. Sections with zero items render as "*(none)*"
or are omitted — never stubbed.

---

## 9. Pull-quote rule of thumb

**Use when.** A skill produces one durable lesson worth
remembering. The reader will skim back to find it months later.

**Don't use when.** The content is procedural (use a list) or
the rule isn't a single sentence.

**Pattern.**

```markdown
<surrounding context paragraph>

> **Rule of thumb:** <one sentence — universal phrasing,
> applicable beyond this specific instance>

<continuation if any>
```

**Used by.** `/regret`, `/codify`, `/postmortem` (where a
takeaway crystallizes).

**Notes.** Block-quote with bold "Rule of thumb:" prefix. One
sentence — if it needs two, split into two rules. Phrase it so
a different person in a different project can apply it.

---

## 10. Branching options menu

**Use when.** Consent gate where the user must pick a path.
2-5 distinct choices, each leading to different behavior.

**Don't use when.** Open-ended input ("describe X"), confirmable
single action ("apply? yes/no"), or so many choices that a
menu becomes a wall.

**Pattern.**

```markdown
**<Question>**

1. **<Option>** — <one-line consequence>
2. **<Option>** — <one-line consequence>
3. **<Option>** — <one-line consequence>

*(Pick a number, or type your own response.)*
```

**Used by.** `/sync` (per-file conflict resolution), `/wrangle`
(Phase 2 plan items), `/contribute` (per-edit classification).

**Notes.** Bold the option name; consequence in plain. Add the
"or type your own" escape so the user isn't railroaded. Don't
use a table — vertical list scans faster for action choices.

---

## When NOT to use any catalog style

- **The data shape doesn't match.** Forcing a tree onto a flat
  list, or a dashboard onto a single value, makes the output
  worse.
- **Plain markdown serves better.** A two-sentence answer
  doesn't need a style.
- **Conversational responses.** Most chat replies are prose, not
  structured artifacts. Reserve catalog styles for skill
  outputs and structured reports.

---

## Adding to the catalog

The catalog grows when a pattern proves useful across multiple
skills. Process:

1. A pattern emerges in 2+ skills' outputs.
2. Distill it: name, when-to-use, when-not-to-use, ASCII
   pattern, used-by list.
3. Add an entry to this file via a `/contribute` PR.
4. Update the index table.
5. Existing skills that already render the pattern can cite it
   by name in their next edit; no mass-migration needed.

A pattern used by exactly one skill is **not** catalog material.
It lives in that skill's "Output structure" section. Two-skill
threshold protects the catalog from premature standardization.
