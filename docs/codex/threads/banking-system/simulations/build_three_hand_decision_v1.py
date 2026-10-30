"""Create the predeclared three-hand Banking comparison from exact v4 forks."""
import json
from pathlib import Path

root = Path(__file__).resolve().parent
data = json.loads((root / "larger-offer-pairs-v1.json").read_text(encoding="utf-8"))
assert len(data["cases"]) == 6
data["policy"]["id"] = "bank-three-hand-decision"
data["policy"]["version"] = "1"
for case in data["cases"]:
    config = case["policy"]["config"]
    assert config["hands"] == {"design": 4, "alpha": 4, "beta": 4}
    config["hands"] = {"design": 3, "alpha": 3, "beta": 3}
    case["study"]["pair_id"] += "-three-hand"
path = root / "three-hand-decision-v1.json"
if path.exists():
    raise SystemExit(f"Refusing to replace {path}")
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
print(path)
