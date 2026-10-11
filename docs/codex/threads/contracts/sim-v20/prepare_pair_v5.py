"""Make the first eligible predeclared v5 neighboring-seed pair."""

import hashlib
import json
from pathlib import Path


HERE = Path(__file__).resolve().parent
PREFIX = HERE / "prefix-v5-run-01" / "cases"
TARGET = HERE / "pair-v5.json"

miss = json.loads((PREFIX / "sports-1105-prefix-v5" / "studio_checkpoint.json").read_text(encoding="utf-8"))
assert not miss["studio_payload"]["run"]["publisher_offers"], "Earlier seed unexpectedly eligible"
source = PREFIX / "sports-1106-prefix-v5" / "studio_checkpoint.json"
raw = source.read_bytes()
envelope = json.loads(raw)
assert envelope["kind"] == "campaign_studio"
run = envelope["studio_payload"]["run"]
assert envelope["source_identity"] == "13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f"
assert run["ironclad_completion_committed"] is True and len(run["released_games"]) == 2
assert len(run["sidestreet_entitlements"]) >= 1
assert any(x["value"]["publisher_id"] in ("crown_quill", "neon_circuit") for x in run["publisher_offers"])

first = {"genre": "sports", "theme": "fantasy", "name_prefix": "SideStreet Screen", "selection": "features_first", "hands": {"design": 3, "alpha": 4, "beta": 4}}
later = {"genre": "sports", "theme": "fantasy", "name_prefix": "SideStreet Screen", "selection": "features_first", "hands": {"design": 5, "alpha": 6, "beta": 6}}
digest = hashlib.sha256(raw).hexdigest()
cases = []
for arm in ("take", "skip"):
    cases.append({
        "schema_version": "1",
        "case_id": f"sports-1106-{arm}-v5",
        "initial": {"checkpoint": envelope},
        "max_commands": 220,
        "target_release_count": 4,
        "telemetry": True,
        "study": {"pair_id": "sidestreet-sports-1106-v5", "arm": arm, "prefix_case": "sports-1106-prefix-v5", "prefix_checkpoint_sha256": digest},
        "policy": {"config": {"mode": "pair", "arm": arm, "development_first": first, "development_later": later}},
    })
config = {"schema_version": "1", "policy": {"script": "sidestreet_policy_v4.gd", "id": "contracts-sidestreet-neighbor-pair", "version": "5"}, "cases": cases}
assert not TARGET.exists(), f"Refusing to overwrite {TARGET}"
TARGET.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"output": str(TARGET), "checkpoint_sha256": digest, "cases": [c["case_id"] for c in cases]}))
