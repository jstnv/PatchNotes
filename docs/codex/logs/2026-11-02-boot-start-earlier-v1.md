# Earlier boot Start input — 2026-11-02

The user found the wait before Start became clickable too long. Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`; existing edits and `.codex-godot-temp` preserved. No commit, push or export.

`patch-notes/scripts/ui/boot_screen.gd` enables Start at the end of its existing fade, 7.5 seconds into the Patch Notes reveal rather than 11.8 seconds. The appearance, logo clip fix and audio beat scheduling remain. `patch-notes/scripts/market/rival_world_checkpoint.gd` accepts the exact verified pre-change runtime identity; gameplay data is unchanged.

Receipts in `docs/codex/findings/boot-start-earlier-20261102-v1/`: native RED had 5 failures in 8 checks on the former gate. Native GREEN 8/0 verifies the fade boundary, pointer click at 7.51 seconds, beat-scheduled switch and handoff. Native prior clipping regression 13/0 and preceding genuine paired player/world save 4/0 pass; the save check preserves finance/history/RNG and rejects unknown identities. An earlier headless clipping run and early-click harness emitted an audio resource shutdown error; final native runs were clean after the new harness released its test audio. Existing invalid-UID fallback warnings remain. Tests use Dummy audio; physical listening and exported builds remain unverified.
