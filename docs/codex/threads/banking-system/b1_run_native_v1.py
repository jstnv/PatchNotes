"""Run bounded current-source Banking B1 no-loan routes; gameplay is unchanged."""
from __future__ import annotations

import concurrent.futures
import hashlib
import argparse
import itertools
import json
import os
from pathlib import Path
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PROJECT = ROOT / "patch-notes"
SCRIPT = PROJECT / "analysis" / "b1_banking_route_v1.gd"
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
OUT = HERE / "evidence"
OUT.mkdir(exist_ok=True)

expected = hashlib.sha256((HERE / "b1_native_routes_v1.gd").read_bytes()).hexdigest()
assert SCRIPT.exists() and hashlib.sha256(SCRIPT.read_bytes()).hexdigest() == expected
parser = argparse.ArgumentParser()
parser.add_argument("--band", choices=("early", "odd", "middle", "slow"))
args = parser.parse_args()
bands = (args.band,) if args.band else ("early", "odd", "middle", "slow")
jobs = list(itertools.product(("base", "trait"), bands,
                              ("ordinary", "synergy"), (1104, 4417)))


def run(job: tuple[str, str, str, int]) -> dict:
    funding, band, policy, seed = job
    label = f"{funding}_{band}_{policy}_{seed}"
    args = [str(GODOT), "--quiet", "--headless", "--path", str(PROJECT),
            "--script", "res://analysis/b1_banking_route_v1.gd", "--",
            f"--funding={funding}", f"--band={band}", f"--policy={policy}",
            f"--seed={seed}", f"--out={OUT}"]
    with tempfile.TemporaryDirectory(prefix="pn-banking-b1-") as profile:
        env = os.environ.copy()
        for variable, name in (("APPDATA", "Roaming"), ("LOCALAPPDATA", "Local")):
            path = Path(profile) / name
            path.mkdir()
            env[variable] = str(path)
        try:
            result = subprocess.run(args, cwd=ROOT, env=env, capture_output=True,
                                    text=True, encoding="utf-8", errors="replace", timeout=90)
            output = result.stdout + "\n" + result.stderr
            exit_code = result.returncode
        except subprocess.TimeoutExpired as error:
            output = (error.stdout or b"").decode("utf-8", "replace") if isinstance(error.stdout, bytes) else (error.stdout or "")
            output += "\nTIMEOUT 90s"
            exit_code = -1
    (OUT / f"run_{label}.log").write_text(output, encoding="utf-8")
    trace = OUT / f"route_{label}.json"
    data = json.loads(trace.read_text(encoding="utf-8")) if trace.exists() else {}
    return {"job": label, "command": args, "exit": exit_code,
            "trace": trace.name if trace.exists() else None,
            "valid": data.get("valid", False), "release_cycles": [x.get("cycle") for x in data.get("releases", [])],
            "reviews": [x.get("final_review") for x in data.get("releases", [])],
            "initial_cash_cents": data.get("initial", {}).get("cash_cents"),
            "final_cycle": data.get("final", {}).get("cycle"),
            "errors": data.get("errors", []), "discrepancies": data.get("discrepancies", []),
            "warning_lines": output.count("WARNING:"), "error_lines": output.count("ERROR:")}


with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    results = list(pool.map(run, jobs))
summary = {"source_script_sha256": expected, "routes": results}
(OUT / f"native-runs-{args.band or 'all'}.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
passed = sum(x["exit"] == 0 and x["valid"] and len(x["release_cycles"]) == 2
             and not x["errors"] and not x["discrepancies"] for x in results)
print(f"BANK B1 native routes: {passed}/{len(results)} passed")
for row in results:
    print(row["job"], row["exit"], row["release_cycles"], row["reviews"],
          len(row["errors"]), len(row["discrepancies"]))
raise SystemExit(0 if passed == len(results) else 1)
