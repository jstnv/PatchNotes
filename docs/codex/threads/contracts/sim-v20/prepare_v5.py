"""Create the two fixed neighboring-seed SideStreet prefixes."""

import json
from pathlib import Path


HERE = Path(__file__).resolve().parent
TARGET = HERE / "prefix-v5.json"
development_first = {"genre": "sports", "theme": "fantasy", "name_prefix": "SideStreet Screen", "selection": "features_first", "hands": {"design": 3, "alpha": 4, "beta": 4}}
development_later = {"genre": "sports", "theme": "fantasy", "name_prefix": "SideStreet Screen", "selection": "features_first", "hands": {"design": 5, "alpha": 6, "beta": 6}}
cases = []
for seed in ("1105", "1106"):
    cases.append({
        "schema_version": "1",
        "case_id": f"sports-{seed}-prefix-v5",
        "initial": {"recipe": {"schema_version": 1, "studio_id": f"contracts-sidestreet-v5-{seed}", "studio_name": f"SideStreet v5 {seed}", "specialty": "sports", "traits": [], "seed": seed}},
        "max_commands": 180,
        "target_release_count": 2,
        "telemetry": True,
        "policy": {"config": {"mode": "prefix", "starter_ids": ["sprites", "general_combat", "levels"], "development_first": development_first, "development_later": development_later}},
    })
config = {"schema_version": "1", "policy": {"script": "sidestreet_policy_v4.gd", "id": "contracts-sidestreet-neighbor-prefix", "version": "5"}, "cases": cases}
assert not TARGET.exists(), f"Refusing to overwrite {TARGET}"
TARGET.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"output": str(TARGET), "cases": [c["case_id"] for c in cases]}))
