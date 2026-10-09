# Studio checkpoint runtime — 2026-10-07

In progress on `main`, starting HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`. Preserved pending card-tempo documentation and `.codex-godot-temp`. No commit/push or release claim.

The user's Banking/Contracts/Fanbase screenshots were reconciled against CURRENT_STATE, TODO, the checkpoint specification and the current source. Banking B3–B5 are complete; full restart/export acceptance was missing. Crown/Neon C1–C5 are approved and queued. Fanbase's two bounded attempts are exhausted with no new continuation authority.

## Runtime work

- Added explicit trusted checkpoint schemas and detached whole-RunState hydration, finance5/Bank1/payroll/traits3/release/Contract validation, data compatibility fingerprint and exact scalar encoding.
- Added run-owned nine-stream RNG and deterministic committed project serials; familiarity now keys stable release IDs.
- Connected initial/returned Studio and committed Studio actions to generation storage. Added Continue, New Run archive confirmation, retry/return/quit failure controls and unsaved-exit warning. Mutations/departure block on save failure; a second mutation flushes an earlier pending save.
- Added explicit backup recovery and non-destructive replacement archives. Normal loading never silently skips damaged/incompatible current data. Old valid generations prune only after successful publication, retaining the newest two; damaged/incompatible/temp evidence remains.

Files: `scripts/persistence/` schema/adapter/coordinator/RNG/store/codec; RunState, Gameplay, MainMenu and phase RNG bindings. Focused verifier/capture/process scripts are in `scripts/debug/`; evidence is [checkpoint-runtime-v1](../findings/checkpoint-runtime-v1/).

## Verification so far

- Cumulative maintained gate: 79 verifiers recorded with exit 0 and no unclassified errors; later focused reruns cover subsequent checkpoint UI/boundary refinements. `gate.json` and per-suite commands/logs retain results. Known deliberate invalid-scene/partial-snapshot probes have narrow, named error classifications.
- Seven separate Godot processes: initial Studio, accepted loan/payroll, installment, payoff, unsaved Contract rollback, completed Contract and reload; all exact mapped fields compare against the prior process's hash. Frozen sales setup is a fixture; subsequent finance/Contract operations are native, not a human balance route.
- Actual scene Continue reproduces project ID/tutorial deal; Design/Alpha/Beta native deals and hand effects reproduce from the same checkpoint. Codec rejects malformed/incompatible state, and publication failure preserves the previous generation while blocking new mutations.
- Rendered and inspected Continue, saved Studio and save-failure UI at actual 1152×648/1280×720. Repaired overlapping failure buttons by using a readable dialog. Initial parallel capture was invalid because another isolated verifier held the single-writer lease; final capture ran serially and asserts a valid saved Studio.
- Existing tests updated for the approved four-beat notification, New Run confirmation and deferred scene readiness. No gameplay rule was changed to satisfy these tests.

## Remaining gate

Checkpoint runtime is implemented locally; final integrated/exported acceptance and broader A01–A12 coverage are still being completed. Do not mark Task10/Task11 or Contracts C5 complete from this progress record. Approved audio and human release readiness remain separate. Contracts gameplay work follows the checkpoint runtime slot; Fanbase remains at its bounded stop.

## Subsequent same-session result

Checkpoint and Crown/Neon integration continued through83 maintained suites, the42-field audit, both seven-process restart sequences and the refreshed export/package/startup checks. [Closure record](2026-10-07-checkpoint-contracts-closure-v1.md) and [current finding](../findings/2026-10-07-checkpoint-contracts-implementation-v1.md) supersede the earlier progress-only status. Remaining A01–A12 breadth/exported interaction is explicit; no full release acceptance is claimed.
