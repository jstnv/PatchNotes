# Playtest percentage targeting

2026-10-10. User requested corrective cards based on lowest percentage of standard. Shared dirty main at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; existing edits preserved, no commit/push.

Changed `scripts/phases/alpha_phase.gd` and `beta_phase.gd` to rank by current Core score / `PrimitiveReviewCalculator.get_project_profile()` standard. Ratios stay uncapped; existing Alpha priority/Core-order and Beta Core-order ties remain. Missing invalid profile returns no selection. No cost, time, pending snapshot, injection or scoring changes.

Extended `scripts/debug/verify_beta_host_playtest.gd` with both-phase Action tests where raw and percentage order differ, unequal-score equal-percentage ties, and above-cap percentages. Initial test attempted a priority increase without freeing allocation points and failed its fixture expectation; corrected to a valid 20/20/20/40 distribution. Retained failed-run evidence. Updated core-and-studio design, TODO and CURRENT_STATE.

Commands using bundled Python and isolated test profiles:

- `docs/codex/findings/card-presentation-v2/run.py playtest-percent-beta-v2 verify_beta_host_playtest.gd` — PASS, exit0, no errors, source unchanged.
- `docs/codex/findings/card-presentation-v2/run.py playtest-percent-alpha verify_alpha_phase.gd` — PASS, exit0, no errors, source unchanged.
- Focused `git diff --check` — PASS after trailing blank-line cleanup.

Exact commands/source hashes/logs reside in those findings directories. No computer control or refreshed export in this patch; earlier exported acceptance is pinned to earlier source.
