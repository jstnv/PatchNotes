# Starwave cross-specialty reachability and liquidity screen v14

2026-10-09 (America/Los_Angeles). **Completed bounded read-only evidence; no new rule approval.** The user asked this Contracts thread to do most of the cross-specialty investigation here. This finding covers the predeclared first pass through live Starwave hand 3. A matched Game 4 continuation is a separate question. The approved ACTIVE/TRIAL terms remain a $0 acceptance advance, up to $2,240 earned on hand 3, and 0 Starwave Promotion.

## Source and reproduction

- Repository branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. The simulation used the frozen native-v3 Starwave source, including its then-dirty overlay, rather than the concurrently changing checkout. The [original source manifest](../../findings/starwave-implementation-v1/source-manifest-v3.json) has SHA256 `8922fd57eac43ec6ec04160bce01ca8f9712d4c05d396e7ebff721741953e8db`; [recovery provenance](../../findings/starwave-implementation-v1/source-pin-recovery-v3.json) confirms the full pin. The [v12 selected-file manifest](sim-v12/source-manifest.json) records 748 byte-matched project files and SHA256 `6f8893133de0349891c2a5062ca2e0c038259277b0e542cd17d71ee086b3437b`.
- An isolated copy under `C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-cross-specialty-v12-source-copy` hosted the analysis-only [route](sim-v12/cross_specialty_route.gd). Neither the original pin nor repository gameplay files were run or edited. The [runner](sim-v12/run.py) checked source, copy and driver hashes before and after the import and every attempt. Godot 4.7.1 stable headless import and all attempt commands/results are preserved in `sim-v12/import/command.json` and each attempt's `command.json`, `attempt.json`, `godot.log`, `source-after.json`, and `native-route.json`.
- The [predeclaration](sim-v12/PREDECLARATION.md) fixed eight specialty rosters, seed 1104 first, fallback seed 4417 only after a failed primary, and at most 16 attempts. It fixed Lean Production, Studio Buzz, Expensive Lease, contract-deal seed 31104, and a deterministic synergy/mixed/QA card policy. Project Genre matched specialty. The route used real releases, publisher offers, Contracts, Bank, payroll, rent and sales. No cash, ownership, debt, offer, draw or result was injected.
- The [independent audit](sim-v12/audit-summary.json) passed **158,470 checks** over all 14 executed attempts. It verified the source gate, the exact Action 1104 native-v3 control route, legal finance/eligibility, three-hand score and payout arithmetic, and no source drift. All 14 attempts produced structured legal outcomes; there were no driver failures.

## Results

The first pass found three earned and completed Starwave offers. Action and Racing succeeded on their primary seed; Puzzle succeeded only on its declared fallback. The other five specialties did not reach the Crown Review prerequisite under either fixed seed and policy. Puzzle's failed primary brings the total to **14 attempts: 3 completions and 11 legal foundation dropouts**. All dropouts stopped at an unearned Crown offer, with both recorded Reviews below 7.0; no failed route was counted as a Starwave hand.

| Specialty | Seed(s) | Review sequence | Outcome | Starwave numerator / 112 | Hand-3 receipt | Cash before acceptance → after hand 3 |
|---|---:|---|---|---:|---:|---:|
| Action | [1104](sim-v12/action-1104/native-route.json) | 5.8 / 7.3 / 7.8 | Earned; three hands completed | 111 | $2,220 | $16,847.67 → $20,670.83 |
| Adventure | [1104](sim-v12/adventure-1104/native-route.json), [4417](sim-v12/adventure-4417/native-route.json) | 4.2 / 6.1; 4.1 / 6.1 | Crown not earned in either route | — | — | — |
| Role-Playing | [1104](sim-v12/role_playing-1104/native-route.json), [4417](sim-v12/role_playing-4417/native-route.json) | 4.5 / 6.6; 4.9 / 4.9 | Crown not earned in either route | — | — | — |
| Strategy | [1104](sim-v12/strategy-1104/native-route.json), [4417](sim-v12/strategy-4417/native-route.json) | 4.7 / 6.9; 4.6 / 6.4 | Crown not earned in either route | — | — | — |
| Simulation | [1104](sim-v12/simulation-1104/native-route.json), [4417](sim-v12/simulation-4417/native-route.json) | 3.7 / 6.0; 4.3 / 4.9 | Crown not earned in either route | — | — | — |
| Puzzle | [1104](sim-v12/puzzle-1104/native-route.json), [4417](sim-v12/puzzle-4417/native-route.json) | 3.5 / 6.4; 3.8 / 7.4 / 7.4 | First route stopped; fallback earned and completed | 96 | $1,920 | $15,632.65 → $18,792.17 |
| Sports | [1104](sim-v12/sports-1104/native-route.json), [4417](sim-v12/sports-4417/native-route.json) | 4.1 / 5.7; 4.5 / 6.0 | Crown not earned in either route | — | — | — |
| Racing | [1104](sim-v12/racing-1104/native-route.json) | 5.5 / 7.8 / 7.6 | Earned; three hands completed | 106 | $2,120 | $17,761.06 → $21,505.19 |

The successful traces record the actual seven-card draws, four-card selections, finite Feature use, renewable Passes, frozen eligible pool, exact scores, finance journal and credit. Their hand-3 cash changes include normal cycle effects and are **not** equal to the Contract receipt alone. Action 1104 matched the pinned implementation route on the audited release, Contract hand/result, and before/after cash fields after normalizing run-owned IDs. [Raw attempt folders](sim-v12/) and the [audit summary](sim-v12/audit-summary.json) provide the full per-stage evidence.

No successful route had a useful action blocked for lack of cash or an unpaid original due bill between Starwave acceptance and its completing-hand receipt. All three accepted with more than $15,000 cash. Therefore this declared sample does **not** justify an acceptance-advance comparison. This negative result does not prove that no legal low-cash route exists.

## Interpretation and limits

The primary obstacle in these fixed routes was earning Crown, not completing Starwave's three hands. This is a route-coverage observation, **not** a finding that five specialties are inherently unable to unlock Starwave or that the rosters are balanced. The sample uses two seeds at most, one selection/spend policy, one trait bundle and Genre matched to specialty. Genre rating effects and roster effects are confounded. It does not sample alternative development choices, Store purchases or later successful releases.

This first pass ends at hand 3. It cannot measure the opportunity cost of three productive cycles against starting Game 4, later settled sales, or next-project access. Headless simulation and independent ledger checks also do not substitute for the implementing thread's maintained combined gate, rendered review or actual exported interaction.

**Recommendation:** retain the approved $0/$2,240/0-Promotion Starwave trial unchanged. Run a separately declared matched Game 4 continuation for the three successful checkpoints before interpreting net economic value. If cross-specialty fairness becomes a priority, test a deliberately different *legal* route policy that can earn Crown in additional specialties; preserve failed attempts and separate Genre from roster effects. Keep any advance amount and final balance OPEN until a naturally constrained route and a later user ruling exist.
