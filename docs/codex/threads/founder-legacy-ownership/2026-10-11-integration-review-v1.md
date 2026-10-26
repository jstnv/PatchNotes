# Founder integration review — 2026-10-11

**Complete at Handoff v3's read-only integration-review scope. Gameplay, world persistence and calibration remain unimplemented.** Reviewed on `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, with existing soundtrack/design edits and the implementation thread's two-parent Store work preserved. [Exact inspected file hashes](2026-10-11-integration-source-v1.json) distinguish current bytes from HEAD. No simulation or performance result is claimed for this review.

Authority: [Handoff v3](HANDOFF-v3.md), [v2 milestones](HANDOFF-v2.md), [SPEC v2](SPEC-v2.md), [share-sale/control amendment](2026-10-11-share-sales-and-control-v2.md), and [two-boundary founder transition](2026-10-11-founder-role-transition-v1.md). The current task authorizes this assessment, not the dependent corporate gameplay.

## Current source and reuse

| Surface | Current authority | Integration consequence |
|---|---|---|
| Time, productive effects, sales, Fans and bills | `run_state.gd::_plan_productive_cycle`, `complete_productive_action`, `can_transition_without_productive_cycle` | One local Run cycle plans sales/Fans/finance, commits the callback once, then publishes signals. Calling this separately for rivals would let each Studio own time; this is not the selected world clock. Preserve direct-cash preflight before settlement and exact-once effects. |
| Legal player/AI command surface | `simulation/campaign_session.gd::_execute`; `development_session.gd`; `contract_session.gd` | Existing command freshness, phase state, RNG and event ordering are reusable. A session represents one Studio. No founder authority, corporate commands, world transaction or idle rival calendar adapter exists. |
| Finance | `studio_finance_ledger.gd::plan/_apply`, `outstanding_expenses.gd`, `bank_loan.gd` | Typed arrears, original dates, payment allocation, credit, principal/interest and exact quotes already exist. Ordinary Bank eligibility must remain based on actual settled sales. Founder startup underwriting is a distinct future command; it must not call initial Studio funding twice. |
| Release identity and forecasts | `launch_settlement.gd`, `run_state.gd::register_release`, `released_game_sales.gd` | Frozen launch records and real earned/settled receipts can support future IP forecasts. Current accounting does not supply the required rights register, non-IP recurring valuation model or intercompany eliminations. Forecasts must never enter cash. |
| Save boundary | `checkpoint_coordinator.gd::entered_studio/before_departure/flush`, `studio_checkpoint.gd::capture/hydrate`, `studio_checkpoint_store.gd` | Existing writer lease, atomic save/backup and failure guard protect one Studio. Active Contracts cannot be captured. The coordinator enforces when development may be saved; the codec alone has no active-project object. A world envelope needs explicit session/boundary validation, not merely several calls to the Studio codec. |
| Rivals | `market/competitor_definition.gd` plus AI Competitors current Handoff and October 11 rulings | Canonical competitor metadata/snapshots are not persistent rival companies. G1a cohort/provenance/migration, G2 exact search/envelope, G3 due projection, G4 objective/exit/recovery, and G5 news/load bounds remain dependencies. Private rank/$2,500-floor values were rejected for final adoption. |

## Route to an operator handoff: exhaustive state classes

These are source-derived reachability conditions, not a claim that every possible generated state was simulated. A pending control transaction cannot silently make a legal exit available.

| Current manual session | Legal route to durable Studio | Unaffordable/blocked continuation |
|---|---|---|
| Quiescent Studio, no active Contract | Flush existing pending actions; future role reassignment and full-world snapshot must commit atomically before exposure | Save/writer failure leaves the old operator and pending role review intact. No operator transfer on a failed write. |
| Design before initial deal / active hand | Begin the existing legal deal if needed; request Design exit; enter Alpha | Design exit adds no productive cycle. It does not ensure any Feature was implemented. A currently animating committed hand must finish presentation before UI departure; do not replay its command. |
| Alpha before deal / active hand with implemented Feature work in Design or Alpha | Begin if needed, request exit, confirm under-Scope warning, enter Beta | `can_finalize` uses `can_transition_without_productive_cycle`, so arrears alone do not block this free exit. Project/history/state guards still apply. No compulsory extra hand or QA spending is justified. |
| Alpha with no implemented Feature in either phase | Resolve a legal Feature hand, then take the route above | **Hard blocker:** `has_launch_feature_work` forbids exit. If all available legal Feature hands are unaffordable or blocked by arrears and no legal income/financing recovery exists, there is no guaranteed route. Redraw/priority actions do not create money and may themselves be blocked. Finite AI deferral is not a founder handoff. |
| Beta before deal / active hand | Begin if needed; request and confirm launch warnings; finalize Beta; settle launch and enter Studio | With valid prior Feature/Alpha histories and snapshots, further Beta production is optional. Unpaid bills/bugs/low scores can warn without requiring an extra productive action. Corrupt definitions/histories remain errors, not a migration escape. |
| Exit confirmation / already finalized phase | Confirm the existing legal exit (or cancel back to that phase), then enter the next phase; after Beta use launch | Confirmation grants no additional cash and does not bypass finalization guards. Launch is once-only and free; it does not settle a month on its own. |
| Accepted Contract before deal / between hands | Begin, play exactly the remaining legal four-card hands, then dismiss completed result to Studio | **Conditional blocker:** each hand must pass the ordinary productive finance plan. If prior blocking arrears remain after the available legal receipt and settlement, the hand is rejected. An intermediate zero-receipt hand cannot borrow the final payout. Contract cancel/abandon does not exist. |
| Completed Contract, result still open | Dismiss result; then durable Studio checkpoint | Dismissal pays nothing again. The pending role review must wait for this boundary, not serialize the active result as a new mid-Contract Continue kind. |
| Any save/definition failure | Existing recovery/error flow; restore only the last valid Studio checkpoint | Continue rolls back unsaved project/Contract work; it is not a way to preserve a newly committed world takeover while discarding its unfinished manual work. World rollback must include every Studio and ownership event together. |

The first-sale ordinary Bank gate cannot guarantee recovery of a broke first project. The continuity permit also explicitly withholds new borrowing authority; a future governance request is not an approved loan. Therefore F6's universal safe-handoff obligation is **not currently satisfiable**. The owning Founder/AI design threads must select a legal insolvency/blocked-work policy before forced departure is implementable. Do not add a mid-phase cancel, free cash, erased debt, automatic Contract completion or a second manual team.

## F0–F7 disposition

| Milestone | Disposition and dependency |
|---|---|
| F0 | Source/dependency and boundary audit complete here. Numeric calibration remains OPEN. No private cohort, hand count or CPU limit is promoted. |
| F1 | Existing scene-free one-Studio engine is reusable. Requires an explicit world tick transaction, stable Studio order, idle-calendar servicing, launch-boundary eligibility and rollback of all participating RNG. AI G1–G4 policy gates remain upstream. |
| F2 | Requires F1 state ownership, explicit world-safe boundaries and a versioned world envelope. Legacy conversion cannot finalize until historical cap-table attribution and exact supported source versions are selected. Preserve original save bytes and writer semantics. |
| F3 | Exact rational shares/control can later be implemented as a pure validator independently of numerical valuation. Runtime adoption still needs entity IDs, transaction ordering and cross-Studio cash journals. Exactly 50% is no direct majority; founder consent and authorized issuance remain mandatory. |
| F4 | Blocked on calibrated starting budget, underwriting and valuation components; requires F2/F3 formation identity and actual financing journal receipts. Old Studio cash, education debt and IP never follow the founder. |
| F5 | Requires F1/F3/F4 plus approved buyer/seller quotas, premiums, warning rules and measured populations. Six-cycle evaluation must use stable work quotas rather than elapsed-time cutoffs. |
| F6 | Requires F1/F2 and resolution of the Alpha/Contract hard blockers above. Role decisions, permits and owner-approved Bank requests must be represented explicitly. Former-Studio AI continuation is unimplemented. |
| F7 | Requires the preceding world/role/save model, milestone content and measured long-horizon bounds. Endless Continue is direction, not a proven stable runtime. |

## Recommend one narrow first extraction

Extract the existing **one-Studio productive-cycle projection** into a scene-free `simulation/run_cycle_plan.gd`, taking an explicit immutable snapshot (cash, local cycle, released records, Fanbase, finance), direct cash delta, campaign ID and finance/source identifiers, and returning the same preflight plan or rejection. Keep `RunState.complete_productive_action` as the sole committer and notification publisher. Move only the calculation now in `_plan_productive_cycle`; retain the reentrancy/checkpoint guards in RunState.

This first slice changes no world clock, AI policy, idle behavior, founder identity, saving, funding or migration. It creates the calculable unit required to design a later atomic multi-Studio tick without prematurely scheduling rivals. A caller must not use it to advance an idle Studio until that distinct command and finance semantics are approved. Prefer this over introducing a partially functioning ownership UI or wrapping multiple independently advancing RunStates.

Proposed exact extraction checks: old/new plan equality from identical state and RNG for non-month/month boundaries; positive, zero and negative direct cash; one-cent short rejection; released-title age zero and first eligibility; partial rent/payroll/Bank/education service and original due dates; Fan gain/loss; Research completion and Resourceful; callback failure and reentrancy; MAX_INT overflow; identical emitted order and native/headless snapshots; existing fresh campaigns/replay and cold Studio Continue. Add a poisoned-input immutability test. No performance claim until measured. **Not implemented by this review.**

## Migration and unresolved owners

- Keep current `StudioCheckpoint.RULES`, supported legacy migrations and Studio-only Continue unchanged for the extraction. A later world-format version must be explicit; never rewrite `content_revision` to make old bytes pass.
- Founder owns formation allocation, majority/mandate governance, mandate term, exit reputation, milestones and blocked-work policy. Banking owns startup underwriting coefficients/budgets and liability interpretation. AI Competitors owns cohort/provenance, finite legal policy, entrants, news threshold and population/CPU bounds. Feature Pools/Store retains era and card rollout decisions.
- A future pure converter must prove exact old cash, journal, debt, traits, Fans, release IDs, RNG and one-time funding before/after. Historical outside-equity attribution must introduce no receipt or callback. No supported world migration, rival parity, transaction conservation or CPU benchmark is claimed here.

Checks for this pass: inspected listed current source and design authorities; generated SHA-256/Git-blob manifest; reviewed the legal command branches and negative exits. No Founder simulator variant, code, commit, push or cross-thread dispatch.
