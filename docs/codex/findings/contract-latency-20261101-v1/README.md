# Contract action / Studio autosave latency — 2026-11-01

Implementation is local. This is a bounded responsiveness repair, **not a no-lag, whole-release or EXE acceptance claim**. Seven production files and one maintained verifier changed; pre-existing Engine/Awards work and `.codex-godot-temp` were preserved. No commit, push or export.

## Source and reproduction

- Branch `main`; HEAD `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`, heavily dirty on entry.
- Genuine pre-repair runtime: `6b3fa06073593241c439c080903dcada00360f952fe2b084ff591656080d6563`.
- Final runtime: `b496434dc8095aefd67d498de3f9f98c2992abaa5d531bbd36ff7017ec9a2547`.
- Godot4.7.1 Windows, supplied eight-rival48/96-cycle fixtures from the preceding Awards acceptance. Setup completes pending presentation only through its legal APIs, then uses the actual Gameplay/Studio/Contract scenes and ordinary acceptance, Search and hand commands.
- `before-production/` preserves the exact owned production inputs. `scoped-production.patch` isolates this repair from earlier dirty work. Each run has stdout/error scan, actual command and full canonical source manifest/fence.
- `preceding-pair.json` is the genuine pre-repair cycle53 player/world after the legal two-Contract/Search route. It is the evidence for the one new exact-source compatibility admission.

## Diagnosis and change

Contract hands made **zero active-Contract save writes**. They consumed their normal productive cycles and remained outside the Studio checkpoint boundary. Return/Search starts full background saves; the following Accept waited for them. Every measured publication ran off the main thread.

Search previously awaited departure durability despite remaining in Studio. It now uses a bound Studio-only mutation guard. The guard rejects outside Studio or after failure, and preserves existing custom departure callbacks when the new hook is absent. Acceptance still waits for the latest durable state and rechecks the selected offer and engine.

Background Studio entry batches same-frame changes. A newer mutation may supersede obsolete preparation through a mutex-protected transition, before Store publication starts. Started publications finish. Superseded preparation never increments Saved, replaces durable payload/native receipts, clears a failure, or loses replacement intent. Explicit `flush`, departure and teardown still drain the latest state.

Existing successful current-format semantic proofs now retain their detached decoded DTO, under the same exact typed payload, active-rival/data/script context, with separate canonical positive generation checking. The27-entry/32MiB bounds include native bytes; callers receive deep copies. Misses, failed predicates and legacy migration still use full decoding/validation. Closed Codec records check required keys before traversing large histories; recursive encoding/decoding stops on failure, while later union alternatives remain independent.

No Contract price, reward, card rule, economy value, finance/history/RNG rule or save schema changed. The exact6b3 source is admitted with current annual-ledger, Pass Budget and raw frozen-engine requirements, before legacy defaults can fill fields.

## Measured outcomes

Matched48-cycle fixture, two legal Contracts and one Search, headless:

| Operation | Pre-repair | Final |
|---|---:|---:|
| Return after first Contract, synchronous call |59ms|10ms|
| Search |5,276ms|169ms|
| Immediately Accept found work |5,205ms|4,501ms|
| Search + immediate Accept |10,481ms|4,670ms|
| Final Contract return, synchronous call |75ms|9ms|
| Durable publications for entire route |4|3|

`state-comparison.json`: **entire player exact; entire world exact except executing-source stamp**, including finance, history, engine state and RNG. No active-Contract writes. The combined wait improves about55%; final publication is still a real durability barrier.

Unmodified windowed96-cycle flow on the final source, with private profile outside OneDrive (`native-local-profile96-v2`): Search214ms; immediate Accept7,041ms; synchronous returns9–10ms; Contract hand calls approximately0.2–0.25s. All writes remain on the worker. This proves the measured route, **not an instantaneous large-world save or a general native frame budget**.

Earlier native runs varied to approximately23–26s for Accept and also slowed actions *before* tested interventions. Hiding, capping, suspending and changing priority therefore do not establish causality. No such presentation/scheduling changes were adopted. Test profiles initially lived in the synchronized findings folder; later runs use the separately permitted local profile root, with its path retained in receipts. Sync/host load remains a confound, not a proven root cause.

## Verification and retained failures

- Focused Search guard13, Codec short-circuit/key shape16, decoded-DTO85, exact predecessor11 and coalescing/replacement38 checks pass. The latter includes early cancellation, already-started publication, pause, failure/Retry, exact latest finance/history/RNG, teardown, outside-Studio rejection and different-run replacement preservation/Retry/Continue.
- Maintained codec/RNG/Store/runtime/Studio checkpoint, Contract definitions/challenge and background-checkpoint checks pass at their recorded sources. `final-reviewed-results.json` collects the refreshed five maintained and five focused final-source cases. The original aggregate remains unchanged: its old prebuilt-schema timing comparison narrowly failed after Codec preflight sped up raw decoding (7.84ms vs5.93ms). The corrected comparison includes schema construction, matching the actual uncached operation; same75% threshold,85 checks PASS,17.10ms→5.79ms. No canonical code or validity check was changed to clear that timing result.
- Independent read-only review found no Critical/Important defect. Its requested replacement-mode coverage was added and passed.
- Original REDs and setup errors remain: Search callback failures; standalone decode cache slower than direct; legacy-guard RED; recursive/record-shape REDs; worker lifecycle RED; initial setup accessor/API mistakes; decode test argument/native-map mistakes; anonymous-script global-class conflict; temporary-profile nested-directory sandbox failure. Corrected runs have separate output directories.
- The independent schema/decode cache and string-parser/cache trials were **discarded**, not relaxed to pass their performance thresholds. Parser trials retained285 semantic comparisons but did not provide the required improvement; final parser is the original strict parser. Normal thread priority was also discarded; worker retains LOW priority.
- **Broader historical fixture failures remain OPEN:** `verify_contract_extraction` constructs an invalid Engine state; an anonymous exact preceding adapter rejects the same fixture with the same reason (`fixture-diagnosis-v2`). `verify_contract_search` reaches obsolete research setup and crashes reading `can_admit` from an empty quote, with retired Audio IDs in its old30-Scope acquisition route. That unrelated commission fixture needs current Engine/Feature setup. Neither failure is counted as a pass or a live-game regression fixed here.
- Missing artwork and exit-time ObjectDB warnings are retained. Existing EXE/ZIP, device/audio acceptance and unrestricted late-career performance are not verified by this repair.

## Remaining work

Full larger-world validation/publication still takes seconds and can gate immediate departure. Incremental provenance validation or a broader checkpoint architecture pass requires separate measured work; do not skip validation, drop history or relax the Studio-only Continue boundary to hide it. Modernize the two historical fixtures through current legal Engine/Feature APIs separately. No balance value is approved by these runs.
