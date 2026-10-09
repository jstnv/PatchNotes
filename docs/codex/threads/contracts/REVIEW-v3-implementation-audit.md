# Contracts implementation status audit v3

2026-10-07 (America/Los_Angeles). Read-only review on `main` at HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19` with uncommitted gameplay and documentation changes. The exact reviewed working-tree files include `publisher_catalog.gd` SHA-256 `D30743C4D477AD9C59B2CF0DB962E7C076E798D64D5CC29F5C580E7C74702CB2`, `publisher_browser.gd` `81B08D5640936944634BA176AF64F0E44EB4C0EE95C391B07E22C53B5656305F`, and `run_state.gd` `6164551A9FFB2B9A2F29D74FA571895CE3DDB7A22BB163AB96CC9BB9ED04341D`. This audit inspected source and existing findings; it did not rerun Godot or modify gameplay.

## Verified status from current evidence

- The [implementation finding](../../findings/2026-10-07-checkpoint-contracts-implementation-v1.md) records 83 maintained suites passing, ten native routes with 31 releases, seven-process Crown/Neon checkpoint restores and both supported UI sizes. Current [trial terms source](../../../patch-notes/scripts/contracts/publisher_trial_terms.gd) contains the approved Crown $150/Scope 9/$1,920/12 and Neon $0/Scope 10/$1,560/20 values. `RunState` has new offer and keyed Promotion state; the SideStreet unlock predicate now checks committed Ironclad completion. These support C1–C3 locally and most of C4.
- C5's disk restart and once-only identity checks pass in separate processes. The exported interactive Bank/Continue route remains unverified, and the broader Task 10 A01–A12 matrix is not complete. The implementing thread reports Computer Use app approval timed out before that exported playthrough.

## Player-facing discrepancy

`publisher_catalog.gd:13–14` still gives Crown and Neon the availability text **“Publisher profile only; no offer is implemented yet.”** `RunState.get_publisher_status` passes that text through as `availability`, and `publisher_browser.gd:90–113` displays it for Crown and Neon without an override. Thus the publisher browser contradicts the playable offers in the same build. The maintained publisher browser check verifies names, prerequisites, layout and navigation, but not this availability copy. This is a specific C4 presentation gap even though the chooser itself was captured and inspected.

**Recommendation:** the main implementing thread should make Crown/Neon browser availability accurately reflect pending, active and completed offers, then run a focused browser check at 1152×648 and 1280×720. Keep C4's broad native evidence, but do not call its player-facing acceptance fully verified until this copy is corrected and checked. Keep C5 PARTIAL until the exported interactive Continue route passes. Do not change the approved trial numbers or infer final balance from this audit.
