"""Check generated MIDI structure and exact eight-bar tick alignment."""

from pathlib import Path
import struct

from compose import BAR, END, PPQ, TEMPO_US


def read_vlq(data: bytes, pos: int) -> tuple[int, int]:
    value = 0
    while True:
        byte = data[pos]
        pos += 1
        value = (value << 7) | (byte & 127)
        if not byte & 128:
            return value, pos


def check(path: Path, bpm: int = 140, guitar: bool = False, percussion_only: bool = False,
          expected_tracks: int | None = None) -> None:
    data = path.read_bytes()
    assert data[:4] == b"MThd"
    count = expected_tracks if expected_tracks is not None else (3 if percussion_only else (9 if guitar else 8))
    assert struct.unpack_from(">IHHH", data, 4) == (6, 1, count, PPQ)
    pos = 14
    tempos, signatures, ranges, names = [], [], [], []
    for track_number in range(count):
        assert data[pos:pos + 4] == b"MTrk"
        length = struct.unpack_from(">I", data, pos + 4)[0]
        chunk = data[pos + 8:pos + 8 + length]
        pos += 8 + length
        tick = cursor = 0
        active: dict[tuple[int, int], int] = {}
        seen_eot = False
        note_count = 0
        lo, hi = 127, 0
        while cursor < len(chunk):
            delta, cursor = read_vlq(chunk, cursor)
            tick += delta
            status = chunk[cursor]
            cursor += 1
            if status == 0xFF:
                kind = chunk[cursor]
                cursor += 1
                size, cursor = read_vlq(chunk, cursor)
                payload = chunk[cursor:cursor + size]
                cursor += size
                if kind == 0x03:
                    names.append(payload.decode())
                elif kind == 0x51:
                    tempos.append((tick, int.from_bytes(payload, "big")))
                elif kind == 0x58:
                    signatures.append((tick, payload[:2]))
                elif kind == 0x2F:
                    assert size == 0 and tick == END and cursor == len(chunk)
                    seen_eot = True
            elif status & 0xF0 == 0xC0:
                cursor += 1
            else:
                assert status & 0xF0 in (0x80, 0x90)
                note, velocity = chunk[cursor:cursor + 2]
                cursor += 2
                key = (status & 0x0F, note)
                if status & 0xF0 == 0x90 and velocity:
                    assert key not in active
                    active[key] = tick
                    note_count += 1
                    lo, hi = min(lo, note), max(hi, note)
                else:
                    assert key in active and active.pop(key) < tick
                assert 0 <= tick <= END
        assert seen_eot and not active
        if track_number:
            assert note_count > 0
            ranges.append((lo, hi, note_count))
        else:
            assert note_count == 0
    assert pos == len(data)
    assert tempos == [(0, round(60_000_000 / bpm))]
    assert signatures == [(0, bytes((4, 2)))]
    assert len(names) == count
    if percussion_only:
        assert names[1:] == ["Techno drum machine", "Funk/breakbeat percussion"]
    elif guitar:
        assert names[-1] == "Muted electric guitar comp"
    print(f"{path.name}: Type 1, {count} tracks, {count - 1} note tracks, one {bpm} BPM tempo, 4/4, {END} ticks = 8 bars")
    for name, (lo, hi, count) in zip(names[1:], ranges):
        print(f"  {name}: {count} notes, MIDI {lo}-{hi}")


if __name__ == "__main__":
    directory = Path(__file__).resolve().parent
    for filename in ("crunch_time.mid", "crunch_time_variation.mid"):
        check(directory / filename)
