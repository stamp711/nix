# Mental-model doc template

Skeleton for `<subsystem>/docs/mental-model.md`. Adapt section names to the system;
keep the order and the IDs. Micro-examples below are form hints, not content.

Writing rules (apply to every section except the appendix):

- Normative voice: "X must", "only Y writes Z" — not "currently, X does".
- Name symbols (`TaskMgr`, `commit()`, `journal/`), never `file:line` — line refs go stale;
  readers use symbol search. `file:line` belongs only in the dated findings appendix.
- State absence invariants explicitly ("the coordinator never writes worker-owned state") —
  absences cannot be discovered by reading code.
- Only slow-changing facts. If it changes monthly, it belongs in code comments, not here.
- Every claim a reviewer might check should be checkable: name the mechanism and the symbol.

---

````markdown
# <subsystem>: mental model

Scope: <what code this covers, what it deliberately excludes, date of last full review>.

One-sentence summary:

> <Drive A toward B via C, such that D.>

Compact invariant statement (the error kernel, quotable in one breath):

> <One owner per X; nothing lost after ack; every effect replayable or provably done; ...>

## 1. State planes, one authority each

<A table or ASCII diagram of the distinct state stores/planes. Typical planes:
DESIRED (intent), COMMITTED/PUBLISHED (what consumers see), ACTUAL (what executors hold),
EXECUTION (in-flight work). Rename to fit; the rule is invariant:>

**Every datum has exactly one authority.** Per plane, state:

- what lives there (and the authoritative store/symbol)
- who may write it, under what gate
- who reads it, and how stale those reads may be
- explicit absences ("<actor> never writes <plane>")

## 2. Actors and cadences

| Actor         | Trigger / cadence | Reads | Writes | Gate                         |
| ------------- | ----------------- | ----- | ------ | ---------------------------- |
| <api handler> | on request        | ...   | ...    | <leader check / lock / none> |
| <worker loop> | queue-driven      | ...   | ...    | ...                          |
| <sweeper>     | every <N>s        | ...   | ...    | ...                          |

Observation-lag chain — how stale a decision can be, end to end:

```
<source truth> --(<=Xs)--> <cache/heartbeat> --(<=Ys)--> <decision site>
```

State the consequence: "<actor> decisions run against state up to ~Zs stale; every
wait/poll flow must reason against this."

## 3. The unit of work

<The atom the system processes: task / batch / txn / lease. Its lifecycle states,
which transitions are persisted vs memory-only, and where the persistence points are.
One diagram or list: state -> state (persisted at <symbol>).>

## 4. Invariants

<Always-true statements only. Conditionally-true properties (pre/post of a step) belong
inside the flow that owns them. Number I1..In, stable forever; never renumber.>

### I<n>. <short name, e.g. "Single writer per table">

- **Statement**: <one sentence, plain English; or pre → action → post for tricky ones>
- **Scope**: <which planes/actors/data it constrains>
- **Enforced at**: <mechanism + symbol: "lease check in `Claim()`", "CAS on epoch",
  "persist-first ordering in `PersistLocked`">
- **Checked by**: <test / assert / fuzz / review-only — be honest if review-only>
- **Error kernel**: yes|no — yes means violation = loss, corruption, or stuck-forever.
- <Absence invariants get the same treatment: "Statement: nothing in <layer> depends
  on <layer>.">

## 5. Logic flows

<The named protocols the system executes. Number F1..Fn. Each flow cross-references the
invariants it relies on and the ones it exists to uphold ("F4 is the model citizen of I3").>

### F<n>: <name> (<trigger>)

- **Steps**: numbered; per step note the pre/post condition when it matters and the
  persistence point if any.
- **Crash/restart**: what happens if the actor dies after each persistence point —
  resumed, replayed, or abandoned-and-safe (say which, and why).
- **Concurrency**: which other flows can interleave with this one, and why each
  interleaving is safe (which invariant makes it safe).

## 6. Constants the flows reason with

| Constant    | Value | Defined at      | Used by          |
| ----------- | ----- | --------------- | ---------------- |
| <lease TTL> | <30s> | <config symbol> | F4 recovery wait |

<Every value sourced from code/config or from the user — never invented. These are the
operational facts a reviewer (or an LLM) cannot know without being told.>

## 7. Enforcement summary

<The registry, one row per invariant — the review checklist in table form.>

| Inv | Mechanism       | Where (symbol) | Checked by   |
| --- | --------------- | -------------- | ------------ |
| I1  | <lease + epoch> | <`Claim()`>    | <proptest X> |

## Appendix: findings (<date>)

<Deviations between model and implementation found in review. file:line allowed here.
Tag: H = error-kernel invariant violated (reachable loss/corruption/stuck-forever);
M = wrong-but-recoverable state; P = protocol-level weakness (holds today, breaks under
allowed perturbation: retry, crash timing, scale); L = doc/model mismatch or hygiene.
Mark fixed items with date; never delete history.>

- **H1** <one-line claim> — violates I<x> at <file:line>: <evidence>. <suggested direction.>
````
