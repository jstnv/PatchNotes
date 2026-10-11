class_name FeatureResearch
extends RefCounted

## Pure integer-cent arithmetic. Live admissions always use one action.
static func payment(base: int, actions: int, completed: int, discount: int) -> Dictionary:
	if base < 0 or actions < 1 or actions > 1024 or completed < 0 or completed >= actions or discount < 0 or discount > 50: return {}
	var down := base / 2 + base % 2
	var remainder := base - down
	var nominal := remainder / actions
	if completed == actions - 1: nominal += remainder % actions
	var percent := 100 - discount
	var due := (nominal / 100) * percent + ((nominal % 100) * percent) / 100
	return {"down_cents":down,"nominal_cents":nominal,"due_cents":due}

static func schema() -> Dictionary:
	var entry := CheckpointSchema.fields("base_cents actions admitted_cycle")
	entry.merge(CheckpointSchema.fields("id feature_id", "id"))
	entry.payments = CheckpointSchema.array_of(CheckpointSchema.fields("cycle nominal_cents discount_percent paid_cents saving_cents window"))
	return entry

static func validate(entries: Array, owned: Dictionary, ledger: Dictionary, cycle: int, run_id: StringName) -> bool:
	var seen := {}
	var waiting := false
	var sources := {}
	var previous_completion := -1
	var previous_admission := -1
	for entry: Dictionary in entries:
		if seen.has(entry.feature_id) or entry.id != StringName("%s:research:%s" % [run_id,entry.feature_id]): return false
		seen[entry.feature_id] = true
		if entry.admitted_cycle < previous_admission: return false
		previous_admission = entry.admitted_cycle
		if entry.actions < 1 or entry.payments.size() > entry.actions or entry.admitted_cycle > cycle: return false
		var arithmetic := payment(entry.base_cents,entry.actions,0,0)
		if arithmetic.is_empty(): return false
		var completed: bool = entry.payments.size() == entry.actions
		if owned.has(entry.feature_id) != completed or (waiting and not entry.payments.is_empty()): return false
		waiting = waiting or not completed
		var expected := [{"source_id":StringName(str(entry.id)+":admit"),"cycle":entry.admitted_cycle,"direct_delta":-arithmetic.down_cents,"productive":false}]
		var last: int = entry.admitted_cycle
		for index in entry.payments.size():
			var paid: Dictionary = entry.payments[index]
			arithmetic = payment(entry.base_cents,entry.actions,index,paid.discount_percent)
			if arithmetic.is_empty() or paid.discount_percent % 10 != 0 or paid.nominal_cents != arithmetic.nominal_cents or paid.saving_cents > mini(10000,int(arithmetic.due_cents)) or (paid.saving_cents > 0 and index != entry.actions-1) or paid.paid_cents != arithmetic.due_cents-paid.saving_cents or paid.cycle <= last or paid.cycle > cycle: return false
			if paid.cycle <= previous_completion: return false
			last = paid.cycle
			expected.append({"source_id":StringName("%s:%d" % [entry.id,index]),"cycle":paid.cycle,"direct_delta":-paid.paid_cents,"productive":true})
		if completed: previous_completion = last
		for action: Dictionary in expected:
			sources[action.source_id] = true
			var matches := 0
			for actual: Dictionary in ledger.actions:
				if actual.source_id != action.source_id: continue
				if actual.kind != &"store": return false
				for key in action:
					if actual[key] != action[key]: return false
				matches += 1
			if matches != 1: return false
	for action: Dictionary in ledger.actions:
		if str(action.source_id).begins_with(str(run_id)+":research:") and not sources.has(action.source_id): return false
	return true
