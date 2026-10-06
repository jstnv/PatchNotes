"""Verify and render the five-category Feature Store without changing run rules."""
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import tutorial_task17_verify_v1 as v

v.OUT = v.ROOT / "design-logs/feature-bloom-map-v1"
v.OUT.mkdir(exist_ok=True)
(v.OUT / ".gdignore").touch()

def classify_output(output):
    lines = output.decode("utf-8", errors="replace").splitlines()
    known_environment = [line for line in lines if "ERROR: Failed to read the root certificate store." in line]
    errors = [line for line in lines if any(marker in line for marker in
              ["SCRIPT ERROR", "Parse Error", "ERROR:", "FAIL:", "Assertion failed"])
              and line not in known_environment]
    return errors, known_environment

if "--render" in sys.argv:
    profile = Path(tempfile.mkdtemp(prefix="pn-bloom-map-render-"))
    env = os.environ.copy()
    for key in ["APPDATA", "LOCALAPPDATA"]:
        directory = profile / key
        directory.mkdir()
        env[key] = str(directory)
    command = [v.GODOT, "--path", str(v.ROOT), "--rendering-method", "gl_compatibility",
               "--position", "-5000,-5000", "--script",
               "res://scripts/debug/verify_feature_store_radial.gd", "--", "--capture"]
    process = subprocess.run(command, env=env, capture_output=True, timeout=120)
    output = process.stdout + process.stderr
    (v.OUT / "render.log").write_bytes(output)
    errors, environment_diagnostics = classify_output(output)
    result = dict(command=command, exit=process.returncode, profile=str(profile),
                  errors=errors, environment_diagnostics=environment_diagnostics)
    (v.OUT / "render.command.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result), flush=True)
    assert process.returncode == 0 and not result["errors"]
else:
    results = [v.run("editor-import", v.ROOT, ["--editor", "--import"])]
    assert results[0]["exit"] == 0 and not results[0]["errors"]
    for name in ["feature_store_radial", "feature_store_navigation", "feature_store",
                 "feature_store_cycle_purchase", "first_studio_feature_economy",
                 "menu_navigation", "gameplay_hud_overlay", "studio_finances"]:
        results.append(v.run("verify_" + name, v.ROOT,
                             ["--script", "res://scripts/debug/verify_" + name + ".gd"]))
    for result in results:
        output = (v.OUT / (result["name"] + ".log")).read_bytes()
        result["errors"], result["environment_diagnostics"] = classify_output(output)
    diff = subprocess.run(["git", "diff", "--check"], cwd=v.ROOT, capture_output=True)
    (v.OUT / "diff-check.log").write_bytes(diff.stdout + diff.stderr)
    source = {str(p.relative_to(v.ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
              for folder in ["scripts", "scenes", "data"] for p in (v.ROOT / folder).rglob("*")
              if p.is_file()}
    (v.OUT / "source-final.json").write_text(json.dumps({
        "head": v.git("rev-parse", "HEAD").decode().strip(), "files": source}, indent=2))
    (v.OUT / "final-status.txt").write_bytes(v.git("status", "--short"))
    (v.OUT / "final-diff.patch").write_bytes(v.git("diff"))
    report = {"results": results, "diff_check": diff.returncode,
              "passed": all(r["exit"] == 0 and not r["errors"] for r in results) and diff.returncode == 0}
    (v.OUT / "verification.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("BLOOM MAP PASS", report["passed"], flush=True)
    assert report["passed"]
