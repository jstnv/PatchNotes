# Cap sensitivity session log

2026-10-07, America/Los_Angeles. Shared checkout: branch `main`, HEAD `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`. The working tree already contained unrelated modified/untracked design and gameplay work, which this slice preserved. The Task 34 input is its isolated pinned copy and 42 result files; [hashes](input-sha256.json) record the exact inputs read.

Files added only in this folder: `PREDECLARATION.md`, `analyze.py`, `input-sha256.json`, `results.json`, `paired-payouts.csv`, `FINDINGS-v1.md`, and this log. No shared TODO/design authority, gameplay source, test, asset or configuration was edited by this slice.

Executed `analyze.py` with the bundled Codex Python runtime. It verified exact baseline payouts for all 2,880 Crown/Neon arms across 42 Task 34 result files, re-scored 2,712 recorded completions at three caps each, and produced 2,052 primary paired payout rows plus a header. Assertions passed; exit code 0. The paired table uses exact fraction numerator/denominator and integer-cent floors. No Godot typed-finance continuation was run, so alternate-cap completion and downstream economy effects remain unverified.

Recommendation: retain the current $1,920 Crown/$1,560 Neon cap candidates for the design ruling, with Crown $150/Neon $0 advance recommendations kept separate. No value was approved, implemented, committed or pushed here.
