"""Frozen-source, isolated-profile Continue loading acceptance. No player saves."""
from pathlib import Path
import argparse
import importlib.util
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[4]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--godot", required=True, type=Path)
    parser.add_argument("--native", action="store_true")
    parser.add_argument("--tests", nargs="+", default=["verify_continue_loading"])
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    sim = module("loading_simulate", ROOT / "tools/simulate.py")
    gate = module("loading_gate", ROOT / "tools/release_gate.py")
    source = sim.copy_snapshot(ROOT / "patch-notes", out / "project")
    sim.write_json(out / "source.json", source)
    provenance = {}
    for label, arguments in [("branch", ["branch", "--show-current"]), ("head", ["rev-parse", "HEAD"]), ("tracked_status", ["status", "--porcelain=v1", "--untracked-files=no"])]:
        result = subprocess.run(["git", *arguments], cwd=ROOT, capture_output=True, timeout=30)
        provenance[label] = result.stdout.decode("utf8", errors="replace").strip()
    provenance["scope"] = "Tracked status plus complete frozen source.json including untracked runtime files; avoids known slow all-untracked repository inventory."
    sim.write_json(out / "provenance.json", provenance)
    report = {"checks": [], "native": args.native, "pass": False}
    try:
        sim.run_process("import", [str(args.godot), "--headless", "--editor", "--path", str(out / "project"), "--import", "--quit"], out, sim.isolated_environment(out / "import-profile"), 180)
        for name in args.tests:
            sim.run_process("parse-" + name, [str(args.godot), "--headless", "--path", str(out / "project"), "--check-only", "--script", "res://scripts/debug/" + name + ".gd"], out, sim.isolated_environment(out / "parse-profile"), 30)
        for name in args.tests:
            profile = out / ("profile-" + name)
            env = sim.isolated_environment(profile)
            env["PN_CHECKPOINT_TEST_PORT"] = "47733"
            env["PN_CARD_FRAME_OUTPUT"] = str(out / (name + ".json"))
            captures = out / "captures"
            captures.mkdir(exist_ok=True)
            if args.native:
                env["PN_LOADING_CAPTURE_DIR"] = str(captures)
            wrapper, metadata = gate.checkpoint_wrapper(ROOT / "patch-notes/scripts/debug" / (name + ".gd"), out / "wrappers")
            argv = [str(args.godot), "--path", str(out / "project"), "--script", str(wrapper)]
            if not args.native:
                argv.append("--headless")
            command = sim.run_process(name, argv, out, env, 300)
            report["checks"].append({"name": name, "command": command, "wrapper": metadata})
        sim.check_snapshot(out / "project", source)
        report["pass"] = True
    except Exception as error:
        report["error"] = str(error)
    finally:
        sim.write_json(out / "result.json", report)
    print(json.dumps({"pass": report["pass"], "output": str(out), "error": report.get("error"), "checks": len(report["checks"])}))
    return 0 if report["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
