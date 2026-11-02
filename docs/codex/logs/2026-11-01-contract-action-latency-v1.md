# Contract action / autosave repair — 2026-11-01

User report: Contract acceptance, Search and preparation feel slow around Studio autosaves. Proceeded without routine questions, using headless reproduction first and isolated windowed runs afterwards.

Branch `main`, HEAD `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`. Shared checkout was heavily dirty; preserved earlier Engine/Awards/other edits and both `.codex-godot-temp` directories. No commit, push, EXE/ZIP rebuild or publication.

## Implementation

- `patch-notes/scripts/run_state.gd`: new nonpersisted Studio-action guard; Search uses it, with the existing custom departure hook as fallback; detached release probes clear it.
- `patch-notes/scripts/phases/studio_phase.gd`: Search no longer awaits departure saving; existing quote/transaction checks remain. Accept still awaits latest durability and rechecks offer/engine selection.
- `patch-notes/scripts/persistence/checkpoint_coordinator.gd`: bind/clear Studio guard, reject outside Studio/failure, defer background entry snapshot to batch same-frame changes; newer revisions can supersede preparation, with unchanged durable receipts and replacement intent.
- `patch-notes/scripts/persistence/checkpoint_write.gd`: mutex-protected supersede/publication transition; encoding failures still surface, started publications finish. LOW worker priority retained.
- `patch-notes/scripts/persistence/studio_checkpoint.gd`: existing exact positive semantic proofs retain detached native DTOs; strict generation/mode/data/adapter-chain/codec/schema identity, deep return copies,27-entry/32MiB shared accounting, full miss/legacy/failure paths.
- `patch-notes/scripts/persistence/checkpoint_codec.gd`: fail early during recursion, preflight closed-record keys before expensive older union alternatives; strict original JSON parser retained.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: admit only genuine exact pre-repair6b3 source, with modern annual/Pass Budget/raw frozen-engine guards.
- `patch-notes/scripts/debug/verify_background_checkpoint.gd`: explicitly starts obsolete preparation and expects only the newest durable generation; recovery/teardown checks remain.
- Updated scoped design/state/TODO records and findings. Other queued implementation was not taken over.

No prices, rewards, calendar rules, cards, finance/history/RNG semantics or save schema changed. Contract hands remain outside the Studio-only Continue boundary.

## Evidence

All commands, source manifests, retained failures, fixtures and scoped patch are in [contract-latency-20261101-v1](../findings/contract-latency-20261101-v1/README.md). Runner example:

```text
python docs/codex/findings/contract-latency-20261101-v1/run.py --script <absolute findings script or res:// verifier> --fixture <genuine paired fixture> --output <new directory> --fence --timeout 180
```

Use `--native` for windowed acceptance. New private profiles use the permitted local visualization root outside OneDrive, and record their exact path. The default sandbox temp location rejected nested profile writes; continued using that already permitted local root without an escalation request. Earlier synchronized profiles and their timing variability are retained, not treated as a causal performance experiment.

Final runtime `b496434dc8095aefd67d498de3f9f98c2992abaa5d531bbd36ff7017ec9a2547`; pre-repair runtime `6b3fa06073593241c439c080903dcada00360f952fe2b084ff591656080d6563`.

Matched48-cycle real Gameplay route, legal introductory Contract→Search→cash Contract: Search5,276→169ms; immediate Accept5,205→4,501ms; combined10,481→4,670ms. Returns59/75→10/9ms synchronous; publications4→3; zero active-Contract writes. **Entire player matches; entire rival world matches except executing-source stamp**, including finance/history/engine/RNG (`state-comparison.json`).

Unmodified final windowed96-cycle route: Search214ms, immediate Accept7,041ms, return about10ms, Contract hand CPU calls about0.2–0.25s; all publications off main thread. Earlier native waits23–26s were accompanied by slower actions before interventions. Priority, rendering visibility, processing suspension and frame caps were not established as causes and were not adopted.

## Checks and review

Final common-source cases: five maintained suites (checkpoint Codec, Store, runtime recovery, Studio checkpoint and background checkpoint) and focused Search13, Codec16, decoded DTO85, compatibility11 and coalescing/replacement38 checks PASS. Source fences unchanged. Earlier maintained RNG, Contract definitions and Contract challenge runtime also PASS at their recorded source.

The original aggregate is retained with its timing failure: prebuilt-schema raw decode7.84ms versus warm5.93ms narrowly missed the75% bound after Codec preflight accelerated raw decoding. Corrected benchmark compares the complete uncached operation, including schema construction, with the same threshold and all85 checks:17.10→5.79ms PASS. No production code or validation assertion was weakened. `final-reviewed-results.json` points to both original and corrected receipts.

Coverage includes exact typed values, nested RNG mutation isolation, active-rival/subclass contexts, int64 generation, proof eviction/bytes, bad shapes and semantic finance changes; genuine6b3 cold restoration and missing annual/budget/engine/RNG/calendar rejection; early cancellation versus started publication, paused completion, failure/Retry, teardown, outside-Studio denial, different-run replacement cancellation/failure/Retry/Continue. Independent read-only reviews identified no Critical/Important defect; requested replacement coverage was added and passed.

Scoped diff whitespace check PASS with `git -c core.whitespace=cr-at-eol diff --check -- <eight owned source/verifier paths>`; the default check flags existing Windows CR-at-EOL lines and is retained separately in tool output. No global formatting conversion.

## Retained failures and remaining work

- Larger-world full validation/publication still takes seconds: native immediate Accept7.04s remains **OPEN**, not zero-lag or whole-release acceptance.
- Historical `verify_contract_extraction` constructs invalid Engine state; the exact preceding anonymous adapter rejects the same state for the same reason. Historical `verify_contract_search` crashes during obsolete30-Scope research setup reading `can_admit` from an empty quote, with retired Audio IDs. Neither is counted as a pass; modernize these fixtures through current Engine/Feature APIs separately.
- Rejected standalone schema-key cache was slower; rejected parser/string caches gave inadequate performance benefit. Original REDs, setup accessor/map/script errors and discarded experiments remain in separate run folders. Final strict parser and LOW priority are preserved.
- Artwork/ObjectDB warnings, native host variability, longer careers, device/audio and exported-package acceptance remain separate. Existing EXE/ZIP has not received these source changes.
