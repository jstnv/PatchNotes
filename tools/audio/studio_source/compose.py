"""Deterministic, dependency-free Type 1 MIDI generator for Crunch Time.

Run: python compose.py
All scheduling uses integer ticks on a 16th-note grid (960 PPQ).
"""

from __future__ import annotations

from pathlib import Path
import struct

PPQ = 960
SIXTEENTH = PPQ // 4
BAR = PPQ * 4
END = BAR * 8
# SMF stores whole microseconds per quarter note. This is the nearest value
# to the mathematical 60,000,000 / 140; DAWs display it as 140 BPM.
TEMPO_US = 428571
OUT = Path(__file__).resolve().parent

PITCH_CLASS = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3,
               "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8,
               "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def pitch(name: str) -> int:
    split = -2 if name[-2] == "-" else -1
    value = 12 * (int(name[split:]) + 1) + PITCH_CLASS[name[:split]]
    assert 0 <= value <= 127, name
    return value


def vlq(value: int) -> bytes:
    assert value >= 0
    parts = [value & 0x7F]
    value >>= 7
    while value:
        parts.insert(0, (value & 0x7F) | 0x80)
        value >>= 7
    return bytes(parts)


def meta(kind: int, data: bytes) -> bytes:
    return bytes((0xFF, kind)) + vlq(len(data)) + data


class Track:
    def __init__(self, name: str, channel: int | None = None, program: int | None = None):
        self.name = name
        self.events: list[tuple[int, int, bytes]] = [(0, 0, meta(0x03, name.encode()))]
        self.channel = channel
        if program is not None:
            self.events.append((0, 1, bytes((0xC0 | channel, program))))

    def note(self, bar: int, step: int, duration: int, name: str | int, velocity: int, offset_ticks: int = 0):
        start = bar * BAR + step * SIXTEENTH + offset_ticks
        stop = start + duration * SIXTEENTH
        value = pitch(name) if isinstance(name, str) else name
        assert 0 <= bar < 8 and 0 <= step < 16 and 0 <= offset_ticks < SIXTEENTH and start < stop <= END
        assert 0 <= value <= 127 and 1 <= velocity <= 127
        self.events.append((start, 3, bytes((0x90 | self.channel, value, velocity))))
        self.events.append((stop, 2, bytes((0x80 | self.channel, value, 0))))

    def chunk(self) -> bytes:
        events = self.events + [(END, 9, meta(0x2F, b""))]
        events.sort(key=lambda event: (event[0], event[1], event[2]))
        encoded = bytearray()
        previous = 0
        for tick, _, message in events:
            encoded += vlq(tick - previous) + message
            previous = tick
        return b"MTrk" + struct.pack(">I", len(encoded)) + encoded


CHORDS = [
    # Rootless Rhodes shapes; bass supplies each root. Smooth inner voices.
    ("Dm9",    ["F3", "C4", "E4", "A4"], ["D4", "F4", "A4", "C5", "E5"]),
    ("G13",    ["F3", "B3", "E4", "A4"], ["G4", "B4", "D5", "E5", "F5"]),
    ("Cmaj9",  ["E3", "B3", "D4", "G4"], ["C4", "E4", "G4", "B4", "D5"]),
    ("A7alt",  ["G3", "C#4", "F4", "Bb4"], ["A3", "C#4", "F4", "G4", "Bb4"]),
    ("Dm9",    ["F3", "C4", "E4", "A4"], ["D4", "F4", "A4", "C5", "E5"]),
    ("Bbmaj9", ["A3", "C4", "D4", "F4"], ["Bb3", "D4", "F4", "A4", "C5"]),
    ("Em7b5",  ["G3", "Bb3", "D4", "E4"], ["E4", "G4", "Bb4", "D5", "G5"]),
    ("A7b9",   ["G3", "C#4", "E4", "Bb4"], ["A3", "C#4", "E4", "G4", "Bb4"]),
]

BASS = [
    [(0, 2, "D2"), (3, 2, "A2"), (6, 1, "C3"), (8, 2, "D3"), (11, 1, "F2"), (14, 1, "F#2")],
    [(0, 2, "G2"), (3, 1, "D3"), (5, 2, "F2"), (9, 1, "B2"), (11, 2, "E3"), (14, 1, "B2")],
    [(0, 2, "C2"), (3, 2, "G2"), (7, 1, "B2"), (9, 2, "C3"), (12, 1, "E2"), (14, 1, "G#2")],
    [(0, 2, "A1"), (3, 1, "E2"), (6, 2, "G2"), (10, 1, "C#3"), (12, 1, "Bb2"), (14, 1, "C#3")],
    [(0, 2, "D2"), (3, 1, "A2"), (5, 1, "C3"), (7, 2, "D3"), (11, 1, "A2"), (13, 2, "F2")],
    [(0, 2, "Bb1"), (3, 1, "F2"), (6, 1, "A2"), (8, 2, "Bb2"), (11, 1, "D3"), (14, 1, "F2")],
    [(0, 2, "E2"), (3, 1, "Bb2"), (6, 2, "D3"), (10, 1, "G2"), (12, 2, "E3"), (15, 1, "G#2")],
    [(0, 2, "A1"), (3, 1, "E2"), (5, 1, "G2"), (8, 2, "Bb2"), (11, 1, "C#3"), (13, 1, "E2"), (15, 1, "C#2")],
]

# Two related versions of the three-note hook: high A, low F, rising E.
MELODY = [
    [(1, 2, "A4"), (4, 1, "F4"), (6, 2, "E5"), (10, 1, "D5"), (12, 2, "C5")],
    [(2, 2, "B4"), (5, 1, "A4"), (7, 2, "E5"), (11, 1, "D5"), (13, 2, "F5")],
    [(1, 2, "G4"), (4, 1, "E4"), (6, 2, "D5"), (10, 1, "B4"), (12, 2, "G4")],
    [(2, 1, "Bb4"), (4, 2, "C#5"), (8, 1, "F5"), (11, 2, "E5"), (14, 1, "C#5")],
    [(1, 2, "A4"), (4, 1, "F4"), (7, 2, "E5"), (10, 1, "D5"), (12, 1, "F5"), (14, 1, "E5")],
    [(2, 2, "A4"), (5, 1, "F4"), (7, 2, "C5"), (11, 1, "D5"), (13, 2, "A4")],
    [(1, 2, "Bb4"), (5, 1, "G4"), (7, 2, "E5"), (11, 1, "D5"), (13, 2, "Bb4")],
    [(2, 1, "Bb4"), (4, 2, "C#5"), (8, 1, "E5"), (10, 1, "F5"), (12, 2, "E5"), (15, 1, "C#5")],
]

TECHNO_HOOK = [
    [(0, 1, "E5"), (2, 1, "E5"), (5, 1, "C5"), (7, 1, "A4"), (10, 2, "D5"), (14, 1, "F5")],
    [(0, 1, "E5"), (2, 1, "E5"), (5, 1, "B4"), (7, 1, "G4"), (10, 2, "D5"), (14, 1, "F5")],
    [(0, 1, "D5"), (2, 1, "D5"), (5, 1, "B4"), (7, 1, "G4"), (10, 2, "C5"), (14, 1, "E5")],
    [(0, 1, "Bb4"), (2, 1, "Bb4"), (5, 1, "G4"), (7, 1, "E4"), (10, 2, "C#5"), (14, 1, "F5")],
    [(0, 1, "E5"), (2, 1, "E5"), (5, 1, "C5"), (7, 1, "A4"), (10, 1, "D5"), (12, 1, "F5"), (14, 1, "E5")],
    [(0, 1, "C5"), (2, 1, "C5"), (5, 1, "A4"), (7, 1, "F4"), (10, 2, "Bb4"), (14, 1, "D5")],
    [(0, 1, "D5"), (2, 1, "D5"), (5, 1, "Bb4"), (7, 1, "G4"), (10, 2, "E5"), (14, 1, "D5")],
    [(0, 1, "Bb4"), (2, 1, "Bb4"), (5, 1, "G4"), (7, 1, "E4"), (10, 1, "C#5"), (12, 1, "E5"), (15, 1, "C#5")],
]

# Three-note upper-register guitar grips; bass supplies roots. Bar 4 spells
# A7b13 specifically (G-C#-F), as shown in the supplied progression image.
GUITAR_VOICINGS = [
    ["F3", "C4", "E4"], ["F3", "B3", "E4"], ["E3", "B3", "D4"],
    ["G3", "C#4", "F4"], ["F3", "C4", "E4"], ["A3", "C4", "D4"],
    ["G3", "Bb3", "D4"], ["G3", "C#4", "Bb4"],
]


def build_tracks(variant: bool, bpm: int = 140, guitar: bool = False) -> list[Track]:
    conductor = Track(f"Conductor - {bpm} BPM / 4-4")
    conductor.events += [
        (0, 1, meta(0x51, round(60_000_000 / bpm).to_bytes(3, "big"))),
        (0, 1, meta(0x58, bytes((4, 2, 24, 8)))),
        (0, 1, meta(0x59, bytes((255, 1)))),  # D minor, one flat
    ]
    machine = Track("Techno drum machine", 9)
    breaks = Track("Funk/breakbeat percussion", 9)
    bass = Track("FM synthesizer bass", 0, 38)
    piano = Track("Rhodes-style electric piano", 1, 4)
    lead = Track("FM synth melody", 2, 81)
    brass = Track("Synth brass accents", 3, 62)
    arp = Track("Electronic arpeggiator", 4, 80)
    guitar_track = Track("Muted electric guitar comp", 5, 28) if guitar else None

    for bar in range(8):
        for step in (0, 4, 8, 12):
            machine.note(bar, step, 1, 36, 104 if step == 0 else 91)
        if variant and bar in (1, 3, 5, 7):
            machine.note(bar, 10, 1, 36, 72)
        if bar in (1, 3, 5, 7):
            machine.note(bar, 15, 1, 36, 70)
        for step in (4, 12):
            machine.note(bar, step, 1, 38, 98)
        for step in (2, 6, 10, 14):
            machine.note(bar, step, 1, 46, 57 if step in (2, 10) else 64)
        for step in (0, 8):
            machine.note(bar, step, 1, 42, 35)
        if variant:
            for step in (3, 7, 11, 15):
                machine.note(bar, step, 1, 42, 35)

        ghost_steps = (3, 11, 15) if (bar + int(variant)) % 2 == 0 else (6, 10, 14)
        for step in ghost_steps:
            breaks.note(bar, step, 1, 38, 30 + (step % 3) * 5)
        for step in ((7, 13) if variant else (7, 15)):
            breaks.note(bar, step, 1, 42, 37)
        if bar in (3, 7):
            breaks.note(bar, 14, 1, 39, 53)  # short clap pickup

        for step, duration, note in BASS[bar]:
            shift = 1 if variant and step in (3, 11) and step + 1 < 16 else 0
            bass.note(bar, step + shift, duration, note, (84 if step == 0 else 66) if variant else (98 if step == 0 else 80))

        voicing = CHORDS[bar][1]
        # Stabs leave room for the hook. Delayed upper-voice answer adds movement.
        hits = ((2, 3, 74), (9, 2, 64)) if not variant else ((3, 2, 55), (10, 2, 49))
        for step, duration, velocity in hits:
            for note in voicing:
                piano.note(bar, step, duration, note, velocity)
        piano.note(bar, 14 if not variant else 13, 1, voicing[-1], 46)

        for step, duration, note in (TECHNO_HOOK if variant else MELODY)[bar]:
            lead.note(bar, step, duration, note, 86 if step < 8 else 73)

        # Brass answers in holes after lead phrases, with no sustained pads.
        brass_notes = ["F4", "B4", "E4", "Bb4", "A4", "D5", "Bb4", "G4"]
        response = 12 if variant else 14
        if bar not in (3, 7):
            brass.note(bar, response, 1, brass_notes[bar], 62)
            if bar in (1, 5):
                brass.note(bar, response + 1, 1, "E5" if bar == 1 else "C5", 54)
        else:
            brass.note(bar, 1 if variant else 0, 1, "G4", 57)

        tones = CHORDS[bar][2]
        for step in (range(16) if variant else (0, 2, 4, 6, 8, 10, 12, 14)):
            if step in ((7, 15) if variant else (6, 14)):
                continue
            index = ((step if variant else step // 2) + (1 if variant else 0)) % len(tones)
            arp.note(bar, step, 1, tones[index], (39 if step % 4 else 45) if variant else (28 if step % 4 else 34))

        if guitar_track is not None:
            # Short, gently staggered upstrokes live between card downbeats.
            strokes = ((3, 2, 63), (11, 1, 55)) if not variant else ((3, 1, 58), (9, 1, 52), (13, 1, 50))
            for step, duration, velocity in strokes:
                for string, note in enumerate(GUITAR_VOICINGS[bar]):
                    guitar_track.note(bar, step, duration, note, velocity - string * 3, string * 22)

    tracks = [conductor, machine, breaks, bass, piano, lead, brass, arp]
    if guitar_track is not None:
        tracks.append(guitar_track)
    return tracks


def compose(variant: bool, bpm: int = 140, guitar: bool = False) -> bytes:
    tracks = build_tracks(variant, bpm, guitar)
    return b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), PPQ) + b"".join(t.chunk() for t in tracks)


def main() -> None:
    for variant, name in ((False, "crunch_time.mid"), (True, "crunch_time_variation.mid")):
        target = OUT / name
        target.write_bytes(compose(variant))
        print(f"{target.name}: {target.stat().st_size} bytes")


if __name__ == "__main__":
    main()
