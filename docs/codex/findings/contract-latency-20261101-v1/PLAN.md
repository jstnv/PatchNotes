# Contract action latency implementation plan

> Execute inline using the executing-plans workflow. Preserve all shared edits and temp directories; no commit/push/export in this repair.

**Goal:** Make nondeparting Contract Search responsive during an outstanding Studio save and reduce repeated typed decoding without changing rules or weakening validation.

**Architecture:** Separate the existing durable departure guard from a Studio-only mutation guard. Background Studio mutations may coalesce; accepting/beginning work and quitting still wait for the latest durable Studio state. Retain a detached decoded DTO only within the existing successful semantic predicate proof, with exact payload/data/loaded-script identity and shared count/byte bounds. Discard obsolete preparation only before an atomic publication transition. Misses, failures and legacy migration remain fully validated.

**Tech stack:** Existing Godot4.7.1/GDScript RunState, CheckpointCoordinator, Studio UI, typed checkpoint codec.

**Spec:** User contract lag report2026-11-01; design/publishers-contracts.md and design/release-engineering.md. No-input authorization persists.

## Evidence and constraints

- Real48-cycle/eight-rival Gameplay: acceptance34/37ms when already saved; Contract hands174–205ms with zero active-contract writes; return/search writes cause5.09/5.52/5.34s waits. Every measured write runs off the main thread. Preserve these failures/measurements.
- Search explicitly invokes the departure guard and its UI awaits outstanding writes despite remaining in Studio. Entry must still preserve its durable-before-departure guarantee.
- Preserve exact finance/history/RNG, monthly settlement, Contract rewards and exhaustion, old saves, safe failure/Retry and Studio-only Continue. No balance/catalog changes.
- No arbitrary mutable RunState/RNG/Node objects may enter caches. Decoder proofs concern types only; they cannot waive semantic validity.

## Steps

- [x] RED/GREEN Search Studio guard, durable acceptance, outside-Studio/legacy callback rejection.
- [x] Studio mutation callable binding/detachment and Search UI correction.
- [x] RED/GREEN exact typed decoded DTO, mutation isolation and later semantic rejection; discarded the separate schema-key cache.
- [x] Existing successful proof retains detached native data under27/count and32MiB total bounds; codec preflight and fail-fast RED/GREEN.
- [x] Legal ordinary/rapid48/96-cycle flows, complete player/world/RNG comparison and exact pre-repair source admission with cold/negative checks.
- [x] Failure/Retry/replacement/teardown and windowed flow, independent code review; refreshed relevant maintained checks. Broader historical extraction/commission fixture failures are retained OPEN.
- [ ] Larger-world full-save latency: native repeat still requires about7s for immediate Accept. No zero-lag or export acceptance claim. See README and dated log.

## Review focus

Rapid return→Search→Accept; a failed/in-flight save and newer revision; out-of-Studio calls; stale quote/engine selection; tampered/history/RNG data; mutable cached return; legacy fields and wrong codec/schema context. Any changed protected data must miss or fail normally; no active Contract checkpoint may be published.

Ruling: retain the existing semantic-positive predicate as the only decoder reuse authority instead of an independent schema/type cache. The standalone trial was slower (24.8ms versus13.1ms raw decoding) because its schema construction/key cost dominated; it is archived and removed. The existing positive proof has already completed strict decoding and all semantics, so retain its detached native result under the same predicate identity/bounds. A miss still fully decodes/validates. No separate weak trust context or schema-generating lookup.
