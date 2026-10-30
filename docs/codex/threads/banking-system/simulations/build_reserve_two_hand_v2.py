"""Create a fresh fixed two-hand configuration from the v1 legal forks."""
import json
from pathlib import Path

root = Path(__file__).resolve().parent
source = json.loads((root / "reserve-pairs-v1.json").read_text(encoding="utf-8"))
source["policy"]["id"] = "bank-reserve-two-hand"
source["policy"]["version"] = "2"
for case in source["cases"]:
    assert case["policy"]["config"]["hands"] == {"design": 1, "alpha": 1, "beta": 1}
    case["policy"]["config"]["hands"] = {"design": 2, "alpha": 2, "beta": 2}
    case["study"]["pair_id"] += "-two-hand"
path = root / "reserve-two-hand-v2.json"
if path.exists():
    raise SystemExit(f"Refusing to replace {path}")
path.write_text(json.dumps(source, indent=2) + "\n", encoding="utf-8")
print(path)
