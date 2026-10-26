# Pause soundtrack audibility correction — 2026-10-18

**Implemented and verified locally; user listening confirmation remains OPEN.** User again reported no music in pause and clarified Esc in a game launched from Godot. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, pre-existing dirty worktree preserved. No commit/push/export. `.codex-godot-temp`, player saves and saved volume settings untouched.

## Finding and correction

The editor metadata and recent player log identify this project and Godot4.7.1 `a13da4feb`, matching the test runtime. Existing tests verified that transport advanced and emitted nonzero PCM, but their amplitude threshold accepted extremely quiet music. A new pre/post-effects capture found the pause filter's `resonance = 0.15` suppressed the track strongly: Studio output reached -67.3 dBFS in sampled half-second windows at test Master80/Music13. This is a reproduced mix defect, not proof that the user's transport actually stopped.

Changed only the filter resonance to Godot's normal0.5. The650Hz cutoff, steep filter,0.3-second fade, reverb settings, playback/grid behavior and user volume/mute controls remain. The [Godot filter documentation](https://docs.godotengine.org/en/stable/classes/class_audioeffectfilter.html) identifies the resonance default and its effect around cutoff; [filter implementation](https://raw.githubusercontent.com/godotengine/godot/master/servers/audio/audio_filter_sw.cpp) uses resonance as Q. Runtime PCM measurements below establish the actual effect in the installed build.

The new focused verifier measures a complete phrase of each actual arrangement through the Music effects, with Esc-generated pause, frozen gameplay, advancing music clock, unchanged playback identity and post-resume filter removal. It requires the paused song to retain at least half the dry RMS amplitude over the phrase (-6dB), rather than accepting any nonzero audio. This is an audibility regression threshold, not a loudness-normalization feature.

## Checks

All runs use isolated profiles/checkpoint ports. [Audit, hashes and exact commands](../findings/pause-audibility-20261018-v1/audit.json); [task-only production diff](../findings/pause-audibility-20261018-v1/soundtrack.patch).

| Check | Result |
| --- | --- |
| Initial actual-track WASAPI probe |112/112; documented the attenuation while playback continued. |
| Candidate filter probe |112/112; improved levels for both themes. |
| New full-phrase verifier, native OpenGL window + WASAPI |444/444, exit0, no errors. Main attenuation0.72dB; Studio1.04dB relative to pre-effect PCM. |
| Same new verifier with captured old resonance restored only in an isolated process |**Expected failure:**442/444, exactly the two audibility assertions fail. Main attenuation7.74dB; Studio10.64dB. No transport failure. |
| Pause menu behavior |60/60, exit0. |
| Pause effects, settings, resume/presentation behavior |713/713, exit0. |
| Soundtrack synchronization |3,503/3,503, exit0. |

Known existing card-art warnings and six ObjectDB shutdown leaks occurred in some headless suites; no unexpected script/runtime errors. Focused whitespace and source-delta checks passed. The original response and candidate probes retain shorter sampled windows; use the full-phrase results above for the final comparison.

## Files and remaining boundary

- `patch-notes/scripts/audio/soundtrack.gd`: resonance correction/comment only relative to the captured dirty baseline.
- `patch-notes/scripts/debug/verify_pause_audibility.gd`: actual-track audibility regression.
- `docs/codex/findings/pause-audibility-20261018-v1/`: baseline, diagnostic probes/runner, raw PCM-level traces, source pins and intentional old-filter regression failure.
- This log and concise shared design/state/TODO reconciliation.

Stop the current Godot play session and run the project again to construct the updated filter; changing script source does not reconstruct an already-created AudioEffect resource. Native automated verification used a fresh standalone game process with the same engine, renderer and project, not interaction inside the editor's embedded window. The user's exact embedded session and subjective listening remain unverified. If it persists after a fresh run, inspect that live session's transport and device output rather than treating another nonzero-capture result as sufficient.
