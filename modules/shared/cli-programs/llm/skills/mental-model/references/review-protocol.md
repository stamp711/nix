# Review protocol: deviations from the model

Purpose: catch bugs that are locally correct everywhere but globally incorrect —
interactions between flows, actors, and crash timing that per-file review cannot see.
The model doc is the checklist; this file is the procedure.

Scope forms: a diff/branch (review the change against the model) or a subsystem
(review the implementation against the model wholesale). Passes below say when they
narrow to the diff and when they must not.

## Pass 0 — model freshness

Spot-check the doc's durable claims against current code (authorities, actors, mechanisms
in the enforcement summary). If the model is stale, stop and fix/flag it first — reviewing
against a wrong model produces confident nonsense. Cheap: grep the named symbols and `MM:`
anchors; read only what moved.

## Pass 1 — per-invariant sweep

For each invariant I\*, in ID order:

1. Enumerate **all** writers/transitions that can affect what it constrains — from the
   model's actors table, then verified against code. Never limit this enumeration to the
   diff: the diff may add the _second_ writer to something that was safe only while it
   had one.
2. For each writer: does the stated mechanism actually gate it? (The mechanism is named
   in the enforcement summary — check that specific lock/CAS/epoch/ordering, not a vibe.)
3. For error-kernel invariants, additionally ask: what is the _cheapest_ sequence of
   allowed events (crash here, retry there, stale read) that violates it?
4. Check the absence invariants by searching for the forbidden dependency/write — their
   violation never appears in a diff hunk you happen to be reading.

## Pass 2 — per-flow ladder

Walk each flow F\* (or only the flows the diff touches, plus every flow sharing a state
plane with them). Three rungs, in order — do not skip rungs:

1. **Happy path conformance.** Step through the code against the model's numbered steps.
   Per step, check its stated pre/post condition. A code path that does the right thing
   in a different order than the model is a finding (or a model bug — surface it).
2. **Crash/restart.** At each persistence point: kill the actor just before and just
   after. Does restart resume, replay, or abandon as the model claims? Replays must be
   idempotent or deduplicated — find the dedup mechanism, don't assume it.
3. **Interleavings.** Two instances of the same flow on the same unit of work; then each
   pair of flows sharing a plane. For each pair, identify the invariant that makes the
   interleaving safe. If you can't name one, that's a finding even without a concrete
   trace ("safety depends on timing, not on a stated invariant" is P-severity by itself).

## Pass 3 — generic failure-mode probes

After the model-anchored passes, run these regardless of what the model says
(they catch what the model forgot to say):

- Every remote/cross-process call has a timeout; and a timeout is treated as an
  **indeterminate outcome** (the effect may have happened), never as a clean failure.
  Look for the resolution mechanism: reconciliation, status query, replay-with-dedup.
- Every retried effect is idempotent, or deduplicated by key/sequence.
- No remote calls while holding a lock or an open transaction.
- Every operation that can be interrupted mid-way has a stated owner for completing or
  reverting it (no "someone will notice" recovery).
- Anything published in parts: consumers cannot observe the partial state, or the partial
  state is explicitly harmless (which invariant says so?).

## Pass 4 — findings

Each candidate finding:

1. **Adversarial verify before reporting.** Attempt to refute it from the code: find the
   gate/dedup/ordering you may have missed. At high effort, fan out independent skeptic
   subagents per finding (refute framing, distinct lenses: correctness / crash-timing /
   does-the-trace-actually-execute). Drop findings that don't survive.
2. Record as: `<tag><n>` + one-line claim + **violates I<x> / breaks F<y> step <s>** +
   evidence (`file:line` allowed) + the minimal event sequence that triggers it +
   suggested direction (one line, not a patch).
3. Severity tags:
   - **H** — error-kernel invariant violated; reachable loss, corruption, or stuck-forever.
   - **M** — wrong-but-recoverable state; degraded behavior with a real repair path.
   - **P** — protocol weakness: holds today, breaks under allowed perturbation
     (retry storm, crash at a new point, second instance, scale).
   - **L** — model/doc mismatch or hygiene.
4. Dedupe across passes (the same root cause often surfaces in Pass 1 and Pass 2 — one
   finding, multiple references).
5. Append to the model doc's findings appendix under today's date; report in chat as a
   table ordered H → L.

## Coverage statement

End every review by stating what was checked and found clean — per invariant and per
flow/rung ("I1–I5 swept; F1–F3 all rungs; F4 rungs 1–2 only, interleavings not walked").
Silent partial coverage reads as full coverage; never allow that.
