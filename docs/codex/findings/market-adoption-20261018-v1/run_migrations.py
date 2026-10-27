"""Sequential detached Store writers; every run retains its own evidence."""
from pathlib import Path
import json
import subprocess
import sys

out = Path(__file__).resolve().parent
tag = sys.argv[1]
cases = sys.argv[2:] or ["prior-world", "current-world", "synergy-world", "bank-recovered", "bank-only", "founder-v1", "world-v1", "founder-v2"]
results = []
pause_file = out / (f"migration-{tag}.pause")
for case in cases:
    if pause_file.exists():
        print(f"Paused before {case}; retained completed results", flush=True)
        break
    label = f"migration-{tag}-{case}"
    if (out / (label + ".json")).exists():
        raise SystemExit(f"Output already exists: {label}")
    command = [sys.executable, str(out / "run.py"), label, str(out / "migration.gd"), "--case=" + case]
    result = subprocess.run(command)
    results.append({"label": label, "exit": result.returncode})
    if result.returncode:
        break
    if pause_file.exists():
        print(f"Paused before {case} cold; retained completed results", flush=True)
        break
    cold = label + "-cold"
    command = [sys.executable, str(out / "run.py"), cold, str(out / "migration.gd"), "--case=" + case,
               "--mode=cold", "--input=" + str(out / (label + ".json.expected.json"))]
    result = subprocess.run(command)
    results.append({"label": cold, "exit": result.returncode})
    if result.returncode:
        break
(out / (f"migration-{tag}-runs.json")).write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
sys.exit(1 if any(x["exit"] for x in results) else 0)
