# Starwave implementation — resumable status

**Current follow-up:** the later non-Computer-Use resumption completed the native work below. [Final evidence and source pin](../findings/starwave-implementation-v1/README.md):1190-file final source, final native route pass,10 fresh process passes,52,934 independent audit checks, headless UI/input checks. Parent's combined automated gate is in progress; actual exported interaction/rendered review remains deferred overnight. The stopped-state sections below are historical and preserved.

2026-10-09 (America/Los_Angeles). Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Preserved current Fanbase implementation and other queued work. Sole gameplay writer slot began after Fanbase writer released it. Work stopped at the parent's request after Computer Use reported physical Escape; no further implementation or test was started after that instruction.

## Implemented locally

- `PublisherTrialTerms` adds the approved Starwave Scope14/Core7,112-denominator,$2240-cap,zero-advance/zero-Promotion terms and frozen three-hand count.
- `ContractState` uses the frozen per-offer count; previous publishers stay at two. `RunState` issues one immutable aggregate-gate offer with empty source-release identity, accepts current frozen quotes and completes without adding a Promotion entry.
- Typed checkpoint validation recognizes Starwave, verifies three prior distinct non-Starwave completions, exact three-hand receipt ordering and result arithmetic. A new `starwave1` content revision rejects unsupported old bytes without migration.
- Checkpoint hand counting now excludes productive priority changes. Failed Contract redraw restores the RNG stream. Both are covered by the focused Starwave verifier.
- Chooser, browser, Contract status/result and tutorial text show three hands and cash-only terms. Existing Promotion is preserved.

Changed runtime files: `publisher_trial_terms.gd`, `contract_state.gd`, `run_state.gd`, `checkpoint_schema.gd`, `studio_checkpoint.gd`, `contract_phase.gd`, `studio_phase.gd`, `publisher_catalog.gd`, `tutorial_overlay.gd`. Added maintained `verify_starwave.gd`, updated `verify_publisher_browser_states.gd`, and added `starwave_native_route.gd`.

## Checks and failures preserved

[Evidence directory](../findings/starwave-implementation-v1/). Runner: `python docs/codex/findings/starwave-implementation-v1/run.py focused`, using Godot4.7.1 and isolated APPDATA/LOCALAPPDATA profiles. All13 listed suites exited0 without runtime error: Starwave; publisher trial offers/cash/Promotion/liquidity/browser; Publisher Connections; Ironclad; SideStreet; Studio checkpoint; checkpoint RNG; Fanbase checkpoint; Feature Research. `focused-results.json` records false for each failure flag, meaning pass.

The Starwave suite covers exact0/half/full/capped payout, constructed zero-score completion, native three-hand draw/retention/exhaustion at1152×648 and1280×720, failed-redraw RNG preservation, a productive priority change, once-only receipt/identity, no Starwave Promotion, existing banked awards and next-launch consumption, same-process typed roundtrip and corrupt hand-count rejection.

First import caught one inferred-type parser error in `prior_completions`; explicit typing repaired it. The subsequent import had no compile errors and only the known root-certificate diagnostic. First new test incorrectly called `duplicate()` on RefCounted CardData; fixed by constructing explicit fixture cards. Its failed log remains. One standalone `--check-only` triggered the known Godot signal11 compiler issue; exec session47312 was stopped with Ctrl+C and exited1. No repeated check-only invocation. Normal runtime verifiers compiled successfully. Placeholder-art warnings remain.

Targeted `git diff --check` passed (line-ending notices only). No commit/push/release readiness claim.

## Genuine native route and export seed

`starwave_native_route.gd` uses seed1104, Action, Lean/Buzz/Lease, synergy policy, existing legal native production/Contract APIs and declared contract RNG31104. It earned releases5.8→7.3→7.8, completed Ironclad→Crown→Neon, then earned the Starwave offer. A genuine pre-acceptance Studio checkpoint is preserved as `before-starwave.payload.json` and the ready storage envelope `before-starwave.checkpoint.1.json`, with SHA256 in `checkpoint-hashes.json`. This is not injected eligibility or cash. Neon18 Promotion remains pending. Source/action/finance/Fan traces are in `native-route.json`.

The route then legally completed all three Starwave hands, Scope20, numerator111/112, payout222000c, Promotion0. Next game Review8.1 launched and consumed the existing Neon18 award. Completed-Contract and next-launch checkpoint captures succeeded.

**The overall route is still failed/incomplete:** its optional later earning tail reported `earning priorities` after attempting an initial priority commit on an already planned Design phase. It continued to cycle78; preserve this failed attempt rather than relabeling it a pass. The early Bank quote was ineligible and accepted=false; Production hire succeeded. Native Bank exposure must therefore still be added at an actually eligible boundary. No separate-process Starwave restore or independent finance audit has run yet.

## Resume next

1. Correct only the route's optional earning-tail initial-priority check, preserve this attempt, and finish genuine post-launch settlement plus an eligible Bank case.
2. Add corruption cases for frozen terms/receipt/identity and an actual zero-payout RunState completion count (current zero case is ContractState-only).
3. Run separate-process acceptance/hand1/hand2/completed-before-dismissal rollback, durable dismissed completion, future RNG and next-launch restores, preserving original Studio bytes on invalid payload.
4. Inspect rendered chooser/Contract/result at both supported sizes; current size checks are native state/UI text checks, not visual acceptance.
5. Freeze gameplay, capture final source hashes, and ask parent to run combined maintained gate and actual exported Continue/three-hand/restore/next-launch route from the genuine earned seed. Parent owns shared TODO/CURRENT_STATE updates.

All processes from this subtask have ended: focused session31097 exited0; native-route session26113 exited1; the check-only session was interrupted as above.

## Resumption after Computer Use was held

User clarified that Computer Use should wait for overnight work. Parent authorized remaining non-Computer-Use Starwave work. No Computer Use, visible interactive app or additional check-only invocation was used.

Native-v2 fixed the optional earning-tail initial-planning guard and accepted a genuinely eligible late Bank quote. Independent review then found a malformed initial-deal RNG failure in the reused Contract path; setup now validates roll values before binding and failed partial deals restore RNG. Added focused assertions pass. Main gameplay was frozen after that fix. Native-v3 pins1190 current project files and repeats the complete legal route on that final source.

Final route: start$5,650; Reviews5.8→7.3→7.8; Ironclad/Crown/Neon complete; cycle54 pending Starwave plus Neon18, actual$500/12-month Bank acceptance and hired Specialist. Starwave completes at57 with111/112 and$2,220; first Bank due56 occurs before that completion receipt. Next launch at75 Review8.1 consumes only the pre-existing18 Promotion; next-project work reaches78 and the Bank schedule closes with$500 principal/$32.50 interest. Native finance remains valid with rent/payroll/settlement together.

Final ten processes independently verify unsaved acceptance/hand1/hand2/completion rollback, deterministic repeated native deals and effects, durable dismissal, cold Continue and the next genuine release/Continue. Corrupt terms, count, identity and receipt fail without changing the valid generation. Added zero-payout RunState count and roundtrip cases pass. A separate constructed adverse-liquidity fixture verifies early hands cannot use future cash and completing income can clear original rent debt.

Final focused commands and process exits are in the evidence directory. Additional commands: `python .../run.py restart native-v3` (ten stages, all0) and `python .../audit.py` (52,934 independent checks, exit0). `verify_starwave_ui` runs headlessly: mouse/keyboard/animation and layout bounds pass at both supported sizes. These are not rendered captures or exported visual acceptance. The final storage-envelope hash and precise overnight continuation instructions are in the evidence README.

Runtime/test source remained frozen while parent started the combined headless gate. No shared TODO/CURRENT_STATE/DECISIONS edits were made by this subtask. S5's actual exported interaction remains deferred; final balance remains ACTIVE/TRIAL / OPEN as documented.

Final acceptance classification: S4 headless text, layout bounds and native input checks are complete; rendered inspection remains pending overnight. S5 native route, independent audit and ten fresh-process checks passed; the full maintained gate is parent-owned and still in progress, and actual exported input remains pending overnight. The first combined gate exposed a stale synthetic Fanbase fixture in `verify_monthly_sales_report`; parent is preserving that failure and repairing only the verifier before a fresh gate. The native-v3 source pin predates that reporting-test-only edit; its gameplay source and native evidence remain unchanged.

## Exact source preservation follow-up

Parent requested reproducible native-v3 provenance after three reporting-verifier fixes changed the worktree. No gameplay/debug/main files were edited in this follow-up. `pin_source.py` verified all 1,190 original hashes before creating a complete copy at `C:/Users/64jus/Downloads/Patch Notes Design Folder/starwave-native-v3-pinned-source`: 1,187 current files, two exact Git HEAD blobs (`verify_game_lifespan_trial.gd` and `verify_sales_earning_and_settlement.gd`), and the exact monthly-report verifier from the earlier Fanbase source copy. The initial HEAD-only monthly mismatch is preserved in `source-pin-attempt-v3.json`; recovery needed no normalization or synthesized bytes.

All copied hashes were checked again after writing. The 1.10 GB full copy stays in Downloads. A 622,862-byte supplemental scripts/scenes/data/project/export archive is retained in evidence; it is explicitly partial. The complete recovery record and archive hash are in the evidence README. Original `source-manifest-v3.json` and `audit-summary-v3.json` are unchanged.

`audit.py` now reads the complete pinned source/card ledger and a local frozen finance auditor, preserving its original version separately. Command `python docs/codex/findings/starwave-implementation-v1/audit.py` exited 0 and wrote distinct `audit-recheck-v3.json`: the same 52,934 checks (1,850 logic/source checks plus 51,084 finance checks), unchanged checkpoint hashes, ten prior process results. This is a provenance reproduction of the native run, not a new gameplay run or an assertion that later test fixes are part of the earlier source pin. No live process remains from this follow-up.
