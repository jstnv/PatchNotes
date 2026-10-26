# Contracts definition foundation: private candidate findings v1

2026-10-17 (America/Los_Angeles). **Structural candidate verified in bounded headless checks; canonical adoption QUEUED, not implemented here.** [Approved scope](FOUNDATION-DECISION-2026-10-17-v1.md) is extensibility with unchanged current terms. [Predeclared plan](FOUNDATION-PLAN-2026-10-17-v1.md) records the hypothesis and stop conditions.

## Source and setup

- Repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree. No canonical Contracts gameplay file was edited by this thread. Private [variant](simulators/contracts-foundation-v1/variant.json) baseline identity `ab7b4324cb93c94d3a65c935b353917f94590bc8b5d59bbf5ab4a2c672140ed8`, candidate identity `aeac243b2384f4b740583559f1b104b6b835ce15d67195281697d6d8e8a4648c`; run-time canonical identity `7a3e1350de0633268fba6c687cf25a66da3bef96c98886e05d927eeaeb3aa21e`. The [variant provenance](sim-v27/foundation-crown-run-03/variant-provenance.json) records exact changed paths and unrelated concurrent canonical drift.
- Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. Runner SHA-256 `b7a8a414b255b4c7b9602372880680bafca25f6ccb15d3e732ea49134bd84ae1`. Isolated APPDATA/LOCALAPPDATA profiles for focused verifiers and isolated `simulate.py` project/profile for campaign and replay.
- Changed only the private `project/`: new `ContractDefinitions` registry and focused verifier; routed `ContractState` and `PublisherTrialTerms` through definitions. Current five IDs, terms and output shapes remain. The [source delta](sim-v27/foundation-crown-run-03/variant-provenance.json) includes generated UID for the new class. No new offer, checkpoint field, runtime-mod entry point, UI or numerical tuning.

## Checks and comparison

- Private focused verifiers: [Ironclad](sim-v27/foundation-focused-01/verify_balanced_primitive_contract.log) 63 PASS, [SideStreet](sim-v27/foundation-focused-01/verify_sidestreet_contract.log) 99 PASS, [trial cash](sim-v27/foundation-focused-01/verify_publisher_trial_cash.log) 30 PASS, [Starwave](sim-v27/foundation-focused-01/verify_starwave.log) 188 PASS, [Publisher Connections](sim-v27/foundation-focused-01/verify_publisher_connections.log) 49 PASS. Each exited 0 with zero named failures. [New definition verifier](sim-v27/foundation-focused-01/verify_contract_definitions.log) exited 0 with zero failures; it checks registered IDs, detached definitions, malformed rejection, exact stored terms, full rewards and Ironclad override. The Godot exit warning about six leaked ObjectDB instances was retained in logs.
- [Candidate run](sim-v27/foundation-crown-run-03/run-report.json) completed one legal fresh Action/Cult20 seed4417 case at 85 accepted commands, cycle34, four releases. Exact [fresh-process replay](sim-v27/foundation-crown-replay-01/replay-report.json) passed all 85 steps, final state `f1c475182a42f2130a422106eeb7f44edf843b85ade66677997e249fcada6871`.
- Compared against the earlier [canonical-source v27 replay](sim-v26/current-crown-no-reuse-replay-01/replay-report.json) with the same legal fresh starting recipe and policy: all 85 accepted flags and state digests match, including the final state. Source/tape identities differ as expected for distinct source revisions; equal seeds alone were not used as proof. The candidate's own [case](sim-v27/foundation-crown-run-03/cases/action-cult20-4417-crown-no-reuse/result.json) and retained prior case record remain available.

Exact successful runner commands:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py run --variant docs/codex/threads/contracts/simulators/contracts-foundation-v1 --config docs/codex/threads/contracts/study-v12-current-crown-no-reuse.json --output docs/codex/threads/contracts/sim-v27/foundation-crown-run-03 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py replay --bundle docs/codex/threads/contracts/sim-v27/foundation-crown-run-03 --case action-cult20-4417-crown-no-reuse --output docs/codex/threads/contracts/sim-v27/foundation-crown-replay-01 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
```

Focused command pattern (each verifier received a distinct profile and log under `foundation-focused-01`):

```powershell
$env:APPDATA='<repo>/docs/codex/threads/contracts/sim-v27/foundation-focused-01/<verifier>-profile/AppData'
$env:LOCALAPPDATA='<repo>/docs/codex/threads/contracts/sim-v27/foundation-focused-01/<verifier>-profile/LocalAppData'
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --headless --path docs/codex/threads/contracts/simulators/contracts-foundation-v1/project --script res://scripts/debug/<verifier>.gd
```

## Retained failures and limits

- A first direct private-project Godot invocation crashed with signal 11 before verifier output, prior to profile isolation. A later import without writable APPDATA/LOCALAPPDATA reported permissions errors and was not treated as gameplay evidence. Isolated-profile checks passed.
- [Run attempt 01](sim-v27/foundation-crown-run-01/run-report.json) and [run attempt 02](sim-v27/foundation-crown-run-02/run-report.json) were rejected while recording canonical drift because other work changed the shared source during their snapshots. They produced no campaign outcome and were not counted as failures of Contract rules. Attempt 03 passed without relaxing the source fence, changing policy, seed or budget.
- The exact campaign route exercises Ironclad and Crown; the focused suites cover the other offer rules. This is headless structural/regression evidence, not exported UI, player comprehension, future new-type validation, full C5 acceptance or final balance approval. Canonical drift outside Contracts must be reconciled at adoption.

**Recommendation:** adopt the bounded registry and compatibility wrappers via the sealed handoff after reviewing current source drift. Keep current numerical status and existing exported acceptance status unchanged. Verify all five focused suites and a fresh-route replay after canonical integration; a later new Contract type needs separate approved rules, offer issuance and checkpoint review.
