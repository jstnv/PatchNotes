# 2026-11-04 — New proprietary engine starter Features

Starting branch `main`, HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`. Existing tracked/untracked edits and `.codex-godot-temp` were preserved. Direct user request: new engines should have Text, 4-Color Palette, 8-Bit Sound and Keyboard & Mouse implemented by default.

## Implementation

New paid proprietary engines now create those four actual Feature cards in the initial, implemented and future-supply library; together they have 5 printed Scope. They require no separate implementation deposit, queue entry or productive completion. Existing $100 creation, 25 maximum Scope, card play costs/exhaustion and Skill Tree effects remain unchanged. The existing fixed Public and licensed libraries are unchanged. Active projects and accepted Contracts continue to use their frozen supply. UI creation text, Skill Tree explanation and How to Play now describe the new rule and retain the distinction for older engines.

New records use `proprietary-creation-v2` with the exact starter manifest; the old `proprietary-creation-v1` remains valid only with its original empty initial manifest. Engine-feature, proprietary, commission royalty and rival frozen-capacity validation recognize the distinct origin. This permits old and new engines to coexist without retroactive grants while retaining strict tamper/provenance checks. One exact preceding runtime source identity, `c47e5abf16d401fd7b06ad7b2e7e2e188a060410e5929b60dfc1ce882e9f109c`, was captured before editing and admitted to the existing validated predecessor list.

Runtime edits: `scripts/run_state.gd`, `scripts/engines/proprietary_engine_state.gd`, `scripts/engines/engine_feature_state.gd`, `scripts/contracts/publisher_commission_trial.gd`, `scripts/market/rival_world_checkpoint.gd`, `scripts/ui/engine_market_browser.gd`, `scripts/ui/progression_tree_data.gd`, `scripts/ui/how_to_play_content.gd`. Debug verifiers: new `verify_new_engine_foundations.gd` and updated `verify_proprietary_engine_foundation.gd`, `verify_first_studio_feature_economy.gd`, `verify_engine_feature_workflow.gd`, `verify_engine_skill_tree.gd`, `verify_engine_skill_world_continue.gd`.

## Checks

- Final isolated headless Godot 4.7.1 starter verifier passed 43/43: exact initial/implemented/future IDs, no added cycle/queue/RNG changes, unchanged Public library, creation cost, project freeze, genuine pre-change engine checkpoint restore, mixed old/new engines, malformed origin/manifest rejection, and missing-field rejection. A legal released-game Studio accepted an actual Contract and retained the frozen four-card pool after switching engines. A synthetic proprietary release binding projected zero royalty; this is not a full commission career. `sims/new-engine-foundations-20261104/contract-royalty-malformed-final/`.
- Actual pre-change old-engine checkpoint and separate started-project supply metadata were captured before changes in `sims/new-engine-foundations-20261104/old-engine/`. The checkpoint restores exactly with its old empty library. Active projects are not Studio checkpoints, so this is not a claim of mid-project save restoration; the frozen-project test uses a project started after continuing that old engine.
- Final isolated workflow, foundation, first-Studio economy, Skill Tree and world Continue verifiers each reported zero failures, including paid Controller implementation, FIFO/discounts, play costs, project freezes, old migrations and world roundtrip. Logs: `sims/new-engine-start-features-20261104/{workflow-confirm,foundation-confirm,economy-confirm,skill-tree-confirm,skill-world-confirm}/`. Initial Skill Tree and world-fixture failures are retained in `skill-tree/` and `skill-world/`; the former mislabeled a new grant as an old state, the latter raced asynchronous title inspection. The corrected fixtures passed.
- The exact pre-change player/eight-rival pair restored with `player_exact=true`, `world_except_stamp_exact=true`, `unknown_rejected=true`, eight studios: `sims/engine-starter-features-20261104/restore-final/`.
- Whitespace check: `git -c core.whitespace=cr-at-eol diff --check` for changed runtime scripts and docs.

## Limits

These are focused headless checks, not exported-build, device or broad balance acceptance. Known missing-artwork/UID fallback warnings and 20 ObjectDB instances leaked at some isolated test exits remain in retained stderr logs; no cause for the latter is claimed. The separate disk cleanup and performance audit remain paused. No commit, push or release build was made.
