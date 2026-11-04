# Menu note threads — source provenance

2026-11-03. Scope: source note timing for the five boot and main-menu audio segments. This is source evidence, not listening or exported-build acceptance.

Music paths below are relative to `C:/Users/64jus/OneDrive/Documents/ChatGPT/Patch Notes Music/`. Repository paths begin with `patch-notes/`. Each digest is SHA-256.

## Sources

- `soundtrack/prototype-01-crunch-time/Tempo_70/Main_Menu_Theme_Echo_Dreamwave_Bass_v03/MIDI/dreamwave_synth_and_bass.mid` — `e716399d9e70ae698bccf038e96e0a0a870cb31dae259fc23dbf41d75cafa418`
- `soundtrack/prototype-01-crunch-time/Tempo_70/Main_Menu_Sway_v01/MIDI/crunch_time_menu_sway_v01.mid` — `b63589624742d06f52a4d38f1610466f46567a60203b2782bee0ef03567d2ab0`
- `soundtrack/prototype-01-crunch-time/Tempo_70/MIDI/crunch_time_A_jazz_70bpm.mid` — `a61f0282bc894e1fe31ef53d0ac104c1f6cec14ce9bdc331b38d9fe3aa74dd59`
- `soundtrack/prototype-01-crunch-time/make_boot_continuous_groove.py` — `a9751f991451eb4371a3f2894d0cf8577dd58347f60527606a5991aeb057766a`
- `soundtrack/prototype-01-crunch-time/make_boot_dreamwave_set.py` — `0993c6112aa7a1204aa27692bd03250ab9560bbfabd8522ffdfc654107f54111`
- `soundtrack/prototype-01-crunch-time/make_boot_short_transitions.py` — `6bd06f3051aa12228bc25d83c8b028df60c626d0015ac25c370bf68aff787038`
- `soundtrack/prototype-01-crunch-time/audition_boot_rhythm_alignment.py` — `76f57600f79fa00652be474fe62c46ce58b20197f135897c98bf1edb222ab9b1`
- `soundtrack/prototype-01-crunch-time/make_main_menu_theme_echo_dreamwave_bass.py` — `37ed3aab000e6a4d8764fdca590ed2c35c4a0239adc51622041137560f92afc6`
- `soundtrack/prototype-01-crunch-time/make_main_menu_theme_echo_reverb.py` — `65fb7bc450d3b109774344cb772eeb07366846488a4a04276a23199c5f1bb54a`
- `soundtrack/prototype-01-crunch-time/make_main_menu_sway.py` — `1642474967b2cc9f4a759f60c4a9da90a610266d2508da47901951c6edf1c997`
- `soundtrack/prototype-01-crunch-time/Tempo_70/Main_Menu_Theme_Echo_Dreamwave_Bass_v03/time_map.json` — `696cd273e121c9d5af7d28179c301dff6e6f42218f18740ff4961551e2ce4258`
- `soundtrack/prototype-01-crunch-time/Tempo_70/Boot_Dreamwave_Set_v05/Separate_Tracks/01_startup.wav` — `0231c402ed88310b5dc257bd00254d0a6362c0f1cfa303e93fbdd5ccdfdb1c8c`
- `patch-notes/assets/boot/sequence_v1/01_startup.wav` — `93763e6432d0805e9c37e37f681d93e2a53f78d0fe2d0e567c6a31a6a768b9cd`
- `soundtrack/prototype-01-crunch-time/Tempo_70/Boot_Dreamwave_Set_v05/Separate_Tracks/02_logo_loop_A.wav` — `9b79dc36a69368db411d2d7af481bc4893d217d51b28c22d2faabb7de393eb46`
- `patch-notes/assets/boot/sequence_v1/02_logo_loop_A.wav` — `0a39530f5b114bf9d5389daa27d71f627a0f15eb681941f610f48a89bfe6ddac`
- `soundtrack/prototype-01-crunch-time/Tempo_70/Boot_Dreamwave_Set_v05/Separate_Tracks/03_logo_loop_B.wav` — `61bae6cfe4c47d386fc3ba4b99317c4adb9f183a1e0a8dc561caf33c441d1557`
- `patch-notes/assets/boot/sequence_v1/03_logo_loop_B.wav` — `14243fd8f425b76c61b509bf115fe06dc22ce5f81e9561f4aa82d1f1697f33ed`
- `soundtrack/prototype-01-crunch-time/Tempo_70/Boot_Switch_v10_Rhythm_Alignment/v10_continuous_two_bar_switch.wav` — `fbf98357513f42b6a6c011211f63990b5fff0129de536c9fa33193eb1c790ad6`
- `patch-notes/assets/boot/sequence_v1/04_start_switch.wav` — `ec423709744829c86e2c17f33c66e1c4c891246ffbed3fa588a16ead9d445686`
- `soundtrack/prototype-01-crunch-time/Tempo_70/Main_Menu_Theme_Echo_Dreamwave_Bass_v03/WAV/crunch_time_menu_theme_echo_dreamwave_bass_v03.wav` — `233bbb67ee37c8396e3a6703b271af4f61719c78d0d89fa4f637bd7d3a7ec0c6`
- `patch-notes/assets/boot/sequence_v1/crunch_time_menu_theme_echo_dreamwave_bass_v03.wav` — `d54e5afb2dd24ab35f14541c011c161b08b08daea8e5f7a555e49ca9272197ba`
- `patch-notes/assets/boot/sequence_v1/startup_ab_continuous.wav` — `b94ca67a1c5c41167cdf832624898fac4e8c7ca845bddc39bc2072288acd1554`
- `patch-notes/assets/boot/sequence_v1/switch_menu_continuous.wav` — `a7fbb8daddaf67449e112e370025985c2b3c13b62bbbda29729e6c5e3e114000`

## Derivation and timing

- The candidate `.codex-godot-temp/menu-note-manifest-candidate.json` (SHA-256 `0c7bc589bde8473780cfe9540df3463c74a63e1d83f20ba0886e5dd8d8e14dbd`) is evidence, not a runtime dependency. `tools/build_menu_note_manifest_candidate.py --music-root <prototype-01-crunch-time> --output <candidate.json>` regenerated it byte for byte and verified the original PCM and continuous-stream concatenations.
- At 48 kHz and 70 BPM, each full eight-bar segment has 1,316,571 frames; the two-bar switch has 329,143. MIDI uses 960 ticks per quarter. Note onsets use integer nearest-sample conversion of ticks; generated comp and response chord onsets use the timing formula in their source scripts. A simultaneous chord is represented as individual note-ons.
- Startup and A use Dreamwave chord synth plus A comp; B uses chord synth, B comp, and four response chords. The switch is the final 329,143 frames of A, starting at frame 987,428. The menu combines the Dreamwave chord synth with the Rhodes, plucked-string, electric-piano, muted-guitar and arpeggiator layers. Bass follows the adapted super-wet bass MIDI. The 17 low-synth notes per full segment are retained separately in the candidate, not counted as bass or chord events; hook and percussion are excluded.
- Startup fades layers in while preserving the A arrangement timings. The note map describes source note-on events, not the timing of subsequent reverb echoes.

| Segment | Bass note-ons | Chord note-ons | Separate low synth |
| --- | ---: | ---: | ---: |
| startup | 48 | 160 | 17 |
| loop_a | 48 | 160 | 17 |
| loop_b | 48 | 172 | 17 |
| switch | 12 | 39 | 4 |
| menu | 48 | 328 | 17 |

## Verification

- Every sample of each of the five runtime 16-bit PCM WAVs equaled its paired original 24-bit sample shifted right by eight bits, with identical frame counts; there was no added phase or offset in this conversion.
- `startup_ab_continuous.wav` exactly concatenates the startup, A, and B runtime PCM. `switch_menu_continuous.wav` exactly concatenates the switch and menu runtime PCM.
- `tools/tests/verify_menu_note_manifest.py --candidate .codex-godot-temp/menu-note-manifest-candidate.json --verify-sources`: PASS; five tracks, 1,063 bass/chord note-ons, zero failures. The checker compared runtime events with the candidate and rehashed the pinned local sources. This does not itself verify in-game sound-to-visual synchronization.
