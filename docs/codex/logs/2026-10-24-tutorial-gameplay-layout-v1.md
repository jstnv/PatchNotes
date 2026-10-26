# Tutorial gameplay layout correction — 2026-10-24

## State / request

`main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty checkout. User screenshot shows cards hiding QA scores and a synergy banner covering instructions; request is a tutorial layout matching regular gameplay. Preserved inherited/parallel work and `.codex-godot-temp`. No commit/push/export or player-profile use.

## Implementation

Extracted the existing read-only header/rendering into `scripts/ui/production_scoreboard.gd`; live `gameplay_hud.gd` and tutorial share it. Tutorial keeps the top scoreboard visible, guides on the right, actions/phase controls below and cards in a stable clipped stage with a separate synergy lane. Reused existing card/music presentation. A tutorial-only CardFan fit option prevents selected/backlog groups clipping at1152 width; the default live arrangement is unchanged. `rival_world_checkpoint.gd` admits the exact measured immediately preceding source under existing full validation. Added the component UID and expanded the maintained UI verifier.

[Plan](2026-10-24-tutorial-gameplay-layout-plan-v1.md) · [full files, scoped diffs, exact commands/receipts, captures and retained failures](../findings/tutorial-layout-20261024-v1/README.md).

## Checks

Meaningful old-layout RED retained. Final model27/27; preference verifier PASS. Headless/native UI115/115 each PASS, including complete practice, real pointers/keyboard, card/bonus/return geometry, stable actions, full card bounds, Beta values and all real state/world/RNG/save byte preservation. Rendered1152×648,1280×720 and1906×932 captures inspected. Seven broader UI suites have passing receipts; live HUD and first-game tips also pass on final source with explicit answered-preference fixtures. Fresh-process prior-world restoration preserves all fields/RNG and rejects unknown/mixed source. Source fences pass for both final batches and native/cold runs.

Read-only review caught clipping; targeted geometry RED reproduced it and GREEN verifies the repair. Review accepted the narrow fix. Original wrapper-source-drift, fixture deferred focus, unseeded ordinary-HUD and native-pointer-reflow attempts remain retained. Existing missing-art/engine shutdown warnings are documented separately.

## Boundaries

Final source identity `6800a07e9c01c2aa0476d8251afdfc3f0f3c61ad5989ff2c99bcd813d1c2ae65`; predecessor `b8785b47ebb32a94fbf1dbbf682b015be4171259a8ce9631a2df9fc93f7a6205`. No gameplay/model/AI/music rule change, whole-release or human/audible approval. Existing EXEs/ZIPs remain at their previous source. Restart the Godot play session to construct the corrected layout.
