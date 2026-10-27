"""Run the private archive verifier with the simulator's source/profile isolation."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[4]
SPEC = importlib.util.spec_from_file_location("isolated_simulator", ROOT / "tools" / "simulate.py")
SIM = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SIM)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--godot", required=True)
    args = parser.parse_args()
    variant = (ROOT / args.variant).resolve()
    output = (ROOT / args.output).resolve()
    if output.exists():
        raise FileExistsError(output)
    output.mkdir(parents=True)
    source = variant / "project"
    expected = SIM.copy_snapshot(source, output / "project")
    environment = SIM.isolated_environment(output / "profile")
    godot = str(Path(args.godot).resolve())
    project = str(output / "project")
    source_identity = hashlib.sha256(json.dumps(expected, sort_keys=True).encode()).hexdigest()
    summary = {"source_identity": source_identity, "source_files": len(expected), "import": "pending", "verifier": "not_run"}
    try:
        SIM.run_process("import", [godot, "--headless", "--path", project, "--editor", "--import", "--quit"], output, environment, 240)
        summary["import"] = "passed"
        SIM.run_process("verifier", [godot, "--headless", "--path", project, "--script", "res://scripts/debug/verify_incumbent_archive.gd"], output, environment, 240)
        summary["verifier"] = "passed"
        return 0
    except Exception as error:
        summary["error"] = str(error)
        return 1
    finally:
        try:
            SIM.check_snapshot(output / "project", expected)
            summary["source_unchanged"] = True
        except Exception as error:
            summary["source_unchanged"] = False
            summary["source_error"] = str(error)
        (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(summary))


if __name__ == "__main__":
    sys.exit(main())
