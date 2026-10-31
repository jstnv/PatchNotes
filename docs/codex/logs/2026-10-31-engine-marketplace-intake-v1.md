# Engine Marketplace implementation intake — 2026-10-31

Branch `main`, observed HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`. The inherited dirty worktree and `.codex-godot-temp` were preserved. No commit, push, export or release claim.

The user requested a complete Engine System and Marketplace, but three live rules are undefined: whether 20% royalty uses gross or platform-net sales, whether the 25-Scope starting engines hard-cap projects below the existing 30-Scope requirement, and what engine an unlicensed new Studio uses. The brief explicitly says to report undefined rules rather than invent financial or gameplay mechanics. These questions were sent to the user. The live transaction, capacity, royalty, selection, UI and checkpoint paths remain pending their answer.

Independent implementation completed:

- `scripts/engines/engine_marketplace.gd`: fixed Action/Puzzle listings with exact owner IDs, specialty, 25 Scope, $7,500, 20% and dominant +0.1 categories. Both certified openings contain `incumbent-action` / Arcade Foundry and `incumbent-puzzle` / Prism Logic with matching specialties.
- `scripts/engines/engine_entitlements.gd`: pure, typed entitlement record and license quote. It preflights $7,500 buyer debit/creator credit, insufficient funds, wrong owner, duplicate entitlement and overflow, without mutating a live RunState. It is not a completed purchase flow.
- `scripts/simulation/production_hand.gd`: backward-compatible optional per-category basis-point addition to the existing 1.5 Specialization arithmetic. No live engine selection supplies this input yet; ordinary production remains unchanged.
- New focused verifiers: `verify_engine_catalog.gd`, `verify_engine_entitlements.gd`, `verify_engine_specialization.gd`. [Design and remaining plan](../design/engine-marketplace.md) · [implementation steps](../threads/engine-system/2026-10-31-implementation-plan-v1.md).

Verification used the available Godot **4.7.1** executable, redirected `APPDATA`/`LOCALAPPDATA` into `.codex-godot-temp`, and `--headless --path patch-notes --script res://scripts/debug/<name>.gd`. The three new verifiers were seen failing first for missing APIs/files, then each passed with zero failures. Existing `verify_production_extraction`, `verify_score_floats` (385/0) and `verify_pass_budget` also passed. Stdout/stderr are retained in `.codex-godot-temp/*engine*.out.txt` and `*.err.txt`. Godot 4.4, full suite, real purchases, royalties, saves and UI were **NOT RUN** for this intake.
