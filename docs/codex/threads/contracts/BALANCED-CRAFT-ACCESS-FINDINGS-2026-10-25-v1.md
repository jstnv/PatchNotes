# Balanced Craft Brief — new-roster access baseline

2026-10-25. **Existing-behavior screen complete; paid-search/Brief affordability not yet measured.** [Approved pilot terms](BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md) · [fixed pre-run plan](studies/balanced-craft-access-20261025-v1/PLAN.md) · [analysis](studies/balanced-craft-access-20261025-v1/analysis.json).

## Result

All **32 cases** complete four releases: 2,304 accepted commands, 128 releases, 28 productive cycles per case. No rejected commands, timeouts or overdue balance in this screen. **Zero cases reach Crown's existing released Review7 gate.** Actual Reviews span0.4–2.4. Starting cash is $5,700; final cash spans **$954.88–$4,028.85**. The lowest observed transaction balance is **$440.90**, in Adventure/4417/visible-order. This cash result covers the recorded production routes only, not hypothetical Search or Brief payments.

| Specialty | Best recorded Review across four cases | End cash range |
|---|---:|---:|
| Action | 2.2 | $2,207.68–$3,965.29 |
| Adventure | 1.5 | $954.88–$1,750.96 |
| Puzzle | 1.9 | $1,806.07–$2,107.33 |
| Racing | 2.3 | $2,244.94–$3,272.56 |
| Role-Playing | 1.6 | $1,451.24–$2,144.32 |
| Simulation | 2.1 | $1,751.31–$2,857.68 |
| Sports | 2.0 | $2,064.52–$2,960.12 |
| Strategy | 2.4 | $2,571.17–$4,028.85 |

These are deliberately simple **two-hands-per-phase policies**, without cash Contracts, Research, Bank, Traits, employees, redraws or priority changes. They provide a reproducible baseline and a warning against assuming that completing several games establishes Crown access. They do not show that a specialty cannot reach Crown, that four games is the intended progression, or that the Review7 gate should be lowered. No before/after-roster comparison was run; the outcomes cannot be attributed solely to the roster revision.

## Search status and approval

The user explicitly approved [the unchanged Brief terms](BALANCED-CRAFT-PILOT-TERMS-2026-10-25-v1.md) this turn. Prior pending-user-approval wording is superseded by the approval record. Two hands, Scope9/Core4/spread2, the retained balance fade and up-to10R formula remain fixed; cash/advance/Promotion/Investment are zero. No reward or gate was adjusted in this study.

At intake, internal TODO still lists Contract Search QUEUED. Source search for `search_contract|contract_search|search_for_work` across scripts/tools found no implementation symbols; the canonical publisher definition has no Crown Brief. A compact read-only PN Implementation snapshot reported new-save loading and Employees work in progress. No completed Search acceptance receipt was found. Thus this is an **existing-behavior prerequisite study**, not a substitute Search implementation. No paid wait, fake offer, edited standing or fabricated release source was used.

## Setup and source identity

- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty shared worktree preserved. [Git snapshot](studies/balanced-craft-access-20261025-v1/status.txt) and [diff summary](studies/balanced-craft-access-20261025-v1/diff.txt).
- Named thread variant `simulators/balanced-craft-access-20261025-v1`, canonical baseline and creation identity **`0d63b4ab5aeb0def3c526e613d613beef7f54f415dce2c777d4603a8abbbd343`**. No project edits or gameplay delta. Actual executed mechanics identity **`8216dc125219a21db6dd1b8971b6a6740c95e80ca472b4fc9bcb0d680d015d5f`**. Original manifest/archive/ancestry retained; current canonical drift belongs to concurrent work.
- All eight current roster-v3 specialties, seeds4417 and4521, no Traits, legal fresh recipe with same Studio ID/name/seed within each policy pair. Frozen founding ownership matches the independent v3 fixture for **all32 cases**.
- Existing finite test policy: visible_order versus features_first, exactly two hands each in Design/Alpha/Beta, same specialty Genre/Fantasy theme; four-release target,160-command limit,600second import/experiment limits. One runner at a time. First observation/state and RNG exactly match for **all16 pairs**. Equal seeds alone were not accepted as sufficient.
- Telemetry records every command boundary and newly observed transaction lows. Final/initial digests and sample counts reconcile to every result. Missing finance would have been unknown; measured overdue is available and zero. No Bank loans are taken by this policy.

## Reproduction, evidence and failures

Bundled Python: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`; Godot: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.

From repository root:

1. `tools/simulator_variant.py create --id balanced-craft-access-20261025-v1 --owner contracts --output docs/codex/threads/contracts/simulators/balanced-craft-access-20261025-v1`
2. `docs/codex/threads/contracts/studies/balanced-craft-access-20261025-v1/run.py setup`
3. Same helper `run.py baseline`, then `analyze.py`.
4. Same helper `run.py replay action-4417-features_first`, `run.py replay action-4521-features_first`, and `run.py continue action-4417-features_first`.

The helper invokes the documented `tools/simulate.py run --variant ... --config ... --output ... --timeout 600 --godot ...`; exact absolute arguments, exit codes and driver logs are retained per command in the study folder. Raw bundles live outside OneDrive at `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/balanced-craft-access-20261025-v1/`. [Evidence hashes](studies/balanced-craft-access-20261025-v1/evidence-manifest.json) preserve cases/results/tapes/telemetry; do not overwrite outputs to rerun.

Baseline exit0, elapsed182.68seconds including isolation/import. All cases retained. No rejected case exists, so failure reduction is **not applicable**. Discovery included missing-path/Windows-wildcard read errors, corrected with explicit source paths; they are not failed game cases. The analysis initially chose two replays from one pair; corrected before replay execution to the predeclared two distinct pairs, with no change to seeds/budgets/cases/outcomes.

The baseline and replay logs retain an exit warning for six leaked ObjectDB instances. Passing replay/status checks do not clear that warning or establish release readiness.

**PASS:** both representative fresh-process replays match72 commands and73 telemetry samples each. Cold Studio Continue restores exact initial state/RNG, then completes18 accepted commands/one more release to Game5/cycle35. All32 final Studio checkpoints confirm founding roster3 and Crown still locked. Variant source has zero gameplay delta against its preserved baseline. [Closeout](studies/balanced-craft-access-20261025-v1/closeout.json) also records concurrent canonical drift; it is not overwritten or treated as tested by this frozen study. No native/UI/export or human comprehension check is claimed. No populated active-rival or new employee-payroll exposure is established by this policy.

## Recommendation / next work

Keep approved rewards unchanged. The next useful access policy should use ordinary introductory cash work, legal affordable Research and quality-oriented development on the new rosters, with fixed budgets and no redraw optimization. Register that separately; do not extend this baseline until a favorable seed appears. Its purpose is to earn genuine Review7 Studio boundaries and expose how much development/cash is required before Crown.

Once accepted Contract Search exists, create a new source-pinned private Crown Brief variant using the approved terms. Regenerate compatible legal prefixes; compare Brief-led, release-led and no-search routes from identical eligible states. Measure actual search+hand costs, rent/debt, R progress and provisional preview behavior. The minimum three-cycle commitment is a rule statement, **not an affordability result from these runs**. Keep cash-poor and historical-roster cohorts explicit and preserve structural adoption gates before player exposure.
