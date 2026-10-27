"""Render and sample audio from an unchanged, already imported test snapshot."""
from pathlib import Path
import argparse
import importlib.util
import json

ROOT = Path(__file__).resolve().parents[4]
spec = importlib.util.spec_from_file_location("loading_simulate", ROOT / "tools/simulate.py")
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
parser = argparse.ArgumentParser()
source_group = parser.add_mutually_exclusive_group(required=True)
source_group.add_argument("--from-run", type=Path)
source_group.add_argument("--fresh", action="store_true")
parser.add_argument("--output", required=True, type=Path)
parser.add_argument("--godot", required=True, type=Path)
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=False)
if args.fresh:
    project = args.output / "project"
    source = sim.copy_snapshot(ROOT / "patch-notes", project)
    sim.run_process("import", [str(args.godot), "--headless", "--editor", "--path", str(project), "--import", "--quit"], args.output, sim.isolated_environment(args.output / "import-profile"), 180)
else:
    project = args.from_run / "project"
    source = sim.read_json(args.from_run / "source.json")
sim.check_snapshot(project, source)
(args.output / "captures").mkdir()
sim.write_json(args.output / "source.json", source)
env = sim.isolated_environment(args.output / "profile")
env.update(PN_CHECKPOINT_TEST_PORT="47734", PN_CARD_FRAME_OUTPUT=str(args.output / "loading.json"), PN_LOADING_CAPTURE_DIR=str(args.output / "captures"))
command = sim.run_process("native-loading", [str(args.godot), "--path", str(project), "--script", "res://scripts/debug/verify_continue_loading.gd"], args.output, env, 180)
sim.check_snapshot(project, source)
sim.write_json(args.output / "result.json", {"pass": True, "unchanged_source": True, "command": command, "result": sim.read_json(args.output / "loading.json")})
print(json.dumps({"pass": True, "output": str(args.output)}))
