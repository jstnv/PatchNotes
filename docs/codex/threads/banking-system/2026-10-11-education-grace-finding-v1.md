# Education grace-boundary finding — 2026-10-11

## Status and evidence

**Bounded finding, no gameplay value approved.** The [predeclared plan](2026-10-11-education-grace-study-plan-v1.md) and [six-case input](simulations/education-grace-v1.json) tested existing canonical behavior. No simulator variant or rule edit was needed. Run bundle: [education-grace-run-v1](simulations/education-grace-run-v1/run-report.json); independent [summary](simulations/education-grace-summary-v1.json) and [analysis script](simulations/analyze_education_grace_v1.py). Frozen source identity `577f46fd83d5a1e2bd21d017c40eba0b20a543faf9c2301cd6316d48aa394533`, policy identity `e168d3a6ea700eed8cad3b02a276003a359048d0c04e620b9e285f19b5197a00`; captured dirty `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Godot 4.7.1 console SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.

Exact commands (PowerShell, repository root, bundled Python `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`, Godot `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`):

```text
python tools/simulate.py run --config docs/codex/threads/banking-system/simulations/education-grace-v1.json --output docs/codex/threads/banking-system/simulations/education-grace-run-v1 --godot <Godot path above> --timeout 240
python tools/simulate.py replay --bundle docs/codex/threads/banking-system/simulations/education-grace-run-v1 --case <control-4417 | dropout-4417 | graduate-4417> --output docs/codex/threads/banking-system/simulations/education-grace-replay-<case>-v1 --godot <Godot path above> --timeout 240
python docs/codex/threads/banking-system/simulations/analyze_education_grace_v1.py docs/codex/threads/banking-system/simulations/education-grace-run-v1 docs/codex/threads/banking-system/simulations/education-grace-summary-v1.json
```

All six cases completed **72 accepted commands, three releases at cycles 13/26/39**, with zero rejected or timed-out cases. The three seed-4417 [fresh-process replays](simulations/education-grace-replay-graduate-4417-v1/run-report.json) each reproduced 72 steps, final exact state and all 73 telemetry samples; [control](simulations/education-grace-replay-control-4417-v1/run-report.json) and [Dropout](simulations/education-grace-replay-dropout-4417-v1/run-report.json) are retained separately. The analysis checks each first due, month-before-grace, telemetry/final state, command acceptance and same-seed trace. Import and run logs contain only the known `Failed to read the root certificate store` environment error; no gameplay failure marker was found.

## Measured outcomes

| Cohort, both seeds | Start cash | First due at c26 | Seven dues through c38 | c39 cash, seed 4417 / 90210 | c39 credit, seed 4417 / 90210 |
|---|---:|---:|---:|---:|---:|
| No trait | $5,700 | $0 | $0 | $6,826.28 / $7,309.84 | 621 / 624 |
| College Dropout | $5,800 | $70.68 ($33.33 interest) | $494.76 | $6,431.52 / $6,915.08 | 621 / 624 |
| Graduate | $6,000 | $282.73 ($133.33 interest) | $1,979.11 | $5,147.17 / $5,630.73 | 621 / 624 |

The first 12 completed months had no education payment or interest. At c26/month13 the first due was fully paid in each debt case. Month13 cash for seed4417 was $2,990.48 control, $3,019.80 Dropout and $3,007.75 Graduate: the startup point receipt still outweighed the first bill by $29.32/$17.27 at that boundary. By c39, seven dues outweighed that receipt: relative to no trait, Dropout had **$394.76 less cash** and Graduate **$1,679.11 less cash** in both seeds. Credit, release cycles and Review sequences matched by seed (4.0/5.2/4.0 and 5.8/4.3/5.3). The lowest observed command-boundary cash was $1,840–$2,640 across cases. No case developed overdue bills or a financially blocked action. Remaining education principal at c39 is $4,733.27 Dropout or $18,933.08 Graduate; final cash alone is not debt-adjusted wealth.

The legal initial Studio states **differ** by trait and receipt, although same-seed initial RNG streams, command choices/cycles and selected candidate tokens matched within each three-cohort set. These are comparable policy traces, not identical-state paired counterfactuals. The observed cash differences equal the distinct startup receipt minus seven contracted education payments; they do not imply that a different player policy or sales path will preserve the same actions.

## Interpretation and next question

The hypothesis that Graduate's first dues would cause a liquidity or credit failure **did not hold** in these two finite policy seeds. The accounting/schedule boundary behaved as designed. This does not establish that Graduate is affordable under Store spending, Research, payroll, weak sales, longer first games or Bank borrowing; the policy did none of those. Three releases and 19 completed months leave 89 of 96 education dues unobserved. The first release at c13 fits the intended roughly-14-cycle opening, but the policy's selection is a test fixture, not a player strategy or balance target.

**Recommendation: DESIGN review needed, no adoption candidate.** Before changing education payment values or the Bank reserve, test a declared paid-Feature/Research and optional Bank route from genuine post-settlement Studio states, including a low-cash/weak-sales case. If the design goal is simply correct due/payment behavior, the existing implementation and this bounded screen need no further gameplay task. Keep the current LOCKED schedule/service rules and ACTIVE/TRIAL credit weights unchanged pending a user ruling.
