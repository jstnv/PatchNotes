# Feature Store header and input repair — 2026-11-01

User request: show the selected engine name instead of Feature Implementation, remove the implemented/available counts and the entire visible implementation queue strip, repair tip dismissal and the Implement action.

## Changes

- `scripts/ui/feature_store.gd`: selected engine name and full-name tooltip in the header; redundant counts/heading removed; queue strip hidden. Its legacy internal handles remain for historical presentation probes, but neither dropdown nor top action is visible or interactive. Selected-node details provide admission and completion. A fresh engine-scoped quote drives completion; finance/FIFO/affordability guards remain in RunState. Header relayout follows refresh.
- `scripts/ui/feature_store_map.gd`: the mouse handler yields to hovered higher-CanvasLayer controls even when the map still has keyboard focus. This fixes the tip close button; existing map drag ownership, toolbar footprints and focused Tutorial handling remain. A queued head's detail action is now enabled when `can_research` permits completion; waiting heads remain disabled.
- `scripts/market/rival_world_checkpoint.gd`: exact preceding editor runtime `e4512254abfa3817c820f5f42923946f25ea75012aa7cb1dfa6358d18595cc75` added to the existing modern predecessor group. No validator/schema guard changed. The original durable pre-edit envelope is checksum-verified and source-pinned in `predecessor-origin.json`; player/world state is checked exactly except the executing-source stamp.

No gameplay model, catalog, topology, pricing, finance, RNG, audio, engine library, active project or Studio-only Continue rule changed. Existing shared edits and `.codex-godot-temp` are preserved. No commit, push, export or ZIP replacement.

## Reproductions and retained failures

- `red`, `red-diag`, `red-diag2`: actual-game setup hit the application-wide writer lease. The runner's random port is not consumed by the production Store. The fixture now uses the existing checkpoint verifier's private `_writer` lease seam; production locking is untouched and no running game was closed.
- `red-private`, `red-confirm`: reproduced tip/copy failures; the first confirmation injection used dialog-local input incorrectly. `red-embedded` fixes the test to send parent-window coordinates through the root; admission/top completion pass on original source while the tip/copy failures remain.
- `red-detail`: queued Feature detail action remains disabled; pointer completion fails on original source. This is distinct from model admission and the functional former top action.
- `green`, `native`, `headless-final`: first passing input repair, superseded by removal of the whole visible queue strip.
- `red-queue`: queue strip visibility fails. `no-queue-green` passes after hiding it.
- `navigation`: wrapper-generation error repeated the private-lease insertion after freeing the game. Retained timeout/error; corrected wrapper inserts it only at initial creation. `navigation-final` passes, with later final-source rerun recorded separately.
- `native-final`: visual inspection caught a blank title after destination entrance, despite a correct text property. `native-verified` strengthened width assertions; image still showed clipped text. Removed the unnecessary compact-width optimization and restored expanding Label sizing; final images must be inspected.
- `compat-red`: genuine preceding save rejects its old runtime identity before the exact predecessor entry.
- `compat-green`: fixture extraction had omitted required `sequence`, so typed hydration correctly rejected it. Restored the field, normalizing this generation-only value to the adapter's capture value1. `compat-final` then passes11 checks but its full-source fence crosses the separately owned Audio asset update; retain it as a crossing attempt, not final acceptance.
- `native-final-v2` / `headless-final-v2`: parallel full-game startup exceeded the shared helper's20-second transition bound; subsequent checks ran against an unfinished destination and failed. The fixture now awaits the real transition before calling that helper. Final full-game acceptance runs are serialized; no production timeout or navigation guard was relaxed.
- Read-only process inspection through CIM was unavailable; no process was stopped. Unaffected testing continued with isolated leases.

## Verification commands and scope

Runner: `docs/codex/findings/large-save-20261101-v2/run.py`; Python is the bundled Codex runtime. Every retained result contains the exact command, isolated profile, exit/error scan and full-source fence. Godot4.7.1, Windows; native uses the real game/renderer with software-injected balanced pointer events and Dummy audio. Player saves are never used.

```
python docs/codex/findings/large-save-20261101-v2/run.py --script <script> --output <new output> [--native] [--fixture <pair>] --fence --timeout 120
```

Final results in `final-audit.json`:

| Receipt | Result |
|---|---|
| `headless-acceptance` |404 checks,0 failures; full-source fence PASS |
| `native-acceptance` |404 checks,0 failures; runtime/three changed sources match. Full fence crosses only two independently generated debug UID files; no executable delta |
| `layout-release` |786 checks,0 failures;1152/1280/900, long names, FIFO, public fixed rejection, pan/wheel/controls |
| `navigation-release` |Maintained navigation behavior,0 failures; private writer lease wrapper only |
| `workflow-release` |Maintained engine Feature workflow,0 failures |
| `copy-release` |54 checks,0 failures; rejected transactions retain exact state |
| `compat-acceptance` |11 checks,0 failures; genuine preceding world/player exact except executing-source stamp, seven protected-field negatives |

The final source comparison explicitly separates the independently owned three WAV/provenance/Audio credits update and generated debug UIDs from this task's three changed scripts. Gameplay model/engine actions/RunState/project/phase/simulation/finance/persistence sources match intake. Native1152/1280 captures are inspected with a readable engine title and no queue strip. All scoped diff whitespace checks pass, HEAD is unchanged, independent review has no Critical/Important findings.

Core checks cover both1152×648/1280×720 actual-game routes: tip close/reopen, visible engine title, no queue strip, real node admission/confirmation/completion, exact deposit/one-cycle due, repeat-click/empty-queue rejection and automatic target-engine supply. Maintained copy/workflow and navigation checks cover prerequisite/arrears rejection, finance/history/RNG, keyboard/drag/Tutorial/Pause and passive navigation. These results do not extend to Audio listening or combined export acceptance.

Physical/controller/device, broader release acceptance, performance and EXE/ZIP are not claimed by these UI checks. The existing ObjectDB shutdown warning remains visible in retained logs.

Independent scoped review reported no Critical/Important findings, including the final hidden strip, selected-node action and exact predecessor entry. Review did not run or replace behavior checks.
