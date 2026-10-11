"""Serial maintained-harness checks for the approved Cult twenty-Fan trial."""
from pathlib import Path
import hashlib
import importlib.util
import json

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
EVIDENCE = ROOT / "docs/codex/findings/card-presentation-v2"
spec = importlib.util.spec_from_file_location("cult20_harness", EVIDENCE / "run.py")
harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)

checks = []
for name in [None, "cult_following", "studio_traits", "fanbase_checkpoint", "studio_checkpoint", "primitive_awareness", "campaign_stress_cult", "campaign_live_parity"]:
    label = "cult20-" + ("import" if name is None else name.replace("_", "-")) + "-01"
    script = None if name is None else "verify_" + name + ".gd"
    try:
        harness.run(label, script)
    finally:
        folder = EVIDENCE / label
        record = {"suite": script or "editor import", "evidence": folder.relative_to(ROOT).as_posix()}
        command = folder / "command.json"
        if command.exists():
            record.update(json.loads(command.read_text()))
        else:
            record["incomplete"] = True
        for suffix in ["before", "after"]:
            manifest = folder / ("source-" + suffix + ".json")
            if manifest.exists():
                record["source_manifest_" + suffix + "_sha256"] = hashlib.sha256(manifest.read_bytes()).hexdigest()
        log = folder / "output.log"
        if log.exists():
            record["result_lines"] = [line for line in log.read_text(errors="replace").splitlines() if any(term in line.lower() for term in ["checks=", "failures", "verification:", "parity", "boundaries", "stress"]) and len(line) < 1500]
        fit = folder / "fit.json"
        if fit.exists():
            record["fit_sha256"] = hashlib.sha256(fit.read_bytes()).hexdigest()
            record["fit"] = json.loads(fit.read_text())
        checks.append(record)
        (HERE / "focused-checks.json").write_text(json.dumps(checks, indent=2) + "\n", encoding="utf-8")
