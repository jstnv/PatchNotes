# Compact Feature Package — conditional feasibility findings v1

2026-10-26. **PASS at offline compatibility scope; design remains PROPOSED.** [Preregistered plan](studies/compact-package-20261026-v1/PLAN.md) · [analysis source](studies/compact-package-20261026-v1/analyze.py) · [results](studies/compact-package-20261026-v1/run-v1/summary.json) · [all choices](studies/compact-package-20261026-v1/run-v1/options.json) · [per-cell witnesses](studies/compact-package-20261026-v1/run-v1/cells.json).

## Source and setup

Current inspected branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`, with five pre-existing tracked edits. The source of observed play is the earlier private Crown experiment: full identity `f7de61169758dcd874972c59e584c7b6a9a36f1fedc4f24b2398f6a2edfdf60f`, mechanics `9dd1e4551338d38894dace6eb98bc635c38b7e6ec47427b4078cf0ccfe8b0bd6`. These are different revisions; no current-runtime parity is claimed. The analysis verifies the original nine pinned input files before/after, including three raw experiment logs; [hashes](studies/compact-package-20261026-v1/run-v1/input-pins.json).

Six legal earned starts: Puzzle4417 at Game4/cycle80, Puzzle4418 at Game3/cycle62, Puzzle4521 at Game3/cycle65, Puzzle4522 at Game4/cycle83, Action4417 at Game3/cycle63, Simulation4417 at Game4/cycle79. Puzzle uses its previously earned Sound+Sprites research; other routes retain their recorded access policies. These are progressed Studios, **not untouched starter rosters**. Three Briefs each, public-mean256 planning, no redraws. No seed search, edited state, new cards, changed first-hand choices or future draw inspection.

Test existing behavior first:36 selected hand score projections and18 requested-award results reproduce exactly;630 final choices reproduce baseline completion/balance. For the same630 reached final-hand choices, compare eight fixed cells: Core3 or4 completion target, Scope9 target, no ceiling or ceiling9/10/12, fade4. Base completion and bonus remain separate.5,040 candidate evaluations and36 constructed ceiling boundaries pass. Hypothetical alternate final plays are evaluated only from each actual prior hand; they are not committed/replayed candidate careers.

## Results

Results below are identical for Core3 and Core4 **on the reported counts**, not identical partial completion values. Lowering Core targets does not solve balance failures.

| Ceiling | Recorded selected full base / full bonus / joint full | Reached states with any joint-full choice | States with any positive bonus | Positive choices /630 | Choices with bonus reduced by ceiling |
|---|---|---:|---:|---:|---:|
| None, control | 5 / 5 / 3 | 3 /18 | 10 /18 | 79 | 0 |
| 9 | 5 / 5 / 3 | 3 /18 | 10 /18 | 77 | 4 |
| 10 | 5 / 5 / 3 | 3 /18 | 10 /18 | 79 | 1 |
| 12 | 5 / 5 / 3 | 3 /18 | 10 /18 | 79 | 0 |

Joint-full witnesses occur in Puzzle4417, Puzzle4521 and Simulation4417, and include the actual selected two-hand paths. Puzzle4418, Puzzle4522 and Action4417 have no joint-full final alternative in this retained sample. Eight reached final hands offer no positive balance grade even without a ceiling. Raising the ceiling cannot repair that. Counts are conditional coverage of correlated choices, not independent win rates or estimates of human success.

The ceiling9 hypothesis receives limited support: it preserves all observed joint-full witnesses but removes two positive alternatives. Ceiling10 retains those alternatives and reduces one grade; ceiling12 changes none. The candidate's distinctive Scope decision is therefore weakly exercised in this evidence. Full success is possible; broad accessibility and compelling differentiation are not established.

## Commands and checks

From repository root, executable `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/threads/contracts/studies/compact-package-20261026-v1/analyze.py run-v1
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/threads/contracts/studies/compact-package-20261026-v1/analyze.py replay-v1 | Select-Object -First 9
```

Both fresh processes exit0 in under2 seconds, within the declared60-second limit. The second is an **offline deterministic repeat**, not a Godot gameplay replay. No new gameplay commands, releases, saves, import caches or simulator variants were used. All rows and negative outcomes retained; no rejected cases, incomplete runs, timeouts, retries or failure reduction. [Verification receipt](studies/compact-package-20261026-v1/verification.json) records exact output equality, baseline reference hash, source snapshot and checks.

## Recommendation and remaining uncertainty

Retain Core4 for the next research candidate. Use ceiling9 as the smallest screened case preserving joint-full coverage, with10 and no-ceiling as controls. Keep the threshold **OPEN** because the lost positive choices and largely inactive size rule need actual two-hand planning evidence. Do not adopt ceiling12 simply because it is easier; this sample shows no added decision from it.

Prefer completion-based cash plus a separate minimum(balance,size) bonus. Exact payment, Promotion, advance and Reputation gate remain OPEN; this study does not calculate affordability, income, opportunity cost or the policy optimal for cash. It cannot establish a money-making alternative to Briefs without approved new terms. Existing canonical rewards remain unchanged. No native UI, live settlement, migration, current-source replay, brand-new starter accessibility or player comprehension was tested. The next private pilot must resolve those declared boundaries before an implementation handoff.
