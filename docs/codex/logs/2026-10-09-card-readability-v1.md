# Card readability and corner repair — 2026-10-09

User reported unreadable text and rectangular corners outside the symmetric border. Main at41c87c76fb4d3c06a5332d93f0e7b0997007475d, existing dirty work preserved; no commit/push.

Changed `patch-notes/scenes/cards/card_view.tscn` and `patch-notes/scripts/cards/card_view.gd`: Godot fallback SystemFont with MSDF and linear filtering on text only replaces aliased Tiny5 display; sprites remain nearest-filtered. Measured names prefer15px, score types11px, numeric scores20px. Original field rectangles, symmetry, data binding, scoring and motion stay unchanged. Background/art are inset8px beneath the complete frame; selection outline has rounded corners. No image assets modified.

Verification through `docs/codex/findings/card-readability-v1/run.py`: `fit-v2 verify_card_frame.gd` passes1705 assertions across51 cards, zero abbreviated catalog fields; `beta-v1 verify_beta_planning.gd` exit0/errors[]; `capture-v1 capture.gd render` exit0/errors[] generates native240x336 and actual Alpha scene fan captures at1152x648/1280x720, visually inspected. Captures use synthetic presentation candidates, not an earned playthrough. Source unchanged during each successful run. Initial fit-v1 caught the new font's34px height at24px score size; lowering score size to20px restored the exact30px fields. Original failure retained. Focused diff-check passes after trimming EOF whitespace.

Remaining text limits: fixed40px score-type fields still use GFX/TECH/MKTG; unknown extra-long future labels use ellipsis with full tooltips. Fan overlap still hides portions of unselected cards as before. No refreshed export or human readability approval claimed. The previous105-suite gate predates this presentation-only follow-up.
