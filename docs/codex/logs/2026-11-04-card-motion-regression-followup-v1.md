# Card-motion regression follow-up — 2026-11-04

Started on `main` at `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`, with the previous Production visualizer changes already uncommitted. The user's TODO request includes previously retained acceptance failures. Preserved existing edits, unrelated files, `.codex-godot-temp` and real saves.

The older broad card-motion verifier expected one-card hands to be rejected despite the current one-to-four-card rule, assumed synchronous title checkpoint inspection, and checked the Store details tween before deferred layout had settled. Updated only `patch-notes/scripts/debug/verify_card_motion.gd` to test empty-hand rejection, wait for the actual checkpoint inspection, and allow the Store's deferred focus transition to establish its tween. Gameplay behavior is unchanged.

- Baseline retained at `.codex-godot-temp/card-motion-audit-20261104/result.log`: three failed assertions and two script errors.
- Corrected headless run `.codex-godot-temp/card-motion-audit-green-20261104/result.log`: 122 pass, zero failed assertions or script errors, exit 0.
- Corrected native run `.codex-godot-temp/card-motion-audit-native-20261104/result.log`: 122 pass, zero failed assertions or script errors, exit 0. Both runs cover 1152×648 and 1280×720 and use isolated profiles and a test-only checkpoint store.

Existing missing-artwork and layout warnings remain visible in the logs. Physical devices and exported-game acceptance were not tested in this pass. No commit, push or release package was made for this follow-up.
