"""Thread-owned, read-only delayed Sub-Areas purchase check."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import gzip
import hashlib
import json
import os
import subprocess
import tempfile
import time

REPO = Path(__file__).resolve().parents[5]
PROJECT = REPO / "patch-notes"
OUT = Path(__file__).resolve().parent
DRIVER = OUT / "driver.gd"
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
JOBS = [("strategy", policy, "sub_areas", "fixed_after_game4", "none", seed)
        for seed in (1104, 4417) for policy in ("ordinary", "synergy")]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_manifest():
    names = subprocess.check_output(["git", "ls-files", "--", "scripts", "scenes", "data", "analysis"], cwd=PROJECT).decode().splitlines()
    files = [PROJECT / name for name in names if (PROJECT / name).is_file()]
    return {str(p.relative_to(PROJECT)).replace("\\", "/"): digest(p) for p in sorted(files)}


def run(job):
    specialty, policy, arm, timing, parent, seed = job
    stem = f"route_early_{specialty}_{policy}_{arm}_{timing}_{parent}_{seed}_0"
    profile = Path(tempfile.mkdtemp(prefix="pn-feature-store-sim-v7-"))
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA"):
        directory = profile / key
        directory.mkdir()
        env[key] = str(directory)
    command = [str(GODOT), "--headless", "--path", str(PROJECT), "--script", str(DRIVER), "--",
               "--band=early", f"--specialty={specialty}", f"--policy={policy}",
               f"--store={arm}", f"--timing={timing}", f"--parent={parent}", f"--seed={seed}", "--campaign=0"]
    path = OUT / f"{stem}.json"
    if path.exists():
        path.unlink()
    started = time.monotonic()
    try:
        result = subprocess.run(command, env=env, capture_output=True, timeout=180)
        output = result.stdout + result.stderr
        code = result.returncode
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or b"") + (exc.stderr or b"")
        code = "timeout"
    (OUT / f"{stem}.log").write_bytes(output)
    data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else None
    trace_sha256 = digest(path) if data else None
    if data:
        (OUT / f"{stem}.json.gz").write_bytes(gzip.compress(path.read_bytes(), compresslevel=6, mtime=0))
        path.unlink()
    errors = [line for line in output.decode(errors="replace").splitlines()
              if "SCRIPT ERROR" in line or "FAIL:" in line or
              ("ERROR:" in line and "Failed to read the root certificate store." not in line)]
    return {"job": job, "command": command, "exit": code, "elapsed_seconds": round(time.monotonic()-started, 3),
            "profile": str(profile), "trace_sha256": trace_sha256,
            "valid": data.get("valid") if data else None, "releases": len(data.get("releases", [])) if data else None,
            "stop": data.get("stop") if data else None, "discrepancies": len(data.get("discrepancies", [])) if data else None,
            "errors": errors}


def main():
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO).decode().strip()
    branch = subprocess.check_output(["git", "branch", "--show-current"], cwd=REPO).decode().strip()
    before = source_manifest()
    plan = {"branch": branch, "head": head, "seeds": [1104, 4417], "jobs": JOBS,
            "startup": "Current MainMenu background 1, no secondary previews, genuine $5700 receipt",
            "driver_sha256": digest(DRIVER), "source_before": before,
            "scope": "Four native Strategy routes, fixed purchase opportunity after Game 4, independent Sub-Areas at trial $1700 and zero later-card play fee. Paired to the four previously captured Strategy no-buy and fixed-after-Game-3 routes in sim-v6. Process-local shadow only.",
            "evaluation": "Does one-release deferral avoid the financial block seen in one fixed-after-Game-3 buyer while still yielding actual Game-5 supply/draw/play? Compare with unchanged same-seed/policy native controls at matched calendar and Game-5 launch. Fixed purchase timing is a probe, not an availability rule. This is not the broad Task 2 timing comparison."}
    (OUT / "predeclaration.json").write_text(json.dumps(plan, indent=2), encoding="utf-8")
    with ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(run, JOBS))
        for item in results:
            print(item["job"], item["exit"], item["valid"], item["releases"], item["stop"], flush=True)
    after = source_manifest()
    report = {"results": results, "head_before": head,
              "head_after": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO).decode().strip(),
              "source_changes": sorted(k for k in before.keys() | after.keys() if before.get(k) != after.get(k)),
              "driver_after_sha256": digest(DRIVER)}
    (OUT / "run-report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("DONE", len(results), "valid", sum(bool(r["valid"]) for r in results), "source_changes", report["source_changes"], flush=True)


if __name__ == "__main__":
    main()
