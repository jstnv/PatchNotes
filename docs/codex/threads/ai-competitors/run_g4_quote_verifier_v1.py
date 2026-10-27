"""Run the thread-owned quote audit against a frozen isolated simulator bundle."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--timeout", type=float, default=120)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        raise SystemExit("Output folder already exists")
    output.mkdir(parents=True)
    project = (args.bundle.resolve() / "project")
    if not (project / "project.godot").is_file():
        raise SystemExit("Frozen project missing")
    script = Path(__file__).with_name("verify_g4_current_hand_quote_v1.gd").resolve()
    repo = Path(__file__).resolve().parents[4]
    spec = importlib.util.spec_from_file_location("patch_notes_simulate", repo / "tools" / "simulate.py")
    assert spec and spec.loader
    sim = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sim)
    before = sim.source_hashes(project)
    environment = sim.isolated_environment(output / "profile")
    script_sha256 = hashlib.sha256(script.read_bytes()).hexdigest()
    try:
        command = sim.run_process(
            "g4-quote-verifier",
            [str(sim.resolve_godot(args.godot)), "--headless", "--path", str(project), "--script", str(script)],
            output,
            environment,
            args.timeout,
        )
    finally:
        sim.check_snapshot(project, before)
    result = {
        "ok": True,
        "bundle": str(args.bundle.resolve()),
        "project_source_unchanged": True,
        "script": str(script),
        "script_sha256": script_sha256,
        "process_exit": command["exit"],
        "elapsed_seconds": command["elapsed_seconds"],
    }
    (output / "result.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
