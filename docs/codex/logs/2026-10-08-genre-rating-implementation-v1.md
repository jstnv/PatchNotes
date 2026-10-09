# Genre-dependent base rating implementation — 2026-10-08

## Authority and source state

- User approved implementation after discussing the132-total/average33 target table, independent project Genre and Studio specialty,8/10 and10/10 anchors, visible targets and preserved history/save behavior.
- ACTIVE/TRIAL implementation, not final balance approval. [Current rule table](../design/genre-specialties.md) supersedes the earlier candidate-only status and separate Genre Fit penalty for new calculations.
- Branch `main`, HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`. Existing shared worktree changes and `.codex-godot-temp` preserved. No commit, push or export.

## Changes

- `patch-notes/scripts/review/primitive_review_calculator.gd`: eight immutable target profiles, named `primitive_genre_targets_v1:<genre>`. Normalize scores by the project's Genre targets; keep1.25 cap,0.5 normalized-deviation coefficient,8× production scale, Scope/Bugs/variance/rounding. Remove the separate Genre Fit calculation. Legacy no-identity fixtures retain equal33 standards and the old baseline profile helper. Malformed project identity rejects.
- `patch-notes/scripts/project_state.gd`: clarify retained legacy ratio metadata; no state field/schema added.
- `patch-notes/scripts/ui/predevelopment_overlay.gd`: visible selected-Genre targets and production anchors; changing Genre updates guidance without changing draw priorities.
- `patch-notes/scripts/ui/gameplay_hud.gd`: score/target counters and explanation. Committed projects display their frozen Review standards.
- `patch-notes/scripts/phases/post_game_review.gd`: explain saved-target comparison and anchors. Historical metadata continues to supply its own standards/results.
- `patch-notes/scripts/persistence/studio_checkpoint.gd`: append review2 rules revision; explicitly accept the immediately previous rules revision only with identical data hashes/schema/RNG. No payload field migration or eager disk rewrite. Continue is passive; next normal committed checkpoint writes current revision. Other incompatible saves retain existing rejection/recovery.
- Updated `verify_genre_fit.gd` and existing card-motion expected labels; added `verify_genre_checkpoint.gd`, `verify_genre_targets_ui.gd`, and analysis-only `genre_rating_live_v1.gd`. Updated design, release compatibility, decisions, TODO and CURRENT_STATE.

## Verification

Evidence directory: [genre-rating-implementation-v1](../findings/genre-rating-implementation-v1/). Every headless invocation has an exact `.command.json` record and `.log`, with exit0 and no unexpected errors. Tests use isolated APPDATA/LOCALAPPDATA, never the player's save directory. Known environment root-certificate warning excluded; expected invalid-selection refresh warnings retained.

Godot4.7.1 editor import passed. **14 focused suites passed**:

1. `verify_genre_fit` —95 assertions: all eight target/cap anchors; independently calculated normalized imbalance; project Genre independent of specialty; legacy fallback; malformed identity; Scope/Bugs/variance/rounding; immutable cached Review.
2. `verify_genre_checkpoint` —43 assertions: constructed historical equal33 Action release preserves7.7 Review, standards and sales through previous-revision restore; Continue leaves bytes/files unchanged; next committed action upgrades revision; bad revision/RNG/finance reject; historical and new detailed Review displays use their own targets.
3. `verify_genre_targets_ui`
4. `verify_primitive_review`
5. `verify_predevelopment`
6. `verify_studio_specialties`
7. `verify_primitive_units_sold`
8. `verify_primitive_month_one_sales_revenue`
9. `verify_studio_checkpoint`
10. `verify_checkpoint_runtime`
11. `verify_gameplay_hud_overlay`
12. `verify_publisher_trial_offers`
13. `verify_publisher_trial_promotion`
14. `verify_card_motion` — animated scores still update at the proper beats while retaining target labels; cancellation and Contract presentation remain intact.

Two native two-release routes pass through real development hands, launch, Ironclad, sales/calendar progression and current checkpoint capture/hydrate equality:

| Studio specialty | Project Genres | Final Reviews | Month1 projected units |
|---|---|---|---|
| Action | Action → Puzzle |5.8 →7.2|472 →717|
| Simulation | Simulation → Action |3.7 →5.5|301 →548|

`live-action.json` / `live-simulation.json` contain complete actions and results. These are legal focused integration traces with actual new ratings feeding live sales. They do not establish final balance or a broad economy comparison.

Rendered `verify_genre_targets_ui` passed with OpenGL compatibility at1152×648 and1280×720. Exact PNG pixel dimensions asserted; all four final Pre-Development/HUD captures visually inspected. `rendered.log` has0 failures. The initial HUD capture inherited gameplay's1280 window setup; the verifier now reapplies each requested size after scene ready and waits for card entrances before capturing. No production fix was needed. Command:

```powershell
$env:APPDATA='C:/Users/64jus/Downloads/Patch Notes Design Folder/genre-rating-render/appdata'
$env:LOCALAPPDATA='C:/Users/64jus/Downloads/Patch Notes Design Folder/genre-rating-render/local'
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path patch-notes --rendering-method gl_compatibility --script res://scripts/debug/verify_genre_targets_ui.gd -- --capture *> docs/codex/findings/genre-rating-implementation-v1/rendered.log
```

The checkpoint verifier initially used two overly strict whitespace checks for UI text; those assertions were corrected before the saved canonical passing run. Independent final source review found no correctness blocker.

`git diff --check` passed; line-ending normalization warnings only.

## Limits

Local implementation complete. No refreshed executable or exported interactive acceptance; broader Task10/Task11 remain separate. Exact target values are trial balance, and different Genres can retain different strengths. Historical study files retain their original results and are not retroactively re-scored. Specialty grants, card supply, priorities, production synergies and economy values were not changed by this task.
