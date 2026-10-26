# Crown access: shorter production and selective Research v1

2026-10-25. **Completed bounded policy study; no gameplay adoption or balance approval.** User delegated the cheaper-access follow-up. Rewards unchanged; redraw research parked. [Preregistered methods](studies/crown-access-policy-20261025-v1/PLAN.md) · [review handoff](CROWN-ACCESS-POLICY-HANDOFF-2026-10-25-v1.md) · [paid-Search preview handoff v2](CROWN-PREVIEW-HANDOFF-2026-10-25-v2.md).

## Results

| Policy | Completed4 releases | Earned Crown access | Any arrears | First qualifying release cycles |
|---|---:|---:|---:|---|
| control | 0/6 | 0/6 | 6/6 | None |
| exit | 6/6 | 5/6 | 0/6 | 63, 63, 74, 79, 64 |
| reserve | 6/6 | 5/6 | 0/6 | 66, 46, 67, 66, 89 |

All cases use six real paid SideStreet cash searches. The controls reproduce the previous failures exactly, including initial/final state and RNG. Shorter production can preserve runway and reach later releases; this study separates that policy change from reducing Research. Access means an actual released Review>=7, not a projected quality score. See every case below before generalizing.

## Source and exact method

Branch main; HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f; dirty shared worktree preserved. Named owner contracts variant `crown-access-policy-20261025-v1` forks immutable `crown-search-access-20261025-v1`. Full canonical, parent and candidate source identity `434971b9525f09fab3fa0846ed094f53d6ee778f76ae8b97740a136c7b0fda3f`; no runtime delta. [Full before/after source pins](studies/crown-access-policy-20261025-v1/source-before.json) match. External [policy](studies/crown-access-policy-20261025-v1/policy.gd) and [its exact hash/preregistered plan hash](studies/crown-access-policy-20261025-v1/pin.json) are separate research inputs. No old checkpoint identity was edited.

18 fresh legal recipes: Action/Puzzle/Simulation × seeds4417/4521 × control/exit/reserve. Six triples have exact initial state/RNG/source and roster-v3 fixture checks. All control/exit pairs also match at Game2 Begin; reserve shares an exactly verified state prefix until its declared Research choice changes. Game1 remains2/2/2. Six paid searches plus real Ironclad precede Game2; no Bank, employees, hidden future draws, Brief rewards or fabricated funds. Exact candidate commands and return codes are in `studies/crown-access-policy-20261025-v1/*-command.json` and `*-exit.json`.

Control: four legal purchases, Game2 10/10/12 hands, later6/6/6. Exit: same purchases/selection, bounded quality/cash-based phase exits. Reserve: same exit policy, at most two purchases with quoted acquisition cost leaving$6,000. The reserve and phase thresholds are research heuristics, not newly approved game rules or player restrictions. Design cap6; Alpha cap10; Beta cap6; minimums/quality/known-bug/cash triggers are fully declared in PLAN. Static Core quality proxy is not actual frozen-market Review and ignores hidden bugs/variance. Known bugs0 does not prove bug-free.

Each case stops at4 releases,420 commands, first rejection or timeout; each genre has a separate isolated runner/cache/profile and600sec import/run limit. Three run invocations return nonzero when retained controls reject; case-level reports distinguish those economic failures from process faults. No seeds or budgets were adjusted after outcomes. 2366 accepted commands in the18 declared cases. Exit reasons: `{'design_cap': 36, 'cash_reserve': 30, 'alpha_quality': 6, 'known_clear_after_search': 20, 'alpha_cap': 16}`.

## Complete result table

| Case | Releases | Reviews in release order | First Crown cycle | Minimum transaction cash | Maximum arrears |
|---|---:|---|---:|---:|---:|
| action-4417-control | 1 | 2.0 | Not reached | $0.00 | $431.78 |
| action-4417-exit | 4 | 2.0, 5.3, 8.5, 6.1 | 63 | $1,608.22 | $0.00 |
| action-4417-reserve | 4 | 2.0, 5.9, 8.4, 6.3 | 66 | $1,968.22 | $0.00 |
| action-4521-control | 1 | 2.5 | Not reached | $0.00 | $132.09 |
| action-4521-exit | 4 | 2.5, 6.3, 8.2, 8.1 | 63 | $1,467.91 | $0.00 |
| action-4521-reserve | 4 | 2.5, 8.2, 6.9, 8.0 | 46 | $1,867.91 | $0.00 |
| puzzle-4417-control | 1 | 1.1 | Not reached | $0.00 | $484.13 |
| puzzle-4417-exit | 4 | 1.1, 3.1, 4.5, 4.8 | Not reached | $795.87 | $0.00 |
| puzzle-4417-reserve | 4 | 1.1, 5.6, 6.5, 6.9 | Not reached | $1,915.87 | $0.00 |
| puzzle-4521-control | 1 | 1.7 | Not reached | $0.00 | $385.16 |
| puzzle-4521-exit | 4 | 1.7, 3.9, 6.0, 8.6 | 74 | $1,728.05 | $0.00 |
| puzzle-4521-reserve | 4 | 1.7, 6.8, 7.7, 8.7 | 67 | $1,514.84 | $0.00 |
| simulation-4417-control | 1 | 1.5 | Not reached | $0.00 | $438.91 |
| simulation-4417-exit | 4 | 1.5, 4.0, 6.4, 7.2 | 79 | $1,601.09 | $0.00 |
| simulation-4417-reserve | 4 | 1.5, 5.0, 7.1, 5.7 | 66 | $1,941.09 | $0.00 |
| simulation-4521-control | 1 | 1.7 | Not reached | $0.00 | $131.82 |
| simulation-4521-exit | 4 | 1.7, 5.1, 7.6, 7.8 | 64 | $1,255.58 | $0.00 |
| simulation-4521-reserve | 4 | 1.7, 6.6, 6.8, 7.7 | 89 | $1,748.18 | $0.00 |

[Analysis](studies/crown-access-policy-20261025-v1/analysis.json) retains final cash/cycles, purchases/actions, Game2 starting cash, rejection sample and every logged exit. [Evidence hashes](studies/crown-access-policy-20261025-v1/evidence-manifest.json). Raw complete sources/tapes/checkpoints/logs: `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-access-policy-20261025-v1/`.

## Verification and limits

- PASS: six historical controls match exact initial/final state/RNG, counters and statuses; six three-arm initial matches and six shared-prefix checks;18 current-roster fixtures.
- PASS: fresh-process replay of `action-4417-exit` and `action-4417-control`, including telemetry and the original rejection. First failure reduced with500-command/240sec bounds and fresh confirmation. This reproduces an economic policy failure, not a repaired runtime bug.
- PASS: first successful non-control Studio Continue to one additional release, max100commands/240sec; exact checkpoint state/RNG preserved. [Receipts and coverage](studies/crown-access-policy-20261025-v1/verification.json).
- PASS: independent integer/card recomputation of12 previously recorded paid-Search hand projections and six settlements (24 assertions). These witnesses use the existing private Crown Search candidate, not this unchanged access baseline. [Preview evidence and explicit source](studies/crown-access-policy-20261025-v1/preview-evidence.json).
- Retained diagnostics: each six-case batch reports six ObjectDB instances leaked at exit. No `ERROR:` or `SCRIPT ERROR:` lines occurred in those import/experiment logs. This study does not fix or dismiss the exit leak warning.
- NOT RUN here: graphical/native/export acceptance, human comprehension, broader seeds/specialties, actual new-policy post-unlock Brief campaigns, active-rival migration. No additional maintained runtime suite was needed for an external policy-only delta; previous runtime acceptance remains separately scoped.

Two seeds per specialty cannot establish universal accessibility. Release quality/cash/cycle changes are mediated by chosen hand counts, Research ownership, RNG consumption and calendar sales. Equal starting state does not promise identical later draws after policies diverge. All six reserve routes share65 exact telemetry samples with control, through the same first two purchases; they diverge at the third admission versus Begin. Thus the observed Research intervention is stopping at two purchases; the$6,000 filter never changes those first two selections and its independent benefit is NOT established. It reserves quoted acquisition costs only, excluding future rent/production/sales, so later cash can legally fall below$6,000. Design's quality trigger never fires: all36 Design exits hit the six-hand cap. The shorter policy combines fixed caps, six Alpha quality exits,20 known-clear Beta exits and30 cash-reserve exits; it does not isolate the benefit of quality awareness. The earlier18-search access result is historical context, not a paired estimate of twelve searches' causal cost in these new policies.

## Recommendation and next decision

Keep rewards and the Review7 gate unchanged. Retain the shorter policies as useful access fixtures; neither the former18-search route nor the new cash/Research thresholds are player requirements. The reserve policy is a useful next liquidity-conscious baseline, but its purchase cap and reserve are combined and its cadence is not uniformly faster. Puzzle4417 still misses Crown within four releases, so preserve that seed for a separately preregistered specialty-aware purchase/selection comparison. Review the updated paid-Search grade preview before canonical Brief exposure. Do not expand to Crown commissions/support on the strength of these access results.
