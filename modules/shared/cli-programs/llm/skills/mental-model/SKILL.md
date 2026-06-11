---
name: mental-model
description: >
  Construct, review against, and maintain an invariants-and-logic-flows mental model of a
  concurrent/distributed subsystem (control planes, schedulers, storage protocols, replication,
  multi-actor state). Use when the user says "mental model", "invariants and logic flows",
  "what's the core invariant", "review against the model", asks to deeply review concurrent or
  multi-actor code, or when a mental-model.md exists near code being reviewed. Not for CRUD,
  UI, prototypes, or single-threaded glue code.
---

# Mental model: invariants and logic flows

The model is the alignment artifact: a shared statement of what, platonically, the system
must do. Code review anchored on it catches bugs that are locally correct everywhere but
globally incorrect — interaction bugs per-file review cannot see. Findings are defined as
deviations from named invariants, never as free-floating observations.

The model is **normative, not descriptive**. It states what must hold, not what the code
happens to do. When code and model disagree, that is either a finding or a model bug —
ask the user which, never silently bend the model to match the code.

## The artifact

One markdown doc per subsystem, living next to the code: `<subsystem>/docs/mental-model.md`
(follow the repo's existing docs convention if one exists). Structure defined in
`references/template.md`; compact example in `references/example.md` (imitate its form,
not its content).

Before doing anything, check whether a model doc already exists for the scope
(glob for `**/mental-model*.md`, `**/docs/*model*.md`).

## When NOT to use

The full treatment costs real effort (prior art reports 2–3x). Decline (and say so) when:
error cost is low, the code is straight-line CRUD/glue, or the system has one actor and no
shared state. A subsystem qualifies when it has ≥2 concurrent actors, persistent state with
multiple writers, crash/restart semantics, or cross-feature interactions.

## Modes

Dispatch on the argument: `build <scope>`, `review [scope|diff]`, `sync [scope]`.
Bare invocation: if a model doc covers the scope and there are pending changes → `review`;
if a doc exists but code moved on → `sync`; otherwise → `build`.

### build <scope>

1. **Scope gate.** Briefly read the code first (entry points, state stores, threads/actors),
   then STOP and discuss with the user what should be modeled — boundaries, what to exclude,
   which parts worry them. Do not commit to the full pass before this conversation.
2. **Socratic extraction.** Construct the model in dialogue, not in one shot. Per round,
   focus on one problem and ask numbered questions (the user answers by number). Never guess
   what you can ask: workload shape, scale constants, cadences, which effects must never
   happen, what is allowed to be weird ("readers may see stale X — acceptable?").
   For every moving part extract:
   - who is the single authority for this datum?
   - what cadence does it act on, and how stale are its reads?
   - what must never happen (including absence invariants: "X never writes Y")?
   - what happens at crash/restart at each step?
3. **Draft early, iterate in the file.** Create the md from `references/template.md` as soon
   as the planes/actors are roughly known; keep refining it in place. Chat is for
   negotiation; the file is the deliverable.
4. **Confront mismatches.** Where the code contradicts the emerging model, present the
   contradiction and ask: deviation (record as finding in the appendix) or model wrong
   (fix the model)? This is the alignment moment — never skip it.
5. **Persist.** Final location per the repo's docs convention. Optionally (ask first) add
   anchor comments at enforcement points of error-kernel invariants only — one line,
   `// MM:I3 <short clause>` — so `sync` can grep code↔doc. Keep these rare; they are
   load-bearing markers, not documentation.

### review [scope|diff]

1. Require the model doc. If missing, offer `build` first; a review without a model is just
   ordinary code review — say so and fall back gracefully.
2. Align first: read the model doc fully before reading any diff. The invariants are the
   review checklist; the flows are the walk order.
3. Follow `references/review-protocol.md` exactly: freshness pass → per-invariant sweep →
   per-flow ladder (happy path → crash/restart → interleavings) → generic failure-mode
   probes → adversarially verified findings.
4. Findings reference invariant/flow IDs, carry severity tags, and get appended to the
   model doc's dated findings appendix. Also report what was checked and found clean.
5. At high effort, fan out verification subagents per finding (refute-attempt framing);
   keep the main loop as the synthesizer.

### sync [scope]

Run after changes touch modeled code, or when the user doubts the doc.

1. Grep anchor tags (`MM:`) and the symbols named in the doc; diff each durable claim
   against current code.
2. Durable sections change only when the _design_ changed — confirm with the user before
   rewriting an invariant (a changed invariant is a design decision, not an edit).
3. Stale findings in the appendix: mark fixed/obsolete with date, don't delete.
4. Flag staleness in _other_ docs encountered along the way (design docs that contradict
   the code) — report, don't fix unasked.

## Conventions

- IDs: invariants `I1..In`, flows `F1..Fn`, stable across doc revisions; findings
  `H1../M1../P1../L1..` per review date. Cross-reference liberally ("F4 exists to uphold I3").
- Durable sections name symbols (types, functions, files) — never `file:line`, which goes
  stale. `file:line` is allowed only in the dated findings appendix.
- Constants (sizes, QPS, TTLs, cadences) are asked or read from code/config — never invented.
  Every constant in the doc states where it comes from.
- Write tersely. No hedging, no narrative. An invariant is one sentence plus its mechanism.
- The user may interrupt and redirect at any point; treat "you are describing in an ad-hoc
  way" as the signal to drop narration and restate via invariants and flows.
