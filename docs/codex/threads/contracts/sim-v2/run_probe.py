"""Run one saved-ledger compatibility probe in the isolated Godot copy."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent / "sim-v1" / "project"
GODOT = Path(
    r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe"
    r"\Godot_v4.7.1-stable_win64_console.exe"
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def main() -> int:
    original_finance = HERE.parents[4] / "patch-notes/scripts/finance/studio_finance_ledger.gd"
    copied_finance = PROJECT / "scripts/finance/studio_finance_ledger.gd"
    script = HERE / "raw_snapshot_probe.gd"
    copied_script = PROJECT / "analysis/task34_raw_snapshot_probe.gd"
    input_route = HERE.parent / "sim-v1/legacy-strong-probe.json"
    copied_input = PROJECT / "task34-input-legacy.json"
    assert sha256(original_finance) == sha256(copied_finance)
    assert sha256(script) == sha256(copied_script)
    assert sha256(input_route) == sha256(copied_input)
    profile = HERE.parent / "sim-v1/profile"
    environment = os.environ.copy()
    environment["APPDATA"] = str(profile / "APPDATA")
    environment["LOCALAPPDATA"] = str(profile / "LOCALAPPDATA")
    command = [
        str(GODOT),
        "--headless",
        "--path",
        str(PROJECT),
        "--script",
        "res://analysis/task34_raw_snapshot_probe.gd",
    ]
    try:
        process = subprocess.run(
            command,
            cwd=PROJECT,
            env=environment,
            capture_output=True,
            timeout=60,
            check=False,
        )
        exit_code: int | str = process.returncode
        output = process.stdout + process.stderr
    except subprocess.TimeoutExpired as error:
        exit_code = "timeout"
        output = (error.stdout or b"") + (error.stderr or b"")
    (HERE / "raw-snapshot-probe-isolated.log").write_bytes(output)
    record = {
        "command": command,
        "exit": exit_code,
        "log": "raw-snapshot-probe-isolated.log",
        "finance_sha256": sha256(original_finance),
        "probe_sha256": sha256(script),
        "input_sha256": sha256(input_route),
    }
    (HERE / "raw-snapshot-probe.command.json").write_text(
        json.dumps(record, indent=2), encoding="utf-8"
    )
    output_path = PROJECT / "task34-raw-snapshot-probe.json"
    if output_path.exists():
        shutil.copy2(output_path, HERE / "raw-snapshot-probe.json")
    print(json.dumps(record), flush=True)
    return 0 if exit_code == 0 and output_path.exists() else 1


if __name__ == "__main__":
    sys.exit(main())
