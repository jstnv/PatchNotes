"""Prepare two legal one-command post-launch settlement continuations."""
import json
from pathlib import Path

root = Path(__file__).resolve().parent
source = root / "three-hand-decision-run-v1" / "cases"
cases = []
for cohort in ("control-90210", "graduate-90210"):
    case_id = f"{cohort}-borrow-2500-12"
    folder = source / case_id
    result = json.loads((folder / "result.json").read_text(encoding="utf-8"))
    assert result["status"] == "completed" and result["final_release_count"] == 2 and result["final_run_cycle"] == 27
    checkpoint = json.loads((folder / "studio_checkpoint.json").read_text(encoding="utf-8"))
    cases.append({
        "schema_version": "1", "case_id": case_id,
        "initial": {"checkpoint": checkpoint},
        "max_commands": 1, "target_release_count": 3, "telemetry": True,
        "policy": {"config": {"genre": "action", "theme": "fantasy",
            "name_prefix": "Control" if cohort.startswith("control") else "Graduate",
            "selection": "visible_order", "hands": {"design": 3, "alpha": 3, "beta": 3}}},
    })
data = {"schema_version": "1", "policy": {
    "script": "res://scripts/simulation/finite_fixture_policy.gd",
    "id": "bank-three-hand-next-boundary", "version": "1"}, "cases": cases}
path = root / "three-hand-settlement-v1.json"
if path.exists():
    raise SystemExit(f"Refusing to replace {path}")
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
print(path)
