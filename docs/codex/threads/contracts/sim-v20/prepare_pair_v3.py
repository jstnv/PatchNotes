"""Materialize the predeclared Sports/1104 pair from its untouched Studio envelope."""

import hashlib
import json
from pathlib import Path


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "prefix-v3-run-01" / "cases" / "sports-1104-prefix" / "studio_checkpoint.json"
TARGET = HERE / "pair-v3.json"
envelope_bytes = SOURCE.read_bytes()
envelope = json.loads(envelope_bytes)
assert envelope["kind"] == "campaign_studio"
run = envelope["studio_payload"]["run"]
assert run["ironclad_completion_committed"] is True
assert len(run["released_games"]) == 2
assert len(run["sidestreet_entitlements"]) >= 1
assert any(entry["value"]["publisher_id"] in ("crown_quill", "neon_circuit") for entry in run["publisher_offers"])
development_first = {"genre": "sports", "theme": "fantasy", "name_prefix": "SideStreet Screen", "selection": "features_first", "hands": {"design": 3, "alpha": 4, "beta": 4}}
development_later = {"genre": "sports", "theme": "fantasy", "name_prefix": "SideStreet Screen", "selection": "features_first", "hands": {"design": 5, "alpha": 6, "beta": 6}}
pair_id = "sidestreet-sports-1104-v3"
cases = []
for arm in ("take", "skip"):
    cases.append({
        "schema_version": "1",
        "case_id": f"sports-1104-{arm}",
        "initial": {"checkpoint": envelope},
        "max_commands": 140,
        "target_release_count": 3,
        "telemetry": True,
        "study": {"pair_id": pair_id, "arm": arm, "prefix_case": "sports-1104-prefix", "prefix_checkpoint_sha256": hashlib.sha256(envelope_bytes).hexdigest()},
        "policy": {"config": {"mode": "pair", "arm": arm, "development_first": development_first, "development_later": development_later}},
    })
config = {"schema_version": "1", "policy": {"script": "sidestreet_policy_v3.gd", "id": "contracts-sidestreet-matched-v1", "version": "3"}, "cases": cases}
assert not TARGET.exists(), f"Refusing to overwrite {TARGET}"
TARGET.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"output": str(TARGET), "checkpoint_sha256": hashlib.sha256(envelope_bytes).hexdigest(), "case_ids": [item["case_id"] for item in cases]}))
