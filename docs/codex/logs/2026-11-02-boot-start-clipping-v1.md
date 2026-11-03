# Boot Start clipping — 2026-11-02

The user reported an awkward clip when Start appeared. The boot reveal's later atlas frames include a cropped fragment of a baked-in Start button even as a separate interactive Start button fades in below the image. Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`; existing edits and `.codex-godot-temp` preserved. No commit, push or export.

`patch-notes/scripts/ui/boot_screen.gd` holds the completed clean frame 202 through the rest of the intro. The actual button fade, interaction gate, soundtrack and transition cues are unchanged. The exact pre-fix runtime identity is added to `patch-notes/scripts/market/rival_world_checkpoint.gd` for old saves; no gameplay data changes.

Receipts in `docs/codex/findings/boot-start-clipping-20261102-v1/`: focused RED had 8 failures in 13 checks, exposing the atlas mismatch; native GREEN 13/0 checks the clipped-frame interval, logo reveal, button fade and input gate. Native transition 25/0 covers three window sizes, sound cues, keyboard, input gating and navigation. Genuine pre-fix player/world save 4/0 passes before and after, preserving finance/history/RNG and rejecting unknown identities. `native/entrance.png` shows the clean intermediate appearance. Tests used Dummy audio; physical listening and exported builds remain unverified. Existing invalid-UID fallback and shutdown warnings remain.
