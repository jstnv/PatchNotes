extends SceneTree

## Bounded CPU diagnostic. Uses a private Studio, never a player's save.
var samples: Array = []

func timed(operation: Callable, repeats: int = 3) -> float:
	var elapsed: Array[int] = []
	for _repeat in repeats:
		var start := Time.get_ticks_usec()
		operation.call()
		elapsed.append(Time.get_ticks_usec()-start)
	elapsed.sort()
	return elapsed[elapsed.size()/2]/1000.0

func quotes(run: RunState) -> void:
	for id: StringName in run._feature_definitions:
		run.get_feature_research_quote(id)

func _initialize() -> void:
	await process_frame
	var run := RunState.new()
	run.initialize_cash(0)
	assert(run.create_studio_with_traits("Private latency diagnostic", &"action", [&"family_funding"]))
	run.finalize_starter_selection()
	# Synthetic accounting funds keep this CPU fixture solvent; not balance evidence.
	assert(run.add_cash(100000))
	var store := FeatureStore.new()
	root.add_child(store)
	store.setup(run)
	var adapter := StudioCheckpoint.new()
	for target in [0,12,24,48,96]:
		while run.get_completed_run_cycles()<target:
			if not run.complete_productive_action(): break
		if run.get_completed_run_cycles()!=target: break
		var row := {"cycle":target,"actions":run._studio_finance.actions.size(),
			"ledger_validate_ms":timed(func(): return StudioFinanceLedger._is_valid(run._studio_finance)),
			"store_quotes_ms":timed(func(): quotes(run)),
			"store_refresh_ms":timed(store._refresh),
			"checkpoint_capture_ms":timed(func(): return adapter.capture(run),1)}
		samples.append(row)
		print(JSON.stringify(row))
	var path := OS.get_environment("PN_LATENCY_OUTPUT")
	if not path.is_empty(): FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(samples,"\t"))
	store.free()
	run = null
	quit()
