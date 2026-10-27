# Temporary Insider hold and75 priority cap — 2026-10-26

Direct request: temporarily disable Insider cards/priorities and let priority sliders reach75, without user input. Interpreted priorities as **Insider priorities**, preserving other planning controls. Read current state/TODO, relevant design and source; inspected shared dirty `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`, status and diff. Preserved concurrent work, exports, player saves and `.codex-godot-temp`. No commit, push or rebuild.

## Current rules and source

Implementation is ACTIVE/TRIAL, not final balance. [Audit](../findings/insider-hold-20261026-v1/audit.json) lists all30 changed runtime/scene/verifier files with final hashes, exact run commands, results and the original checkpoint hash. [Findings](../findings/insider-hold-20261026-v1/) retain failed attempts and rendered evidence.

- `phases/beta_priority_allocation.gd`: one code-owned `gameplay/beta/insider_enabled` setting defaults false. New Beta defaults QA50/Marketing50/Insider0; new commitments reject positive Insider weight. Keep the three-key storage shape and strict typed/step/total validation. Historical positive Insider weights and5-point floors remain readable. Only an editable draft proportionally redistributes QA/Marketing to five-point steps, clamped25–75, with Insider0; hydration never reweights a saved object.
- `simulation/beta_hand_command.gd`: shared initial/redraw/refill grouping excludes disabled Insider definitions; retained Insider execution rejects before effects/RNG can commit. Original nine definitions and resolver remain for historical decoding and explicitly enabled isolated variants. No card-ledger deletion, rewritten past outcomes, replacement synergy or compensating income.
- `phases/beta_phase.gd`, `ui/priority_overlay.gd`: hide the Insider column, bind the pie/budget feedback to the two active sliders, prevent Insider edits and disable a retained Insider hand's Play action. New Beta planning supports75/25 and25/75. Existing priority-change cost/candidate behavior is retained.
- `phases/priority_allocation.gd`, three phase scenes, `ui/predevelopment_overlay.gd`, `ui/employee_planning_dialog.gd`, `phases/contract_phase.gd`: cap sliders/validators at75. Preserve10 minimum, five-point steps and exact100 total. Consequently a four-category plan's legal maximum remains70;75 plus three10s is an invalid over-budget draft. Existing red budget animation remains.
- `market/rival_trial.gd`, `market/rival_beta_synergy_choice.gd`, `simulation/finite_fixture_policy.gd`: skip retained disabled Insider candidates instead of submitting illegal hands. Snapshots keep their actual candidates; no save-time card replacement.
- `ui/phase_workspace.gd`, `ui/how_to_play_content.gd`, `ui/tutorial_overlay.gd`: describe QA/Marketing and the hold,75 ceiling, unchanged production synergies, and unavailable Balanced Operations. QA and Marketing Specialization formulas remain untouched.
- `market/rival_world_checkpoint.gd`: admit only the exact immediate predecessor `f479c5b654d756972e5cb822756328ae3fae7eff2fdf66eb4e7badf967d20311` in addition to existing known sources. Preserve full current schema/content/ownership checks and reject unknown sources. This is prospective behavior; no claim of identical future outcomes under changed rules.
- `debug/verify_insider_hold.gd` covers default held behavior. Planning/Host Playtest fixtures use the new allocation. Eight retained historical Beta suites explicitly enable the old pool within their isolated process, preserving its resolver/oracle evidence without reenabling ordinary play. `verify_campaign_session.gd` now explicitly funds its fixed mechanics/replay fixture with a synthetic$20,000 bootstrap receipt; it is not a legal earning route or solvency check. `verify_priority_influence.gd` exercises the current two-slice75/25 UI.
- Shared design, decisions, current state and TODO record the new temporary rule, exact100 constraint and separate economic observation. Unrelated employee research design remains unimplemented and preserved.

## Verification

Godot4.7.1; separate profiles under `.codex-godot-temp/insider-hold-<label>` and private test writer ports. Run `python docs/codex/findings/insider-hold-20261026-v1/run.py <fresh-label> res://scripts/debug/<verifier>.gd`. Native capture uses the findings' absolute `capture.gd` path plus `--native`; fresh PNGs remain in this findings folder, not an old capture directory.

| Default held-rule check | Result |
| --- | --- |
| Draws/refills, old weights, rejected Insider effects/RNG, live/headless hand equivalence, retained-candidate policies, all slider surfaces, `hold-complete-v2` | PASS82/82 |
| Planning charts/drafts/commit/cancel at1152×648 and900×600, `priority-chart` | PASS306/306 |
| Native OpenGL planning/captures, `priority-native` | PASS316/316 |
| Host Playtest, corrective passes and75/25 priority change, `beta-host` | PASS |
| Marketing Specialization, `beta-marketing` | PASS |
|10% floor, budget pulse, Contract sliders/pie, `priorities` | PASS |
| Scripted tutorial/current Studio state preservation, `guided` | PASS115/115 |
| Rival20-cycle progression, active-world capture/restore and two releases, `rivals` | PASS120/120 |
| Funded fixed three-project campaign and deterministic replay, `campaign-funded-v2` | PASS81 commands/42 reentry checks |
| Actual pre-edit Studio pair capture / fresh-process restore, `baseline` / `cold-restore` | PASS2/2 and10/10 |
| Scoped CRLF-aware source diff check | PASS |

Opt-in historical checks all PASS: `beta-planning-legacy`, `beta-base-legacy`, `beta-balanced-legacy`, `beta-state-legacy`, `beta-finance-legacy`, `beta-qa-legacy`, `beta-launch-legacy`, `beta-command-legacy`. The latter retains84 exact legacy headless/oracle scenarios. These are explicitly **not** acceptance for drawing or resolving Insider under the default hold.

Native captures include75/25 with only QA/Marketing controls, four Core screens and Contract planning. Opened/inspected the actual Beta1152 capture: both labels, values, controls, pie, total and Begin button are visible. Old-pair restore preserves exact player/finance/RNG and world except the new executable-source marker, leaves original/generation bytes unchanged, publishes no replacement generation and rejects an unknown source. Coverage is one fresh pre-edit Studio pair, plus current active-world progression; not every historical/compiled save.

## Retained failures and open acceptance

- The initial red run showed the expected old ceiling/Insider pool failures, then a test harness untyped-empty-array error; it was interrupted. Do not call it a clean completed red receipt. Corrected typed arguments; final focused verifier exits normally. Subsequent parity probing found different randomly created project IDs; the paired fixture now explicitly uses the same project ID and seeds. It then agrees on project effects, cash, RNG and refill identities. No runtime effect ordering was altered to satisfy that test.
- Two initial retained-policy assertions assumed slot indices were instance tokens. Corrected the harness to assert the actual captured tokens; both real policies skip the three retained Insider instances.
- The original fixed three-project recipe with no extra funds runs out of cash in Game2 Beta, cycle14. A legal Family Funding-only variant still runs out. These FAIL receipts (`campaign`, `campaign-funded`) are retained. The separately synthetic-funded fixture passes mechanics/replay; **ordinary solvency and balance are OPEN**. No prices, rent, Bank, loan eligibility or rewards were changed to avoid the failure. Contract/loan/other legal alternative routes were not evaluated here.
- Existing six ObjectDB exit warnings and deliberate rejection warnings remain in relevant logs. A read-only CIM process inventory was unavailable; no escalation or process deletion was performed. This is not a release or performance gate.
- Other historical full-matrix/seeded routes were not rerun or reconciled wholesale. Positive Insider commitments in an old unopted test/policy now correctly reject; current/default checks above are separated from explicitly opted-in historical coverage. Exported EXE/ZIP remain unchanged; broader balance/device/release acceptance is not claimed.
