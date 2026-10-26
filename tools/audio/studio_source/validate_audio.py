"""Validate rendered PCM and decode MP3 previews with the available FFmpeg."""

from pathlib import Path
import subprocess
import wave

import numpy as np

from compose import build_tracks
from render_audio import HERE, RATE, SAMPLES, STEM_NAMES, events, find_ffmpeg


def load_wav(path: Path, samples: int = SAMPLES) -> np.ndarray:
    with wave.open(str(path), "rb") as handle:
        assert handle.getnchannels() == 2
        assert handle.getsampwidth() == 3
        assert handle.getframerate() == RATE
        assert handle.getnframes() == samples
        raw = np.frombuffer(handle.readframes(samples), dtype=np.uint8).reshape(-1, 3)
    value = raw[:, 0].astype(np.int32) | (raw[:, 1].astype(np.int32) << 8) | (raw[:, 2].astype(np.int32) << 16)
    return (((value ^ 0x800000) - 0x800000).reshape(-1, 2) / 8388608).astype(np.float32)


def main(bpm: int = 140, output: Path = HERE, guitar: bool = False) -> None:
    ffmpeg = find_ffmpeg()
    assert ffmpeg, "MP3 decoder unavailable"
    samples = round(8 * 4 * 60 / bpm * RATE)
    hooks = []
    for variant, label in ((False, "A_jazz"), (True, "B_techno")):
        wav_path = output / "WAV" / f"crunch_time_{label}.wav"
        mix = load_wav(wav_path, samples)
        peak = float(np.max(np.abs(mix)))
        rms = float(np.sqrt(np.mean(mix * mix)))
        seam = float(np.max(np.abs(mix[0] - mix[-1])))
        start_rms = float(np.sqrt(np.mean(mix[:RATE // 50] ** 2)))
        assert 0.005 < peak < 0.90
        assert rms > 0.005 and start_rms > 0.001
        assert seam < 0.06, f"Loop seam discontinuity: {seam}"
        stem_names = STEM_NAMES if guitar else STEM_NAMES[:-1]
        stems = [load_wav(output / "Stems" / label / f"{name}.wav", samples) for name in stem_names]
        assert float(np.max(np.abs(sum(stems) - mix))) < 5 / 8388608
        mp3_path = output / "MP3" / f"crunch_time_{label}.mp3"
        result = subprocess.run([ffmpeg, "-v", "error", "-i", str(mp3_path), "-f", "null", "-"],
                                capture_output=True, text=True)
        assert result.returncode == 0, result.stderr
        hooks.append([(start, stop, note) for start, stop, note, _ in events(build_tracks(variant, bpm, guitar)[5])])
        print(f"{label}: {samples} samples at {bpm} BPM, peak={peak:.4f}, RMS={rms:.4f}, seam={seam:.4f}, "
              f"start RMS={start_rms:.4f}; {len(stem_names)} stems sum to mix; MP3 decodes")
    assert hooks[0] != hooks[1]
    shared = len(set(hooks[0]) & set(hooks[1]))
    assert shared < 10
    print(f"Lead hooks: {len(hooks[0])} and {len(hooks[1])} notes; {shared} identical timed notes")


if __name__ == "__main__":
    main()
