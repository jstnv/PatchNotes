# Feature Store prerequisite links — 2026-10-24

**IMPLEMENTED locally** for the direct user request. Clicking Missing expands individual wrapping node buttons horizontally to its right, with the existing44px/.24s cubic entrance and50ms stagger. Another Missing click collapses them; selecting a link opens its node. One-parent and AND gates share this interaction. The detail panel keeps its compact height, and camera framing includes the links and entrance footprint.

## Source and scope

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; inherited1,829-entry dirty checkout and `.codex-godot-temp` preserved. No commit/push. Final runtime identity `1a65c871916b3b42eef25df2684c5f2e7ef1087565563864c55f41158c39019b`.

Runtime delta against the immutable pre-change RED copy consists of three files:

- `scripts/ui/feature_store_map.gd`: external horizontal chooser; wrapping labels, combined bounds, pointer/keyboard routing, cancellation and focus restoration.
- `scripts/ui/menu_transitions.gd`: names the existing entrance distance/duration as shared constants without changing the existing motion.
- `scripts/market/rival_world_checkpoint.gd`: admits the two actual preceding editor/compiled-package identities with their matching current Studio revision and all existing world validation. Presentation sources participate in the world fingerprint, so this prevents a UI change from invalidating those worlds. Unknown and mixed revisions still reject; every restored field/RNG stays exact.

New maintained verifier: `scripts/debug/verify_store_prerequisite_links.gd`. Documentation, local audit harnesses and captures accompany it. [Exact runtime patch](runtime.patch), [delta hashes](adoption-delta.json), [complete source](source.json), [machine audit](audit.json). No scoring, ownership, pricing, parent requirements, Research/FIFO, finance, AI policy or Studio-only Continue boundary changed.

## Verification and retained failures

- Final maintained affected matrix: **11/11 PASS**, canonical unchanged. Store copy/navigation/radial/prerequisite links/usability, gameplay transition, Studio/persistence and rival activation/cold continuation all pass on the exact final source; rival trial includes120 assertions across20 cycles/four rival releases. This is a focused regression run, not a refreshed full-project gate.
- Original layout RED:45 assertions,21 expected behavioral failures on the old inline/direct-navigation implementation.
- First GREEN reached45/0 assertions but correctly failed its engine-error gate: Escape passed a null focus owner to `is_ancestor_of`. Added the null guard; the failed log remains retained.
- Review found lost keyboard focus during camera framing. Actual Enter→Right keyboard RED reproduced two failures. The repair restores the activating action only if no other control owns focus; revision/cancellation guards prevent stale callbacks. Final keyboard probe passes5/5: expand, focus recovery, rightward focus, Enter navigation and Escape during entrance. Read-only repair review found no remaining important issue.
- Final native Godot/OpenGL run passes45/45 with actual pointer input at1152×648,1280×720 and900×600. Buttons fit, labels wrap without ellipses, the panel stays compact, actual clicks follow external links, toggle/Escape work and the entire captured Studio state/RNG remains unchanged. The1152/900 captures were visually inspected.
- Actual previous editor and compiled-PCK sources each generated a36-command legal two-release player campaign with interleaved rivals. Separate final-source cold processes restore both unchanged payloads, compare all player/world fields and RNG, and reject unknown world identities/mixed Studio revisions. Both PASS. The old compiled PCK was loaded through Godot; this is not direct release EXE input acceptance.

The earlier11-suite `final` run has passing individual suites but reports `canonical_unchanged:false`, because the reviewed focus repair was applied while its immutable copy ran. Its receipts remain source-specific. The final unchanged-source continuation passes11/11 and is recorded in [the final matrix receipt](receipts/final-v2/result.json).

Known ObjectDB leak warnings in existing component suites remain in raw logs; no final focused/native engine errors. No refreshed export, human usability test, computer-control interaction or release-readiness claim.

## Captures

[1152×648](captures/prerequisites-1152.png) · [1280×720](captures/prerequisites-1280.png) · [900×600](captures/prerequisites-900.png)

## Reproduction

Use the bundled Python and Godot paths in [checks.py](checks.py). The maintained matrix driver is `docs/codex/findings/overnight-20261024-v1/all_checks.py`; pass a **fresh** `--output` directory, a private test `--port` and the eleven names in the retained receipt. The wrappers isolate the writer lease without changing production's lease.

`checks.py keyboard-<new-name>` repeats real keyboard input; `checks.py native-<new-name>` repeats the native maintained verifier in a new immutable copy/profile. `final_audit.py` records the shared final-copy/native/cold sequence used here; `world_probe.gd --input=<unchanged predecessor fixture>` performs the exact restore comparison. Existing output names intentionally cannot be overwritten. [audit.py](audit.py) reconciles these receipts and source hashes. Large snapshots/imports/profiles stay outside the synced checkout; [raw paths, commands and artifact hashes](external-artifacts.json) retain the boundaries.
