# Startup prompt styling and direct project setup —2026-10-27

User requested matching the saved-Studio replacement prompt to the existing menu design and removing low starting-Scope confirmation because the first run deliberately starts small. Clear scoped task under the standing no-input direction.

Baseline `main/f3e0f2b5d35270c879327bc297b389748571feb4`, runtime `700d6a166649a7487ecc2abd87655435a69dfcdcaea4c5e6d09278abdc31bbee`. Existing Main Menu discard styling, Studio refresh coalescing, other dirty work and `.codex-godot-temp` preserved. No commit, push or new public EXE/ZIP.

## Change

- `patch-notes/scripts/phases/main_menu.gd`: replacement uses the existing animated/chamfered confirmation component, a bounded680×220 surface, explicit **Continue setup** and Cancel. Existing archive-later explanation remains. Cancel, Escape and× leave replacement unacknowledged; confirmation opens setup without creating/replacing the Studio yet.
- `scripts/phases/studio_phase.gd`: first-project selection opens planning directly. Remove the low starting-Scope trigger/confirmation connection; planning remains free and starter purchases stay open until actual Begin. The hidden scene node is retained for older analysis/capture scripts that query it. Scope requirements, Begin validation and Alpha under-Scope exit confirmation are unchanged.
- `scripts/market/rival_world_checkpoint.gd`: exact preceding runtime added to the existing presentation/current-player/current-rival rules pair; full saved-state validation remains.
- `scripts/debug/verify_first_game_and_tips.gd` now asserts direct opening/reopening and removes artificial warning confirmation. New `verify_replace_studio_prompt.gd` covers both supported sizes and dismissal/acknowledgment behavior.
- `tools/fixtures/startup_prompts_predecessor.json` and provenance capture the actual preceding player/world state. SHA `c89e3f292a2b92f0b5ae72bce1344e1538e77ed14659f9648ed0c866952644d0`.

Final runtime `98e0b0926f13b8cf207ef375ff41bf2d8d9a82f6e7ac26d63aa447dc0fb50083`. Compared with the preceding manifest, runtime changes are exactly Main Menu, Studio phase and the compatibility entry. No scene/data/model rules changed.

## Verification

Use `python docs/codex/findings/startup-prompts-20261027-v1/run.py <fresh-label> <script> [--native|input output]`; exact commands/hashes/results are retained in [verification.json](../findings/startup-prompts-20261027-v1/verification.json), using Godot4.7.1 and private profiles/ports.

- `replacement-before ... verify_replace_studio_prompt.gd`: **RED**, generic dialog lacks the shared confirmation surface.
- `scope-before ... verify_first_game_and_tips.gd`: **RED**, actual12-Scope starter is blocked by the warning.
- `replacement-headless-final ... verify_replace_studio_prompt.gd`: **54 checks PASS**.
- `replacement-native ... verify_replace_studio_prompt.gd --native`: **56 checks PASS**;1152×648 and1280×720 captures inspected, complete wrapped message/buttons fit.
- `scope-after ... verify_first_game_and_tips.gd`: **38 assertions PASS**, including free direct/reopened setup, invalid-name rejection, normal actual first-project Begin and once-only starter closure.
- `economy ... verify_first_studio_feature_economy.gd`: **45 assertions PASS**, including starter purchasing and exact once-only hand cost.
- `alpha-guard ... verify_alpha_exit_arrears.gd`: **149 assertions PASS**; retained Alpha exit/arrears behavior. Its controlled historical Insider recovery fixture does not re-enable Insider in normal play.
- `cold-before ... verify_world_restore_file.gd <fixture> <output>`: expected source-guard **RED** before the narrow compatibility entry.
- `cold-after ... verify_world_restore_file.gd <fixture> <output>`: **7 checks PASS**, exact persisted player/rival/finance/history/ownership/RNG and rejection of unknown source/old revision pairs.

UI replacement checks use synthetic existing-checkpoint metadata and invoke actual native button/keyboard paths; no real user's save is replaced. Cold checks use a separate genuine serialized test world. These are local/editor checks, not new-export or physical-device acceptance. Existing artwork/resource warnings retained; final command receipts have no script/runtime errors. Final diff check is retained in the findings.

The unrelated newly queued Store Handoff022 remains pending for the authorized implementation follow-up; Handoff023 is DESIGN review, not approved content. This UI task does not adopt either packet or new AI values.
