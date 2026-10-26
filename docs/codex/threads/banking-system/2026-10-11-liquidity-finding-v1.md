# Bank liquidity usefulness screen — 2026-10-11

**Bounded result: the loan unlocked immediate FIFO Research, but no tested arm completed game two. No balance or gameplay rule is approved.** Three legal high-sales/low-cash Studio checkpoints supported exact no-loan/$500/$1,000 comparisons. Each $500 arm completed one Research payment that its no-loan control could not afford; two $1,000 arms completed two, and the third completed one. The fixed four-hand game-two policy then encountered insufficient cash in every arm. The fourth declared Store admission failed because its 16-Bit Music parent was absent; it was retained and excluded, not repaired.

## Source, precommitment and exact runs

- [Plan](2026-10-11-liquidity-study-plan-v1.md) fixed seeds, four cohort-specific Store admission lists, loan amounts, twelve-arm ceiling, visible-information policy, bounds and stops before execution. `main` HEAD was `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared worktree dirty. No canonical gameplay edit. Python was `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe` (3.12.14). Godot was `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`, SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.
- Private [v3 variant](simulators/education-bank-quote-v3/variant.json) was created from v2. Original canonical baseline `ab152c2c263867e6b19da0446488bd47469a85e017dc4f4db47de50030aa779e`; v2 parent `ead6f694065a8922d7e8269bb87b37513b14292ea7bd9f9738e46b81411b4ff2`; v3 candidate `890781bc0c39c8a2e89c7440747d4724b8dcb99f3527e7a32c26e355b6058c32`. Its sole additional project delta is a read-only `$1,000/12-month` Studio quote beside v2's read-only $500 quote. The project does not modify finance, loan, Store, RNG or saved-state rules. Different injected policies produced frozen source identities `890781bc...` [first](simulations/liquidity-first-run-v3/run-report.json), `55432479...` [c16 Studio](simulations/liquidity-studio-run-v3/run-report.json), `f251c09d...` [admissions](simulations/liquidity-admit-run-v3/run-report.json), and `5a131b18...` [matched arms](simulations/liquidity-pairs-policy-v2-run-v3/run-report.json).
- The [config builder](simulations/build_liquidity_configs_v1.py) copied the declared four *fresh recipes* and then used only each preceding run's valid Studio checkpoint. Four v3 first releases completed at c13; four five-action prefixes reached c16 with all actions accepted and expected `command_bound` status. V2/v3 final state digests, cash and commands matched in all four cohorts at both boundaries. A bound produces overall run `ok=false` because the two-release target is intentionally unmet.

From repository root, these were the primary commands; `$py` and `$godot` are the exact executables above. All run outputs were new folders, `--timeout 240`, and each policy was injected into an isolated private project/profile:

```powershell
$py = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $py tools/simulator_variant.py create --id education-bank-quote-v3 --owner banking-system --from-variant docs/codex/threads/banking-system/simulators/education-bank-quote-v2 --output docs/codex/threads/banking-system/simulators/education-bank-quote-v3
& $py docs/codex/threads/banking-system/simulations/build_liquidity_configs_v1.py first
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v3 --config docs/codex/threads/banking-system/simulations/liquidity-first-v3.json --output docs/codex/threads/banking-system/simulations/liquidity-first-run-v3 --godot $godot --timeout 240
& $py docs/codex/threads/banking-system/simulations/build_liquidity_configs_v1.py studio
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v3 --config docs/codex/threads/banking-system/simulations/liquidity-studio-v3.json --output docs/codex/threads/banking-system/simulations/liquidity-studio-run-v3 --godot $godot --timeout 240
& $py docs/codex/threads/banking-system/simulations/build_liquidity_configs_v1.py admit
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v3 --config docs/codex/threads/banking-system/simulations/liquidity-admit-v3.json --output docs/codex/threads/banking-system/simulations/liquidity-admit-run-v3 --godot $godot --timeout 240
& $py docs/codex/threads/banking-system/simulations/build_liquidity_configs_v1.py pairs
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v3 --config docs/codex/threads/banking-system/simulations/liquidity-pairs-v3.json --output docs/codex/threads/banking-system/simulations/liquidity-pairs-run-v3 --godot $godot --timeout 240
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v3 --config docs/codex/threads/banking-system/simulations/liquidity-pairs-policy-v2-v3.json --output docs/codex/threads/banking-system/simulations/liquidity-pairs-policy-v2-run-v3 --godot $godot --timeout 240
& $py docs/codex/threads/banking-system/simulations/run_liquidity_verifiers_v3.py --godot $godot --output docs/codex/threads/banking-system/simulations/liquidity-verifiers-v3
& $py docs/codex/threads/banking-system/simulations/analyze_liquidity_v3.py
```

The six paired reporters used `tools/compare_simulations.py --bundle docs/codex/threads/banking-system/simulations/liquidity-pairs-policy-v2-run-v3 --left <cohort>-no-loan --right <cohort>-borrow-<500|1000>-12 --output docs/codex/threads/banking-system/simulations/liquidity-compare-<cohort>-<500|1000>-v3`, for `control-4417`, `graduate-4417` and `control-90210`. Representative exact replay and reduction commands were:

```powershell
& $py tools/simulate.py replay --bundle docs/codex/threads/banking-system/simulations/liquidity-pairs-policy-v2-run-v3 --case control-4417-borrow-500-12 --output docs/codex/threads/banking-system/simulations/liquidity-replay-pair-control-4417-borrow-500-12-v3 --godot $godot --timeout 240
& $py tools/reduce_simulation.py --bundle docs/codex/threads/banking-system/simulations/liquidity-admit-run-v3 --case graduate-90210 --kind rejection --output docs/codex/threads/banking-system/simulations/liquidity-reduced-graduate-90210-godot-v3 --godot $godot --timeout 240 --max-commands 12
& $py tools/reduce_simulation.py --bundle docs/codex/threads/banking-system/simulations/liquidity-pairs-policy-v2-run-v3 --case control-4417-borrow-500-12 --kind rejection --output docs/codex/threads/banking-system/simulations/liquidity-reduced-pair-control-4417-borrow-500-12-v3 --godot $godot --timeout 240 --max-commands 50
```

All other exact case IDs, original bundles, source hashes and outputs are in their retained `run-report.json` and `reduction-run.json` files.

The original [pair-policy v1 run](simulations/liquidity-pairs-run-v3/run-report.json) is retained as **invalid setup**: Godot JSON loan amounts arrived as floats, and its factory rejected every case before a command. [Policy v2](simulations/liquidity_pair_policy_v2.gd) changed only exact-whole-cent input validation; the declared behavior, checkpoints, amounts, seeds and bounds stayed fixed. It was run in a new output folder. The admission run's `ok=false` includes three intended bounds and one real rejection; the corrected pair run's `ok=false` reflects nine rejected development commands. No failed batch is called a complete two-release run.

## Legal admissions and qualified quotes

Starting ledgers were $5,700 no trait and $6,000 Graduate, each with a distinct unused-point receipt; this study did not test the bare $5,500 baseline. First releases occurred at c13 and settled strong positive sales at c14 and c16, as in the [prior finding](2026-10-11-eligible-sales-finding-v1.md). Existing parent familiarity made the first FIFO `scripted_ai` due $855.

| Cohort | Declared admitted down payments | c16 cash after accepted admissions | Admission outcome |
|---|---:|---:|---|
| No trait 4417 | $2,650 | $735.52 | 3/3 accepted; c16 checkpoint |
| Graduate 4417 | $3,200 | $485.52 | 4/4 accepted; c16 checkpoint |
| No trait 90210 | $4,300 | $833.77 | 5/5 accepted; c16 checkpoint |
| Graduate 90210 | $3,750 of $4,600 attempted | $1,683.77 after four | fifth `16_bit_music` rejected; no comparison checkpoint |

The fourth rejection was a mistaken prerequisite assumption in the declared route: it owned 8-Bit Sound, not the required 8-Bit Music parent. Its [full failed case](simulations/liquidity-admit-run-v3/cases/graduate-90210/result.json) and [one-command fresh-process reduction](simulations/liquidity-reduced-graduate-90210-godot-v3/reduction-run.json) are retained. An initial reduction attempt without a Godot path also remains [recorded](simulations/liquidity-reduced-graduate-90210-v3/reduction-run.json); the corrected reduction succeeded. The other three checkpoints had zero overdue bills and cash below the $855 first due.

At each valid checkpoint both selected loan quotes were eligible under existing rules. The older/latest settled sales were $1,510.48/$1,965.04 for seed4417 and $2,265.73/$2,958.04 for seed90210. Quote basis and monthly capacity were $1,737.76/$309.44 (no trait4417), $1,737.76/$238.75 (Graduate4417, including $282.73 education overlap reserve), and $2,611.88/$527.97 (no trait90210). Maximum eligible principal was respectively $3,315.48, $2,558.04 and $5,656.80, so the actual $500 and $1,000 quotes fit. $500/12 schedules had $32.50 total interest and a maximum $46.67 installment; $1,000/12 schedules had $65 total interest and a maximum $93.34 installment, first due c18 and last due c40. These are existing prototype terms, not a newly approved ceiling or fixed offer.

## Matched effect and censoring

Six [paired comparison reports](simulations/liquidity-compare-control-4417-500-v3/comparison.md) (all named `liquidity-compare-<cohort>-<amount>-v3`) verified matching source, exact initial Studio state/RNG and checkpoint within each triplet. All report `both_cases_completed=false`; only matched observed cycles are comparable. The independent [audit script](simulations/analyze_liquidity_v3.py) and [summary](simulations/liquidity-summary-v3.json) assert every quote, accepted Research count, censoring status, state/RNG match and replay result.

| Cohort | No loan | $500/12 | $1,000/12 |
|---|---|---|---|
| No trait 4417 | 0 Research; unaffordable Design hand c20 | 1 Research; unaffordable Design hand c19 | 2 Research; unaffordable Design hand c19 |
| Graduate 4417 | 0 Research; unaffordable Design hand c19 | 1 Research; unaffordable Design hand c18 | 1 Research; calendar blocked c20 with $199.25 overdue |
| No trait 90210 | 0 Research; unaffordable Design hand c23 | 1 Research; unaffordable Design hand c22 | 2 Research; unaffordable Design hand c21 |

The Graduate $1,000 arm's c20 shortage left $106.74 of original c20 rent and $92.51 of its second Bank installment unpaid. Every other arm had $0 overdue at its own stopping point. The accepted loan actions and Research were legal; their later blocked hands are part of the result. The larger loan generally financed more queued Research and advanced the cash shortage sooner. Since no arm launched game two and endpoints are at different cycles, there is **no measured second-game Review, payoff, debt-adjusted winner or completed-game usefulness claim**. Outstanding principal and paid interest are preserved per arm in the summary; the principal cannot be counted as earnings.

## Checks, interpretation and next question

- [Twelve fresh-process replays](simulations/liquidity-replay-pair-control-4417-borrow-500-12-v3/run-report.json) passed `ok=true`/`telemetry_verified=true`: two first-release, two c16, three valid admission and five representative pair tapes. Replaying a rejected arm verifies its *accepted command prefix*, not the final rejected policy decision. The latter is independently reproduced by [two pair failure reductions](simulations/liquidity-reduced-pair-control-4417-borrow-500-12-v3/reduction-run.json) and the Graduate $1,000 [reduction](simulations/liquidity-reduced-pair-graduate-4417-borrow-1000-12-v3/reduction-run.json), each with fresh-process confirmation.
- [Focused private-project checks](simulations/liquidity-verifiers-v3/result.json) all exited 0 without script error: Campaign Session 81 steps/55 reentrant checks, Finance Observation 108 checks/21 comparisons, Bank Loan 14,112 checks, Feature Research, Research Integration, and Education Atomicity 36 checks; each printed zero failures. The known Education Debt/Edges external-fixture limitation from v2 was not reclassified as a pass here.

**Recommendation: keep current Bank rules unchanged.** The Bank demonstrably bridged the immediate Research payment, while this deliberately cash-depleting Store strategy failed to support a full second build. A next study should protect a predeclared rent and game-two production reserve, use a legal payable Research target and fixed visible policy, then test whether borrowing changes a completed release rather than merely shifting the first blocked hand. Do not infer a new qualification reserve, rate, term, amount minimum, Store restriction, credit weight or player-facing warning from these nine censored paths alone. The delayed first-game 6.2/bankruptcy screen and exported late/partial debt acceptance remain separate.
