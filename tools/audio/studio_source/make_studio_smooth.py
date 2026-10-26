"""Create a sparse, down-tuned, reverberant studio-phase Crunch Time loop."""

from pathlib import Path
import struct
import subprocess

import numpy as np

from compose import (BAR, BASS, CHORDS, GUITAR_VOICINGS, MELODY, PPQ,
                     Track, meta, pitch)
from render_audio import RATE, encode_mp3, find_ffmpeg, render_stem, write_wav
from validate import check as check_midi
from validate_audio import load_wav

HERE = Path(__file__).resolve().parent / "Tempo_70" / "Studio_Smooth"
BPM = 70
FRAMES = round(8 * 4 * 60 / BPM * RATE)
TRANSPOSE = -2  # D minor to C minor
PARTS = ("soft_drums", "warm_bass", "electric_piano", "soft_lead", "muted_guitar", "soft_arp")
ROLES = (0, 2, 3, 4, 7, 6)  # indices of original procedural instruments
LEVELS = (0.15, 0.22, 0.23, 0.12, 0.14, 0.05)


def lower(note: str) -> int:
    return pitch(note) + TRANSPOSE


def build_studio_tracks() -> list[Track]:
    conductor = Track("Crunch Time - Studio Smooth / 70 BPM")
    conductor.events += [
        (0, 1, meta(0x51, round(60_000_000 / BPM).to_bytes(3, "big"))),
        (0, 1, meta(0x58, bytes((4, 2, 24, 8)))),
        (0, 1, meta(0x59, bytes((253, 1)))),  # C minor, three flats
    ]
    drums = Track("Soft electronic drums", 9)
    bass = Track("Warm FM bass", 0, 38)
    piano = Track("Studio electric piano", 1, 4)
    lead = Track("Soft FM hook", 2, 81)
    guitar = Track("Muted electric guitar", 5, 28)
    arp = Track("Low digital texture", 4, 80)

    for bar in range(8):
        for step in (0, 8):
            drums.note(bar, step, 1, 36, 74 if step == 0 else 60)
        for step in (4, 12):
            drums.note(bar, step, 1, 38, 55)
        for step in (2, 6, 10, 14):
            drums.note(bar, step, 1, 42, 26)
        if bar in (3, 7):
            drums.note(bar, 15, 1, 38, 28)

        # Fewer bass notes than the action mix, but preserve root and pickup.
        source_bass = BASS[bar]
        for source_index in (0, 1, 3, len(source_bass) - 1):
            step, duration, note = source_bass[source_index]
            bass.note(bar, step, min(16 - step, max(duration, 2)), lower(note),
                      72 if source_index == 0 else 55)

        for note in CHORDS[bar][1]:
            piano.note(bar, 2, 5, lower(note), 55)
        piano.note(bar, 11, 3, lower(CHORDS[bar][1][-1]), 39)

        selected = (0, 2, 4) if bar % 2 == 0 else (1, 3)
        for index in selected:
            step, duration, note = MELODY[bar][index]
            lead.note(bar, step, min(16 - step, duration + 1), lower(note), 54)

        for string, note in enumerate(GUITAR_VOICINGS[bar]):
            guitar.note(bar, 7, 2, lower(note), 49 - string * 3, string * 24)
        if bar in (3, 7):
            guitar.note(bar, 13, 1, lower(GUITAR_VOICINGS[bar][-1]), 40)

        tones = CHORDS[bar][2]
        for step, index in ((0, 0), (4, 2), (8, 1), (12, 3)):
            arp.note(bar, step, 2, lower(tones[index]), 30)

    return [conductor, drums, bass, piano, lead, guitar, arp]


def reverb_ir(seed: int, length: int) -> np.ndarray:
    """Original short stereo room impulse; no sample or external plugin."""
    rng = np.random.default_rng(seed)
    ir = np.zeros(length, dtype=np.float32)
    for seconds, gain in ((0.031, 0.27), (0.067, 0.19), (0.109, 0.14),
                          (0.173, 0.10), (0.251, 0.07)):
        ir[round(seconds * RATE)] += gain
    tail_start = round(0.055 * RATE)
    t = np.arange(length - tail_start, dtype=np.float32) / RATE
    noise = rng.standard_normal(t.size).astype(np.float32)
    # Consecutive averaging smooths the noise into a diffuse, darker tail.
    kernel = np.ones(13, dtype=np.float32) / 13
    noise = np.convolve(noise, kernel, mode="same")
    ir[tail_start:] += 0.020 * noise * np.exp(-t * 4.0)
    return ir


def soften_with_reverb(dry: np.ndarray, wet: float) -> np.ndarray:
    length = round(1.65 * RATE)
    left_ir = np.zeros(FRAMES, dtype=np.float32)
    right_ir = np.zeros(FRAMES, dtype=np.float32)
    left_ir[:length] = reverb_ir(521, length)
    right_ir[:length] = reverb_ir(809, length)
    # Circular convolution carries each bar-eight decay into the next bar one.
    output = dry.copy()
    for channel, impulse in enumerate((left_ir, right_ir)):
        reflection = np.fft.irfft(np.fft.rfft(dry[:, channel]) * np.fft.rfft(impulse), n=FRAMES)
        output[:, channel] += wet * reflection.astype(np.float32)
    return output


def main() -> None:
    tracks = build_studio_tracks()
    midi_path = HERE / "MIDI" / "crunch_time_studio_smooth_70bpm.mid"
    midi_path.parent.mkdir(parents=True, exist_ok=True)
    midi = b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), PPQ)
    midi_path.write_bytes(midi + b"".join(track.chunk() for track in tracks))
    check_midi(midi_path, BPM, expected_tracks=7)

    stems = []
    for part, role, level, track in zip(PARTS, ROLES, LEVELS, tracks[1:]):
        dry = render_stem(track, role, level, 2, BPM)
        stems.append(soften_with_reverb(dry, 0.46 if part != "soft_drums" else 0.14))
    mix = np.sum(stems, axis=0)
    gain = 0.78 / float(np.max(np.abs(mix)))
    mix *= gain
    wav_path = HERE / "WAV" / "crunch_time_studio_smooth_70bpm.wav"
    write_wav(wav_path, mix)
    for part, stem in zip(PARTS, stems):
        write_wav(HERE / "Stems" / f"{part}.wav", stem * gain)

    stored = load_wav(wav_path, FRAMES)
    reconstructed = sum(load_wav(HERE / "Stems" / f"{part}.wav", FRAMES) for part in PARTS)
    peak = float(np.max(np.abs(stored)))
    seam = float(np.max(np.abs(stored[0] - stored[-1])))
    assert peak < 0.9 and seam < 0.06
    assert float(np.max(np.abs(reconstructed - stored))) < 5 / 8388608
    print(f"{wav_path.name}: {FRAMES} frames, peak={peak:.4f}, seam={seam:.4f}, six stems reconstruct mix")

    ffmpeg = find_ffmpeg()
    if ffmpeg:
        mp3_path = HERE / "MP3" / "crunch_time_studio_smooth_70bpm.mp3"
        codec = encode_mp3(ffmpeg, wav_path, mp3_path)
        decoded = subprocess.run([ffmpeg, "-v", "error", "-i", str(mp3_path), "-f", "null", "-"],
                                 capture_output=True, text=True)
        assert decoded.returncode == 0, decoded.stderr
        print(f"{mp3_path.name}: {codec}, decode passed")
    else:
        print("MP3 skipped: FFmpeg unavailable")


if __name__ == "__main__":
    main()
