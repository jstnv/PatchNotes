# 2026-11-04 — Menu, loading and Studio transitions

Branch `main`; starting HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`. The worktree already contained unrelated changes, including the Studio panel, unlock notices and performance investigations; these were retained. No commit, push, export or broad performance audit was performed.

## Change

- The New Studio and Continue loading surfaces appear over the live title while its existing logo-disappearance sequence, button exit and decorative frame exit play. New Studio also slides the setup screen right. Input is fenced throughout; a failed load restores the menu. The live circuits and soundtrack transport persist.
- After Continue, tutorial exit/skip, launch-review return and contract completion, the Studio HUD bars enter first, followed by the Studio panel from the left. An already-open Studio companion is hidden during the entrance and restored afterward. Returning to title removes the HUD first, then uses the existing Start logo reveal and staggered title entrance without restarting the boot soundtrack sequence.
- One exact predecessor source identity, `c7e39d147c08e780cc9eb14bafe5d805a4dcb484503573254f17bc7dca0abbef`, was captured before the runtime edits and added to the existing validated checkpoint predecessor list. This is presentation-only; other unknown identities remain rejected.

Changed production files: `scripts/gameplay.gd`, `scripts/phases/main_menu.gd`, `scripts/phases/studio_phase.gd`, `scripts/ui/continue_loading.gd`, `scripts/ui/gameplay_hud.gd`, `scripts/ui/studio_hub.gd`, and `scripts/market/rival_world_checkpoint.gd`. Focused debug verifiers were added for title, Studio choreography, HUD/hub geometry, and review/contract arrival; the existing New Save and Continue fixtures were adapted for the intentional staged handoff.

## Checks

- Native Godot 4.7.1, isolated profile, actual New Studio → tutorial skip → Studio → pause → title: 31/31, including input fencing, visual order, audio transport, unchanged checkpoint and all five title buttons after the entrance and checkpoint inspection. Captures: `sims/choreography-test-20261104/captures3/`; log: `sims/choreography-test-20261104/profile5/choreography.out.log`.
- Isolated headless open-companion and real-route check: 26/26, `sims/choreography-test-20261104/profile6/choreography.out.log`. HUD/hub geometry and hidden tutorial/review coverage passed: `sims/phase-transitions-20261104/hud-companion/`.
- Real launch-review and completed Contract returns: 20/20, including guard, stage order, payout, release and calendar preservation; `.transition-verify-contract-final/stdout.txt` and `stderr.txt`.
- New Save loading 19/19, `sims/choreography-test-20261104/new-save/`. Full Continue loading 248/248, `sims/choreography-test-20261104/continue3/`; both used isolated profiles. Continue includes retry, teardown, saved player/world, generation bytes, duplicate-settlement and soundtrack-transport checks. Its dummy audio does not establish physical listening acceptance. Earlier fixture failures in `continue/` and `continue2/` are retained: they raced asynchronous title inspection and accessed a loader after its intentional staged removal; the final fixture waits for readiness and handles the handoff.
- Main Menu entrance/departure and failure restoration: 12/12, isolated headless. Exact pre-change player/eight-rival pair restored with `player_exact=true`, `world_except_stamp_exact=true`, `unknown_rejected=true`, eight studios; `sims/phase-transitions-20261104/old-save-check-final/`.
- `git -c core.whitespace=cr-at-eol diff --check` passed for the changed production scripts.

## Limits

Native captures cover the exercised 1280×720 creation/Studio/title route; other displays, exported builds and physical-device listening remain unverified. The headless HUD/Hub and review/contract verifiers reported 20 ObjectDB instances leaked at test exit; existing missing-artwork and invalid scene UID fallback warnings were also recorded. The separate cleanup and whole-game performance audit remain paused, and earlier retained issues remain open.
