# Distilled borrowings → skill components

What each source contributes to the skill. (Bilingual output dropped — not core value.)

## Into `references/template.md` (doc skeleton)

- **Trail of Bits — invariant registry row**: `ID | statement | scope/components | enforced-at | checked-by`.
  Statement in plain English; Hoare triple (pre → action → post) for tricky ones.
  `enforced-at` = the mechanism (lock, CAS, persist-first ordering, epoch check) — our extension of
  their "testing strategy" column; matches lgstore doc's "enforcement summary".
- **matklad**: durable sections name symbols (types/modules/files), never `file:line` (stale);
  explicitly state _absence_ invariants ("master never writes brokers/{id}");
  document boundaries/layers (= state planes + one-authority rules);
  bird's-eye first (= one-sentence summary + compact invariant statement);
  only slow-changing facts in durable sections.
- **Hillel Wayne**: separate always-true invariants (I*) from conditionally-true properties —
  conditional pre/post conditions live inside flow (F*) steps, not in the invariant list.
- **G-Research/LLM-review**: "Constants the flows reason with" is mandatory and comes from
  _asking the user_ (sizes, QPS, cadences) — never guessed.
- **Sridharan**: mark error-kernel invariants (violation = loss/corruption) vs degraded-only.
  Build mode must extract implicit assumptions from the user.

## Into `references/review-protocol.md`

- **ShardStore — verification ladder**: per-invariant check = enumerate _all_
  writers/transitions that could violate it, not just what the diff touched; each property
  checked by the best-fit method. Review-ordering rungs:
  1. happy-path conformance: walk each flow F\* against code step-by-step;
  2. crash/restart executions: what persists, what resumes, takeover;
  3. concurrent interleavings.
- **Kislay Verma — failure-mode probes** (generic pass after the model-anchored pass):
  timeouts on every remote call; timeout = indeterminate state needing explicit resolution
  (pairs with "every effect is replayable or provably done"); all APIs idempotent;
  no remote calls inside transactions; explicit recovery path for interrupted operations.
- **Hillel Wayne — purpose statement**: this protocol targets "locally correct everywhere but
  globally incorrect" bugs (feature interactions); per-file review handles the local ones.
- Findings = deviations from named invariants/flows, severity-tagged (H/M/P/L),
  file:line evidence allowed (dated appendix only), cross-referenced into the model doc.

## Into `SKILL.md` (gates, lifecycle, framing)

- **ezyang — framing**: the model is the alignment artifact ("a shared vision of what,
  platonically, the system should do"); findings are misalignments; align the LLM with
  invariants _before_ reviewing.
- **Antithesis — staleness contract**: obligations pinned as comments with review tags;
  touching the code obliges updating the obligation + re-review. Lightweight version:
  one-line anchor comments with invariant IDs at enforcement points
  (`// I3: persist before memory commit`) so sync mode can grep code↔doc.
  Honest cost (2–3x) → encode a when-NOT-to-use gate.
- **Hillel Wayne — when it pays off**: control planes, concurrency, storage protocols,
  cross-feature interactions; skip when error cost is low (CRUD, prototypes).
- **matklad vs Antithesis sync tension — resolution**: durable model sections are
  slow-changing and revisited deliberately; findings appendix is dated and may stale;
  anchor comments are the only always-sync surface.

## Ours already (differentiators; no external source)

- State planes with exactly one authority each + observation-lag chain
  ("decisions run against ≤Ns stale state").
- Actors + cadences table (who runs when, reads/writes what, gated by what).
- Named flows F\* cross-referenced to invariants ("F4 is the model citizen of I3").
- Findings-as-deviations appendix in the model doc.
- The forcing move: refuse ad-hoc narration ("what's the core invariant around the
  moving parts?").
- Scope-negotiation gate before committing an expensive review
  ("briefly read it and discuss what should be reviewed with me").
