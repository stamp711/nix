# Example mental-model doc (synthetic)

A complete, compact instance for a fictional system. **Imitate the form, not the content** —
your planes, invariants, and flows come from the target system and the user, not from here.

---

# jobq: mental model

Scope: the persistent job queue and its workers (`jobq/` — `Enqueue`, `Claim`, `Complete`,
the sweeper, the checkpointer). Excludes the HTTP layer and job payload semantics.
Last full review: 2026-06-11.

One-sentence summary:

> Drain submitted jobs to exactly-one-effective completion each, surviving worker crashes,
> via durable enqueue, leased claims, and idempotent completion.

Compact invariant statement:

> A job acked to the producer is never lost; at most one worker holds a job at a time;
> a job's effect happens once no matter how many times it runs; the queue's order is
> advisory, its durability is not.

## 1. State planes, one authority each

| Plane                       | Lives in                   | Written by                           | Read by (staleness)         |
| --------------------------- | -------------------------- | ------------------------------------ | --------------------------- |
| DESIRED — submitted jobs    | WAL segment files (`wal/`) | `Enqueue` only                       | recovery scan (cold)        |
| COMMITTED — claimable set   | index (`QueueIndex`)       | `Enqueue` (add), `Complete` (remove) | workers (fresh, in-process) |
| ACTUAL — in-flight claims   | lease table (`LeaseTable`) | `Claim`/`Complete`/sweeper           | sweeper (≤1 poll behind)    |
| EXECUTION — worker progress | worker memory only         | the owning worker                    | nobody                      |

- `Enqueue` never touches `LeaseTable`; the sweeper never touches `wal/` (absences).
- Worker progress is deliberately unobservable: recovery is re-run, not resume (see I3).

## 2. Actors and cadences

| Actor        | Trigger / cadence | Reads      | Writes                  | Gate                 |
| ------------ | ----------------- | ---------- | ----------------------- | -------------------- |
| Producer API | on request        | —          | WAL, QueueIndex         | fsync before ack     |
| Worker (×N)  | poll, 100ms       | QueueIndex | LeaseTable              | lease CAS            |
| Sweeper      | every 5s          | LeaseTable | QueueIndex (requeue)    | lease expiry only    |
| Checkpointer | every 60s         | QueueIndex | snapshot + WAL truncate | snapshot fsync first |

Observation-lag chain:

```
worker death --(<=lease TTL 30s)--> sweeper requeue --(<=100ms)--> another worker claims
```

A dead worker's job is invisible for up to ~35s; nothing else in the system may assume
faster takeover.

## 3. The unit of work

A job: `submitted -> claimed -> done` (plus `claimed -> submitted` on lease expiry).
Persisted transitions: `submitted` (WAL append + fsync, in `Enqueue`), `done`
(tombstone append, in `Complete`). `claimed` is memory-only by design — crash = silent
unclaim after TTL.

## 4. Invariants

### I1. Durable before ack

- **Statement**: `Enqueue` returns success only after the job record is fsync'd to the WAL.
- **Scope**: producer API ↔ DESIRED plane.
- **Enforced at**: fsync-before-reply ordering in `Enqueue` (`wal.Append` then `wal.Sync`).
- **Checked by**: crash-injection proptest `enqueue_ack_survives_kill`.
- **Error kernel**: yes — violation = acked job lost.

### I2. At most one holder per job

- **Statement**: at any instant, at most one worker's lease on a job is unexpired.
- **Scope**: ACTUAL plane; `Claim`, sweeper.
- **Enforced at**: CAS on `LeaseTable` entry (`Claim`); sweeper requeues only entries
  whose expiry < now − clock-skew bound.
- **Checked by**: model-checked interleaving test `claim_sweep_race`.
- **Error kernel**: no — double execution is tolerated by I3; this bounds waste, not safety.

### I3. Effects once, runs many

- **Statement**: a job's externally visible effect is applied exactly once even if the job
  body runs multiple times (lease expiry + original worker still alive).
- **Scope**: worker, external effect targets.
- **Enforced at**: effect dedup key = job id, checked by the effect sink (`EffectSink.Apply`).
- **Checked by**: review-only. (Honest gap — candidate for a proptest.)
- **Error kernel**: yes — violation = duplicated side effect.

### I4. Checkpoint never strands a job

- **Statement**: WAL truncation only covers jobs present in the fsync'd snapshot or
  tombstoned as done.
- **Enforced at**: snapshot-fsync-then-truncate ordering in `Checkpointer.Run`.
- **Checked by**: recovery proptest `restart_after_each_step`.
- **Error kernel**: yes.

## 5. Logic flows

### F1: Enqueue (producer request)

- **Steps**: 1. append to WAL (pre: payload validated) → 2. fsync [persistence point] → 3. insert QueueIndex → 4. ack. Post: job claimable.
- **Crash/restart**: die after 2 → recovery scan re-inserts to index (replay safe: insert
  idempotent by job id). Die after 1 → job not acked, may or may not survive; either is
  correct (producer retries; dedup by I3's key).
- **Concurrency**: concurrent enqueues independent (per-job records); interleaves with
  checkpointer via I4's ordering.

### F2: Claim + execute (worker; upholds I2, leans on I3)

- **Steps**: 1. pick from QueueIndex → 2. CAS lease (pre: no live lease) → 3. run body → 4. `Complete`: tombstone + fsync [persistence point] → 5. remove from index, drop lease.
- **Crash/restart**: die in 3 → lease expires, F3 requeues; effect dedup makes the re-run
  safe (I3). Die between 4 and 5 → recovery sees tombstone, treats job done (index rebuild
  drops it); lease expires harmlessly.
- **Concurrency**: with F3 on the same job — safe iff sweeper honors expiry bound (I2);
  with another F2 instance — CAS loses, picks next.

### F3: Sweep (lease expiry recovery; the model citizen of I2)

- **Steps**: scan LeaseTable → for each expired lease: requeue to index, delete lease.
- **Crash/restart**: idempotent scan; partial sweep just delays takeover ≤ one cadence.
- **Concurrency**: with `Complete` racing requeue — tombstone wins on recovery; transient
  double-presence in index is filtered at claim time (lease CAS re-checks done-tombstone).

### F4: Restart recovery

- **Steps**: load snapshot → replay WAL tail → rebuild QueueIndex (skip tombstoned) →
  start actors. Leases start empty: every previously claimed job re-runs (I3 absorbs this).

## 6. Constants the flows reason with

| Constant           | Value | Defined at               | Used by                    |
| ------------------ | ----- | ------------------------ | -------------------------- |
| lease TTL          | 30s   | `config.LeaseTTL`        | F3 expiry; lag chain bound |
| sweep cadence      | 5s    | `config.SweepEvery`      | takeover latency           |
| clock-skew bound   | 2s    | `config.SkewBound`       | I2 sweeper margin          |
| checkpoint cadence | 60s   | `config.CheckpointEvery` | F1×I4 interaction window   |

## 7. Enforcement summary

| Inv | Mechanism                 | Where (symbol)         | Checked by  |
| --- | ------------------------- | ---------------------- | ----------- |
| I1  | fsync-before-reply        | `Enqueue`              | proptest    |
| I2  | lease CAS + expiry margin | `Claim`, `Sweeper.Run` | model check |
| I3  | effect dedup by job id    | `EffectSink.Apply`     | review-only |
| I4  | snapshot-then-truncate    | `Checkpointer.Run`     | proptest    |

## Appendix: findings (2026-06-11)

- **H1** Requeue/Complete race can resurrect a done job after restart — breaks F3
  concurrency claim: tombstone check at claim time reads the index, not the WAL
  (`claim.go:88`); a crash between requeue and tombstone-filter leaves the job claimable
  again. Sequence: expire → requeue → complete lands → crash → rebuild. Direction: filter
  tombstones during index rebuild, not at claim.
- **P1** I3 is review-only while being error-kernel — no test pins the dedup key's
  stability across retries. Direction: proptest with forced double-run.
