# Campaign slowdown — 2026-10-25

## Disposition

**IMPLEMENTED and packaged locally:** repeated Store rebuilds, finance replay and checkpoint revalidation are reduced without changing game outcomes. **Remaining:** synchronous large-save publication still produces a measurable late-game hitch; this pass does not claim constant-time saves or eliminate all campaign growth. No player saves, previous packages or `.codex-godot-temp` were modified.

- [Performance ZIP](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.03 - Performance.zip>)
- [Performance EXE](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.03 - Performance/Patch Notes v0.03 - Performance.exe>)
- [Artifact hashes and package verification](package.json)

## Source and cause

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, with substantial inherited uncommitted changes. HEAD alone does not describe the tested build. [Final input hashes](final-source.json), [clean build inputs/overrides](build-manifest.json), [original four-file hashes](before-source.json), and the preserved [original checkpoint adapter](studio-checkpoint-before.txt) pin the local revisions.

Final editor identity: `a866e98020c0018f943ce8b98bbbd564b83d4ecd356bc6a4fd5cf66b0c483fa7`. Original compiled v0.03 identity: `a458650917031ee5dddd23c8a5b7c79986254f731f03a0113ddab4377aab0435`. Performance package identity: `617a97c83aabe2bba6613a8b4e5bddca7f1b9c4a974b8efb06e3595ad7334c94`.

Growing finance histories were reconstructed repeatedly for every Store quote. Multiple synchronous signals rebuilt the same map, including while hidden. Studio publication repeatedly validated/hydrated the same player/rivals, hashed executable inputs and historical revisions, and reparsed identical JSON generations. The actual Studio scene mount remained about 3–7ms in the measured route; the surrounding save dominated the release delay.

## Runtime files changed in this pass

| File under `patch-notes/scripts/` | Change |
| --- | --- |
| `finance/studio_finance_ledger.gd` | Reuse only successful exact Variant-byte validation proofs; maximum9 entries and4MiB serialized keys, locked accounting, full original replay on miss/oversize. |
| `ui/feature_store.gd` | Coalesce transaction signals into one deferred visible refresh; reopening and explicit transaction/UI refreshes remain immediate. |
| `persistence/studio_checkpoint.gd` | Current DTOs skip historical revision hashes; successful current-state proofs are bounded to27 entries/8MiB serialized keys. Sequence, validator identity, live content hashes and active-rival boundary remain checked. |
| `persistence/studio_checkpoint_store.gd` | Publication-local exact typed proofs avoid duplicate semantic work. Three-entry/8MiB serialized parse cache matches complete envelope bytes/context and returns detached copies. Trusted serializer proofs require the original strict UTF-8/type/depth/node limits. Disk reads, generation checks, checksum authority, corruption recovery and atomic publication remain. |
| `persistence/checkpoint_coordinator.gd` | Hydrate validates once; reuse only the freshly captured live source identity within synchronous publication. Cold loads calculate their own identity. |
| `market/rival_world_checkpoint.gd` | Avoid duplicate source hashing; accept the two named pre-fix editor/compiled sources with unchanged strict rules/data/field checks. Unknown sources still reject. |

Cache byte limits describe serialized content, not total allocator memory. They are not revision counters or hash-only acceptance. Invalid states are never cached. Persistent journal/rival history is not truncated. The Studio-only Continue boundary, RNG, card scoring, costs, Bank servicing and AI policy remain unchanged. Build-only compatibility admits the exact tested editor identity; reverse compatibility from this new EXE into older executables/editor revisions is not promised.

## Measurements

Same fixed seed/recipe/policy and72 campaign commands produce four player releases, followed by native productive calendar actions through cycle96 with the actual two active rivals. Extra$100,000 is an **explicit solvency fixture**, not a legal economy/balance claim. Each run uses private settings, checkpoint paths and leases. Old/new compiled mechanics are loaded from their actual embedded packs using the same Godot host/harness. This controls the host, but is not stopwatch evidence from a person's running EXE, a repeated statistical distribution or a hardware guarantee.

| Operation | Original compiled v0.03 | Performance compiled package |
| --- | ---: | ---: |
| Game2 queue, including deferred work | 2076ms | 337ms |
| Game2 Research, including deferred work | 2284ms | 382ms |
| Game4 Studio save, cycle29 | 2819ms | 470ms |
| Studio save, cycle96 | 13540ms | 2130ms |

[Old actual-pack run](long-v003.command.json) · [new actual-pack run](compiled-performance96.command.json). Final editor run measured464/515ms Game2 queue/Research and2351ms cycle96 save: [receipt](long-final.command.json). Independent Store microprofile at96 cycles changed364→51ms refresh,182→26ms quotes and12.8→0.96ms repeated ledger validation: [before](baseline-v2.profile.json), [after](profile-complete.profile.json). Timings vary with host load.

## Verification

- **PASS:** [197 focused assertions](bounded-final.result.json), including nested same-length corruption, equal-value type corruption, independent Studios, eviction, hidden/visible refresh behavior, current/legacy revision dispatch, generation normalization, active-rival/validator separation, changed readback with recomputed checksum, numeric JSON/type erasure rejection, parser depth/node budgets, Unicode/escape roundtrips, detached cached payloads and same-size external replacement. Original independent finance implementation is preserved in `scripts/debug/fixtures/finance_before_campaign_latency.gd`.
- **PASS:** [18 maintained suites](focused-suite-v3.json), serial with isolated profiles/leases, cover checkpoint codec/store/runtime/RNG, Research/Store/navigation, finance/Bank, simulation efficiency, launch/release and QA transactions. These are the final-source focused set, not the whole project release gate.
- **PASS:** [36 fresh-process restore assertions](restore-complete.result.json), including genuine prior editor and original compiled v0.03 saves through cycle96, exact next player/rival outcomes/RNG against the old executable, unknown-source rejection and corrupt rival finance rejection.
- **PASS:** [complete state comparison](exact-parity-final.json): original compiled v0.03, final editor and performance package match every player/session/world field through cycle96, excluding only executable source identity.
- **PASS:** [native Research UI](native-research-complete.command.json),1152×648 and1280×720, passive browsing, confirmation, queue/control bounds and real research completion.
- **PASS:** official matching templates/hash, clean import/export,416-entry package contents/checksums, six embedded PE icon sizes, actual native/headless EXE startup, four-release embedded comparison, old/current saves, [cold restore of new EXE's own96-cycle world](self-cold-package.json), ZIP CRC/hash and unchanged original v0.03 EXE/ZIP hashes. [Package receipt](package.json).
- **PASS:** static review of validation/publication/source and parser proof paths; no actionable finding. Reviewer ran no engine tests and edited no files. This is supplementary review, not independent dynamic evidence.

Earlier red checks, intermediate profiles and failures remain in this folder. First regression exposed5 failures; current-schema dispatch exposed3; publication reuse exposed2; whole-state reuse exposed1 before correction. Early harness attempts also exposed cleanup/tuple/profile-path errors; their retained failures are not final passing receipts. Existing six-ObjectDB cleanup warnings remain in several diagnostic/maintained runs; error-marker checks and final exit codes are clean. Plain `git diff --check` treats repository CRLF as whitespace; the CRLF-aware check passes. No blanket warning-free claim.

## Remaining scope

Large synchronous JSON publication still grows with saved history: the2130ms cycle96 observation is explicitly retained. If a later pass targets that hitch, profile serialization/disk publication and assess an immutable snapshot/background writer while preserving single-writer ownership, exact readback, atomic recovery and Studio-only Continue. Do not silently move publication off-thread or stop validating cold saves in this patch. Larger populations, much longer histories, clean-machine/human timing, audible/device and final balance/release acceptance are NOT established. Normal Employees exposure and private Crown research keep their existing gates. No unrelated TODO implementation, commit, push or Drive synchronization was performed in this performance pass.
