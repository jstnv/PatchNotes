"""Verify the user-requested Studio refill and owned-price presentation changes."""
from pathlib import Path
import concurrent.futures
import hashlib
import json
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs/studio-entry-polish-v1"
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
ALLOWED = {
    "scripts/gameplay.gd", "scripts/ui/feature_store.gd", "scripts/ui/tutorial_overlay.gd",
    "scripts/debug/verify_beta_finalization_and_launch.gd",
    "scripts/debug/verify_balanced_primitive_contract.gd", "scripts/debug/verify_feature_store.gd",
    "scripts/debug/verify_main_menu_history.gd",
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / ".gdignore").touch()
    profile = Path(tempfile.mkdtemp(prefix="patchnotes-studio-polish-"))
    env = os.environ.copy()
    for key, name in [("APPDATA", "roaming"), ("LOCALAPPDATA", "local")]:
        (profile / name).mkdir()
        env[key] = str(profile / name)

    def run(name, arguments):
        command = [str(GODOT), "--headless", "--path", str(ROOT), *arguments]
        completed = subprocess.run(command, env=env, capture_output=True, text=True,
                                   encoding="utf-8", errors="replace", timeout=180)
        output = completed.stdout + "\n" + completed.stderr
        (OUT / (name + ".log")).write_text(output, encoding="utf-8")
        result = {"name": name, "command": command, "exit": completed.returncode,
                  "errors": [s for s in ["SCRIPT ERROR", "Parse Error", "Assertion failed", "FAIL:"] if s in output]}
        print(json.dumps(result), flush=True)
        return result

    results = [run("import", ["--editor", "--import"])]
    if results[0]["exit"] == 0 and not results[0]["errors"]:
        paths = sorted((ROOT / "scripts/debug").glob("verify_*.gd"))
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
            results += list(pool.map(lambda p: run(p.stem, ["--script", "res://scripts/debug/" + p.name]), paths))
    baseline = json.loads((ROOT / "design-logs/feature-store-staged-v1/baseline_source_manifest.json").read_text())
    changed = [p for p, value in baseline["files"].items()
               if not (ROOT / p).exists() or hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != value]
    unrelated = sorted(set(changed) - ALLOWED)
    diff = subprocess.run(["git", "diff", "--check"], cwd=ROOT, capture_output=True, text=True)
    (OUT / "diff-check.log").write_text(diff.stdout + diff.stderr, encoding="utf-8")
    passed = all(r["exit"] == 0 and not r["errors"] for r in results) and not unrelated and diff.returncode == 0
    report = {"passed": passed, "source_head": baseline["head"], "profile": str(profile), "results": results,
              "suites": len(results) - 1, "changed_since_frozen_simulation": changed,
              "unexpected_changed_files": unrelated, "diff_check_exit": diff.returncode}
    (OUT / "verification_v1.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k != "results"}), flush=True)
    raise SystemExit(0 if passed else 1)


if __name__ == "__main__":
    main()
