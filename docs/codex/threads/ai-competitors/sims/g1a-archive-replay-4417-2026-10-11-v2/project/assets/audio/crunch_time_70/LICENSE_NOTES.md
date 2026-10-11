# Crunch Time prototype — resource and authorship notes

Date: 2026-10-09. This is a prototype resource inventory for JooceBox Studios' later commercial review, not a claim about copyright ownership or a legal opinion.

## Composition and audio sources

- The note patterns, chord arrangement, instrument definitions, and synthesis code in this directory were generated for this task by an AI assistant from the user's brief. They need human listening, editing, and authorship review before release. No existing song, recording, sample pack, SoundFont, preset audio file, or proprietary synth patch was copied into the outputs.
- Every audible waveform in the WAVs and stems is generated from equations and deterministic noise in `render_audio.py`: FM-like oscillators, additive partials, and filtered synthetic noise. The MP3s are encodings of those WAVs.
- The requested eight-chord progression came from the user. The MIDI GM program numbers are metadata suggestions only and do not embed GM sounds.

## Software used locally

| Dependency | Use | Local version/source | License evidence | Distributed here? |
| --- | --- | --- | --- | --- |
| Python standard library | MIDI bytes, WAV container, validation | bundled Python 3.12 runtime | Python license in runtime distribution | No |
| NumPy | waveform arrays and PCM conversion | bundled NumPy 2.3.5 | installed `numpy-2.3.5.dist-info/LICENSE.txt`, NumPy BSD-style terms | No |
| FFmpeg | MP3 encode/decode only, `mp3_mf` encoder | `C:\Program Files\Topaz Labs LLC\Topaz Video AI\ffmpeg.exe`, version 7.1.git | this binary's `ffmpeg -L` reports GNU LGPL 2.1 or later; `mp3_mf` uses Windows Media Foundation | No |

Only generated `.mid`, `.wav`, and `.mp3` files plus project source and notes are in this folder. No executable, library, SoundFont, or sample from the dependencies is included. If the production pipeline later redistributes software or swaps in third-party instruments, review those licenses and record the exact sources separately.

The fact that the material was AI-generated does **not** establish automatic copyright protection. Human creative review and release clearance remain open.
