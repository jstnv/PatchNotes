"""Verify the Studio visual note manifest against its pinned source assets."""
from __future__ import annotations

import argparse
import importlib.util
import json
import wave
from pathlib import Path

import numpy as np


def load_builder():
    spec = importlib.util.spec_from_file_location('studio_notes', 'tools/build_studio_visual_notes.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--music-root', type=Path, required=True)
    parser.add_argument('--downloads', type=Path, required=True)
    parser.add_argument('--manifest', type=Path, required=True)
    args = parser.parse_args()
    builder = load_builder()
    data = json.loads(args.manifest.read_text(encoding='utf-8'))
    rebuilt = builder.generate(args.music_root, args.downloads)
    assert data == rebuilt, 'Manifest differs from independently rebuilt source data or hashes'
    assert (data['version'], data['sample_rate'], data['loop_frames']) == (1, 48000, 1316571)
    expected = [(32,20), (32,20), (32,20), (32,4), (48,16), (56,16)]
    for index, (bass_count, hook_count) in enumerate(expected):
        track = data['tracks'][f'studio_{index}']
        assert len(track['bass']) == bass_count and len(track['hook']) == hook_count
        assert builder.sha(builder.PROJECT / track['wav']) == track['wav_sha256']
        for kind in ('bass', 'hook'):
            notes = track[kind]
            assert all(len(n) == 3 and 0 <= n[0] < data['loop_frames'] and 0 <= n[1] <= 127 and 1 <= n[2] <= 127 for n in notes)
            assert notes == sorted(notes, key=lambda n: n[0])
        if index >= 3:
            assert track['wet_bass_zero_lag_correlation'] > 0.999
    assert all(data['tracks'][f'studio_{i}']['bass'] == data['tracks']['studio_0']['bass'] for i in (1,2))
    assert all(data['tracks'][f'studio_{i}']['hook'] == data['tracks']['studio_0']['hook'] for i in (1,2))
    assert data['tracks']['studio_0']['bass'][0] == [0,36,72]
    assert data['tracks']['studio_0']['hook'][0] == [10286,67,54]
    assert data['tracks']['studio_3']['hook'][0] == [123429,69,55]
    assert data['tracks']['studio_4']['hook'][0] == [61714,69,55]
    assert data['tracks']['studio_5']['hook'][0] == [20571,69,55]
    # Independently probe the isolated generated hook WAVs around the first
    # event: there is silence immediately before it and signal after it.
    for index, name in enumerate(('idle', 'main', 'active'), start=3):
        frame = data['tracks'][f'studio_{index}']['hook'][0][0]
        path = args.music_root / f'crunch-inspired-resequence-v02-bassline/{name}/stems/hook.wav'
        with wave.open(str(path), 'rb') as stream:
            assert stream.getsampwidth() == 3 and stream.getnchannels() == 2
            stream.setpos(frame - 1000)
            raw = np.frombuffer(stream.readframes(2500), np.uint8).reshape(-1,3).astype(np.int32)
        values = raw[:,0] | (raw[:,1] << 8) | (raw[:,2] << 16)
        audio = ((values ^ 0x800000) - 0x800000).reshape(-1,2)
        assert np.max(np.abs(audio[:1000])) == 0
        assert np.max(np.abs(audio[1050:])) > 0
    print('STUDIO_NOTE_MANIFEST tracks=6 bass=232 hook=96 failures=0')


if __name__ == '__main__':
    main()
