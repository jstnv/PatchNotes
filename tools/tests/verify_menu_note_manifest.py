"""Compare the runtime note map with the source-pinned extracted candidate.

Run from the repository root, for example:
  python tools/tests/verify_menu_note_manifest.py --candidate .codex-godot-temp/menu-note-manifest-candidate.json

The candidate is intentionally supplied as an argument: it is provenance
evidence, not a second runtime dependency or a hard-coded user-specific path.
"""

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate", required=True, type=Path)
    parser.add_argument("--manifest", type=Path, default=Path("patch-notes/assets/boot/sequence_v1/menu_visual_notes.json"))
    parser.add_argument("--verify-sources", action="store_true", help="also rehash locally available pinned source files")
    args = parser.parse_args()
    candidate = json.loads(args.candidate.read_text(encoding="utf-8-sig"))
    runtime = json.loads(args.manifest.read_text(encoding="utf-8-sig"))
    failures = []

    for field in ("sample_rate", "loop_frames", "switch_frames"):
        if runtime.get(field) != candidate.get(field):
            failures.append(f"{field} differs: runtime={runtime.get(field)!r} source={candidate.get(field)!r}")
    expected_tracks = {"startup", "loop_a", "loop_b", "switch", "menu"}
    if set(runtime.get("tracks", {})) != expected_tracks or set(candidate.get("tracks", {})) != expected_tracks:
        failures.append("Track set does not match the five source music segments")
    counts = {}
    for track in sorted(expected_tracks):
        original = candidate.get("tracks", {}).get(track, {})
        actual = runtime.get("tracks", {}).get(track, {})
        frames = original.get("frames")
        if actual.get("frames") != frames:
            failures.append(f"{track}: source/runtime segment lengths differ")
        for kind in ("bass", "chords"):
            source_notes = original.get(kind, [])
            if kind == "chords":
                # Only the approved synth layer emits blue. Simultaneous
                # duplicate pitches are a single attack at the strongest velocity.
                strongest = {}
                for event in source_notes:
                    if event.get("layer") != "dreamwave_chord_synth":
                        continue
                    key = (event["frame"], event["note"])
                    strongest[key] = max(strongest.get(key, 0), event["velocity"])
                expected = Counter((frame, note, velocity) for (frame, note), velocity in strongest.items())
                expected_count = 19 if track == "switch" else 80
                if len(expected) != expected_count:
                    failures.append(f"{track}: synth source count {len(expected)} != {expected_count}")
            else:
                expected = Counter((e["frame"], e["note"], e["velocity"]) for e in source_notes)
            notes = actual.get(kind, [])
            try:
                got = Counter(tuple(e) for e in notes)
            except (TypeError, ValueError):
                failures.append(f"{track}/{kind}: malformed note tuples")
                continue
            if got != expected:
                failures.append(f"{track}/{kind}: missing={sum((expected-got).values())}, extra={sum((got-expected).values())}")
            for note in notes:
                if not isinstance(note, list) or len(note) != 3 or not all(type(v) is int for v in note):
                    failures.append(f"{track}/{kind}: invalid note tuple {note!r}")
                    break
                frame, pitch, velocity = note
                if not (0 <= frame < frames and 0 <= pitch <= 127 and 1 <= velocity <= 127):
                    failures.append(f"{track}/{kind}: out-of-range note tuple {note!r}")
                    break
            counts[f"{track}/{kind}"] = len(notes)

    if args.verify_sources:
        for source in candidate.get("sources", []):
            path = Path(source["path"])
            if not path.is_file():
                failures.append(f"Pinned source missing: {path}")
                continue
            digest = hashlib.sha256()
            with path.open("rb") as file:
                for chunk in iter(lambda: file.read(1024 * 1024), b""):
                    digest.update(chunk)
            if digest.hexdigest() != source["sha256"]:
                failures.append(f"Pinned source hash changed: {path}")

    for key, count in counts.items():
        print(f"{key}: {count} note-ons")
    for failure in failures:
        print(f"FAIL: {failure}", file=sys.stderr)
    print(f"MENU_NOTE_MANIFEST tracks={len(expected_tracks)} notes={sum(counts.values())} failures={len(failures)}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
