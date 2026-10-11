# Education E1–E4 implementation — 2026-10-09

## Repository and authority

Local `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, shared dirty worktree preserved. No commit or push. Approved activation, payoff, reserve, action-sequence and old-preview conversion rules come from the Banking handoffs dated 2026-10-09. Parent owns shared TODO/CURRENT_STATE/DECISIONS reconciliation. Computer Use and visible app interaction are deferred until the authorized overnight session.

## Implemented

- New Studio trait version **6** activates College Dropout (+2 points, $5,000 liability) and Graduate (+6 points, $20,000 liability). Principal is never deposited. Existing unspent-point financing pays once. Saved v3–v5 education previews retain their exact old inactive effects and point receipts.
- New pure `scripts/finance/education_debt.gd` defines owner-bound identity and the fixed 96-installment schedule. No bill/interest during the 12-month grace; first cycle 26, final cycle 216. Actual arrears never replace the scheduled opening principal. Dropout pays 95×$70.68 then $71.11; Graduate 95×$282.73 then $283.28, with approved total interest $1,785.71/$7,142.63.
- Finance schema **6** integrates original-date bills, integer interest-first payment splits, original-month expense and actual-month cash, existing student-loan credit aging, merged Bank/education ordering, productive recovery gates, future-cost guidance, and term-specific Bank capacity reservation. Ordinary Bank elective payoff retains its previous rent/payroll/Bank path.
- Education payoff is a separate zero-cycle atomic action. Its required cash includes already-due rent/payroll/Bank; those bills precede due education interest/principal and residual future principal. No future interest, fee, instant credit gain, or future bills after closure.
- Main-menu debt preview and a separate Finances Education tab display liability, cash, grace, installments, due/paid history and full payoff cash. Bank confirmation wording names rent/payroll specifically.
- Typed persistence validates education ownership, trait/version, schedule, counters, payment provenance and original point-funding receipts. Only the exact immediate pre-education Fanbase+Starwave revision is converted, using full finance replay and unchanged old bytes until normal new save.

New content revision: `19e79e7fdd6378fc80abfbade73f63943014e43ad88ef0441fe92ac217919127`. Rules: `finance6-bank1-employees1-traits6-sales1-contracts3-research1-review2-fanbase1-starwave1-education1`. Supported previous revision: `c7f6f3165ea85f7afd5070042d053ce581f84338437640c3e4b6de787c1f5a5b`.

## Files owned by this implementation

Runtime: `scripts/finance/education_debt.gd`, `studio_finance_ledger.gd`, `feature_spending_guidance.gd`; `scripts/studio_traits.gd`, `run_state.gd`; `scripts/persistence/checkpoint_schema.gd`, `studio_checkpoint.gd`; `scripts/phases/main_menu.gd`; `scripts/ui/studio_finances.gd`.

Verification: new `scripts/debug/verify_education_debt.gd`, `verify_education_edges.gd`, `verify_education_atomicity.gd`, `education_native_route.gd`, `education_restart_probe.gd` and generated UID sidecars; updated default-version/cash expectations in `verify_studio_traits.gd`. Independent UI/audit and legacy drivers live in findings, without gameplay edits.

## Native checks and independent review

Evidence: `docs/codex/findings/education-implementation-v1/`.

| Accepted check | Result | Duration |
| --- | --- | --- |
| focused-v4 | 1,175 checks, 0 failures, both full 96-line schedules and long-horizon finance replay | 97.532 s |
| atomic-v1 | 36 checks, 0 failures; exact one-cent shortage, stale/repeated/typed quote rejection, all persisted RunState/RNG equality, forged startup receipt and corrupt owner/terms/counters | 2.265 s |
| edges-v3 | 290 checks, 0 failures; chronological mixed debts, Bank tie priority, full elective reserve, final arrears and immutable private-vector capture | 23.407 s |
| native-v1 | Three genuine seeded releases (Reviews 5.8, 7.3, 7.8), cycle 54, naturally eligible Bank acceptance and earned-cash education payoff | 23.969 s |
| restart-v2 | 13 independent OS processes, 325 assertions, 0 failures | 141.486 s total |
| affected Bank finance | Pass | 1.938 s |
| affected Bank integration | Pass, headless controls | 6.328 s |
| affected Studio traits | Pass | 5.437 s |
| affected spending guidance | Pass | 5.547 s |
| affected Studio checkpoint | Pass | 5.047 s |
| parent UI ui-v3 | 288 checks, 18 text/rect captures across 1152×648 and 1280×720 | 21.281 s |

Native-v1 has no injected money: normal selected-trait startup, played releases/contracts and real Bank principal only. It pays $4,412.86 education principal at cycle 54 and ends with $11,989.61. A separate legal creation cohort pays education during grace. The genuine pre-payoff Studio envelope is `before-education-payoff.checkpoint.1.json`, SHA-256 `87e84a62d0815c2bd90c35b8453be44fda9a6eb4535e76045ad262add11bc611`: cycle 54, cash $16,402.47, active Bank and education. This is the preserved overnight exported-input seed.

The active restart chain covers creation, month 12, first 100-cent partial interest payment, education-only productive continuation, recovery, final due 96, continued final arrears, final recovery/no bill 97, and independent closure restore. Its long horizon is explicitly funded through journaled fixture actions, not balance evidence. The separate native branch uses the genuine earned Studio seed, proves an unsaved Design-phase payoff rolls back, then saves payoff and cold-restores closure while Bank stays active. Corrupt save attempts cannot replace the good generation.

Independent native arithmetic audit: **53,722 checks**, 61 distinct route ledgers, pass. Independent old-save acceptance: **16 fresh processes/975 assertions + 6,715 offline checks**, seven genuine v3–v5/ordinary old saves, strict rejection/recovery and exact original bytes. Rich legacy control adds **2 processes/29 assertions + 81,694 structural checks**, preserving all old cycle-54 Bank/payroll/Contract/Fans/18-Promotion/RNG state. UI review found no runtime defect. Parent UI details are in `UI.md`.

Final independent **`audit-education-v1.json`: 208,895 checks passed**, covering the 192 schedule lines, 23 finance cases, four declared private ordering vectors, 61 native route snapshots, all 13 active restart processes/325 assertions, atomicity provenance and 16 E4 compatibility processes. The corrected edge capture reconciles exactly. All 11 prior saved-generation hashes reconstruct from captured canonical envelopes; five still-retained originals also match their exact bytes. The genuine native payoff branch proves complete payload/RNG equality across unsaved cycle-55 payoff rollback to cycle 54, followed by saved closure and another cold restore with Bank preserved. No runtime review finding remains unresolved.

## Failures preserved and repairs

Preparatory focused failures were test typing/declarations and an incorrect 105-month expectation (cycle 4 acceptance reaches the final cycle-216 education due with **106** months). Restart v1 failed a redundant inherited test member declaration; v2 fixes that without runtime change. Normal imports returned exit 0/no runtime errors while recording new UID sidecars as source drift, not behavior acceptance.

Independent audit rejected `edges-v2` evidence despite 290 native assertions passing: a private mixed-payment vector stored its before dictionary by reference, then another vector changed its cash. The maintained test now deep-copies that before snapshot; the distinct `edges-v3` rerun and independent audit both pass. All prior outputs remain intact. The private vectors are explicitly labeled unjournaled isolated payment plans; public APIs reject them, and they are never presented as checkpoints or player balance routes.

## Source and gate boundaries

Per-command source/runner hashes, output freshness, exact diagnostics and immutable captured outputs are required. Only the exact Windows certificate-store diagnostic is exempt. Compact source pins include **676 files / 4.15 MB**, excluding caches/design logs/evidence. `source-current-v1.zip` and `source-focused-v4.zip` preserve exact accepted hashes; the historical pin restores one known deleted test declaration only when the full recorded SHA matches. The final corrected version is `source-edges-v3.zip`, 1,394,767 bytes, SHA-256 `4ca2233e36bb2f9add07e757cc1f5eb8e560b583879964d60cb71af01e3301e9`; earlier archives stay immutable. The pin helper requires a fresh archive label.

Parent owns the final combined headless gate. Its first attempt stopped before tests because an already-running user Godot process held production checkpoint port 62741; that process was left untouched. Actual exported rendered interaction remains deferred overnight. This record does not claim a commit, push, rendered playtest or release readiness.

Focused `git diff --check` passed on owned tracked files (only existing line-ending normalization warnings). No implementation-owned native process remains. The final source freeze includes runtime, debug drivers and UID sidecars; remaining parent gate instrumentation lives outside that runtime set.


## Final combined gate - parent closeout

2026-10-09: [integrated gate v4](../findings/release-gate-education-v4/README.md) passed104 maintained suites, import, clean release export,214 verified PCK entries and headless EXE startup (exit0/errors[]). The initial occupied production lease was preserved; inherited test wrappers used the same TCP lease semantics on47733 with isolated profiles. Runtime/package files were not altered by that instrumentation. Actual exported/rendered interaction remains deferred overnight, with full automated/release-ready flags false.

Two old debug verifiers required bounded repairs: Store intermediate animation sampling now steps real Tweens with container-layout passes; the schema1 fixture now omits the later education field and rejects that hybrid explicitly. All gameplay files still match the accepted Education pin; the original archives/audits retain those two prior test versions. All failed gate/fixture evidence is preserved. No additional gameplay or balance change, commit or push.
