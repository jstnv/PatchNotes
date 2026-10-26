# Studio Traits registry foundation decision v1 — 2026-10-17

## Direction

The user asked to stop balance work and implement the Studio Traits foundation. The currently playable structure and all ten named traits already exist. This pass builds a narrow **registry foundation**: one definition per trait owns its stable ID, display metadata, polarity, build-point amount, first active saved-trait version and historical active-ID order. `evaluate_traits` derives costs, grants and activation from those definitions rather than from separate per-trait branches. Existing effect hooks in RunState, finance, Contracts and Fanbase remain explicit and unchanged.

This is a structural implementation request, not a new trait, point-price decision, economic simulation or final balance judgment. The canonical `patch-notes/` project remains the PN Implementation thread's adoption target. This design thread will prepare a private simulator candidate and a source-pinned adoption handoff under its own folder, then add a minimal internal TODO entry for canonical reconciliation. No player review is reopened.

## Compatibility contract

- Preserve the exact set and order of `trait_ids` and `active_ids` in returned selections for every supported version 3–8 and legal choice. Version 8 remains the new-Studio version. Earlier inactive previews remain inactive and free; saved version 7 Cult keeps 40 Fans and new version 8 Cult keeps 20.
- Preserve four starting points, two-positive/one-negative limits, uncapped $50 conversion, Family's separate $300 receipt, trait version/effects mode, all returned dictionary keys and exact finance/checkpoint provenance. Reject unknown/duplicate/over-limit and unaffordable choices as before.
- Keep the current TRAITS catalog order and visible text. Do not remove the legacy background/secondary reader used by historical fixtures. Do not modify `RunState`, save/checkpoint, UI, finance, publisher or Fanbase code in this candidate.
- Registry metadata is code, not saved payload. Existing checkpoints remain validated by exact reconstruction of their versioned selection.

## Acceptance

1. Capture the pre-edit output of `StudioTraits.evaluate_traits` for every legal zero-to-two-positive/zero-to-one-negative combination across versions 3–8, plus representative invalid choices, from the frozen candidate baseline. Compare the candidate's output byte-for-byte after normal JSON formatting and retain both snapshots. Include exact old-version examples for Resourceful, Publisher, education and Cult activation boundaries.
2. Run focused existing trait and checkpoint verifiers against the private candidate. Retain failures rather than weakening their assertions.
3. Run a bounded legal fresh-Studio simulator route on both the unchanged baseline and candidate with the same policy/seed, and replay a representative candidate route in a fresh process. Compare legal actions, initial selections, finance, RNG, release and final outcome; record source identities and rule differences. A successful candidate remains a prototype until PN Implementation adopts it.
