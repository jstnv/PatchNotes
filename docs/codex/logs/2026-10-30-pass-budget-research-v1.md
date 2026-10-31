# Pass Budget research session — 2026-10-30

Branch `main`, HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`. Shared worktree had many prior modified/untracked files; no existing file was edited by this session. Changed file: `threads/simulation-engine/2026-10-30-pass-budget-preflight-v1.md` and this log only.

Task: source audit for the requested research-only Action Pass Budget comparison. User chose fresh Studio progression as the experiment origin. Findings: live required Scope is hardcoded 30; Action review standards are 40/26/40/26; Scope multiplies production rating; current renewable Pass draw has no budget and exact-seven assumptions. See the [source-pinned preflight](../threads/simulation-engine/2026-10-30-pass-budget-preflight-v1.md).

Correction, same date: the user clarified that 35 means combined Scope of available Feature cards, not project required Scope. The preflight's experimental-capacity inference was wrong and is superseded by the [exact Action Feature research finding](../threads/simulation-engine/2026-10-30-action-feature-build-finding-v1.md). Project required Scope remains 30.

Checks: `git branch --show-current`, `git rev-parse HEAD`, `git status --short`, `git diff --stat` inspected before work; targeted source and ledger reads completed. Exact source lines and the optimistic Scope bound were inspected/calculated. **NOT RUN:** simulator variant, 1,000-run matrix, exact replay, native/headless parity, economy and trace verification. No formula or skill-tree values approved. Follow-up: build an isolated variant with experimental capacity axis and budget, obtain legal fresh-Studio progression for matched seeds, then run the declared strategy matrix and report failures alongside completed releases.
