# Pause track continuity follow-up — 2026-10-18

Dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; existing work preserved. User likes the pause filter and asks for continuous track playback.

Made the soundtrack AudioStreamPlayer explicitly always-process. Filter/reverb values and timing remain unchanged. Added actual-song, raw-playhead and Music-bus capture checks under the real Esc menu. Preserved exact preceding world compatibility. Runtime changes: `scripts/audio/soundtrack.gd`, `scripts/market/rival_world_checkpoint.gd`; new `scripts/debug/verify_pause_track.gd` (+UID).

[Commands, exact source, baseline and final samples](../findings/pause-track-20261018-v1/README.md). Windows WASAPI 29/29, pause/DSP713/713, real menu64/64, soundtrack sync3,503/3,503, Studio music7,620/7,620 and exact prior-world restore5/5 pass. Final raw audio advances 6.037333 seconds while paused, with sound in all twelve captures and no gameplay change/restart. Final source `f4303f0101e1971026080ec0b0acf3c817e96675fa190758d7c8651b8969a412` matches canonical runtime.

The reported stop did not reproduce in the fresh pre-change WASAPI run either; do not claim an identified user-session cause. Restart the current game to load the explicit process setting. No exported binary, commit or push was produced. The original user-approved filter character is retained; fresh-project audio continuity is verified, existing-session/exported-device behavior is not.
