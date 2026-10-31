# Menu music through loading, then Studio cue — 2026-10-31

Branch `main`, HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`. Extensive inherited dirty work was present, including `gameplay.gd` and `gameplay_hud.gd`; only the loading cue sites and focused verifiers were edited in those files. The earlier Audio assets and transport remain intact. No commit, push, export, save manipulation or `.codex-godot-temp` cleanup.

Before this change, `_enter_initial_studio()` called `GameplayHUD.set_phase(studio)` while the New Studio or Continue loading overlay still covered the screen. `set_phase` requested Studio Smooth immediately, so the menu music changed during save creation/restore. The Studio phase now binds under the overlay without requesting music when either loading guard is active. After successful loading and overlay reveal, the flow requests Studio Smooth with the existing quick next-eighth-note cue and one-eighth-note fade. Failure keeps the menu cue. Synchronous and normal phase changes still use `set_phase`'s default cue. No clock seek/restart or saved gameplay rule changed.

Godot 4.7.1, headless/Dummy, redirected `.codex-godot-temp/AppData` and distinct checkpoint test ports:

- `verify_new_save_loading.gd`: **PASS**, 18 checks, 0 failures, exit 0. Menu requested at every creation stage; Studio requested after the invitation reveal. Durable save and continuous transport assertions pass. `audio-loading-new-{out,err}.txt`.
- `verify_continue_loading.gd` with `PN_LOADING_AUDIO_ONLY=1`: **PASS**, 587 checks, 0 failures, exit 0. Both 1152×648 and 1280×720 real Continue routes hold the menu cue through recorded loading stages, then request Studio after reveal; save bytes/player state, playback instance and clock remain exact. `audio-loading-continue-focused-{out,err}.txt`.
- `verify_studio_soundtrack.gd`: **PASS**, 7,716 checks, 0 failures, exit 0. Existing title/Studio quick cue, phase routes, loop and pause boundaries remain. `audio-loading-studio-{out,err}.txt`.
- Full `verify_continue_loading.gd`: **FAIL**, exit 1 after the primary loading routes. Later `check_teardown` attempted to read an overlay already removed, causing a null `stage_label` access; later corrupt-save recovery also failed its explicit New Run assertion. This is retained in `audio-loading-continue-{out,err}.txt`. The focused environment switch stops the verifier after its two primary loading routes and does not claim those later fixtures pass.

Follow-ups: repair/reconcile the broader Continue fixture with its owner and rerun the full suite; assess the audible menu-to-Studio transition on a real device. No final release or old-save compatibility claim follows from these focused checks.
