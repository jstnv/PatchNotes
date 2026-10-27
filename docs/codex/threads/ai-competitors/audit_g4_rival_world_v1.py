"""Compare private original/candidate two-rival verifier outcomes."""

import argparse
import hashlib
import json
from pathlib import Path


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def latest_world(bundle: Path) -> dict:
    folder = bundle / "profile" / "APPDATA" / "Godot" / "app_userdata" / "Patch Notes" / "saves" / "studio"
    candidates = []
    for path in folder.glob("checkpoint.*.json"):
        envelope = read(path)
        payload = envelope["payload_utf8"]
        if hashlib.sha256(payload.encode("utf-8")).hexdigest() != envelope["payload_sha256"]:
            raise ValueError(f"Payload hash mismatch: {path}")
        decoded = json.loads(payload)
        candidates.append((decoded["sequence"], path.name, decoded["rival_world"]))
    if not candidates:
        raise ValueError(f"No isolated world checkpoints: {folder}")
    candidates.sort()
    sequence, name, world = candidates[-1]
    return {"sequence": sequence, "file": name, "world": world}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--original", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit(f"Refusing to overwrite {args.output}")
    original_check = read(args.original / "check-report.json")
    candidate_check = read(args.candidate / "check-report.json")
    original = latest_world(args.original)
    candidate = latest_world(args.candidate)
    old_history = original["world"]["history"]
    new_history = candidate["world"]["history"]
    checks = [
        ("both verifier passes", original_check["ok"] and candidate_check["ok"]),
        ("both 118 assertions", original_check["checks"] == candidate_check["checks"] == 118),
        ("both 20 cycles and four releases", original_check["cycles"] == candidate_check["cycles"] == 20 and len(old_history) == len(new_history) == 4),
        ("same checkpoint world cycle", original["world"]["cycle"] == candidate["world"]["cycle"] == 20),
    ]
    rows = []
    for index, (old, new) in enumerate(zip(old_history, new_history)):
        for field in ("studio_id", "release_cycle", "title", "genre", "theme"):
            checks.append((f"release {index + 1} {field}", old[field] == new[field]))
        rows.append({"studio_id": old["studio_id"], "title": old["title"], "cycle": old["release_cycle"], "original_review": old["review_tenths"] / 10, "candidate_review": new["review_tenths"] / 10, "delta": (new["review_tenths"] - old["review_tenths"]) / 10})
    report = {"checks_passed": sum(ok for _, ok in checks), "checks_total": len(checks), "failures": [label for label, ok in checks if not ok], "original_source": original_check["source_identity"], "candidate_source": candidate_check["source_identity"], "original_checkpoint": original["file"], "candidate_checkpoint": candidate["file"], "original_elapsed_seconds": original_check["elapsed_seconds"], "candidate_elapsed_seconds": candidate_check["elapsed_seconds"], "rows": rows}
    args.output.mkdir(parents=True)
    (args.output / "audit.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    lines = ["# G4 two-rival world comparison", "", f"Checks: {report['checks_passed']}/{report['checks_total']}; original {report['original_elapsed_seconds']:.2f}s, candidate {report['candidate_elapsed_seconds']:.2f}s total verifier wall time.", "", "| Rival | Release cycle | Original Review | Candidate Review | Delta |", "| --- | ---: | ---: | ---: | ---: |"]
    for row in rows:
        lines.append(f"| {row['title']} | {row['cycle']} | {row['original_review']:.1f} | {row['candidate_review']:.1f} | {row['delta']:+.1f} |")
    if report["failures"]:
        lines += ["", "Failures: " + "; ".join(report["failures"])]
    (args.output / "audit.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in report.items() if key != "rows"}))
    if report["failures"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
