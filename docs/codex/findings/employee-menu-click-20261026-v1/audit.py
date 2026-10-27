"""Pin the scoped employee navigation patch and retained test receipts."""
from pathlib import Path
import hashlib
import json
import subprocess

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
paths = [
    "patch-notes/scripts/phases/studio_phase.gd",
    "patch-notes/scripts/ui/employee_panel.gd",
    "patch-notes/scripts/market/rival_world_checkpoint.gd",
    "patch-notes/scripts/debug/verify_employee_click.gd",
    "patch-notes/scripts/debug/verify_employee_unlock.gd",
    "patch-notes/scripts/debug/employee_test_actions.gd",
    "docs/codex/logs/2026-10-26-employee-menu-click-v1.md",
]
receipts = {}
for label in ["baseline", "click-repro", "click-green", "click-final", "click-native", "click-native-v2", "unlock", "employee-ui", "cold-restore"]:
    path = OUT / (label + "-run.json")
    receipt = json.loads(path.read_text(encoding="utf-8"))
    if label not in ["click-repro", "click-native"]:
        assert receipt["exit"] == 0 and not receipt["errors"], label
    else:
        assert receipt["exit"] != 0, label
    receipts[label] = {"receipt_sha256": sha(path), "exit": receipt["exit"],
                       "errors": receipt["errors"], "command": receipt["command"]}
captures = {p.name: sha(p) for p in sorted((OUT / "captures-final").glob("*.png"))}
assert len(captures) == 4
pair = json.loads((OUT / "before-pair.json").read_text(encoding="utf-8"))
assert pair["rival_world"]["source_identity"] == "71f86b840b0af8d425f8166caf169b853229e6c6ff3f4f32db22ecd7712ad019"
save_hashes = {}
import os
for generation in [183, 184]:
    name = f"checkpoint.{generation}.json"
    original = Path(os.environ["APPDATA"]) / "Godot/app_userdata/Patch Notes/saves/studio" / name
    assert sha(original) == sha(OUT / name), name
    save_hashes[name] = sha(original)
result = {
    "date": "2026-10-26", "branch": subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip(),
    "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
    "source_sha256": {p: sha(ROOT / p) for p in paths}, "receipts": receipts,
    "before_pair_sha256": sha(OUT / "before-pair.json"), "captures_sha256": captures,
    "inspected_player_generations_unchanged": save_hashes,
    "fixture_funding_dollars": 20000, "ordinary_solvency_proven": False,
    "user_exact_session_reproduced": False,
    "exported": False, "committed": False, "pushed": False,
}
(OUT / "audit.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print("PASS: source pins, nine receipts, four native captures, unchanged inspected save generations")
