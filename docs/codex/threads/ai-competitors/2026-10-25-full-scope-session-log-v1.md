# Rival full-Scope and Beta priority — session log, 2026-10-25

## Checkout and changes

- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. The shared checkout already had broad dirty tracked/untracked work, including the active untracked `patch-notes/scripts/market/rival_trial.gd`; all canonical and `.codex-godot-temp` contents were preserved. No commit, push or release claim.
- Added [full-Scope / QA-then-Marketing decision](2026-10-25-full-scope-qa-marketing-decision-v1.md). Added short supersession notes to the 2026-10-24 Feature-exhaustion and two-hand-retirement decisions and the 2026-10-25 cash-funded Beta direction. Updated this thread's `README.md`/`working-notes.md` and the AI row in `docs/codex/DECISIONS.md`.
- Re-read internal `docs/codex/TODO.md` immediately before its minimal item22 **DESIGN review needed** entry. It warns against implementing a Scope gate alone. No gameplay source, simulator variant or other TODO item was changed by this session.

## Source and evidence checks

- Read `CURRENT_STATE.md`, `TODO.md`, repository `README.md`, relevant AI decisions and findings, core/economy design, the current `RivalTrial`, `DevelopmentSession`, `DesignHandCommand`, `BetaHandCommand`, `RivalBetaSynergyChoice`, `ProjectState` and launch warning source. Current `RivalTrial` exits Alpha when no legal visible Feature hand remains and confirms the under-Scope warning; Beta exits after two hands. `DevelopmentSession.observation()` exposes actual Scope, required Scope, Known Bugs, Marketing, cash, redraws and current cards, but not Hidden Bugs or future draws.
- Checked the current v3 fixture (`action` Scope27, `adventure`22), `RivalTrial` extras and `card_ledger.json` printed Scope: Arcade adds Music2, Dialogue1, Secrets1 for31; Wayfinder adds Sprites2, 8-Bit Music1, Music2 for27. The first-project required Scope is30. Wayfinder cannot meet30 from its present owned pool. A 35-printed-Scope grant is an untested candidate, not evidence of30 actually played.
- Source confirms Beta resolves Search before Debug; Marketing cards add project Marketing Output, while only an Insider Playtest card in this set deposits $1,000. Every extra Beta productive hand advances the calendar and may cross a real rent/other-dues boundary. The [cash-funded Beta shadow](2026-10-25-beta-shadow-runway-finding-v1.md) captures exit finance but does not validate any new duration/value rule.
- Headless candidate worlds, full-Scope blocked/recovery routes, new Reviews, player challenge, replay, Continue, CPU and save growth: **NOT RUN**. No numerical policy or gameplay balance is approved.

## Follow-up

Author a current-v3 private variant that supplies genuinely attainable Scope and exposes lawful unplayed inventory without future-RNG knowledge. Compare current behavior with the full-Scope gate and funded QA→Marketing policy separately and together. Preserve blocked/unaffordable cases, release frequency and same-calendar player market outcomes. Seal a handoff only after legal recovery, fresh-process replay/Continue and representative CPU/save evidence pass; then replace the item22 DESIGN entry with a narrowly QUEUED implementation request.
