# Release-gate test writer isolation

2026-10-09. **Focused PASS: four native verifier processes /97 assertions, two preflight rejection controls,902 offline checks.** All104 maintained-verifier wrappers were generated and hashed; this focused result does not claim all104 suites ran. The parent owns the full final gate.

`tools/release_gate.py` now accepts `--isolate-checkpoint-writer`. The default production62741 preflight remains unchanged. The explicit mode checks47733 is free, uses fresh isolated user profiles, and runs findings-generated scripts inheriting the original verifiers. A SceneTree.node_added hook replaces a newly created coordinator's pristine store with a test subclass. Directory and validator are preserved; its acquire body exactly matches the existing `verify_checkpoint_store.gd` TestStore convention. It obtains a real local TCP lease, rejects duplicate owners and releases normally. No source/runtime/lease bypass or unconditional acquire success was added.

The hook runs before an inherited `_initialize`. Legacy verifiers that schedule deferred work from `_init` keep that work and do not call a nonexistent parent callback. One narrow source-bound exception preserves `verify_genre_checkpoint`'s own already-listening PN_CHECKPOINT_TEST_PORT lease, acquired before its coordinator enters the tree. Other acquired or modified stores are rejected; they are never reset silently. Original verifier-specific leases assigned after insertion remain under their tests' control.

## Evidence

| Process | Result |
|---|---|
| Wrapped main-menu/history |18 assertions, exit0; fresh coordinator isolated |
| Wrapped checkpoint runtime |26 assertions, exit0; real saves/Continue/recovery/failure retry preserved |
| Wrapped Genre checkpoint |43 assertions, exit0; original acquired test lease retained |
| Findings-owned lease collision |10 assertions, exit0; real listener, same-owner reuse, second-owner rejection, explicit release/takeover and coordinator-exit release |
| Default gate preflight |Existing production writer causes exit2 before import, unchanged behavior |
| Explicit isolation preflight |Deliberately occupied47733 causes exit2 before import |

All native output/commands and source hashes are retained. `source-before.json` and `source-after.json` match236 runtime/debug/tool/harness entries; `wrappers.json` binds each generated wrapper to its exact original verifier. The helper hash is `3168c82e1aa55e876c1f7050b44d741c071dc359872df31984045f48d9a4d147`. The902-check offline audit verifies those bindings, identical TCP acquire bodies, initializer ordering, narrow exception, actual commands/raw diagnostics and rejection controls. Independent read-only review found no remaining tooling issue. An initial offline log regex matched the English word “Failed” in a passing negative-case assertion; diagnostic anchoring was corrected, then the audit passed. No native rerun or evidence modification resulted.

The mode records instrumentation/limits and wrapper hashes in gate-result.json. Resume rejects changed modes, helpers, wrapper bytes or original verifier/source hashes. Final validation checks helper/wrappers remained unchanged.

## Limits and next command

Instrumented coordinators exercise the same ownership semantics on47733; they do not test production62741 ownership. The existing Godot PID69180 was neither closed nor interacted with. No user save, gameplay/debug script, scene or data changed. The earlier blocked final gate-v1 remains intact.

The full gate should use a new output directory with `--isolate-checkpoint-writer --defer-graphical-startup`. Exported smoke remains the original, uninstrumented headless main-menu startup without save mutation. Actual exported save/Continue and rendered interaction remain separate overnight acceptance. No full-gate, release, commit or push claim follows from these helper checks. All four focused native processes exited and47733 was released.
