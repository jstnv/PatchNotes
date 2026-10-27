"""Bounded private probe of the frozen g2-pre-admission-v1 runner bundle.

No gameplay code or checkpoint identity is changed here. Each Godot process gets
its own output and Windows profile; all commands, logs and failures are kept.
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import time


CASES = [
    ("4417", "screen", "", 60000),
    ("4417", "first", "animated_sprites", 60000),
    ("4417", "save-60k", "save_files", 60000),
    ("4417", "save-100k", "save_files", 100000),
    ("90210", "screen", "", 60000),
    ("90210", "first", "multi_directional_scrolling", 60000),
    ("90210", "save-60k", "save_files", 60000),
    ("90210", "save-100k", "save_files", 100000),
]


def write_json(path: Path, data: object) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def process(command: list[str], folder: Path) -> dict:
    folder.mkdir(parents=True, exist_ok=False)
    profile = folder / "profile"
    (profile / "AppData" / "Roaming").mkdir(parents=True)
    (profile / "AppData" / "Local").mkdir(parents=True)
    env = os.environ.copy()
    env["APPDATA"] = str(profile / "AppData" / "Roaming")
    env["LOCALAPPDATA"] = str(profile / "AppData" / "Local")
    write_json(folder / "command.json", command)
    started = time.monotonic()
    try:
        completed = subprocess.run(command, env=env, capture_output=True, text=True, timeout=240)
        exit_code = completed.returncode
        timed_out = False
        output = completed.stdout + completed.stderr
    except subprocess.TimeoutExpired as exc:
        exit_code = None
        timed_out = True
        output = (exc.stdout or b"").decode(errors="replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")
        output += (exc.stderr or b"").decode(errors="replace") if isinstance(exc.stderr, bytes) else (exc.stderr or "")
    (folder / "godot.log").write_text(output, encoding="utf-8")
    result = {"exit_code": exit_code, "timed_out": timed_out, "elapsed_seconds": round(time.monotonic() - started, 3)}
    write_json(folder / "process.json", result)
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--bundle", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    bundle, output = Path(args.bundle).resolve(), Path(args.output).resolve()
    if output.exists():
        parser.error("output directory must be new")
    output.mkdir(parents=True)
    project = bundle / "project"
    summary = []
    source_identities = set()
    for seed, label, candidate, held in CASES:
        checkpoint = bundle / "cases" / f"g2-held-prefix-{seed}" / "studio_checkpoint.json"
        folder = output / f"probe-{seed}-{label}"
        result_path = folder / "result.json"
        command = [args.godot, "--headless", "--path", str(project), "--script", "res://scripts/debug/verify_g2_legal_mix.gd", "--", f"--checkpoint={checkpoint}", "--mode=pre_admission", "--horizon=8", f"--held_cash={held}", f"--candidate={candidate}", f"--output={result_path}"]
        proc = process(command, folder)
        data = json.loads(result_path.read_text(encoding="utf-8")) if result_path.exists() else {}
        if data.get("source_identity"):
            source_identities.add(data["source_identity"])
        ok = proc["exit_code"] == 0 and not proc["timed_out"] and data.get("ok") is True
        summary.append({"seed": seed, "label": label, "candidate": candidate, "held_cash_cents": held, "ok": ok, "status": data.get("status", "missing_result"), "checks": data.get("checks"), "failures": data.get("failures"), "result": str(result_path), "process": proc})
        write_json(output / "summary.json", {"cases": summary, "source_identities": sorted(source_identities)})

    replayed = set()
    for row in list(summary):
        if not row["ok"] or row["status"] != "admitted" or (row["seed"], row["candidate"]) in replayed:
            continue
        replayed.add((row["seed"], row["candidate"]))
        seed, candidate = row["seed"], row["candidate"]
        checkpoint = bundle / "cases" / f"g2-held-prefix-{seed}" / "studio_checkpoint.json"
        tape = Path(row["result"] + ".acquisition.tape.json")
        folder = output / f"replay-{seed}-{candidate}"
        result_path = folder / "result.json"
        command = [args.godot, "--headless", "--path", str(project), "--script", "res://scripts/debug/campaign_replay_cli.gd", "--", f"--checkpoint={checkpoint}", f"--tape={tape}", f"--output={result_path}"]
        proc = process(command, folder)
        data = json.loads(result_path.read_text(encoding="utf-8")) if result_path.exists() else {}
        ok = proc["exit_code"] == 0 and not proc["timed_out"] and data.get("ok") is True
        summary.append({"seed": seed, "label": "replay", "candidate": candidate, "ok": ok, "status": "replayed" if ok else "replay_failed", "steps": len(data.get("steps", [])), "result": str(result_path), "process": proc})
        write_json(output / "summary.json", {"cases": summary, "source_identities": sorted(source_identities)})

    success = all(row["ok"] for row in summary) and len(source_identities) == 1
    write_json(output / "summary.json", {"ok": success, "cases": summary, "source_identities": sorted(source_identities), "scope": "Eight declared Studio guard observations and one replay per distinct admitted node; private rent-only prototype, no approved AI"})
    print(json.dumps({"ok": success, "statuses": [(row["seed"], row["label"], row["status"]) for row in summary], "source_identities": sorted(source_identities)}))
    return 0 if success else 1


if __name__ == "__main__":
    raise SystemExit(main())
