# Unified game typography — 2026-11-03

Started on `main`, HEAD `7c60a01cbfac76d3f3cae1062849a070b1563116`, preserving the prior local Studio, Played Hand, menu-audio and other shared work. Captured an isolated eight-rival pair against exact pre-change source `97967757abe3de7a216351f7d75086775fc28a43a9b3ec3984e8e5894499ee8b`. This work is local, not committed, pushed or exported.

Both shared themes and the card scene now use the existing IBM Plex Sans family; headings, buttons and section captions use its 700 weight, while body copy, metadata and score values use regular. The production and Contract scoreboards split captions from values, preserving score and punch targets, headings, focus and tooltips. The Contract priority heading and Feature Store legend also use a bold role. The wordmark is an image and remains unchanged. No gameplay, calendar, economy or RNG rule was changed.

The existing FontVariation used a string `wght` key that Godot ignored. The numeric OpenType tag `2003265652` actually applies weight 700. A native render showed 13,235 pixels differing between regular and bold, with the corrected theme bold matching an explicitly configured 700-weight font; `Graphics` at 32 pixels measured 127 pixels regular and 134 bold. Evidence `.codex-godot-temp/font-contract-captures/weight-render-probe.log` and `.codex-godot-temp/uniform-typeface-ink-final/`.

Changed runtime files: `patch-notes/resources/ui/onyx_theme.tres`, `workspace_theme.tres`, `patch-notes/scenes/cards/card_view.tscn`, `patch-notes/scripts/ui/production_scoreboard.gd`, `gameplay_hud.gd`, `feature_store_map.gd`, `patch-notes/scripts/phases/contract_phase.gd`, and one exact preceding source in `patch-notes/scripts/market/rival_world_checkpoint.gd`. Focused debug checks added `verify_uniform_typeface.gd` and updated `verify_card_motion.gd`, `verify_genre_targets_ui.gd`, `verify_score_floats.gd`, `verify_guided_tutorial_ui.gd`, `verify_ui_folder_navigation.gd` and the Contract presentation fixture for split captions.

Checks with isolated profiles:

- Before implementation the font test failed 38 of 45 checks. Final native font/typeface/real glyph metric, HUD/creation and two-size fit: 71/0; captures reviewed. `.codex-godot-temp/uniform-typeface-ink-final/`.
- Native Contract presentation: 84/0 across 1152×648, 1280×720 and 1600×900, including text fit and animated score updates. `.codex-godot-temp/font-contract-bold-native/`.
- Post-axis score-float/punch regression 385/0, genre-target UI 0 failures, and folder navigation 101/0 with isolated TestStore. `.codex-godot-temp/uniform-axis-verify_score_floats/`, `uniform-axis-genre/`, `uniform-axis-verify_ui_folder_navigation/`.
- The broad card-motion suite did not pass: two checks expect a one-card hand to be rejected, contrary to the current one-to-four-card rule; another Store camera/menu animation timing assertion failed, and the second fresh-save fixture did not enter Studio. All failures and script errors remain in `.codex-godot-temp/uniform-axis-card-motion-teststore/`; no broad card-motion pass is claimed.
- The exact preceding isolated player/eight-rival pair restored with identical state except the expected source stamp; unknown source rejected. This passed again on the final corrected font and legend source. `.codex-godot-temp/font-unification-compat-final/`.

Static font searches and targeted live screens support the scope; they are not an exhaustive manual traversal of every rare screen, and exported/device acceptance remains open. The unapproved or unrelated queued work in TODO was not adopted.
