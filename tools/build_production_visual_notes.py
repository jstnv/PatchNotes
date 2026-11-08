"""Build source-pinned bass and hook timelines for the production themes.

The soundtrack and its original source files are read only. An explicit
output path prevents a rebuild from silently changing the runtime manifest.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np

from build_studio_visual_notes import BPM, FRAMES, RATE, midi_tracks, samples, sha

PROJECT = Path("patch-notes/assets/audio/crunch_time_70")
VARIANTS = {"a": "A_jazz", "b": "B_techno"}


def generate(source: Path, project: Path = PROJECT) -> dict:
    tracks = {}
    for variant, name in VARIANTS.items():
        wav_name = f"crunch_time_{name}.wav"
        midi_name = f"crunch_time_{name}_70bpm.mid"
        midi_path = source / "MIDI" / midi_name
        reference_path = source / "WAV" / wav_name
        runtime_path = project / wav_name
        parts = midi_tracks(midi_path)
        reference = samples(reference_path)
        runtime = samples(runtime_path)
        correlation = float(np.corrcoef(reference, runtime)[0, 1])
        # The bundled mix is not byte-identical to its source render, but a
        # strong zero-lag correlation checks this is the aligned arrangement.
        if not correlation > 0.99:
            raise ValueError(f"{wav_name}: source/render correlation {correlation}")
        tracks[f"production_{variant}"] = {
            "wav": wav_name,
            "wav_sha256": sha(runtime_path),
            "source_wav_sha256": sha(reference_path),
            "source_midi": midi_name,
            "source_midi_sha256": sha(midi_path),
            "mix_zero_lag_correlation": round(correlation, 8),
            "bass_track": "FM synthesizer bass",
            "hook_track": "FM synth melody",
            "bass": parts["FM synthesizer bass"],
            "hook": parts["FM synth melody"],
        }
    return {"version": 1, "sample_rate": RATE, "loop_frames": FRAMES,
            "bpm": BPM, "tracks": tracks}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True,
                        help="Path to prototype-01-crunch-time/Tempo_70")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.write_text(json.dumps(generate(args.source), separators=(",", ":")) + "\n", encoding="utf-8")
