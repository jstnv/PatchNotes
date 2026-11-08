## Persistent Phase 3A foundation and active Generation I/II Skill Tree ledger.
extends RefCounted

const VERSION := 3
const ORIGIN := "proprietary-creation-v1"
const STARTER_ORIGIN := "proprietary-creation-v2"
const COST_CENTS := 10000
const CAPACITY := 25
const LEGACY_CAPACITY := 20
const FOUNDATIONS: Array[StringName] = [&"text",&"4_color_palette",&"keyboard_and_mouse",&"8_bit_sound"]
const BRANCHES: Array[StringName] = [&"graphics",&"sound",&"technology",&"design"]
const NODES := {
	&"graphics": [{"id":&"raster_workflow","name":"Raster Workflow","threshold":5,"cost_cents":12500},{"id":&"graphics_qa_pipeline","name":"Graphics QA Pipeline","threshold":10,"cost_cents":25000}],
	&"sound": [{"id":&"audio_workflow","name":"Audio Workflow","threshold":5,"cost_cents":12500},{"id":&"sound_qa_pipeline","name":"Sound QA Pipeline","threshold":10,"cost_cents":25000}],
	&"technology": [{"id":&"input_toolchain","name":"Input Toolchain","threshold":6,"cost_cents":12500},{"id":&"technology_regression_harness","name":"Technology Regression Harness","threshold":12,"cost_cents":25000}],
	&"design": [{"id":&"text_production_kit","name":"Text Production Kit","threshold":3,"cost_cents":12500},{"id":&"design_rule_validator","name":"Design Rule Validator","threshold":6,"cost_cents":25000}],
}

static func empty() -> Dictionary:
	return {"version":VERSION,"next_serial":1,"engines":{}}

static func is_creation_origin(origin: Variant) -> bool:
	return origin is String and origin in [ORIGIN,STARTER_ORIGIN]

static func next_id(state: Dictionary,owner: StringName) -> StringName:
	return StringName("%s:proprietary:%d"%[owner,int(state.get("next_serial",0))])

static func record(id: StringName,owner: StringName,label: String,cycle: int) -> Dictionary:
	return {"owner_id":owner,"name":label,"created_cycle":cycle,
		"receipt_id":StringName("engine-create:%s"%id),
		"technology_nodes":FOUNDATIONS.duplicate(),"challenge_progress":{},
		"branch_progress":{},"scope_milestones":[] as Array[StringName],
		"pass_efficiency":{},"pass_effectiveness":{},"bug_prevention":{}}

static func migrate(state: Dictionary,features: Dictionary = {}) -> Dictionary:
	var upgraded:=state.duplicate(true)
	if upgraded.get("version") in [1,2]:
		# Hydration validates the saved terms first. Upgrade only the engine's
		# future capacity; its ledger, supply and frozen projects stay intact.
		for id: StringName in upgraded.engines:
			if features.get("engines",{}).has(id):features.engines[id].capacity=CAPACITY+5*milestone(upgraded.engines[id])
		upgraded.version=VERSION
	return upgraded

static func valid_frozen_capacity(frozen: int,current: int) -> bool:
	# Earlier projects may retain the old20-Scope base or an earlier milestone.
	return frozen in [20,25,30,35] and frozen<=current

static func generation(row: Dictionary,branch: StringName) -> int:
	return int(row.get("branch_progress",{}).get(branch,0))

static func node(branch: StringName,level: int) -> Dictionary:
	if branch not in BRANCHES or level<1 or level>2:return {}
	return NODES[branch][level-1]

static func milestone(row: Dictionary) -> int:
	var level:=2
	for branch: StringName in BRANCHES:level=mini(level,generation(row,branch))
	return level

static func credit(row: Dictionary,contributions: Array) -> void:
	for entry: Dictionary in contributions:
		var branch: StringName=StringName(entry.get("stat",&""))
		if branch not in BRANCHES or generation(row,branch)>=2 or int(entry.get("value",0))<=0:continue
		row.challenge_progress[branch]=mini(int(node(branch,generation(row,branch)+1).threshold),int(row.challenge_progress.get(branch,0))+int(entry.get("value",0)))

static func purchase(row: Dictionary,branch: StringName) -> bool:
	var current:=generation(row,branch)
	var next:=node(branch,current+1)
	if next.is_empty() or int(row.challenge_progress.get(branch,0))<int(next.threshold):return false
	row.technology_nodes.append(next.id)
	row.branch_progress[branch]=current+1
	row.challenge_progress.erase(branch)
	if current==0:row.pass_efficiency[branch]=20
	elif branch in [&"graphics",&"sound"]:row.pass_effectiveness[branch]=10
	else:row.bug_prevention[branch]=15
	for reached in range(1,milestone(row)+1):
		var key:=StringName("generation_%d"%reached)
		if key not in row.scope_milestones:row.scope_milestones.append(key)
	return true

static func _valid_row(row: Dictionary,capacity: int,ledger: Dictionary,engine: StringName,cycle: int,base: int = CAPACITY) -> bool:
	var expected:=record(engine,row.owner_id,row.name,row.created_cycle)
	for branch: StringName in BRANCHES:
		var level:=generation(row,branch)
		if level<0 or level>2:return false
		if level>0:
			expected.branch_progress[branch]=level
			expected.pass_efficiency[branch]=20
			for g in range(1,level+1):
				var definition: Dictionary=node(branch,g)
				expected.technology_nodes.append(definition.id)
				var receipt_id:=StringName("engine-skill:%s:%s"%[engine,definition.id])
				var receipts: Array=ledger.get("actions",[]).filter(func(action: Dictionary) -> bool:return action.source_id==receipt_id)
				if receipts.size()!=1 or receipts[0].kind!=&"other_expense" or receipts[0].direct_delta!=-int(definition.cost_cents) or receipts[0].productive or receipts[0].cycle<row.created_cycle or receipts[0].cycle>cycle:return false
			if level==2:
				if branch in [&"graphics",&"sound"]:expected.pass_effectiveness[branch]=10
				else:expected.bug_prevention[branch]=15
		if level<2:
			var progress: Variant=row.challenge_progress.get(branch,0)
			if not progress is int or progress<0 or progress>int(node(branch,level+1).threshold):return false
			if progress>0:expected.challenge_progress[branch]=progress
	for g in range(1,milestone(row)+1):expected.scope_milestones.append(StringName("generation_%d"%g))
	for key: String in ["branch_progress","challenge_progress","pass_efficiency","pass_effectiveness","bug_prevention","scope_milestones"]:
		if row.get(key)!=expected[key]:return false
	if row.technology_nodes.size()!=expected.technology_nodes.size():return false
	for id: StringName in expected.technology_nodes:
		if id not in row.technology_nodes:return false
	return capacity==base+5*milestone(row)

static func valid(state: Dictionary,owner: StringName,entitlements: Dictionary,features: Dictionary,ledger: Dictionary,cycle: int) -> bool:
	if state.size()!=3 or state.get("version") not in [1,2,VERSION] or not state.get("next_serial") is int or not state.get("engines") is Dictionary:return false
	if state.next_serial<1 or state.next_serial>129 or state.engines.size()!=state.next_serial-1:return false
	for serial: int in range(1,state.next_serial):
		var id:=StringName("%s:proprietary:%d"%[owner,serial])
		if not state.engines.has(id) or not features.get("engines",{}).has(id) or id not in entitlements.get("owned_ids",[]):return false
		var row: Variant=state.engines[id]
		if not row is Dictionary or row.size()!=11 or row.get("owner_id")!=owner or row.get("receipt_id")!=StringName("engine-create:%s"%id):return false
		if not row.get("name") is String or row.name.is_empty() or row.name!=row.name.strip_edges() or row.name.length()>80:return false
		if not row.get("created_cycle") is int or row.created_cycle<0 or row.created_cycle>cycle:return false
		var feature: Dictionary=features.engines[id]
		if feature.get("kind")!=&"proprietary" or not is_creation_origin(feature.get("origin")) or feature.get("name")!=row.name:return false
		if feature.origin==ORIGIN and feature.get("initial")!=[]:return false
		if feature.origin==STARTER_ORIGIN and (state.version!=VERSION or feature.get("initial")!=FOUNDATIONS):return false
		if state.version==1:
			if row.technology_nodes!=FOUNDATIONS or row.challenge_progress!={} or row.branch_progress!={} or row.scope_milestones!=[] or row.pass_efficiency!={} or row.pass_effectiveness!={} or row.bug_prevention!={} or feature.capacity!=LEGACY_CAPACITY:return false
		elif not _valid_row(row,feature.capacity,ledger,id,cycle,LEGACY_CAPACITY if state.version==2 else CAPACITY):return false
		var receipts: Array=ledger.get("actions",[]).filter(func(action: Dictionary) -> bool:return action.source_id==row.receipt_id)
		if receipts.size()!=1 or receipts[0].kind!=&"other_expense" or receipts[0].cycle!=row.created_cycle or receipts[0].direct_delta!=-COST_CENTS or receipts[0].productive:return false
	for id: StringName in features.get("engines",{}):
		if is_creation_origin(features.engines[id].origin) and not state.engines.has(id):return false
	return true
