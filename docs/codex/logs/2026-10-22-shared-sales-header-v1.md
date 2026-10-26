# Shared in-game sales header — 2026-10-22

Branch `main`, HEAD `0132c4da`. This is local uncommitted work in a shared dirty checkout. Existing edits and `.codex-godot-temp` were preserved. No commit, push, or release-readiness claim.

## Change

The sales chart now lives in the existing persistent top HUD, with an empty style box so it adds no independent border. That header is shown in Studio, development phases, Feature Store, Contract, post-game Review and Summary. Main Menu remains outside the in-game HUD; before the first release there is no chart data to show. Studio and non-development screens display a concise Studio/year heading while development screens retain their score and priority controls. The old duplicate Studio heading panel is hidden. The Store title and Owned Pool are placed beneath the shared header, its body starts higher, and the detail popup guidance height adapts to short viewports. Sales calculations and gameplay rules were not changed.

Source touched: `patch-notes/scripts/ui/sales_revenue_hud.gd`, `gameplay_hud.gd`, `feature_store.gd`, `feature_store_map.gd`, and `patch-notes/scenes/phases/studio_phase.tscn`. Focused checks/captures were updated in `patch-notes/scripts/debug/capture_sales_hud.gd`, `capture_release_menus.gd` (and UID), `verify_store_hud.gd`, `verify_release_menus.gd`, and `verify_feature_store_radial.gd`. This log, `docs/codex/CURRENT_STATE.md`, `design/game-lifespan.md`, and `design/feature-store-progression.md` record the current placement.

## Verification

Godot 4.7.1 was run through the isolated project/profile runner. [Final suite commands, exits and summaries](../findings/store-gameplay-links-20261018-v1/w/results.json) and [exact source snapshot](../findings/store-gameplay-links-20261018-v1/w/source.json) are retained. SHA-256 comparison confirms all ten changed runtime/verifier source files match the tested snapshot.

- **RED before implementation:** the new shared-header assertions failed in 20 places on the old placement. [Log](../findings/store-gameplay-links-20261018-v1/u/capture_sales_hud.log).
- **PASS final:** import; sales model 458/0; gameplay HUD; Store behavior, Store radial layout, Store HUD 135/0; release menus; Studio folder; native sales/HUD captures 188/0; native Store captures 153/0; release-menu and Store-map captures. All 12 final jobs exited 0 with no recorded runtime/script errors.
- **Visual inspection:** [Summary at 1280×720](../findings/store-gameplay-links-20261018-v1/w/summary-1280x720.png), [Review at 1152×648](../findings/store-gameplay-links-20261018-v1/w/review-1152x648.png), and [Store at 1152×648](../findings/store-gameplay-links-20261018-v1/w/store-1152x648.png) show one shared top border and no chart border. Native captures also cover Studio, Design, Alpha, Beta, Contract, both supported sizes, and Store at 900×600/1920×1080.

Two broader suites were tried on both a prechange snapshot and the updated code. `verify_predevelopment` failed on its existing next-game fixture and a `studio_phase.gd` to `design_phase.gd` assignment; `verify_pause_menu` failed its pre-pause Rival/Founder checkpoint source/schema assertion. The same failure signatures are in the [prechange logs](../findings/store-gameplay-links-20261018-v1/f/) and updated-run logs; these do not establish a regression from the header work. They remain separate acceptance limits. Human play and refreshed export were not run for this visual change.
