"""Read-only audit of retained-export publisher replays and current source drift."""
from pathlib import Path
import hashlib
import json
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[3]
checks = []


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(ok, label):
    checks.append({"pass": bool(ok), "label": label})


def latest(label):
    path = max((BASE / "checkpoints" / label).glob("checkpoint.*.json"),
               key=lambda p: int(p.stem.split(".")[-1]))
    envelope = json.loads(path.read_text())
    check(hashlib.sha256(envelope["payload_utf8"].encode()).hexdigest() == envelope["payload_sha256"],
          label + ": payload integrity")
    return path, json.loads(envelope["payload_utf8"])


def differing_paths(a, b, prefix=""):
    if type(a) is not type(b):
        return [prefix]
    if isinstance(a, dict):
        result = []
        for key in sorted(a.keys() | b.keys()):
            path = prefix + "/" + key
            result.extend(differing_paths(a[key], b[key], path) if key in a and key in b else [path])
        return result
    if isinstance(a, list):
        if len(a) != len(b):
            return [prefix + "/length"]
        return [p for i, (x, y) in enumerate(zip(a, b)) for p in differing_paths(x, y, prefix + "/" + str(i))]
    return [] if a == b else [prefix]


replays = {}
for name, original, completed, restored, cycle, cash, receipt in [
    ("neon", "neon-completed", "neon-resume-completed", "neon-resume-cold-restored", 17, 540244, 156000),
    ("starwave", "starwave-completed", "starwave-matrix-completed", "starwave-matrix-cold-restored", 37, 1848116, 224000),
]:
    old_path, old = latest(original)
    path, payload = latest(completed)
    cold_path, cold = latest(restored)
    run = payload["run"]
    check(sha(path) == sha(cold_path), name + ": exact checkpoint bytes survive fresh-process Continue")
    check(run["completed_run_cycles"] == str(cycle) and run["cash_cents"] == str(cash), name + ": exact cycle/cash")
    receipts = [t for t in run["studio_finance"]["transactions"] if t["kind"] == "publisher_receipt" and name in t["source_id"]]
    check(len(receipts) == 1 and receipts[0]["amount_cents"] == str(receipt) and receipts[0]["cycle"] == str(cycle), name + ": only completing hand pays once")
    awards = [x for x in run["promotion_awards"] if name in x["key"]]
    check(len(awards) == 1 and awards[0]["value"] == "20" if name == "neon" else not awards, name + ": expected keyed Promotion")
    differences = differing_paths(old, payload)
    # ContractState stores exhausted IDs as a membership Dictionary. Selection order
    # changes insertion order, which the exact checkpoint codec preserves. Compare
    # that one map semantically; preserve every other list's order and all values.
    normalized = []
    for source_payload in (old, payload):
        copied = json.loads(json.dumps(source_payload))
        for offer in copied["run"]["publisher_offers"]:
            state = offer["value"]["state"]
            if isinstance(state, dict) and "exhausted" in state:
                rows = state["exhausted"]
                check(len({row["key"] for row in rows}) == len(rows), name + ": exhausted IDs unique")
                state["exhausted"] = sorted(rows, key=lambda row: row["key"])
        normalized.append(copied)
    check(normalized[0] == normalized[1], name + ": original/replay full payload equal after exhausted-map ordering normalization")
    replays[name] = {"original_sha256": sha(old_path), "completed_sha256": sha(path), "cold_sha256": sha(cold_path),
                     "cycle": cycle, "cash_cents": cash, "receipts": receipts, "promotion_awards": awards,
                     "payload_differences": differences}

source = json.loads((BASE.parent / "two-parent-store-20261011-v1/release-gate/source.json").read_text())
source_diff = []
contract_files = []
for relative, expected in source.items():
    path = ROOT / "patch-notes" / relative
    actual = sha(path) if path.is_file() else None
    if actual != expected:
        source_diff.append({"path": relative, "export_source_sha256": expected, "current_sha256": actual})
    if any(relative.startswith(p) for p in ("scripts\\contracts\\", "scripts\\publishers\\")) or relative in ("scripts\\phases\\contract_phase.gd", "scripts\\simulation\\contract_session.gd"):
        contract_files.append({"path": relative, "matches": actual == expected, "sha256": actual})
check(all(x["matches"] for x in contract_files), "Retained Contract/publisher modules match current bytes")
added_scripts = [{"path": str(p.relative_to(ROOT / "patch-notes")), "sha256": sha(p)}
                 for p in sorted((ROOT / "patch-notes/scripts").rglob("*.gd"))
                 if str(p.relative_to(ROOT / "patch-notes")) not in source]
for name, expected in [("Patch Notes Demo.exe", "7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257"),
                       ("Patch Notes Demo.pck", "2215f0ee1bd7c663b05577204aad8866a379c24abdc3e8215a3d98dcd27aca19")]:
    check(sha(BASE / "build" / name) == expected, "Retained export unchanged: " + name)

result = {"checks": len(checks), "failed": sum(not c["pass"] for c in checks), "results": checks, "replays": replays,
          "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
          "branch": subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip(),
          "contract_modules": contract_files, "source_drift_from_retained_export": source_diff,
          "current_scripts_outside_export_manifest": added_scripts,
          "limits": "Retained export evidence. Current integrated Gameplay/checkpoint/AI changes are not accepted by these replays."}
(BASE / "publisher-matrix-audit-20261017.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({k: result[k] for k in ("checks", "failed", "replays", "source_drift_from_retained_export")}, indent=2))
raise SystemExit(bool(result["failed"]))
