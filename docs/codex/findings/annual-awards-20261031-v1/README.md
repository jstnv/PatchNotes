# Annual Game Awards — implementation and acceptance

Started 2026-10-31; final verification 2026-11-01, America/Los_Angeles. Branch `main`, HEAD `49d769235474a880a73d996499cefa72beec63e5`, dirty shared checkout. User explicitly authorized resolving remaining rules and implementing the complete ceremony without input. No commit, push or export was requested or performed.

**Implemented locally; selected automated and native acceptance PASS. Rules/rewards ACTIVE/TRIAL.** Final runtime identity: `303959a85af6268f88e1cd4b855e747838a25fad8779d85621a17f77a0b19253`. [Complete source hashes and exact delta from preceding capture](final-source.json) · [changed files](CHANGED_FILES.md) · [binding contract](../../threads/annual-game-awards/2026-10-31-implementation-contract-v1.md) · [current design](../../design/annual-game-awards.md).

## Result and architecture

Seven awards rank actual current-year releases/eligible Studios: Graphics, Sound, Technology, Design, Rising Studio, Studio of the Year and GOTY. Ranking freezes once at the committed world transaction entering December Week2, including that transaction's rival launches and royalty work. A separate player launch committed afterward is later even at the same displayed week. No sales/units tie influence, hypothetical releases, retroactive catch-up or previous-year carryover.

Four modules separate authority: pure integer ranking/reward plans; chronological per-owner Fan/Awareness receipts; one RivalWorld ledger with immutable result inputs and durable presentation progress; presentation-only ceremony using existing FolderUI/theme/fonts/chamfers/MenuTransitions. Existing RunState, monthly finance, RNG, calendar, public engine, Pass Budget, historical inputs and Studio-only Continue boundaries remain authoritative.

The ceremony has ten pages, contenders, animated metric counters, ranked podiums, final results and fixed navigation. Its first viewing is mandatory; later Skip to results and a persistent skip-future preference affect presentation only. Gameplay retains/restores Studio/HUD/focus and gates hidden routes, Pause/F8/Escape/controller B. Each page change waits for paired Studio/world persistence. Retry does not advance twice, and Continue resumes the exact stored stage.

Trial reward choice: 10 Fans per nomination entry; a win adds another 40 Fans and 5 Awareness for the next successful release. Same AI/player accounting; stack across entries, no cash or retroactive sales. All owners preflight before mutation. Chronological receipts distinguish same-cycle launches before/after awards and do not count as completed Contracts. Failed/canceled releases preserve the Awareness bank.

Old worlds begin the current award year only before its cutoff, otherwise next year. Calendar dates, including old half-month prefixes with unrepresentable Week2, determine this boundary. The exact genuinely captured preceding runtime `ef14cc34682dbe4ab3e739ea13396da9979c3a8efb9c057c7c8cfa25d78980f6` is admitted with full existing validation, not a wildcard compatibility grant. Unknown sources and forged/missing current ledgers reject. Normal Continue with player award receipts requires its global world in synchronous, writer-validation and background-reader paths; detached owner-adapter hydration remains available inside legitimate paired restoration.

## Acceptance evidence

Godot 4.7.1 Windows, isolated profiles and leased checkpoint ports. Counts overlap; do not sum them as unique test cases. Source fences compare full canonical inventories, not just touched files. Earlier semantic coverage and final exact-byte checks are distinguished below.

| Check | Actual result | Evidence / scope |
| --- | --- | --- |
| Pure rankings | 49 checks / 0 failures | `rules-final/`; ties, sparse categories, exact Review, sales independence, stacking |
| Chronological rewards | 60 / 0 | `receipts-v1/`; before/after launches, replay, failed release, Promotion provenance |
| Shared UI component, headless and native | 263 / 0 each | `ui-headless-v4.stdout.log`, `ui-native-v4.stdout.log`; ten stages, long names, ties, sparse podium, 1152/1280 |
| Actual Gameplay full ceremony, headless and native | 56 / 0 each | `ui-integration-headless-v2.stdout.log`, `ui-integration-native-v2.stdout.log`; all ten pages, cold stage3 Continue, injected failed write/Retry, duplicate input, teardown, exact owner DTOs and restored focus |
| Actual later ceremony routes | 12 / 0 auto; 13 / 0 resumed final; 18 / 0 manual | `ui-integration-later-auto.stdout.log`, `ui-integration-later-final.stdout.log`, `ui-integration-later-manual.stdout.log` |
| Legal first-year world | 241 / 0, full source fence PASS | `final-world-legacyfix/`; actual eight rivals, legal player commands, frozen/tamper/once-only/paired cold checks |
| Final exact-byte legal two-year world | 128 / 0, full source fence PASS | `final-source-acceptance/`; 96 productive cycles, 12 player releases, eight rivals, first1980 completed and second1981 pending; no injected cash, loans or Contracts |
| Genuine previous saves | 54 / 0, full source fence PASS | `final-migration/`; pre-edit player8/9 and world0, genuine old world45/48, loans/employees/finance/history/RNG/engine DTO preservation, no catch-up, current re-save/cold, invalid source/tamper rejection |
| Legacy date-cutover regression | 35 / 0 | `legacy-cutoff-green-v1/`; meaningful RED35/8 retained; modeled raw23/47 old December half-month dates, new44/45/46 and pre1980/January |
| Missing-global-world regression | 7 / 0 | `orphan-world-green/`; meaningful RED7/3 retained; three normal Continue validators reject orphaned player prizes while genuine old standalone saves remain accepted |
| Final exact-byte paired-world validation | 10 / 0, full source fence PASS | `final-source-world-requirement/`; additionally all three validators accept a legitimate current paired save containing player award receipts |
| Final exact-byte native resume/Exit/focus | 19 / 0, exit0 | `ui-integration-final-bytes.*`; final-source first-year fixture and stable implementation/persistence/verifier pins |
| Selected maintained verifiers | all13 PASS | `maintained-v1/results.json`; names below |
| Post-save-guard persistence regressions | all5 PASS | `final-persistence-regressions/results.json`; settings, engine world Continue, Fanbase checkpoint, background checkpoint and Continue loading |

The thirteen maintained names are `verify_annual_awards_rules`, `verify_award_receipts`, `verify_annual_awards_ui`, `verify_calendar_clock`, `verify_fanbase_checkpoint`, `verify_studio_finance_integration`, `verify_monthly_sales_report`, `verify_public_action_engine`, `verify_publisher_trial_promotion`, `verify_engine_world_continue`, `verify_demo_settings`, `verify_pause_menu`, `verify_guided_tutorial_ui`.

Final two-year policy: seed4417, college_dropout, 3 Design/2 Alpha/2 Beta hands per release, legal shared actions; final cash $4,651.90 and Fans50. It demonstrates these acceptance routes, not optimal play or balanced rewards. The earlier old-runtime exact-cutoff capture needed one real Bank loan; its unsuccessful unfunded attempt remains in `prior-cutoff.log`, successful legal route in `prior-cutoff-loan.log`.

## Provenance, failures and review

`preceding-capture/report.json` and its source manifest were captured before canonical edits. `prior-late.json` and `prior-cutoff.json` came from a private archive of exact HEAD, with the genuine old runtime identity confirmed. This is distinct from modeled calendar-cutover coverage. No certified1977 cohort or `data/` byte changed. Supplied JooceBox assets/project splash edits, unrelated design edits and protected temp directories were preserved. Final coordinator polish restored its original CRLF so its tracked delta is precisely the one guard line; final fixtures were regenerated afterward.

Retained RED/failed evidence includes ranking behavior, receipt checks, first UI/settings/invitation/focus attempts, failed source fences during debug development, unfunded old cutoff, legacy-date RED and orphan-world RED. No failed run was relabeled as success. Private baseline/import/profile directories are ignored locally and are not release artifacts.

Independent whole-feature and scoped reviews found and resolved: incorrect inception/cutoff/offset validation, missing frozen-owner coverage, unrepresentable legacy cutoff, and orphaned player rewards without the global result. Final scoped review has no remaining Critical/Important findings. Review package/source pins and scoped session records are retained; the package describes its earlier reviewed source, not the final identity by itself.

The separate synthetic `verify_studio_checkpoint.gd` helper still constructs an invalid30-Scope/unconfigured-engine fixture against current27-Scope Public rules. `baseline-checkpoint.log` reproduces its same invalid-engine/loan/out-of-bounds failures on the exact pre-awards archive. That fixture needs separate maintenance; it does not justify changing gameplay or claiming the entire repository test suite is green. Some legacy verifier exits report ObjectDB leaks; their raw warnings remain in the logs.

## Remaining boundaries

Human pacing/listening, final reward balance, broad performance/no-lag guarantees, other engines/devices and a new EXE/ZIP are NOT established here. Founder Legacy attribution/victory thresholds and future roster/ownership mutation integration remain separate. No reward changes to existing finance values, new victory activation, export, commit, push or external publication occurred.

Reproduction: use `run_check.py --script res://scripts/debug/<verifier>.gd --output <new-directory> --fence` with an isolated profile; `--fixture` supplies a genuine captured paired save and `--native` selects rendering. The actual Gameplay final acceptance additionally uses its `--focus-only` user argument; native agent command/pins are in the corresponding session log. Preserve evidence outputs and use a new directory for each run.
