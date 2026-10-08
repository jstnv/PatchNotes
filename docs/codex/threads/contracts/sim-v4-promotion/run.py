"""Reproduce the small read-only Promotion sweep on the pinned Task 34 project."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
V3 = HERE.parent / "sim-v3"
PROJECT = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-20261007-v3\patch-notes")
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
CASES = {"crown": "route-legacy-ordinary-0-0.bin", "neon": "route-legacy-ordinary-0-1.bin"}


def main() -> None:
    for publisher, capture in CASES.items():
        profile = HERE / "profile" / publisher
        appdata = profile / "appdata"
        localappdata = profile / "localappdata"
        appdata.mkdir(parents=True, exist_ok=True)
        localappdata.mkdir(parents=True, exist_ok=True)
        env = os.environ.copy()
        env["APPDATA"] = str(appdata)
        env["LOCALAPPDATA"] = str(localappdata)
        command = [str(GODOT), "--headless", "--path", str(PROJECT), "--script",
                   str(HERE / "promotion_sweep.gd"), "--", "--input=" + str(V3 / capture),
                   "--publisher=" + publisher, "--out=" + str(HERE / (publisher + ".json"))]
        with (HERE / (publisher + ".log")).open("wb") as stream:
            result = subprocess.run(command, cwd=PROJECT, env=env, stdout=stream,
                                    stderr=subprocess.STDOUT, timeout=180)
        log = (HERE / (publisher + ".log")).read_text(errors="replace")
        record = {"command": command, "exit": result.returncode,
                  "marker": "PROMOTION_V4 " + publisher + " results=2 checks=1600 failures=0"}
        (HERE / (publisher + ".command.json")).write_text(json.dumps(record, indent=2), encoding="utf-8")
        if result.returncode != 0 or record["marker"] not in log or "SCRIPT ERROR" in log:
            raise RuntimeError(publisher + " Godot sweep failed; inspect " + publisher + ".log")
        print(record["marker"])
    subprocess.run([sys.executable, str(HERE / "audit.py")], check=True)


if __name__ == "__main__":
    main()
