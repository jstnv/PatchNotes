"""Read only the frozen private shadow event from Godot Variant tapes.

This intentionally supports the simple dictionary/string subset used by the
DevelopmentReplay.freeze(event) encoding; it is not a general Variant decoder.
"""

import base64
import json
import pathlib
import struct


ROOT = pathlib.Path(__file__).parent
BUNDLE = ROOT / "sims" / "sidestreet-relationship-shadow-v1-run-01"
MARKER = b"sidestreet_relationship_shadow"


def read_value(data: bytes, pos: int):
    type_id = struct.unpack_from("<I", data, pos)[0]
    pos += 4
    if type_id == 4:  # String
        length = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        value = data[pos : pos + length].decode("utf-8")
        pos += (length + 3) & ~3
        return value, pos
    if type_id == 27:  # Dictionary
        count = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        assert count < 100
        value = {}
        for _ in range(count):
            key, pos = read_value(data, pos)
            item, pos = read_value(data, pos)
            value[key] = item
        return value, pos
    raise ValueError(f"Unexpected Variant type {type_id} at {pos - 4}")


def unwrap(value):
    return int(value["integer"])


rows = []
for case_dir in sorted((BUNDLE / "cases").iterdir()):
    if not case_dir.is_dir():
        continue
    tape = json.loads((case_dir / "replay.tape.json").read_text())
    data = base64.b64decode(tape["payload"])
    assert data.count(MARKER) == 1, case_dir.name
    marker = data.index(MARKER)
    # Event dictionary starts 24 bytes before the type value's UTF-8 data:
    # dictionary header 8, "type" key 12, String header 8.
    event, end = read_value(data, marker - 28)
    assert event["type"] == MARKER.decode() and end > marker
    scope = unwrap(event["scope"])
    cores = {int(k): unwrap(v) for k, v in event["core_half_units"].items()}
    redraws = unwrap(event["successful_redraws"])
    score = {k: unwrap(v) for k, v in event["score"].items()}
    expected_completion = 10000 * (4 * min(scope, 10) + sum(min(cores[i], 6) for i in range(4))) // 64
    expected_promise = 0 if redraws or scope >= 12 else 5000 if scope == 11 else 10000
    expected_combined = min(expected_completion, expected_promise)
    assert score == {"completion_bp": expected_completion, "promise_bp": expected_promise, "combined_bp": expected_combined}, case_dir.name
    result = json.loads((case_dir / "result.json").read_text())
    assert result["ok"] and result["status"] == "completed", case_dir.name
    rows.append({"case_id": case_dir.name, "scope": scope, "core_half_units": cores, "successful_redraws": redraws, "score": score, "commands": result["commands"], "final_cycle": result["final_run_cycle"], "initial_state": result["initial_state"], "initial_rng": result["initial_rng"]})

output = ROOT / "SIDESTREET-RELATIONSHIP-SHADOW-INSPECTION-2026-10-18-v1.json"
output.write_text(json.dumps(rows, indent=2) + "\n")
print(json.dumps({"count": len(rows), "rows": [{k: row[k] for k in ["case_id", "scope", "successful_redraws", "score"]} for row in rows], "output": str(output)}))
