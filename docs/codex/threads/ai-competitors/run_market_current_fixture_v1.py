"""Produce and cold-read one real current-source Founder/world fixture in an isolated run bundle."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import socket


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--timeout", type=float, default=240)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    project = args.bundle.resolve() / "project"
    if not (project / "project.godot").is_file():
        raise SystemExit("Frozen project missing")

    repo = Path(__file__).resolve().parents[4]
    spec = importlib.util.spec_from_file_location("patch_notes_simulate", repo / "tools" / "simulate.py")
    assert spec and spec.loader
    sim = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sim)
    source_before = sim.source_hashes(project)
    godot = str(sim.resolve_godot(str(args.godot)))
    pair = output / "world-pair.json"
    cold = output / "cold-recapture.json"
    results: list[dict] = []
    for name, script, extra in (
        ("produce", "verify_legacy_world.gd", []),
        ("cold", "verify_world_restore_file.gd", [str(pair), str(cold)]),
    ):
        environment = sim.isolated_environment(output / ("profile-" + name))
        environment["PN_CARD_FRAME_OUTPUT"] = str(pair)
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        environment["PN_CHECKPOINT_TEST_PORT"] = str(port)
        command = [godot, "--headless", "--audio-driver", "Dummy", "--path", str(project), "--script", "res://scripts/debug/" + script, "--", *extra]
        result = sim.run_process(name, command, output, environment, args.timeout)
        sim.check_snapshot(project, source_before)
        results.append({"name": name, "port": port, "exit": result["exit"], "elapsed_seconds": result["elapsed_seconds"], "profile": str(output / ("profile-" + name))})
        sim.write_json(output / "results.json", results)

    original = json.loads(pair.read_text(encoding="utf-8-sig"))
    recaptured = json.loads(cold.read_text(encoding="utf-8-sig"))
    summary = {
        "pair_sha256": hashlib.sha256(pair.read_bytes()).hexdigest(),
        "cold_sha256": hashlib.sha256(cold.read_bytes()).hexdigest(),
        "world_source": original["world"]["source_identity"],
        "cold_world_source": recaptured["world"]["source_identity"],
        "player_revision": original["player"]["content_revision"],
        "cold_player_revision": recaptured["player"]["content_revision"],
        "legacy_version": original["world"]["legacy"]["version"],
        "operator_run_id": original["player"]["run_id"],
        "studio_ids": [studio["id"] for studio in original["world"]["studios"]],
        "history_count": len(original["world"]["history"]),
        "source_unchanged": True,
    }
    sim.write_json(output / "summary.json", summary)
    print(json.dumps({"ok": True, "output": str(output), **summary}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
