"""Run the rival Feature-exhaustion verifier in a fresh isolated project/profile."""
from __future__ import annotations

import argparse
import importlib.util
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
GODOT = Path("C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    spec = importlib.util.spec_from_file_location("rival_exhaustion_sim", ROOT / "tools/simulate.py")
    assert spec and spec.loader
    sim = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sim)
    source = sim.copy_snapshot(ROOT / "patch-notes", out / "project")
    sim.write_json(out / "source.json", source)
    imported_source = sim.import_project(GODOT, out / "project", out, sim.isolated_environment(out / "import-profile"), 180)
    command = [str(GODOT), "--headless", "--path", str(out / "project"), "--script", "res://scripts/debug/verify_rival_feature_exhaustion.gd"]
    with (out / "verifier.log").open("x", encoding="utf-8") as stream:
        result = subprocess.run(command, env=sim.isolated_environment(out / "profile"), stdout=stream, stderr=subprocess.STDOUT, timeout=120, check=False)
    unchanged = sim.source_hashes(out / "project") == imported_source
    receipt = {"command": command, "exit_code": result.returncode, "source_unchanged": unchanged, "source_identity": sim.sha(ROOT / "patch-notes/scripts/market/rival_trial.gd")}
    sim.write_json(out / "receipt.json", receipt)
    print(json.dumps(receipt))
    return 0 if result.returncode == 0 and unchanged else 1


if __name__ == "__main__":
    raise SystemExit(main())
