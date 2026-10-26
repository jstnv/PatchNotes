"""Render original synthesized 48 kHz stereo WAVs, stems, and MP3 previews.

Requires NumPy. An FFmpeg executable with an MP3 encoder is needed for MP3s.
No samples, soundfonts, or external instrument plugins are used.
"""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import wave

import numpy as np

from compose import BAR, END, PPQ, build_tracks

HERE = Path(__file__).resolve().parent
RATE = 48000
BPM = 140
SAMPLES = round(8 * 4 * 60 / BPM * RATE)
STEM_NAMES = ("drum_machine", "breakbeat", "fm_bass", "electric_piano",
              "fm_lead", "synth_brass", "arpeggiator", "muted_guitar")
PAN = (-0.05, 0.22, 0.0, -0.18, 0.08, 0.23, -0.28, 0.30)
LEVEL_A = (0.32, 0.18, 0.28, 0.23, 0.20, 0.13, 0.09, 0.16)
LEVEL_B = (0.34, 0.19, 0.23, 0.17, 0.23, 0.12, 0.17, 0.14)


def tick_sample(tick: int, bpm: int = BPM) -> int:
    # Multiplication before integer rounding avoids cumulative drift.
    return (tick * RATE * 60 + bpm * PPQ // 2) // (bpm * PPQ)


def events(track):
    active = {}
    for tick, _, message in sorted(track.events):
        status = message[0] & 0xF0
        if status == 0x90 and message[2]:
            active[message[1]] = (tick, message[2])
        elif status == 0x80 or (status == 0x90 and not message[2]):
            start, velocity = active.pop(message[1])
            yield start, tick, message[1], velocity
    assert not active


def envelope(t: np.ndarray, hold: float, attack: float, release: float, decay: float = 0.0):
    env = np.minimum(t / max(attack, 1e-5), 1.0)
    if decay:
        env *= np.exp(-decay * t)
    after = np.maximum(t - hold, 0.0)
    env *= np.maximum(1.0 - after / release, 0.0)
    return env


def synth(index: int, note: int, velocity: int, duration: float, seed: int) -> np.ndarray:
    freq = 440.0 * 2 ** ((note - 69) / 12)
    strength = (velocity / 127) ** 1.3
    rng = np.random.default_rng(seed)
    if index in (0, 1):
        if note == 36:  # pitch-falling analog kick
            length = 0.23
            t = np.arange(round(length * RATE)) / RATE
            phase = 2 * np.pi * (48 * t + 62 * (1 - np.exp(-t * 32)) / 32)
            signal = np.sin(phase) * np.exp(-t * 20)
            signal += 0.07 * rng.standard_normal(t.size) * np.exp(-t * 95)
        elif note in (38, 39):  # snare/clap: filtered noise plus body
            length = 0.16 if note == 38 else 0.12
            t = np.arange(round(length * RATE)) / RATE
            noise = rng.standard_normal(t.size)
            noise = noise - np.convolve(noise, np.ones(17) / 17, mode="same")
            signal = (0.31 * noise + 0.22 * np.sin(2 * np.pi * 185 * t)) * np.exp(-t * (21 if note == 38 else 30))
            if note == 39:
                signal *= 0.6 + 0.4 * np.cos(2 * np.pi * 38 * t) ** 2
        else:  # closed and open hats from original filtered noise
            length = 0.07 if note == 42 else 0.19
            t = np.arange(round(length * RATE)) / RATE
            noise = rng.standard_normal(t.size)
            signal = (noise - np.convolve(noise, np.ones(9) / 9, mode="same")) * np.exp(-t * (60 if note == 42 else 23)) * 0.19
        return (signal * strength).astype(np.float32)

    tail = (0.055, 0.15, 0.11, 0.10, 0.045, 0.10)[index - 2]
    length = duration + tail
    t = np.arange(round(length * RATE)) / RATE
    phase = 2 * np.pi * freq * t
    if index == 2:  # two-operator FM bass; second oscillator lends octave bite
        modulation = 2.3 * np.exp(-t * 22) * np.sin(2 * phase)
        signal = np.sin(phase + modulation) + 0.18 * np.sin(2 * phase)
        env = envelope(t, duration, 0.003, tail, decay=6)
    elif index == 3:  # struck electric tine, mild tremolo
        signal = np.sin(phase + 1.15 * np.exp(-t * 7) * np.sin(7 * phase))
        signal += 0.14 * np.sin(2 * phase) * np.exp(-t * 8)
        signal *= 0.94 + 0.06 * np.sin(2 * np.pi * 5.2 * t)
        env = envelope(t, duration, 0.004, tail, decay=3)
    elif index == 4:  # bright but rounded FM lead
        signal = np.sin(phase + 1.45 * np.sin(2 * phase) * np.exp(-t * 3))
        signal += 0.12 * np.sin(3 * phase)
        env = envelope(t, duration, 0.009, tail, decay=1.8)
    elif index == 5:  # compact brass bite, no long swell
        signal = np.sin(phase) + 0.3 * np.sin(2 * phase) + 0.13 * np.sin(3 * phase)
        signal += 0.13 * np.sin(phase * 1.004)
        env = envelope(t, duration, 0.014, tail, decay=3)
    elif index == 6:  # understated digital arpeggiator
        signal = np.sin(phase) + 0.22 * np.sin(3 * phase)
        env = envelope(t, duration, 0.004, tail, decay=8)
    else:  # original muted electric-guitar-like pluck; no sampled instrument
        signal = np.sin(phase) + 0.48 * np.exp(-t * 15) * np.sin(2 * phase)
        signal += 0.20 * np.exp(-t * 25) * np.sin(3 * phase)
        signal += 0.045 * rng.standard_normal(t.size) * np.exp(-t * 100)
        env = envelope(t, duration, 0.002, tail, decay=7)
    return (0.48 * signal * env * strength).astype(np.float32)


def render_stem(track, index: int, level: float, version: int, bpm: int = BPM) -> np.ndarray:
    samples = round(8 * 4 * 60 / bpm * RATE)
    stereo = np.zeros((samples, 2), dtype=np.float32)
    pan = PAN[index]
    left = np.sqrt((1 - pan) / 2)
    right = np.sqrt((1 + pan) / 2)
    for count, (start, stop, note, velocity) in enumerate(events(track)):
        first = tick_sample(start, bpm)
        duration = (stop - start) * 60 / (bpm * PPQ)
        sound = synth(index, note, velocity, duration, version * 100000 + index * 1000 + count)
        # Fold any release past bar 8 into bar 1. This makes the loop's tail causal.
        indices = (first + np.arange(sound.size)) % samples
        np.add.at(stereo[:, 0], indices, sound * level * left)
        np.add.at(stereo[:, 1], indices, sound * level * right)
    return stereo


def write_wav(path: Path, signal: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = np.rint(np.clip(signal, -1, 1 - 1 / 8388608) * 8388607).astype("<i4")
    raw = pcm.view(np.uint8).reshape(-1, 4)[:, :3].copy().tobytes()
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(2)
        handle.setsampwidth(3)
        handle.setframerate(RATE)
        handle.writeframes(raw)


def find_ffmpeg() -> str | None:
    explicit = os.environ.get("CRUNCH_FFMPEG")
    if explicit and Path(explicit).is_file():
        return explicit
    found = shutil.which("ffmpeg")
    if found:
        return found
    local = Path(r"C:\Program Files\Topaz Labs LLC\Topaz Video AI\ffmpeg.exe")
    return str(local) if local.is_file() else None


def encode_mp3(ffmpeg: str, source: Path, destination: Path) -> str:
    destination.parent.mkdir(parents=True, exist_ok=True)
    for codec in ("libmp3lame", "mp3_mf", "mp3"):
        result = subprocess.run(
            [ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-i", str(source),
             "-acodec", codec, "-b:a", "256k", str(destination)],
            capture_output=True, text=True,
        )
        if result.returncode == 0 and destination.is_file() and destination.stat().st_size > 1000:
            return codec
    raise RuntimeError(f"No usable MP3 encoder in {ffmpeg}: {result.stderr[-600:]}")


def main(bpm: int = BPM, output: Path = HERE, guitar: bool = False) -> None:
    ffmpeg = find_ffmpeg()
    samples = round(8 * 4 * 60 / bpm * RATE)
    for version, label, levels in ((0, "A_jazz", LEVEL_A), (1, "B_techno", LEVEL_B)):
        tracks = build_tracks(bool(version), bpm, guitar)[1:]
        stems = [render_stem(track, index, levels[index], version, bpm)
                 for index, track in enumerate(tracks)]
        mix = np.sum(stems, axis=0)
        peak = float(np.max(np.abs(mix)))
        gain = 0.82 / peak  # consistent preview loudness, about 1.7 dB peak headroom
        mix *= gain
        wav_path = output / "WAV" / f"crunch_time_{label}.wav"
        write_wav(wav_path, mix)
        for name, stem in zip(STEM_NAMES, stems):
            write_wav(output / "Stems" / label / f"{name}.wav", stem * gain)
        print(f"{wav_path.name}: {samples} frames, {samples / RATE:.9f} s, peak {np.max(np.abs(mix)):.4f}")
        if ffmpeg:
            mp3_path = output / "MP3" / f"crunch_time_{label}.mp3"
            codec = encode_mp3(ffmpeg, wav_path, mp3_path)
            print(f"{mp3_path.name}: encoded with {codec}")
        else:
            print("MP3 skipped: FFmpeg not found")


if __name__ == "__main__":
    main()
