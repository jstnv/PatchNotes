# Research action latency repair — 2026-10-27

## Scope and source

User requested fixing the reproduced laggy Research action. Baseline branch `main`, HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`, with substantial inherited uncommitted work. Existing edits and `.codex-godot-temp` preserved. One read-only reviewer was dispatched under the requesting-code-review skill; no implementation delegation, commit, push, public EXE/ZIP or Drive changes. [Curated findings](../findings/research-fix-20261027-v1/README.md) and hash-pinned [verification](../findings/research-fix-20261027-v1/verification.json) distinguish each measured source.

## Owned implementation

- `sales/released_game_sales.gd`, `finance/studio_finance_ledger.gd`, `market/market_transaction_trial.gd`: bounded exact positive validation proofs; finance checked-transition proof reuse. Newly advanced sales results retain full validation/replay.
- `simulation/decision_policy.gd`, `market/rival_trial.gd`, `market/rival_world.gd`, `simulation/development_session.gd`: opt-in narrow stock observations with lazy exit checks; ordinary external Callables retain full observations. Policy owner lifetime is explicit.
- `run_state.gd`, `ui/feature_store.gd`: one fresh Store view bundle, unchanged-style reuse, quote-fact/FIFO comparison before one authoritative productive-action preflight.
- `simulation/productive_cycle_plan_cache.gd`, `run_state.gd`: bounded pure sales/Fan calculation reuse; full entry guards, market-provider reads and finance planning remain. Support assessment computes afresh.
- `simulation/transaction_projection.gd`, `simulation/begin_project.gd`, `simulation/launch_settlement.gd`, `run_state.gd`: exact data-only comparison fingerprints, retaining object/RNG projection for live/mixed containers.
- `ui/gameplay_hud.gd`, `phases/studio_phase.gd`: signal-burst coalescing and avoiding hidden summary forecasting; opening/returning explicitly refreshes current data. Floating-score music timing retains the immediate presentation path.
- `ui/feature_store_map.gd`: retained full-gate failure exposed a Tween-started coroutine resuming after Store teardown. Bound one-shot callbacks preserve the two-frame camera/third-frame menu sequence and disconnect on free; revision/selection guards remain.
- `persistence/checkpoint_write.gd`: low-priority background worker; full validation/durability and departure wait remain.
- `market/rival_world_checkpoint.gd`: user-approved single exact preceding editor source, paired only with current player/rival content revisions. No generalized source bypass.

Paths above are relative to `patch-notes/scripts/`. Owned debug suites/original oracles and curated save/provenance fixtures are listed in the findings folder. Four existing UI verifiers now await actual coalesced refreshes; visible-summary checks explicitly open Summary. Source semantics/asserted values remain unchanged.

## Commands and observed checks

Interpreter: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`; engine: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.

1. `python docs/codex/findings/research-fix-20261027-v1/run.py <fresh-label> res://scripts/debug/<suite>.gd` — retained focused receipts include424 sales checks,63 finance,75 policy parity/24 boundaries,289 Store view,58 pure cycle-plan,12 fingerprints,10 Research preflight,12 refresh and1070 factor checks. Independent frozen originals exercise rejection, exact state/RNG equality, eviction, mutation, bounds and concurrency.
2. `.../run.py final-native-v2 .../research_latency.gd --native` — original queue120.452–166.015ms and Research311.455–457.432ms; original prior Research2229–2497ms. Expanded39-record/cycle192 Research599.300ms **FAILS unchanged500ms screen**. Background durability still validates, but native wait reaches78s. Poor native idle cadence is separately retained. No60FPS guarantee.
3. `.../run.py compatibility-production res://scripts/debug/verify_research_compatibility.gd` — **10 checks,0 failures**, ordinary production restore (no captured-source override). Full persisted player/world/RNG equality; unknown source, corrupt rival finance and old player/rival revision pairings reject.
4. `.../run.py sales-ui-correction ...verify_sales_earning_and_settlement.gd`, `year-ui-correction ...verify_sidestreet_scope_and_year.gd`, `finances-ui-correction ...verify_studio_finances.gd` — **PASS**, including118 finance UI assertions. Earlier history correction also passes.
5. `python tools/release_gate.py --godot <engine> --output docs/codex/findings/research-fix-20261027-v1/final-gate-v2 --isolate-checkpoint-writer` — **168 suites PASS, then FAIL** at `verify_research_ui_refresh`: its12 assertions passed but runtime-error scanning caught a freed `_finish_focus` coroutine. This is not a full-gate pass. Per-verifier private profiles/writer47733 protect player saves; production writer62741 is not tested by the wrappers.
6. `git -c core.whitespace=cr-at-eol diff --check` — final **PASS, exit0**; `verification.json` retains the command output. Ordinary configured Windows line-ending warnings do not represent whitespace failures. Final branch/HEAD remain `main/f3e0f2b5d35270c879327bc297b389748571feb4`;83 tracked dirty files include inherited work, preserved without staging/commit/push.
7. `.../run.py focus-lifecycle-tween-before res://scripts/debug/verify_store_focus_lifecycle.gd` — deterministic predecessor **FAIL**, three runtime errors at all pending await sites despite its six raw assertions passing. The direct-call-only predecessor probe did not reproduce the bug; the actual Tween path was necessary. `focus-lifecycle-after` and `focus-lifecycle-native` pass six checks without runtime errors. Extended `focus-frames-final` and `focus-frames-native` pass **9 checks each**, including exact frame timing and replacement completion.
8. `python docs/codex/findings/research-fix-20261027-v1/check_post_focus.py` — affected and remaining checks on the repaired source, with cold producers included. This is explicitly **not** a fresh full single-source gate. `source-transition.json` proves only `ui/feature_store_map.gd` changed among the preceding gate's existing project files, plus one added debug test; earlier168 receipts keep their earlier source. Current results are in `verification.json`.
9. Closeout of (8): **72 suites PASS,0 failures, no source drift**. Union with the earlier168 is235 unique maintained verifier names, not235 uninterrupted final-source jobs. Current runtime `e3b0d13708d22ce1755a99012dad6a6fbdc13cb5a4a28f47e6734d3a2a327421`.
10. `python .../export_current.py` — clean internal Windows export, **438-entry PCK/hash audit, headless and graphical startup PASS**, no source drift. EXE SHA `ab693d9e0b22a163fab8ed4fe70b83f152600313fd2730c8b101131c872078dd`; external PCK SHA `d231f292d0ea4b7436b59ec367ae72b1549ea4e73b255978c5b1bece9e2ad6da`. This is an internal Demo build; no new public ZIP, final-package Research timing or full release acceptance.
11. `python .../final_campaign.py` — final-source fresh saves on seeds1104/4417/90210: **138 matched scene/headless boundaries, three routes, two real releases each and exact replay PASS**. Current12-Scope rosters and ordinary Ironclad funding; no extra financing. Source stable. Physical pointer/audio/visual acceptance is outside this scene-method test.

## Retained failures and approval decisions

The first full gate retained115 passes then failed an immediate Summary-label assertion before the deferred refresh. The remaining-suite preflight exposed three similar UI tests; all focused corrected reruns pass. Its last cold-consumer lacked the earlier producer because the preflight started halfway through; this is retained, not represented as a full gate.

A proposed shortcut certifying new sales results without complete replay was rejected by automatic approval review and was never applied. Two earlier attempts to admit the preceding editor save identity were rejected as requiring explicit persistent-compatibility authorization. The user subsequently **explicitly approved the single compatibility entry**; production code now contains exactly that entry and the ordinary-path ten-check test passes. There is no outstanding permission request for that approved entry.

The original internal EXE diagnostic predates later improvements and chose different legal actions; it is not a final-source matched-action timing result. No public package update or final-package Research acceptance is claimed.

## Independent source review

One read-only review found no confirmed actionable correctness defect in the owned changes. A separate follow-up review of the focus teardown correction also found no actionable defect and confirmed the retained2+1 frame sequence and auto-disconnect ownership. [Review scope and exclusions](../findings/research-fix-20261027-v1/REVIEW.md). Root retains every stated performance/package/device/balance boundary; the review did not execute tests or imply gate success.

## Remaining work

Original multi-second Research regression is substantially reduced. Expanded-history/native500ms acceptance and long background-publication latency remain **OPEN**. Keep exact rules/RNG/full sales and finance validation, all history and the Studio-only Continue boundary. Profile further before promising a blanket no-hitch result. Human/device audio, final balance and whole-release acceptance remain separate.
