"""Resume retained Pass Budget experiment cases on its pinned imported project."""
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[4] / "tools"))
import simulate


def main() -> int:
    bundle = Path(sys.argv[1]).resolve()
    godot = Path(sys.argv[2]).resolve()
    original = json.loads((bundle / "inputs/experiment.json").read_text())
    completed = {
        result.parent.name
        for folder in [bundle / "cases", *bundle.glob("remaining-cases-*")]
        for result in folder.glob("*/result.json")
    }
    pending = [case for case in original["cases"] if case["case_id"] not in completed]
    first_group = len(list(bundle.glob("experiment-remaining-*.json"))) + 1
    for index in range(0, len(pending), 3):
        group = pending[index:index + 3]
        group_id = first_group + index // 3
        config = dict(original)
        config["cases"] = group
        config_path = bundle / "inputs" / f"remaining-{group_id}.json"
        report_path = bundle / f"experiment-remaining-{group_id}.json"
        log_path = bundle / f"experiment-remaining-{group_id}.log"
        config_path.write_text(json.dumps(config, indent=2) + "\n")
        command = [
            str(godot), "--headless", "--path", str(bundle / "project"),
            "--script", "res://scripts/debug/campaign_experiment_cli.gd", "--",
            f"--config={config_path}", f"--output-dir={bundle / f'remaining-cases-{group_id}'}",
            f"--output={report_path}",
        ]
        print(f"Running group {group_id}: {[case['case_id'] for case in group]}", flush=True)
        result = subprocess.run(
            command, cwd=bundle, env=simulate.isolated_environment(bundle / "profile"),
            capture_output=True, text=True, timeout=600,
        )
        log_path.write_text(result.stdout + result.stderr)
        print(f"Group {group_id} exit {result.returncode}", flush=True)
        if result.returncode and not report_path.exists():
            return result.returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
