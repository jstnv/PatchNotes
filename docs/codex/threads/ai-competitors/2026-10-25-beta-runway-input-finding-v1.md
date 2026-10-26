# Rival Beta runway inputs — read-only finding, 2026-10-25

**COMPLETE bounded input audit; funded Beta policy remains DESIGN/OPEN.** A simple cash/rent screen does not meaningfully select extra Beta hands in the current two-rival trial. The existing world trace cannot establish exact no-new-loan affordability at a Beta exit, because it omits the rival's advanced `run_cycle`, exit-time typed finance report and selected next-hand preflight. Instrument those fields in a private variant before comparing policy outcomes. No gameplay, hand count or reserve is approved here.

## Source and declared scope

The [pre-run plan](2026-10-25-beta-runway-input-audit-plan-v1.md) limited the audit to two completed, legal two-hand-control Action/Fantasy worlds, seeds 4417 and 4418. Both report source identity `5da7bc70f45fc63d33e6f5293e77338992038810b84a2c964ff47aff7a2b1a64`; their complete prior world checks and replay/Continue evidence are in the [two-hand QA finding](2026-10-25-two-hand-qa-finding-v1.md). They are different seed starts, not identical states to each other. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty worktree and `.codex-godot-temp` preserved. No new headless game process or source revision was run for this audit.

The first [v1 output](sims/rival-beta-runway-input-audit-20261025-v1.json) is **INCOMPLETE**, retained: its parser expected integer `report.seed`, while the reports encode decimal strings. The [declared v2 repair](2026-10-25-beta-runway-input-audit-v2-plan.md) changed only that comparison. [V2 script](2026-10-25-beta-runway-input-audit-v2.py), SHA-256 `47726fc0c3e9962ac88b9f0f10e9d4dff9d2363d1f44c90b6bd9776ec4dc8967`, produced the [20-row evidence](sims/rival-beta-runway-input-audit-20261025-v2.json), SHA-256 `7f300d5c448029d62f7b7082c3d67e113baedaa5df1ed3937f3dd58aaa4f200b`, with `PASS_READ_ONLY_SCHEMA` and zero errors. Its two source-file hashes, seed identities and every exit row are embedded in the evidence.

## Observations

| Exit observation | Count of 20 |
| --- | ---: |
| Current cash at least $500 next due plus $500 post-launch reserve | 20 |
| Current cash at least $500 next due plus $1,000 reserve | 20 |
| Current cash at least $500 next due plus $2,000 reserve | 18 |
| Visible Search **and** Debug cards in the seven-card pool | 9 |
| At least one visible Insider cash-payout card | 4 |

Cash at the actual `request_exit` policy observation ranged **$1,800.00–$12,025.90**. The due/reserve rows are only sensitivity arithmetic on that cash; the next due was tested as both $0 and $500 because the trace does not record the rival's exact advanced run cycle at the exit observation. No already-due bill or future income was incorporated. The current authored trial cohort has Family Funding and Cult Following, ordinary $500 rent, and no loan-seeking policy, but a general studio can have other typed dues. Visible Search+Debug is structural availability, not proof that a legal four-card hand would reduce Bugs or improve Review. A visible Insider card is not booked income until a selected legal command commits.

The [harness source](six-hand-phase-study-20261023-v1/world_study.gd) logs `rival_choices.cycle` from `world.cycle` before the rival step, while `rival_progress.cycle` is captured after each completed world step. Earlier prose in the [direction record](2026-10-25-cash-funded-beta-direction-v1.md) and [session log](2026-10-25-cash-funded-beta-session-log-v1.md) treated same-numbered rows as decision-aligned finance/Bugs. Both were corrected. The prior progress rows cannot prove exit-time bills or hidden remaining Bugs. This audit does not treat hidden Bugs as AI policy input.

## Reproduce and disposition

From the repository root, using `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`:

```powershell
& $pnPython docs/codex/threads/ai-competitors/2026-10-25-beta-runway-input-audit-v1.py --output docs/codex/threads/ai-competitors/sims/rival-beta-runway-input-audit-20261025-v1.json
& $pnPython docs/codex/threads/ai-competitors/2026-10-25-beta-runway-input-audit-v2.py --output docs/codex/threads/ai-competitors/sims/rival-beta-runway-input-audit-20261025-v2.json
```

The first command exited 1 on the retained schema failure; the second exited 0 in about one second. Each output path was new; these exact paths cannot be reused because the scripts refuse overwrite. No seed, reserve case or runtime bound was changed in response to the findings. No timed-out headless case occurred.

**Next study:** in a new AI Competitors simulator version, add read-only decision-boundary telemetry for actual `run_cycle`, current cash, typed outstanding and next due schedule, exact selected-hand cost/guaranteed income, and release/next-project reserve assumptions. Validate no-change state/RNG against a frozen two-hand control, real month-end and Insider cases, a low-cash case, an existing-loan case and Studio-only Continue. Only after that instrumentation can a separately versioned funded-opportunity Beta policy be compared at equal legal starts. Marginal QA/Marketing value, reserve size, allowed hand opportunity, publication-density guard, CPU limit and adoption all remain **OPEN**. The current two-hand Beta rule stays **ACTIVE/TRIAL**.
