"""Reproducible current-scene paired driver; uses isolated Godot profiles."""
from pathlib import Path
import concurrent.futures, json, os, subprocess, sys, tempfile, time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs/feature-store-staged-v1"
GODOT = r"C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe"

def run(spec):
    spec = dict(spec)
    tag = spec.pop("tag", "discovery")
    policy, arm = spec.get("policy", "ordinary"), spec.get("arm", "none")
    name = f"{policy}_{arm}_{tag}" + (f"_{spec['start']}" if spec.get("start",0) else "")
    profile = Path(tempfile.mkdtemp(prefix="patchnotes-stage2-"))
    (profile / "roaming").mkdir(); (profile / "local").mkdir()
    env = os.environ.copy(); env.update(APPDATA=str(profile / "roaming"), LOCALAPPDATA=str(profile / "local"))
    defaults = {"policy": "ordinary", "arm": "none", "count": 4, "two-game-count": 110, "long-run": 1, "max-game": 3}
    defaults.update(spec); defaults["tag"] = tag
    cmd = [GODOT, "--headless", "--path", str(ROOT), "--script", "res://analysis/feature_store_stage2_v1.gd", "--"]
    cmd += [f"--{key}={value}" for key, value in defaults.items()]
    start = time.time()
    try:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True, encoding="utf8", timeout=900)
        text = result.stdout + result.stderr
        (OUT / f"stage2_{name}.log").write_text(text, encoding="utf8")
        errors = [line for line in text.splitlines() if "SCRIPT ERROR" in line or "Parse Error" in line]
        record = {"spec": defaults, "command": cmd, "returncode": result.returncode, "errors": errors, "seconds": round(time.time()-start, 2)}
    except subprocess.TimeoutExpired:
        record = {"spec": defaults, "command": cmd, "timeout": True, "seconds": round(time.time()-start, 2)}
    print(name, record.get("returncode", "TIMEOUT"), len(record.get("errors", [])), record["seconds"], flush=True)
    return record

def main():
    manifest = Path(sys.argv[1])
    specs = json.loads(manifest.read_text())
    workers=int(sys.argv[2]) if len(sys.argv)>2 else 2
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        results = list(pool.map(run, specs))
    path = OUT / (manifest.stem + "_results.json")
    path.write_text(json.dumps(results, indent=2), encoding="utf8")
    if any(r.get("returncode") != 0 or r.get("errors") for r in results): raise SystemExit(1)

if __name__ == "__main__": main()
