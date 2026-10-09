# Publisher Connections implementation — 2026-10-08

## State and scope

- Branch `main`, HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`. Existing shared worktree changes and `.codex-godot-temp` preserved. No commit, push or export performed.
- User requested completion of Publisher Connections. Implemented the approved T5 ACTIVE/TRIAL handoff; this does not lock final balance.
- New Studios use trait snapshot v5: Publisher Connections costs one point. Publisher-only starting cash is $5,650. Earlier v3/v4 inactive previews remain inactive.
- First successful Ironclad acceptance creates one $550 publisher receipt. Its frozen completion pool is $1,850, with completion cents `floor(185000 * n / 96)`. Full total remains $2,400. Ordinary Ironclad and other publishers retain their existing terms.
- Ordinary finance recovery and first-hand cash gates apply. Cancellation, failed acceptance and repeated acceptance do not pay again or consume eligibility incorrectly.

## Files changed in this task

- `patch-notes/scripts/studio_traits.gd`: active trait and v5 point accounting.
- `patch-notes/scripts/contracts/contract_state.gd`: frozen connected terms and proportional completion.
- `patch-notes/scripts/run_state.gd`: actual acceptance amount, atomic receipt and trait capture.
- `patch-notes/scripts/phases/studio_phase.gd`: actual advance and remaining-pool offer copy.
- `patch-notes/scripts/persistence/checkpoint_schema.gd` and `studio_checkpoint.gd`: capture, validation and restore of frozen terms; content revision traits5/contracts3.
- `patch-notes/scripts/debug/verify_studio_traits.gd`: current snapshot expectation.
- Added `verify_publisher_connections.gd`, `verify_publisher_connections_ui.gd`, and `publisher_connections_restart_probe.gd` under the same debug directory.
- Updated TODO, CURRENT_STATE, DECISIONS, studio-traits and publishers-contracts design summaries. Added this log and findings evidence.

## Checks and results

Evidence: [publisher-connections-v1](../findings/publisher-connections-v1/). Exact suite invocations are saved in each `.command.json`; stdout is in the corresponding `.log`. Godot 4.7.1, isolated APPDATA/LOCALAPPDATA.

Ten focused suites passed with exit 0 and no unexpected errors:

1. `verify_publisher_connections`
2. `verify_studio_checkpoint`
3. `verify_studio_traits`
4. `verify_research_integration`
5. `verify_publisher_connections_ui`
6. `verify_publisher_trial_cash`
7. `verify_publisher_trial_offers`
8. `verify_publisher_trial_promotion`
9. `verify_studio_folder_menu`
10. `verify_balanced_primitive_contract`

Payout checks cover numerators 0, 48, 94 and 96: completion cents 0, 92500, 181145 and 185000. Controls cover no trait, connected trait, and connected trait with Expensive Lease, native payroll/Bank settlement, failed acceptance, duplicate acceptance, native two-hand completion and checkpoint roundtrip.

The explicit arrears boundary fixture constructs a central finance journal to test ordered recovery and an unresolved first-hand gate. This is a focused constructed state, not a legal playthrough or balance observation.

Four fresh Godot processes passed (`initial`, `unsaved`, `complete`, `inspect`), with exact commands and exit results in `restart-results.json`. Continue restores the prior Studio and rolls back unsaved acceptance. Completion is autosaved; the next process restores identical encoded state, frozen terms and consumed eligibility without another receipt.

Rendered verification passed at 1152×648 and 1280×720. The final UI fixture opens the actual Contracts chooser; offer copy includes $550, $1,850 and the $2,400 cap, Accept remains visible, and cancellation preserves state. Screenshots are `offer-1152x648.png` and `offer-1280x720.png`; final 1152 screenshot visually inspected. Latest rendered output is `rendered.log` (0 failures). Only the known environment root-certificate warning occurred.

`git diff --check` passed; Git emitted line-ending normalization warnings only.

## Limits and follow-up

- Local implementation is complete; exported executable interaction was not tested in this task.
- The new content revision uses existing incompatible-save recovery, preserving old bytes rather than silently migrating earlier checkpoints.
- No remaining T5 blocker. Broader export/Bank acceptance and unrelated TODO items retain their separate scope.
