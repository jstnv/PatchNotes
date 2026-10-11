"""Read-only reconciliation of exported UI checkpoint copies and build evidence."""
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
REPO = BASE.parents[3]
checks = 0

def check(ok, label):
    global checks
    checks += 1
    assert ok, label

def read(path):
    return json.loads(path.read_text(encoding="utf-8"))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

latest = {}
for folder in sorted((BASE / "checkpoints").iterdir()):
    files = sorted(folder.glob("checkpoint.*.json"), key=lambda p: int(p.stem.split(".")[-1]))
    for path in files:
        envelope = read(path)
        check(hashlib.sha256(envelope["payload_utf8"].encode()).hexdigest() == envelope["payload_sha256"], str(path))
        payload = json.loads(envelope["payload_utf8"])
        run = payload["run"]
        finance = run["studio_finance"]
        previous = 0
        for index, transaction in enumerate(finance["transactions"], 1):
            check(int(transaction["cash_before_cents"]) == previous, "cash chain")
            previous += int(transaction["cash_delta_cents"])
            check(previous == int(transaction["cash_after_cents"]), "cash delta")
            check(int(transaction["sequence"]) == index, "transaction sequence")
        check(previous == int(finance["cash_cents"]) == int(run["cash_cents"]), "closing cash")
        latest[folder.name] = run

expected = {
    "before-continue": (9, 616265, 26), "bank-accepted": (10, 618992, 26),
    "second-release": (24, 167108, 26), "promotion32": (28, 1184338, 124),
    "starwave-complete": (31, 1469526, 139), "promotion-consumed": (33, 1463253, 149),
    "no-trait": (0, 570000, 0), "cult-minimum": (0, 565000, 40),
    "education-active": (0, 580000, 0), "education-closed": (0, 80000, 0),
}
for name, expected_values in expected.items():
    run = latest[name]
    observed = (int(run["completed_run_cycles"]), int(run["cash_cents"]), int(run["fanbase"]["fans"]))
    check(observed == expected_values, (name, observed, expected_values))

builds = {}
for name in (".", "creation-control", "cult-minimum", "education"):
    root = BASE / name
    summary = read(root / "export/playable-summary.json")
    check(summary["package_entries"] == 237 and summary["headless_startup_exit"] == 0, "build gate")
    check(not summary["source_drift_since_gate"] and not summary["included_source_drift_after_export"], "build drift")
    for artifact, record in summary["artifacts"].items():
        check(sha(root / "playable" / artifact) == record["sha256"], artifact)
    manifest = read(root / "export/build-manifest.json")
    for relative, digest in manifest["included"].items():
        if relative in ("project.godot", "export_presets.cfg"):
            continue  # Dedicated-profile build configuration, not gameplay.
        check(sha(REPO / "patch-notes" / relative) == digest, relative)
    builds[name] = summary

logs = sorted((BASE / "runtime-logs").rglob("*.log"))
errors = []
warnings = {}
for log in logs:
    for line in log.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith(("ERROR:", "SCRIPT ERROR:")):
            errors.append([str(log.relative_to(BASE)), line])
        if line.startswith("WARNING:"):
            key = "missing optional artwork" if "Artwork not found" in line else line
            warnings[key] = warnings.get(key, 0) + 1
check(not errors, errors)
result = {"checks": checks, "passed": True, "captures": len(list((BASE / "captures").glob("*.png"))),
          "checkpoint_groups": list(latest), "runtime_log_count": len(logs), "runtime_errors": errors,
          "runtime_warnings": warnings, "builds": builds, "release_ready": False}
(BASE / "audit-result.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: v for k, v in result.items() if k != "builds"}, indent=2))

