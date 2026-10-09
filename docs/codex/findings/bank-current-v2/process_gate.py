"""Full Studio DTO across independent Godot processes; isolated profile."""
from pathlib import Path
import json, os, subprocess, tempfile
HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
PROJECT = REPO / "patch-notes"
PROFILE = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\bank-restart-gaps-20261007")
GODOT = r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"

PROFILE.mkdir(parents=True, exist_ok=True)
profile = Path(tempfile.mkdtemp(prefix="restart-", dir=PROFILE))
env = os.environ.copy()
env["PN_CHECKPOINT_TEST_PORT"] = "47412"
for key in ("APPDATA", "LOCALAPPDATA"):
    directory = profile / key
    directory.mkdir()
    env[key] = str(directory)
records = []
for mode in ("setup", "unsaved", "rollback", "arrears", "partial", "recovered", "check"):
    command = [GODOT, "--headless", "--path", str(PROJECT), "--script",
               "res://scripts/debug/banking_restart_gap_probe.gd", "--", mode]
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
