# 2026-11-04 — Uncropped Studio companion motion

Starting branch `main`, HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`; existing edits and `.codex-godot-temp` were preserved. The user reported that Studio submenus appeared cut off while sliding and asked that they emerge from the Studio panel midpoint without a visible crop line.

The previous midpoint clip still drew the moving full-size companion below the root panel. This masked its heading and frame. The companion now starts at the midpoint, slides and fades as one whole surface above the root, and settles in its previous right-hand position. It fades and returns to the midpoint on exit. The companion is pointer-transparent while moving, and its original control input settings are restored afterward; notices stay above it and the existing HUD-safe phase boundary remains. This supersedes the behind-root masking described in the earlier midpoint log.

Changed runtime files: `patch-notes/scripts/ui/studio_hub.gd` and one exact predecessor source identity in `patch-notes/scripts/market/rival_world_checkpoint.gd`. Updated `verify_studio_panel_motion.gd` and `verify_studio_slide_layer.gd`, and added `verify_studio_companion_clipping.gd`. Player rules, save format and gameplay state were not intentionally changed.

## Evidence

- The pre-fix real-Studio regression retained the visible masking failure: `sims/companion-crop-20261104/masked-baseline/` (8 pass, 1 fail).
- Native real-Studio 1280×720 check passed 26/26: full companion and fade at entry/exit, all four groups, and actual pointer navigation into Engines. Captures and logs: `sims/companion-crop-20261104/native-final/`; midpoint and settled captures were inspected.
- Headless Studio motion check passed 57/57, covering midpoint placement, stacking, fade, interaction through the overlap, group and keyboard navigation, resize, and unchanged finance/calendar/ownership/RNG: `sims/studio-uncropped-motion-20261104/headless/`.
- Two additional native destination/HUD/Bank runs initially passed 55/56: the Bank Back midpoint assertion sampled an already-finished tween, then attempted to resume it. A diagnostic measured the tween at 0.150 s before the old fixture added another 0.10 s to its 0.24 s duration. The fixture now freezes the pointer-triggered transition before the extra frame, advances only to the intended 0.10 s sample and checks that the tween remains valid. The corrected native run passed 68/68, including Bank Back and HUD/input/focus/state checks: `sims/companion-crop-20261104/native-layering-sampled/`. Earlier failures and the diagnostic remain in `native-layering/`, `native-layering-repeat/` and adjacent output folders.
- Before editing, an isolated player/eight-rival pair was captured at source identity `0100779ec59b17edffd05ae7d9a9268355e1e641cd92764be802fe9f07b96eb6`. After editing, restoration reported `player_exact=true`, `world_except_stamp_exact=true`, `unknown_rejected=true`, eight studios: `sims/studio-clip-fix-20261104/restore/`.
- `git -c core.whitespace=cr-at-eol diff --check` passed for the runtime changes and motion verifier.

Known scene UID fallback and 20 ObjectDB instances leaked at isolated verifier exit remain recorded; no cause for the latter is claimed. Exported-build and other-device visual acceptance were not performed. The separate disk cleanup and broad performance audit remain paused. No commit, push or build was made.
