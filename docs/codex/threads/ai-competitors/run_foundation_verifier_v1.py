"""Run the focused world verifier on a frozen simulator project/profile."""
from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--timeout", type=float, default=60)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        raise SystemExit("Output folder already exists")
    output.mkdir(parents=True)
    project = (args.bundle.resolve() / "project")
    if not (project / "project.godot").is_file():
        raise SystemExit("Frozen project missing")
    repo = Path(__file__).resolve().parents[4]
    spec = importlib.util.spec_from_file_location("patch_notes_simulate", repo / "tools" / "simulate.py")
    assert spec and spec.loader
    sim = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sim)
    before = sim.source_hashes(project)
    sim.run_process(
        "foundation-verifier",
        [str(sim.resolve_godot(args.godot)), "--headless", "--path", str(project), "--script", "res://scripts/debug/verify_rival_world_foundation.gd"],
        output,
        sim.isolated_environment(output / "profile"),
        args.timeout,
    )
    sim.check_snapshot(project, before)
    print(json.dumps({"ok": True, "output": str(output), "source_unchanged": True}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
