"""Build source-pinned bass and hook note-on maps for the six Studio WAVs.

The project WAVs and source arrangements are read only.  The output is an
explicit path so rebuilding cannot silently replace a checked-in manifest.
"""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
import struct
import wave
from pathlib import Path

import numpy as np

RATE, BPM, FRAMES = 48000, 70, 1316571
PROJECT = Path('patch-notes/assets/audio/crunch_time_70/studio_pool')
NAMES = ('idle', 'main', 'active')


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1048576), b''):
            h.update(chunk)
    return h.hexdigest()


def variable(data: bytes, pos: int) -> tuple[int, int]:
    value = 0
    while True:
        byte = data[pos]
        pos += 1
        value = (value << 7) | (byte & 127)
        if not byte & 128:
            return value, pos


def midi_tracks(path: Path) -> dict[str, list[list[int]]]:
    data = path.read_bytes()
    assert data[:4] == b'MThd'
    form, count, ppq = struct.unpack('>HHH', data[8:14])
    assert form == 1 and ppq == 960
    tracks, pos = {}, 14
    for _ in range(count):
        assert data[pos:pos+4] == b'MTrk'
        end = pos + 8 + int.from_bytes(data[pos+4:pos+8], 'big')
        i, tick, status, name, notes = pos + 8, 0, 0, '', []
        while i < end:
            delta, i = variable(data, i)
            tick += delta
            if data[i] >= 128:
                status = data[i]
                i += 1
            if status == 255:
                kind = data[i]
                i += 1
                length, i = variable(data, i)
                body = data[i:i+length]
                i += length
                if kind == 3:
                    name = body.decode('latin1')
                status = 0
            elif status in (240, 247):
                length, i = variable(data, i)
                i += length
                status = 0
            else:
                op = status >> 4
                length = 1 if op in (12, 13) else 2
                body = data[i:i+length]
                i += length
                if op == 9 and body[1] > 0:
                    frame = (tick * RATE * 60 + BPM * ppq // 2) // (BPM * ppq)
                    assert 0 <= frame < FRAMES
                    notes.append([frame, body[0], body[1]])
        tracks[name] = notes
        pos = end
    return tracks


def constants(path: Path) -> dict:
    module = ast.parse(path.read_text(encoding='utf-8'))
    result = {}
    for node in module.body:
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id in ('CHORDS', 'THIRDS'):
                    result[target.id] = ast.literal_eval(node.value)
    assert len(result['CHORDS']) == len(result['THIRDS']) == 8
    return result


def inspired_notes(mode: str, source: dict) -> tuple[list, list]:
    chords, thirds = source['CHORDS'], source['THIRDS']
    bass, hook = [], []
    for bar, (root, chord) in enumerate(chords):
        third, approach = root + thirds[bar], chords[(bar+1) % 8][0] - 1
        if mode == 'idle':
            notes = ((0, root), (1.5, root+12), (2.75, third), (3.5, approach))
        elif mode == 'active':
            notes = ((0, root), (.75, root+12), (1.5, root+7), (2, root),
                     (2.5, third), (3, root+7), (3.5, approach))
        else:
            notes = ((0, root), (.75, root+12), (1.5, root+7),
                     (2.25, third), (2.75, root+7), (3.5, approach))
        for beat, pitch in notes:
            bass.append([round((bar * 4 + beat) * RATE * 60 / BPM), pitch, 95])
        if mode != 'idle' or bar % 2 == 0:
            positions = (1.5, 3.25) if mode == 'main' else ((.5, 2.5) if mode == 'active' else (3,))
            for index, beat in enumerate(positions):
                hook.append([round((bar * 4 + beat) * RATE * 60 / BPM), chord[(bar+index+1) % 4] + 12, 55])
    return bass, hook


def samples(path: Path) -> np.ndarray:
    with wave.open(str(path), 'rb') as w:
        assert w.getnchannels() == 2 and w.getsampwidth() == 3 and w.getframerate() == RATE
        assert w.getnframes() == FRAMES
        data = np.frombuffer(w.readframes(FRAMES), np.uint8).reshape(-1, 3).astype(np.int32)
    values = data[:, 0] | (data[:, 1] << 8) | (data[:, 2] << 16)
    return ((values ^ 0x800000) - 0x800000).astype(np.float64)[::8]


def generate(music: Path, downloads: Path) -> dict:
    studio = music / 'prototype-01-crunch-time/Tempo_70/Studio_Smooth'
    midi = studio / 'MIDI/crunch_time_studio_smooth_70bpm.mid'
    original = midi_tracks(midi)
    arrangement = music / 'crunch-inspired-resequence-v02-bassline/render.py'
    source_constants = constants(arrangement)
    source_wavs = music / 'studio-phase-variations-v01/WAV'
    led_wavs = music / 'studio-bass-led-variations-v01/WAV'
    reference_bass = music / 'crunch-inspired-resequence-v04-super-wet-bass/Bass_Only'
    source_files = [midi, arrangement, studio.parent.parent / 'make_studio_smooth.py',
                    studio.parent.parent / 'render_audio.py', studio.parent.parent / 'compose.py',
                    music / 'crunch-inspired-resequence-v04-super-wet-bass/README.md',
                    music / 'studio-phase-variations-v01/render.ps1', music / 'studio-bass-led-variations-v01/render.ps1']
    tracks = {}
    for index, name in enumerate(NAMES):
        filename = f'crunch_time_studio_{name}_70bpm.wav'
        runtime, source_wav = PROJECT / filename, source_wavs / filename
        assert sha(runtime) == sha(source_wav)
        tracks[f'studio_{index}'] = {'wav': filename, 'wav_sha256': sha(runtime),
                                     'bass': original['Warm FM bass'], 'hook': original['Soft FM hook']}
        filename = f'crunch_time_studio_bass_led_{name}_70bpm.wav'
        runtime, source_wav = PROJECT / filename, led_wavs / filename
        assert sha(runtime) == sha(source_wav)
        bass, hook = inspired_notes(name, source_constants)
        bass_name = f'crunch_inspired_{name}_bass_only_super_wet_70bpm.wav'
        supplied, reference = downloads / bass_name, reference_bass / bass_name
        a, b = samples(supplied), samples(reference)
        similarity = float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))
        assert similarity > 0.999, (name, similarity)
        tracks[f'studio_{index+3}'] = {'wav': filename, 'wav_sha256': sha(runtime), 'bass': bass, 'hook': hook,
                                       'wet_bass_zero_lag_correlation': round(similarity, 8),
                                       'wet_bass_download_sha256': sha(supplied), 'wet_bass_reference_sha256': sha(reference)}
        source_files.extend([source_wavs / f'crunch_time_studio_{name}_70bpm.wav', source_wav,
                             music / f'crunch-inspired-resequence-v02-bassline/{name}/stems/hook.wav'])
    return {'version': 1, 'sample_rate': RATE, 'loop_frames': FRAMES, 'bpm': BPM,
            'sources': [{'path': str(p.relative_to(music)), 'sha256': sha(p)} for p in source_files],
            'tracks': tracks}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--music-root', type=Path, required=True, help='Path to Patch Notes Music/soundtrack')
    parser.add_argument('--downloads', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.write_text(json.dumps(generate(args.music_root, args.downloads), separators=(',', ':')) + '\n', encoding='utf-8')
