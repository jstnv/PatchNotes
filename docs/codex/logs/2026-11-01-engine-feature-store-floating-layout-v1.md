# Engine Feature Implementation Tree floating layout — 2026-11-01

User requested the updated Feature Store layout follow the current Engines design and expose Implementation Queue/action rather than Research. Adopted the selected v2 layout from isolated worktree613f at `3a61522f18db7a2bae892cb8c5be1fee68cd4100`, reconciling presentation only with current canonical engine-specific transactions. Canonical TODO lacked that isolated entry at intake; its authority/log/source hashes are copied into the finding.

Started/finished `main`, HEAD `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`, dirty shared work preserved, `.codex-godot-temp` untouched. Concurrent Audio owner’s files/GameplayHUD Studio cue were not edited. No commit/push/export/Drive update. [Source, commands, results, captures and retained failures](../findings/store-engine-layout-20261101-v1/README.md).

Changes: floating graph/chrome in `feature_store.gd` and `feature_store_map.gd`; engine context/FIFO/implementation text retained; empty-queue guard and long-name combo bounds; exact published5d27 predecessor admission in `rival_world_checkpoint.gd` with modern protected-field guards. No engine transaction, catalog, price, topology, save-schema or RNG change. A concurrent proprietary starter-gate UI correction was detected and preserved; the old copy expectation was reconciled to its current engine rule. Engine model/action/RunState/browser and Studio phase match their intake hashes.

Checks (complete commands/profiles and source fences in each result receipt):

- `python docs/codex/findings/large-save-20261101-v2/run.py --script <finding>/verify_layout.gd --output <finding>/pointer-headless-v5 --fence --timeout90`:817/0. Same script with `--native` into `pointer-native`:817/0. Three sizes; real balanced injected mouse/wheel events, control shielding, gap drag, queue completion, long names and exact state covered.
- External `verify_studio_layout.gd`, `--native --fence`, into `studio-native`:24/0 at1152/1280. Actual Engine entry, pointer Back/reopen and unchanged state. Images inspected.
- Maintained Engine workflow, Store, copy54/0, grid, radial, navigation0fail, Management and marketplace pass in resolved receipts. Radial now checks initial74%, then explicitly invokes Show all before asserting all50 nodes fit. Navigation now obtains Text legally before clicking its owned no-op; the unintended admission dialog was the cause of later input failures. No production routing change was used to mask them.
- Genuine previous-ZIP `current-release-pair.json` from the prior Save Fix finding, compatibility script with `--fence`:11/0 in `old-zip-green`, including protected-field negatives and exact full-state preservation.
- Independent read-only review: no remaining Critical/Important findings after requested pointer/long-name fixture improvements. Native817 then passed with unchanged critical source hashes.

Preserved RED/setup failures and source-crossing attempt are listed in the finding. Native software events/captures are bounded Windows/Godot4.7.1 evidence; physical/controller/device, broader historical suites and export acceptance remain separate. Prior ZIP was not replaced.
