"""Run a focused rival verifier on a frozen simulator project/profile."""
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
    parser.add_argument("--script", choices=["verify_rival_world_foundation.gd", "verify_rival_trial_activation.gd", "verify_rival_gameplay_activation.gd", "verify_rival_gameplay_cold_continue.gd", "verify_studio_checkpoint.gd", "verify_campaign_session.gd", "verify_market_founder_f8.gd", "verify_market_source_family.gd", "verify_market_historical_sources.gd", "verify_market_coordinator_integrated.gd", "verify_market_player_store_integrated.gd"], required=True)
    parser.add_argument("--test-port", default="47738")
    parser.add_argument("--profile", type=Path, help="Reuse this isolated test profile for a separate cold process")
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
    environment = sim.isolated_environment(args.profile.resolve() if args.profile else output / "profile")
    environment["PN_CHECKPOINT_TEST_PORT"] = args.test_port
    sim.run_process(
        "rival-verifier",
        [str(sim.resolve_godot(args.godot)), "--headless", "--path", str(project), "--script", "res://scripts/debug/" + args.script],
        output,
        environment,
        args.timeout,
    )
    sim.check_snapshot(project, before)
    print(json.dumps({"ok": True, "output": str(output), "source_unchanged": True}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
