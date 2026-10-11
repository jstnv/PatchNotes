"""Diagnostic only: print first structural difference from a saved reference."""
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
RUN_ID = re.compile(r"\b[0-9a-f]{32}\b")


def norm(value):
    if isinstance(value, str):
        return RUN_ID.sub("<run>", value)
    if isinstance(value, list):
        return [norm(item) for item in value]
    if isinstance(value, dict):
        return {norm(key): norm(item) for key, item in value.items()}
    return value


def scrub_snapshot_seed_at(value, path):
    if isinstance(value, dict):
        return {key: ("<run-seeded>" if key == "snapshot" else scrub_snapshot_seed_at(item, path + "/" + str(key))) for key, item in value.items()}
    if isinstance(value, list):
        return [scrub_snapshot_seed_at(item, path + "/" + str(index)) for index, item in enumerate(value)]
    return value


def first(a, b, path=""):
    if type(a) != type(b):
        return path, a, b
    if isinstance(a, dict):
        if set(a) != set(b):
            return path, sorted(set(a) - set(b)), sorted(set(b) - set(a))
        for key in a:
            found = first(a[key], b[key], path + "/" + str(key))
            if found:
                return found
        return None
    if isinstance(a, list):
        if len(a) != len(b):
            return path + "/length", len(a), len(b)
        for i, (left, right) in enumerate(zip(a, b)):
            found = first(left, right, path + f"/{i}")
            if found:
                return found
        return None
    return None if a == b else (path, a, b)


specialty, arm = sys.argv[1:3]
actual = json.loads((ROOT / "sim-v19" / f"{specialty}-{arm}" / "native-route.json").read_text())
reference = json.loads((ROOT / ("sim-v18" if arm == "buy_chain" else "sim-v12") / f"{specialty}-1104" / "native-route.json").read_text())
for key, old_key in (("actions", "actions"), ("releases", "releases"), ("cycles", "cycles"), ("state", "final"), ("finance", "finance")):
    print(key, first(scrub_snapshot_seed_at(norm(actual["prefix"][key]), ""), scrub_snapshot_seed_at(norm(reference[old_key]), "")))
