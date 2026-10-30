from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[6]
HERE=Path(__file__).resolve().parent
P=ROOT/'docs/codex/threads/contracts/simulators/publisher-relationships-foundation-v1/project'
def edit(name,old,new):
    p=P/name;s=p.read_text(encoding='utf-8');assert s.count(old)==1,(name,old[:80],s.count(old));p.write_text(s.replace(old,new),encoding='utf-8')
# Freeze exact predecessor validation before extending the live schema.
old=P/'scripts/contracts/pre_relationships';old.mkdir(exist_ok=False)
s=(P/'scripts/persistence/checkpoint_schema.gd').read_text(encoding='utf-8').replace('class_name CheckpointSchema\n','')
(old/'schema.gd').write_text(s,encoding='utf-8')
s=(P/'scripts/persistence/studio_checkpoint.gd').read_text(encoding='utf-8').replace('class_name StudioCheckpoint\n','').replace('extends RefCounted','extends RefCounted\n\nconst CheckpointSchema := preload("res://scripts/contracts/pre_relationships/schema.gd")',1)
(old/'studio.gd').write_text(s,encoding='utf-8')
edit('scripts/run_state.gd','var _promotion_consumed: Dictionary = {}','''var _promotion_consumed: Dictionary = {}
const RelationshipLedger := preload("res://scripts/contracts/publisher_relationships.gd")
const RelationshipRules := preload("res://scripts/contracts/publisher_relationship_rules.gd")
var _publisher_relationships: Dictionary = {}
var _relationship_commit_in_progress := false
signal publisher_relationships_changed

func get_publisher_relationships() -> Dictionary:
	var resolver := func(request: Dictionary) -> Dictionary: return RelationshipRules.resolve(self,request)
	return RelationshipLedger.reconstruct(_publisher_relationships,_bank_run_id,_completed_run_cycles,resolver)

## Internal producer seam; P1 has no enabled producer. No UI-provided amounts.
func commit_publisher_relationship_event(request: Dictionary) -> bool:
	if _relationship_commit_in_progress or _productive_cycle_in_progress or _publishing_cycle or _committing_cycle_cash or _feature_purchase_in_progress or get_active_contract() != null: return false
	_relationship_commit_in_progress = true
	if not can_mutate_checkpoint():
		_relationship_commit_in_progress = false
		return false
	var resolver := func(source: Dictionary) -> Dictionary: return RelationshipRules.resolve(self,source)
	var planned := RelationshipLedger.plan(_publisher_relationships,_bank_run_id,request,_completed_run_cycles,resolver)
	if planned.is_empty():
		_relationship_commit_in_progress = false
		return false
	if planned.changed:
		_publisher_relationships = planned.ledger
		publisher_relationships_changed.emit()
	_relationship_commit_in_progress = false
	return true
''')
edit('scripts/run_state.gd','\t_employees = EmployeeRoster.create(_bank_run_id)','\t_employees = EmployeeRoster.create(_bank_run_id)\n\t_publisher_relationships = RelationshipLedger.create(_bank_run_id)')
edit('scripts/simulation/run_factory.gd','\trun._employees = EmployeeRoster.create(StringName(stable))','\trun._employees = EmployeeRoster.create(StringName(stable))\n\trun._publisher_relationships = RunState.RelationshipLedger.create(StringName(stable))')
edit('scripts/persistence/checkpoint_schema.gd','\trun.promotion_awards = map_of("id","uint")','\trun.publisher_relationships = preload("res://scripts/contracts/publisher_relationships.gd").schema()\n\trun.promotion_awards = map_of("id","uint")')
edit('scripts/persistence/studio_checkpoint.gd','const RULES := PRE_MARKET_RULES + "-market1"','const PRE_RELATIONSHIP_RULES := PRE_MARKET_RULES + "-market1"\nconst RULES := PRE_RELATIONSHIP_RULES + "-relationships1"\nconst RelationshipPrevious := preload("res://scripts/contracts/pre_relationships/studio.gd")')
edit('scripts/persistence/studio_checkpoint.gd','"_promotion_awards","_promotion_consumed"]','"_promotion_awards","_promotion_consumed","_publisher_relationships"]')
edit('scripts/persistence/studio_checkpoint.gd','rules in [RULES, PRE_MARKET_RULES','rules in [RULES, PRE_RELATIONSHIP_RULES, PRE_MARKET_RULES')
edit('scripts/persistence/studio_checkpoint.gd','func _validate(payload: Dictionary, active_rival: bool) -> String:\n','''func _validate(payload: Dictionary, active_rival: bool) -> String:
	if payload.get("content_revision", "") == RelationshipPrevious.new().revision():
		var upgraded := upgrade_relationship_predecessor(payload,active_rival)
		return error if upgraded.is_empty() else _validate(upgraded,active_rival)
''')
edit('scripts/persistence/studio_checkpoint.gd','\tvar r: Dictionary = value.run\n\tvar roster_version','\tvar r: Dictionary = value.run\n\tvar resolver := func(request: Dictionary) -> Dictionary: return RunState.RelationshipRules.resolve(r,request)\n\tif RunState.RelationshipLedger.reconstruct(r.publisher_relationships,r.bank_run_id,r.completed_run_cycles,resolver).is_empty(): return "Invalid publisher relationship provenance"\n\tvar roster_version')
edit('scripts/persistence/studio_checkpoint.gd','func hydrate(payload: Dictionary, active_rival: bool = false) -> RunState:\n','''func hydrate(payload: Dictionary, active_rival: bool = false) -> RunState:
	if payload.get("content_revision", "") == RelationshipPrevious.new().revision():
		var upgraded := upgrade_relationship_predecessor(payload,active_rival)
		return null if upgraded.is_empty() else hydrate(upgraded,active_rival)
''')
edit('scripts/persistence/studio_checkpoint.gd','func _decode_payload(payload: Dictionary, active_rival: bool = false) -> Dictionary:', '''func upgrade_relationship_predecessor(payload: Dictionary, active_rival: bool = false) -> Dictionary:
	error = ""
	var previous := RelationshipPrevious.new()
	if payload.get("content_revision") != previous.revision():
		error = "Unknown relationship predecessor"
		return {}
	error = previous.validate_active_rival(payload) if active_rival else previous.validate(payload)
	if not error.is_empty(): return {}
	var native: Dictionary = previous._decode_payload(payload,active_rival)
	if native.is_empty(): error = previous.error; return {}
	native.run.publisher_relationships = RunState.RelationshipLedger.create(native.run.bank_run_id)
	native.content_revision = revision()
	var codec := CheckpointCodec.new()
	var upgraded: Variant = codec.encode(native,CheckpointSchema.root(true,active_rival))
	error = codec.error
	return upgraded if error.is_empty() and upgraded is Dictionary else {}

func _decode_payload(payload: Dictionary, active_rival: bool = false) -> Dictionary:''')
edit('scripts/market/market_save_migration_trial.gd','\tnative.content_revision = StudioCheckpoint.new().revision()','\tnative.run.publisher_relationships = RunState.RelationshipLedger.create(native.run.bank_run_id)\n\tnative.content_revision = StudioCheckpoint.new().revision()')
# Coordinator still funnels old player/world validation through StudioCheckpoint.
# No simulation-envelope source bypass or broad world allow-list is added here.
p=P/'scripts/persistence/checkpoint_coordinator.gd';s=p.read_text(encoding='utf-8');s=s.replace('&"finance_changed",&"employees_changed"]','&"finance_changed",&"employees_changed",&"publisher_relationships_changed"]');p.write_text(s,encoding='utf-8')
print('Private P1 integration complete; no enabled reward rules')
