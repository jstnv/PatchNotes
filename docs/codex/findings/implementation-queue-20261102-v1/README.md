# Implementation queue restoration and actual saved-state repair — 2026-11-02

Status: IMPLEMENTED locally; focused headless/native acceptance PASS. No commit, push or export.

## Source and symptom

Intake and final: main at `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`, dirty shared checkout. CURRENT_STATE/TODO/design/source and existing diff were inspected first. Runtime before files and intake manifests are retained here; unrelated edits and `.codex-godot-temp` remain. See `final-audit.json` and `final-source-manifest.json` for exact final bytes and check receipts.

The former Research dropdown had been explicitly hidden in the immediately preceding UI pass. This user correction restores it with Implementation wording. Fresh queues already completed via physical pointer input at all three tested window sizes; the disabled action required the actual saved state to reproduce.

`observed-save-origin.json` records the read-only checksum and source identity of the original player checkpoint275. `observed-save-pair.json` retains its player/world state, normalizing only the generation sequence to the adapter capture value1. Original save SHA256 remains unchanged after testing. All execution uses new private profiles, never player saves.

The actual copied Studio had Text and8-Bit Sound pending at cycle2, cash492500 cents, with15000 and22500 cents still due. Its zero-unit public-engine release used a retained `market-book-v1-0-<64 lowercase hex>` factor. `Market.valid_source` rejected every non-calendar cycle-zero source except `market-0-neutral`, preempting its own dated legacy-book validator. Consequently the sales plan was empty, `can_complete_productive_cycle` was false, and Implement disabled despite sufficient funds. This was neither a stretched-window hit target problem nor an installment affordability problem.

## Exact changes

- `patch-notes/scripts/ui/feature_store.gd`: show the existing engine-filtered queue beside the top Implement action. No new queue model, ordering, fees or supply rules.
- `patch-notes/scripts/market/market_transaction_trial.gd`: let legacy `market-book-v1-` at cycle0 reach the existing exact cycle/prefix/lowercase64-hex validation. Factor arithmetic, historical flags and other rejected sources remain strict.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: append only the verified immediately preceding source `e1720b670204ebb318ed54e92b68cf157b9d9466cd0a61882f92601957c2edf9` to the existing modern compatibility route. `predecessor-origin.json` proves its genuine durable fixture and exact intake-manifest equality. No wildcard or schema relaxation.
- `patch-notes/scripts/debug/verify_cycle_zero_market_book.gd`: maintained15-case source/factor/zero-unit progression regression.
- `patch-notes/scripts/debug/verify_sales_earning_and_settlement.gd`: repair a stale test fixture that invoked the retired global Store route and dereferenced null. Directly construct the legacy tree for its passive-browsing oracle; production navigation is not revived.
- Current state, TODO, Feature Store and UI design records plus the dated session log document the direct queue-visibility supersession.

## Verification

All final rows below exit0 with zero classified errors and an unchanged full-source fence. Receipts contain exact argv/profile/log/manifests.

| Output folder | Result |
| --- | --- |
| `market-regression` |15/15; accepted legacy/current/neutral sources; reject wrong cycle, invalid hash/case/length, historical disguise and wrong factor math; zero-unit first earning step produces no fabricated earnings |
| `green-pointer` |13/13 native; visible queue, fresh quotes and physical-pointer completion at1152×648,1280×720 and1906×932 physical windows using the actual1152×648 canvas transform |
| `observed-aligned-final` |20/20 headless on actual copied save |
| `observed-native` |20/20 native on actual copied save, including physical queue/button clicks and keyboard row selection |
| `predecessor` |11/11; genuine prior source player/world unchanged except source stamp; seven protected missing/corrupt annual/budget/engine/capacity/source/RNG/calendar cases still reject |
| `workflow` | maintained engine Feature workflow,0 failures |
| `store-copy` |54/54; admission/availability/FIFO/financial rejection, state preservation, tooltips and widths |
| `sales-current-fixture` | maintained earning/settlement,0 failures; cumulative royalties, duplicate prevention, overflow, zero-unit behavior, live summary and production integration |

Observed-save checks open the actual dropdown, inspect the waiting Feature without changing any player state, complete Text for15000 cents at cycle3, immediately enable the next head, and complete8-Bit Sound for22500 cents at cycle4 plus exactly one existing30000-cent monthly rent. Cash492500→477500→425000 cents. Both real rival ticks commit. Empty/repeated completion is inert. Full cold player/world capture/restore equality includes finance, histories, supplied library, queue and RNG. This is an in-memory cold-codec round trip, not a claim about a fresh exported EXE or disk-failure recovery.

Native capture `observed-native/observed-queue.png` was visually inspected: visible queue and enabled Implement remain within the view and use the current theme. Native final production bytes match the final audit; its sole later full-project delta is the debug-only sales fixture repair.

## Retained failures and limits

- `red-pointer`: three missing-queue failures; all original fresh pointer completions passed.
- `red-observed`, `red-observed-diag`, `red-sales-diag`: actual saved head rejects/does not charge or complete; traced to factor validation, not finance affordability.
- `red-factor`: three expected source/factor/progression failures; negative controls passed.
- `observed-full`: strengthened fixture initially omitted Gameplay's real rival-calendar connection; first action worked but subsequent world alignment failed. Fixture corrected to use `RivalWorld.advance_committed_player_cycle` with the actual trial policies/bounds.
- `observed-aligned`: fixture-only typed-array assignment error timed out; final fixture corrected and passes. Its source fence crossed creation of the new debug regression only; retain the failed receipt.
- `sales`: stale retired-global-Store fixture raised a null `hide` error despite printing0 failures. Corrected maintained fixture passes with no classified errors.
- Existing headless exit warnings about20 ObjectDB instances and missing card-art warnings are recorded, not represented as leak/artwork acceptance.

No source/library/cohort/balance adoption, calendar or sales formula change. No measured latency/parity claim. Existing EXE/ZIP are not rebuilt; full game/device/export acceptance remains separate. No further implementation blocker found for this reported queue/action defect.

## Reproduction

Use the same Godot and bundled Python paths recorded in each `result.json`. Runner:

`python docs/codex/findings/large-save-20261101-v2/run.py --script res://../docs/codex/findings/implementation-queue-20261102-v1/verify_observed.gd --fixture docs/codex/findings/implementation-queue-20261102-v1/observed-save-pair.json --output <new-output-folder> --fence --timeout 180`

Add `--native` for the native run. Each output directory must be new. Maintained checks use `--script res://scripts/debug/<name>.gd` with their exact names in the table's receipts.
