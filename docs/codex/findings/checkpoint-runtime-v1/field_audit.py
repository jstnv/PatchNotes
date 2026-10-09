"""Fail when a RunState member is missing from the checkpoint ownership map."""
from pathlib import Path
import hashlib, json, re
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
source = ROOT / "patch-notes/scripts/run_state.gd"
adapter = ROOT / "patch-notes/scripts/persistence/studio_checkpoint.gd"
text = source.read_text(encoding="utf-8")
fields = set(re.findall(r"^var (\w+)", text, re.M))
direct = set(re.findall(r'"(_\w+)"', re.search(r"const FIELDS := (\[.*?\])", adapter.read_text(encoding="utf-8")).group(1)))
special = {"_publisher_offers": "first-unlock trial offer DTOs", "_primitive_contract": "completed Contract DTO", "_sidestreet_entitlements": "ordered entitlement DTOs",
           "_first_game_tutorial": "tutorial DTO", "random_streams": "nine seed/state pairs",
           "next_project_serial": "next project identity serial"}
derived = {"_feature_definitions": "compatible packaged catalog", "_feature_offers": "compatible packaged catalog"}
transient = {key: "quiescent transaction guard" for key in
             ("_feature_purchase_in_progress", "_productive_cycle_in_progress", "_committing_cycle_cash",
              "_publishing_cycle", "_pending_contract_completion")}
transient.update(checkpoint_mutations_allowed="coordinator access gate", studio_departure_guard="coordinator callable; never serialized", checkpoint_before_mutation="pending-save flush before the next action")
covered = direct | special.keys() | derived.keys() | transient.keys()
assert fields == covered, dict(missing=sorted(fields-covered), obsolete=sorted(covered-fields))
record = dict(source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(), fields=len(fields),
              direct=sorted(direct), typed_adapters=special, rebuilt=derived, transient=transient)
(HERE / "field-map.json").write_text(json.dumps(record, indent=2))
print(f"All {len(fields)} RunState members classified")
