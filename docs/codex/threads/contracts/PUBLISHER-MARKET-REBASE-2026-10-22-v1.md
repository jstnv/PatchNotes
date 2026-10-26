# SideStreet Brief private variant: current market rebase v1

2026-10-22 (America/Los_Angeles). **CANDIDATE only.** This is a private Contracts simulator revision, not canonical gameplay, a design approval, an adoption packet, or a simulation finding. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; the shared worktree was dirty and left intact. No shared TODO, canonical project, commit, or push was changed.

## Source and ancestry

- Created with `python tools/simulator_variant.py create --id publisher-progression-market-v1 --owner contracts --output docs/codex/threads/contracts/simulators/publisher-progression-market-v1` from the then-current `patch-notes/` working source. [Variant metadata](simulators/publisher-progression-market-v1/variant.json), [frozen source](simulators/publisher-progression-market-v1/base-source.zip), and its manifests preserve base/creation identity `5edfa7878cd17904281d7cf7f2cf907e67b5f40edb4d9db83b3f99580f2aa415`; lineage is empty. They were not edited after creation.
- The historical [publisher-progression-v1](simulators/publisher-progression-v1/variant.json) is a separate candidate from base identity `798e8be69bf595922096064807a0164e6be7911bec8f4595b99d19c40e9a68e3`. This revision is a fresh canonical-base variant, **not** a `--from-variant` descendant. Only its Brief/Reputation delta was consulted and selectively ported.
- The frozen current-market Studio revision is `f522bf2f8166cba5fa68cb9936c04ef0b64d46560d5e68cca9681733e1fa7f0b` (`source_build=studio-checkpoint-runtime-v1`). The private Brief revision is `a4285194b465dd907e8f904ec3dff37796d1689e664a9aebe4c36d7dbc8095ab`. These content revisions match the historical variant's values despite an additional current-source decoder fix; source identities must still be checked independently.

## Port and reconciliation

The private `project/` changes register the two-hand SideStreet Relationship Brief beside the existing cash offer, keep its direct cash and Promotion at zero, grade its Scope/redraw promise, issue at most one pending/active Brief after a qualifying release, and award Reputation once at completion by `floor(1000 * min(completion_bp, promise_bp) / 10000)`. Existing work-Contract completion counts, cash and Promotion stay separate. The candidate carries its own focused verifiers. The added/modified source paths are `scripts/run_state.gd`, `scripts/contracts/{contract_challenges,contract_definitions,contract_state,publisher_relationship_brief}.gd`, `scripts/persistence/{checkpoint_schema,studio_checkpoint}.gd`, `scripts/phases/{contract_phase,studio_phase}.gd`, `scripts/simulation/{campaign_session,studio_actions}.gd`, `scripts/market/{legacy_market_schema,legacy_market_studio_validator,publisher_brief_save_migration}.gd`, and `scripts/debug/{verify_contract_definitions,verify_publisher_relationship_brief,verify_publisher_prior_market_migration}.gd`; Godot generated UIDs for the new files. The exact changed bytes are in this version's `project/` and its preserved baseline.

A file-by-file comparison found that the old variant's Brief gameplay edits had no Oct22 drift except `scripts/persistence/studio_checkpoint.gd`. The current base added a strict seven-line decode branch for current `-market1` payloads. The three-way merge was clean and retained that branch. For prior-current-save migration, `legacy_market_studio_validator.gd` and `legacy_market_schema.gd` were rebuilt from **this variant's own** `base-source.zip`, changing only class/schema names. The adapter checks the exact old build and revision, validates/decodes with that frozen schema, adds only three empty Brief/Reputation maps, encodes at the private revision and validates again. Both validation and hydration route through it. This does not relabel a full rival-world envelope's source identity, and the adapter rejects a `rival_world` payload; world migration remains unproven.

The [SideStreet Brief proposal](SIDESTREET-RELATIONSHIP-BRIEF-PROPOSAL-2026-10-18-v3.md) and [publisher-system design](PUBLISHER-SYSTEM-DESIGN-2026-10-18-v3.md) remain **PROPOSED**. The candidate is an experiment, including its $0 Brief terms and 10-point maximum Reputation award. Commission and support mechanics were not ported or added.

## Focused checks and limits

Godot: `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe` (4.7.1). Checks used separate private profiles under [checks](simulators/publisher-progression-market-v1/checks/), `--headless --path <this variant's project> --editor --quit` for import and `--headless --path <project> --script res://scripts/debug/<name>.gd` for verifiers. The isolated import exited 0 with zero `ERROR:` lines. An earlier non-isolated editor invocation exited 0 but logged inaccessible roaming-profile settings and is **not** counted as a clean check.

| Check | Result | Retained log |
| --- | --- | --- |
| Contract definitions | 34 `PASS` lines; exit 0, zero errors | [log](simulators/publisher-progression-market-v1/checks/verify_contract_definitions.log) |
| Brief issuance, grade, reward, checkpoint | 32 `PASS` lines; exit 0, zero errors | [log](simulators/publisher-progression-market-v1/checks/verify_publisher_relationship_brief.log) |
| Constructed exact prior-current Studio and active-rival Studio migration | 61/61; exit 0, zero errors | [log](simulators/publisher-progression-market-v1/checks/verify_publisher_prior_market_migration.log) |
| Current AI-market transaction regression | 122/122 across 11 cycles and two releases; exit 0, zero errors | [log](simulators/publisher-progression-market-v1/checks/verify_market_density_trial.log) |
| Actual retained prior-current Studio frame migration | 104/104; exit 0, zero errors | [log](simulators/publisher-progression-market-v1/checks/actual-frame-migration.log) |

The actual frame is [Sports 1104 Studio checkpoint](sims/publisher-pilot-current-access-20261022-v7/cases/sports-1104-current-access-alpha5/studio_checkpoint.json), SHA-256 `0d4141d0c78a62aa89f23b32900225ef17d50ada3a923089b7f0544433fd3947`, revision `f522bf2f...`, frame source identity `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536`. The verifier checks its integrity and underlying Studio payload preservation. That frame source identity differs from the new variant's creation identity, so this check **does not** claim direct `simulate.py` Continue compatibility or migrate the frame's whole rival world. No `simulate.py` candidate run or replay has been performed on this new variant yet.

## Next evidence gate

Run the predeclared legal Brief cases using `tools/simulate.py run --variant` into a new bundle, with fresh same-version legal prefixes and exact replay. Keep failed cases. Only after that should a separate private commission/support candidate and source-pinned handoff be considered. Passing private checks cannot approve the proposed values.
