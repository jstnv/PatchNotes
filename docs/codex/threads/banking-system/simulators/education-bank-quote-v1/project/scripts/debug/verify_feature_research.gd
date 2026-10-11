extends SceneTree
var failures := 0

func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures += 1
func snap(run: RunState) -> Array:
	return [run.get_cash_cents(),run.get_completed_run_cycles(),run.get_available_redraws(),run.get_owned_feature_ids(),run._feature_research.duplicate(true),run.get_studio_finance_snapshot(),run.random_streams.snapshot()]
func _run() -> void:
	check(FeatureResearch.payment(150000,2,0,0)=={"down_cents":75000,"nominal_cents":37500,"due_cents":37500},"Two-action baseline arithmetic")
	check(FeatureResearch.payment(150000,2,1,10).due_cents==33750,"Later familiarity discounts only later installment")
	check(FeatureResearch.payment(150000,1,0,10).due_cents==67500,"Live one-action arithmetic")
	for base in [0,1,3,101,150001,9223372036854775807]:
		var total: int = FeatureResearch.payment(base,3,0,0).down_cents
		for step in 3: total += int(FeatureResearch.payment(base,3,step,0).due_cents)
		check(total==base,"Odd-cent/overflow-safe exact total: "+str(base))
	var run := RunState.new()
	run.initialize_cash_cents(0)
	check(run.create_studio_with_traits("Research",&"action",[]),"Create funded Studio")
	var free_before := run.get_completed_run_cycles()
	var starter: StringName
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		if not run.owns_feature(StringName(entry.id)):
			starter = StringName(entry.id)
			break
	check(run.purchase_starter_feature(starter) and run.owns_feature(starter) and run.get_completed_run_cycles()==free_before,"Initial Primitive purchase stays instant")
	run.finalize_starter_selection()
	var quote := run.get_feature_research_quote(&"colored_text")
	var before := snap(run)
	check(not run.admit_feature_research({"feature_id":42}) and not run.research_feature({"feature_id":42}) and snap(run)==before,"Malformed quotes reject without mutation")
	check(run.admit_feature_research(quote),"Admit unlocked Feature")
	check(run.get_cash_cents()==before[0]-quote.down_cents and run.get_completed_run_cycles()==before[1] and not run.owns_feature(&"colored_text"),"Admission pays down without cycles or ownership")
	before = snap(run)
	check(not run.admit_feature_research(quote) and snap(run)==before,"Duplicate stale admission is atomic")
	var second: StringName
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		var id := StringName(entry.id)
		if not run.owns_feature(id): second = id; break
	check(run.admit_feature_research(run.get_feature_research_quote(second)),"Distinct Primitive reserve queues behind head")
	before = snap(run)
	check(not run.research_feature(run.get_feature_research_quote(second)) and snap(run)==before,"FIFO blocks non-head without mutation")
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(run)
	check(not payload.is_empty(),"Admission checkpoint captures: "+adapter.error)
	var restored := adapter.hydrate(payload)
	check(restored != null and snap(restored)==snap(run),"Admission hydration preserves every cent and queue")
	quote = run.get_feature_research_quote(&"colored_text")
	before = snap(run)
	check(run.research_feature(quote),"Research commits")
	check(run.owns_feature(&"colored_text") and run.get_completed_run_cycles()==before[1]+1 and run.get_cash_cents()==before[0]-quote.due_cents,"Completion grants once and advances normal productive cycle")
	before = snap(run)
	check(not run.research_feature(quote) and snap(run)==before,"Duplicate Research cannot advance next queue entry")
	payload = adapter.capture(run)
	check(not payload.is_empty(),"Completion checkpoint captures: "+adapter.error)
	restored = adapter.hydrate(payload)
	check(restored != null and snap(restored)==snap(run),"Completion hydration preserves payments/ownership")
	quote = run.get_feature_research_quote(second)
	check(run.research_feature(quote),"Second queued Feature completes across monthly rent boundary")
	check(run.get_studio_finance_snapshot().last_cycle==2,"Native monthly finance processed")
	print("Feature research: %d failures" % failures)
	quit(failures)
