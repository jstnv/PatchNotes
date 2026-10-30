"""Run selected focused verifiers against the private Banking v3 project."""

import argparse
import json
import os
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent / "simulators" / "education-bank-quote-v3" / "project"
SCRIPTS = [
    "verify_campaign_session",
    "verify_finance_observation",
    "verify_bank_loan",
    "verify_feature_research",
    "verify_research_integration",
    "verify_education_atomicity",
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    assert not output.exists(), output
    output.mkdir(parents=True)
    assert PROJECT.is_dir()
    env = {k: v for k, v in os.environ.items() if not k.startswith("PN_")}
    for key in ("APPDATA", "LOCALAPPDATA", "HOME", "USERPROFILE", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME", "TMP", "TEMP", "TMPDIR"):
        target = output / "profile" / key
        target.mkdir(parents=True, exist_ok=True)
        env[key] = str(target)
    result = {"project": str(PROJECT), "godot": args.godot, "checks": {}}
    for name, extra in [("import", ["--editor", "--import"])] + [(name, ["--script", f"res://scripts/debug/{name}.gd"]) for name in SCRIPTS]:
        command = [args.godot, "--headless", "--path", str(PROJECT), *extra]
        try:
            completed = subprocess.run(command, env=env, capture_output=True, text=True, timeout=180)
            output_text = completed.stdout + completed.stderr
            code = completed.returncode
        except subprocess.TimeoutExpired as exc:
            output_text = str(exc)
            code = "timeout"
        (output / f"{name}.log").write_text(output_text, encoding="utf-8")
        result["checks"][name] = {"command": command, "exit_code": code, "script_error": "SCRIPT ERROR" in output_text or "Parse Error" in output_text}
        print(name, "exit", code, "script_error", result["checks"][name]["script_error"], flush=True)
    (output / "result.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
