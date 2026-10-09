"""Full Studio DTO across independent Godot processes; isolated profile."""
from pathlib import Path
import json, os, subprocess, tempfile
from run_checks import GODOT, PROJECT, PROFILE, HERE, REPO

PROFILE.mkdir(parents=True, exist_ok=True)
profile = Path(tempfile.mkdtemp(prefix="restart-", dir=PROFILE))
env = os.environ.copy()
for key in ("APPDATA", "LOCALAPPDATA"):
    directory = profile / key
    directory.mkdir()
    env[key] = str(directory)
records = []
for mode in ("initial", "loan", "installment", "payoff", "unsaved_contract", "contract", "check"):
    command = [GODOT, "--headless", "--path", str(PROJECT), "--script",
               "res://scripts/debug/checkpoint_runtime_process_probe.gd", "--", mode]
    with (HERE / f"process-{mode}.log").open("wb") as output:
        result = subprocess.run(command, cwd=REPO, env=env, stdout=output,
                                stderr=subprocess.STDOUT, timeout=90)
    text = (HERE / f"process-{mode}.log").read_text(errors="replace")
    errors = [line for line in text.splitlines()
              if ("SCRIPT ERROR" in line or line.startswith("ERROR:") or "FAIL:" in line)
              and "root certificate store" not in line]
    records.append(dict(mode=mode, command=command, exit=result.returncode, errors=errors))
    (HERE / "process-results.json").write_text(json.dumps(dict(profile=str(profile), test_lease_port=env.get("PN_CHECKPOINT_TEST_PORT"), runs=records), indent=2))
    print(mode, result.returncode, errors, flush=True)
    if result.returncode or errors:
        raise SystemExit(1)
