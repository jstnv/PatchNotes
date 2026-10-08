# Contracts low-Scope target sensitivity — read-only finding

2026-10-07 (America/Los_Angeles). **The predeclared narrow sensitivity completed.** Main source revision `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`, from the pinned Task 34 isolated project. Candidate Crown/Neon offers, payouts and Promotion remain analysis overlays; no gameplay, tests, assets, configuration, shared To Do List or design authority were changed. This result is evidence, not a numerical ruling.

## Setup and source

The [predeclaration](PREDECLARATION.md) fixed four genuine typed native checkpoints: Crown eligible ordinary Action routes with $5,500 and $5,700 starts, plus genuinely Neon eligible Game 2 marketing routes with the same two starts. Input SHA-256s are in the predeclaration. At the earliest eligible release in each route, three fixed draw seeds `200929000`–`200929002` ran each target pair with $0 acceptance advance. Candidate caps stayed Crown $1,920/12 Promotion and Neon $1,560/20 Promotion. No cap or advance sensitivity was run here.

An isolated copy of the pinned Godot project lives in ignored `project/` inside this folder. [Copy manifest](copy-manifest.json) records 599 original files checked against the Task 34 source manifest, plus the analysis base and low-Scope policy hashes. Bulky ignored historical design logs and old Godot caches were omitted; a fresh import passed. Godot 4.7.1 ran with `APPDATA` and `LOCALAPPDATA` profiles here. The previous Task 34 project and the shared worktree were not modified. The source copy includes only the pinned source, so later uncommitted gameplay work is outside this experiment.

The target-independent policy chose the legal four-card hand with the least **positive** native Scope addition and positive total Core half-score addition, breaking ties by larger Core addition then first enumerated slot order. Native draw/redraw, `ContractState.plan_hand`/commit, finite owned Features, retained cards, two productive cycles and native finance/sales planners were used. This deliberately stresses Scope and is not an estimate of player strategy. Each paired target saw identical pools, draws, selected cards, Scope and Core.

## Results

All **24/24 candidate arms** completed two legal hands, with final Scope **5, 7 or 6** for seeds `200929000`, `200929001`, `200929002`. Thus both targets bind. The two startups reproduced the same hands and candidate payouts; their final cash differs by the genuine $200 starting receipt. Neither startup had a hand rejection or final arrears in these routes.

| Publisher | Seed | Final Scope | Lower target payout | Higher target payout | Lower minus higher | Conditional Promotion |
|---|---:|---:|---:|---:|---:|---|
| Crown | 200929000 | 5 | Scope 9: $989.09 | Scope 10: $960.00 | $29.09 | 6 vs 6 |
| Crown | 200929001 | 7 | Scope 9: $1,629.09 | Scope 10: $1,588.36 | $40.73 | 10 vs 9 |
| Crown | 200929002 | 6 | Scope 9: $1,570.90 | Scope 10: $1,536.00 | $34.90 | 9 vs 9 |
| Neon | 200929000 | 5 | Scope 10: $1,088.37 | Scope 11: $1,071.88 | $16.49 | 13 vs 13 |
| Neon | 200929001 | 7 | Scope 10: $1,342.32 | Scope 11: $1,319.23 | $23.09 | 17 vs 16 |
| Neon | 200929002 | 6 | Scope 10: $979.53 | Scope 11: $959.74 | $19.79 | 12 vs 12 |

Each row occurs once for each starting ledger; [all arm rows](arms.csv), [paired rows](pairs.csv) and the four unabridged raw JSON outputs preserve both. Exact fixed-share fractions, Core half-scores, selected cards, action journals and finance transactions are in the raw outputs. The target choice changed direct cash by **$29.09–$40.73 Crown** and **$16.49–$23.09 Neon** in this stress, with one conditional Promotion point in one of three seeds for each publisher. Matched final cash changed by exactly the direct payout delta. No Promotion was inserted into live sales or counted as current spendable cash.

## Verification and limits

The four Godot runs report **580 native/model checks and zero failures**. [Independent audit](audit.py) passed **8,137 exact-integer checks**: input/source hashes, native eligibility, paired draw/hand identity, seven-card/four-card membership, finite Feature non-reuse, positive Scope/Core, rational target formulas, floor cents and whole Promotion, harder-target monotonicity, one acceptance action and one hand-2 receipt, productive cycles, full transaction cash/sequence continuity, cash and arrears. [Audit result](audit-results.json), [commands/logs](README.md) and raw results allow inspection. The audit's first draft incorrectly expected the opening funding transaction's `cash_before` to equal initial capital; it was corrected to verify the genuine 0-to-capital funding row before the successful run. The Godot logs include known Windows root-certificate and case-path warnings; they contain no script errors.

The earlier [Task 34 current cohort](../sim-v3/summary.csv) had completed Scope at or above every harder target, so it showed no target effect. This intentionally low-Scope legal stress demonstrates that the fixed-share formulas do distinguish the target choices when Scope binds. It does **not** establish how often players choose these hands, whether lower-Scope play is strategically useful, or whether either target or cap produces the intended economy. It does not evaluate Starwave, a live offer/Promotion implementation, later release timing or adaptive follow-up play. Four prepared routes share one production policy and three draw seeds; startup duplicates are paired ledgers, not six independent strategies.

**Recommendation:** keep Crown 9/10 and Neon 10/11 as OPEN candidates pending the intended Scope difficulty and cash role. The harder target modestly reduces cash on these legal low-Scope hands and sometimes one conditional Promotion point; the normal Task 34 cohort saw no difference. No broad rerun is indicated without a specific new balance question. Neither target nor cap is approved by this finding.
