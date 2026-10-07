"""Thread-owned, read-only Feature Store immediate-purchase screen."""
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
JOBS = [(specialty, policy, arm, timing)
        for specialty, policy in (("action", "ordinary"), ("action", "synergy"), ("adventure", "ordinary"))
        for arm, timing in [("none", "immediate")] + [(a, t) for a in ("sub_areas", "background") for t in ("immediate", "buffer", "stronger_settled")]]
SEED = 1104


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_manifest():
    names = subprocess.check_output(["git", "ls-files", "--", "scripts", "scenes", "data", "analysis"], cwd=PROJECT).decode().splitlines()
    files = [PROJECT / name for name in names if (PROJECT / name).is_file()]
    return {str(p.relative_to(PROJECT)).replace("\\", "/"): digest(p) for p in sorted(files)}


def run(job):
    specialty, policy, arm, timing = job
    stem = f"route_early_{specialty}_{policy}_{arm}_{timing}_{SEED}_0"
    profile = Path(tempfile.mkdtemp(prefix="pn-feature-store-sim-v1-"))
    env = os.environ.copy()
    for key in ("APPDATA", "LOCALAPPDATA"):
        directory = profile / key
        directory.mkdir()
        env[key] = str(directory)
    command = [str(GODOT), "--headless", "--path", str(PROJECT), "--script", str(DRIVER), "--",
               "--band=early", f"--specialty={specialty}", f"--policy={policy}",
               f"--store={arm}", f"--timing={timing}", f"--seed={SEED}", "--campaign=0"]
    started = time.monotonic()
    try:
        result = subprocess.run(command, env=env, capture_output=True, timeout=180)
        output = result.stdout + result.stderr
        code = result.returncode
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or b"") + (exc.stderr or b"")
        code = "timeout"
    (OUT / f"{stem}.log").write_bytes(output)
    path = OUT / f"{stem}.json"
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
    plan = {"branch": branch, "head": head, "seed": SEED, "jobs": JOBS,
            "startup": "Current MainMenu background 1, no secondary previews, genuine $5700 receipt",
            "driver_sha256": digest(DRIVER), "source_before": before,
            "scope": "Four-release timing pilot: immediate, chain plus $1500 short-horizon buffer, and stronger-release actual-settlement deferral. Candidate shadows in process only; zero candidate play fee.", "reserve": "Full quoted parent plus child chain + $1000 for next two rent bills + $500 observed-production allowance; check after each completed release and contracts. No free wait or forecast cash.", "stronger": "Latest release Review >=6.0 and >= first release Review +1.0, with >0 actual settled sales for that latest release; check after contracts. No purchase if this criterion never occurs."}
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
