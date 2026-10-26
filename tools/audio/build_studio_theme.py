"""Render Studio Smooth in the main theme's D-minor map without retiming it.

Usage: python tools/audio/build_studio_theme.py
Requires NumPy. Original synthesis sources are preserved in studio_source/.
Does not modify the user's music project or original listening preview.
"""
from pathlib import Path
import hashlib
import json
import struct
import sys

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / 'studio_source'))
import make_studio_smooth as studio
from compose import meta, CHORDS
from render_audio import render_stem, write_wav
from validate_audio import load_wav


def build():
    out = HERE.parents[1] / 'patch-notes/assets/audio/crunch_time_70'
    studio.TRANSPOSE = -2
    original = studio.build_studio_tracks()
    studio.TRANSPOSE = 0
    tracks = studio.build_studio_tracks()
    # Preserve every onset, duration, velocity and drum note; only pitched notes
    # move +2 semitones. Update conductor key metadata to D minor (one flat).
    conductor = tracks[0]
    conductor.events = [(t, p, meta(0x59, bytes((255, 1))) if data[:2] == b'\xff\x59' else data)
                        for t, p, data in conductor.events]
    notes = 0
    for before, after in zip(original[1:], tracks[1:]):
        assert len(before.events) == len(after.events)
        for (t0, p0, a), (t1, p1, b) in zip(before.events, after.events):
            assert (t0, p0) == (t1, p1)
            if a[0] & 0xf0 in (0x80, 0x90):
                shift = 0 if before.channel == 9 else 2
                assert b == bytes((a[0], a[1] + shift, a[2]))
                notes += 1
            else:
                assert a == b
    stems = []
    for part, role, level, track in zip(studio.PARTS, studio.ROLES, studio.LEVELS, tracks[1:]):
        dry = render_stem(track, role, level, 2, studio.BPM)
        stems.append(studio.soften_with_reverb(dry, 0.14 if part == 'soft_drums' else 0.46))
    mix = np.sum(stems, axis=0)
    mix *= 0.78 / float(np.max(np.abs(mix)))
    wav = out / 'crunch_time_studio_smooth_D_minor.wav'
    write_wav(wav, mix)
    midi = out / 'crunch_time_studio_smooth_D_minor.mid'
    midi.write_bytes(b'MThd' + struct.pack('>IHHH', 6, 1, len(tracks), studio.PPQ)
                     + b''.join(t.chunk() for t in tracks))
    pcm = load_wav(wav, studio.FRAMES)
    peak = float(np.max(np.abs(pcm)))
    seam = float(np.max(np.abs(pcm[0] - pcm[-1])))
    assert peak < 0.9 and seam < 0.06
    result = {'bpm': 70, 'meter': [4, 4], 'bars': 8, 'key': 'D minor',
              'bar_harmony': [c[0] for c in CHORDS], 'frames': studio.FRAMES,
              'sample_rate': 48000, 'note_events_verified': notes,
              'peak': peak, 'loop_seam': seam,
              'wav_sha256': hashlib.sha256(wav.read_bytes()).hexdigest(),
              'midi_sha256': hashlib.sha256(midi.read_bytes()).hexdigest()}
    (HERE / 'studio_render.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    build()
