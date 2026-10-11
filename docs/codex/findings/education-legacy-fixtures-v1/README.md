# Genuine pre-education checkpoint fixtures

2026-10-09. **Seven native producers passed;130 independent offline checks passed.** These checkpoint bytes were generated and pinned before E1–E4 education implementation began. They are controlled legacy-version fixtures, not historical human saves or proof of the new runtime's compatibility.

| Files (prefix) | Canonical trait version | Preview selection |
|---|---:|---|
| `v3-college_dropout` / `v3-graduate` | 3 | Inactive education preview |
| `v4-college_dropout` / `v4-graduate` | 4 | Inactive education preview |
| `v5-college_dropout` / `v5-graduate` | 5 | Inactive education preview |
| `v5-ordinary` | 5 | No traits |

Each prefix has `.checkpoint.json` (exact store envelope), `.payload.json` (its exact UTF-8 payload), `.result.json`, `.command.json`, `.log` and `.manifest.json`. All have unique real run IDs/profiles and exactly$5,700 creation cash: the$5,500 base plus the ordinary four-point$200 financing receipt. Education previews have zero refund, no active trait effect, no education account, no debt or bill. They receive no extra receipt. All files passed the old strict schema/store/codec and hydrate→recapture equality.

## Source and construction

Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, dirty integrated Fanbase/Starwave work preserved. Old rules:

`finance5-bank1-employees1-traits5-sales1-contracts3-research1-review2-fanbase1-starwave1`

Old content revision:

`c7f6f3165ea85f7afd5070042d053ce581f84338437640c3e4b6de787c1f5a5b`

`source-before.json` and `source-after.json` match exactly:215 relevant source files (scripts, JSON data and project configuration), external producer/runner/plan and Godot executable hash. Source was checked before and after every native process. Per-fixture manifests bind these source records, exact envelope/payload/result/command/log hashes and declared inputs. `audit.json` independently verifies all130 checks.

The external findings-owned SceneTree script calls existing `StudioTraits.evaluate_traits(ids, version)` and passes that canonical supported selection to `RunState._commit_studio_creation`, the same commit path used by public creation. It does not assign private runtime state or rewrite any DTO. It captures through StudioCheckpoint, writes through StudioCheckpointStore, opens through CheckpointCodec and exports the exact bytes. Explicit version arguments label controlled old selections; they do not claim an earlier historical engine was run.

Each process uses a unique isolated profile and custom writer port48971. No gameplay scene or default coordinator is instantiated, so production62741 and reserved47733/47846 are never used. No user save, main file, immutable source copy, UI or Computer Use was touched. Only the known exact root-certificate-store environment error is allowed; native scripts otherwise passed without errors. No producer process remains live.

## E4 use

Copy the selected `.checkpoint.json` bytes into a fresh compatibility profile as `checkpoint.1.json`. Keep these originals immutable. Verify the source fixture hash before and after testing. Exercise the new runtime through its real store/Continue coordinator, then inspect canonical trait version, inactive IDs, cash/finance/RNG and zero education state. A subsequent new-schema save and another fresh-process Continue must retain that state without retroactive refund or debt. Use `E4-ACCEPTANCE.md` for the detailed review boundary.

Do not regenerate these fixtures after education implementation. `run.py` deliberately rejects overwriting completed records; its source pins would also no longer match the pre-education source. `audit.py` is an offline byte/metadata audit and can be rerun without invoking Godot or modifying checkpoint fixtures. Unsupported/corrupt tests must use separate copies and retain original bytes.
