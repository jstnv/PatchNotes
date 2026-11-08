"""Verify production note data against source MIDI and shipped WAVs."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from build_production_visual_notes import generate


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()
    actual = json.loads(args.manifest.read_text(encoding="utf-8"))
    expected = generate(args.source)
    assert actual == expected, "Manifest differs from the source MIDI or WAVs"
    assert set(actual["tracks"]) == {"production_a", "production_b"}
    for track in actual["tracks"].values():
        assert track["bass"] and track["hook"]
        for category in ("bass", "hook"):
            for frame, pitch, velocity in track[category]:
                assert 0 <= frame < actual["loop_frames"]
                assert 0 <= pitch <= 127 and 1 <= velocity <= 127
    print("PASS: production A/B manifests match source MIDI, runtime and reference WAVs")
    for name, track in actual["tracks"].items():
        print(f"{name}: {len(track['bass'])} bass, {len(track['hook'])} hook notes; zero-lag correlation {track['mix_zero_lag_correlation']}")


if __name__ == "__main__":
    main()
