extends SceneTree

const Campaign := preload("res://scripts/simulation/campaign_session.gd")
const Bootstrap := preload("res://scripts/debug/campaign_replay_cli.gd")
var failures := 0
var checks := 0

func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func fixture() -> RunState:
	var run := RunState.new()
	run.initialize_cash_cents(2000000)
	# Existing card IDs only; never written into the production ledger.
	run._feature_offers[&"recorded_sounds"] = run._feature_offers[&"recorded_sounds"].duplicate(true)
	run._feature_offers[&"recorded_sounds"].purchase_parents = ["8_bit_sound", "text"]
	return run

func snapshot(run: RunState) -> Array:
	return [run.get_cash_cents(),run.get_completed_run_cycles(),run.get_available_redraws(),run._owned_features.duplicate(true),run._feature_research.duplicate(true),run.get_studio_finance_snapshot(),run.random_streams.snapshot(),run._familiarity.duplicate(true),run._credited_projects.duplicate(true)]

func _run() -> void:
	if not OS.get_environment("PN_PARENT_RESTART").is_empty():
		_restart_probe(OS.get_environment("PN_PARENT_RESTART"))
		quit(failures)
		return
	var run := fixture()
	var pristine := RunState.new()
	pristine.initialize_cash_cents(2000000)
	for id in [&"colored_text", &"save_files", &"difficulty_levels"]:
		check(run.get_feature_store_offer(id) == pristine.get_feature_store_offer(id), "Unchanged quote " + str(id))
		check(run.get_feature_acquisition_quote(id) == pristine.get_feature_acquisition_quote(id), "Unchanged path " + str(id))
	run._owned_features.erase(&"8_bit_sound")
	run._owned_features.erase(&"text")
	var q := run.get_feature_store_offer(&"recorded_sounds")
	check(not q.unlocked and q.missing_parents == [&"8_bit_sound", &"text"], "Both missing parents are explicit")
	var before := snapshot(run)
	check(not run.purchase_feature(&"recorded_sounds") and snapshot(run) == before, "Neither-parent rejection is atomic")
	run._owned_features[&"8_bit_sound"] = true
	q = run.get_feature_store_offer(&"recorded_sounds")
	check(not q.unlocked and q.missing_parents == [&"text"], "One parent still locked")
	run._feature_research.append({"feature_id":&"text","actions":1,"payments":[]})
	check(not run.get_feature_store_offer(&"recorded_sounds").unlocked, "Queued parent does not unlock")
	run._feature_research.clear()
	run._owned_features[&"text"] = true
	check(run.get_feature_store_offer(&"recorded_sounds").unlocked, "Both permanently owned unlock")
	check(run.get_feature_store_offer(&"recorded_sounds").discount_percent == 0, "Selection and quote inspection grant no credit")
	var project := ProjectState.new(30)
	check(not run.record_resolved_feature(project, &"text", &"contract"), "Contract grants no credit")
	run._publishing_cycle = true
	check(not run.record_resolved_feature(project, &"text", &"design"), "Contract publishing guard grants no credit")
	run._publishing_cycle = false
	check(run.record_resolved_feature(project, &"text", &"design"), "First parent committed credit")
	check(run.get_feature_store_offer(&"recorded_sounds").discount_percent == 10, "One combined credit is ten percent")
	check(not run.record_resolved_feature(project, &"text", &"design"), "Repeated parent in same project cannot double credit")
	check(run.record_resolved_feature(project, &"8_bit_sound", &"design"), "Other parent in same project credits independently")
	check(run.get_feature_store_offer(&"recorded_sounds").discount_percent == 20, "Two parents in one project aggregate")
	for parent in [&"text", &"8_bit_sound", &"8_bit_sound"]: run.record_resolved_feature(ProjectState.new(30),parent,&"design")
	q = run.get_feature_store_offer(&"recorded_sounds")
	check(q.discount_percent == 50 and q.parent_contributions[0].credits == 3 and q.parent_contributions[1].credits == 2, "Two plus three credits share fifty percent cap")
	run.record_resolved_feature(ProjectState.new(30), &"text", &"design")
	check(run.get_feature_store_offer(&"recorded_sounds").discount_percent == 50, "Six combined credits remain capped")
	q = run.get_feature_research_quote(&"recorded_sounds")
	check(q.down_cents == (q.base_cents + 1) / 2, "Familiarity does not discount deposit")
	check(run.admit_feature_research(q), "Two-parent admission commits")
	check(not run.owns_feature(&"recorded_sounds") and run.get_completed_run_cycles() == 0, "Admission grants neither ownership nor a cycle")
	before = snapshot(run)
	check(not run.admit_feature_research(q) and snapshot(run) == before, "Duplicate admission is atomic")
	check(run.research_feature(run.get_feature_research_quote(&"recorded_sounds")), "Research completes")
	check(run.owns_feature(&"recorded_sounds") and run.get_completed_run_cycles() == 1, "Ownership only on completion")
	var mid := fixture()
	q = mid.get_feature_research_quote(&"recorded_sounds")
	mid.admit_feature_research(q)
	var old := mid.get_feature_research_quote(&"recorded_sounds")
	mid.record_resolved_feature(ProjectState.new(30), &"text", &"design")
	q = mid.get_feature_research_quote(&"recorded_sounds")
	check(q.down_cents == old.down_cents and q.paid_cents == old.paid_cents and q.due_cents < old.due_cents, "Mid-research credit changes only unpaid installment")
	before = snapshot(mid)
	check(not mid.research_feature(old) and snapshot(mid) == before, "Stale installment rejects atomically")
	for cash in [q.down_cents - 1, q.down_cents]:
		var poor := fixture()
		poor._cash_cents = cash
		var admitted := poor.admit_feature_research(poor.get_feature_research_quote(&"recorded_sounds"))
		before = snapshot(poor)
		check(admitted == (cash == q.down_cents), "Deposit affordability boundary " + str(cash))
		check(not poor.research_feature(poor.get_feature_research_quote(&"recorded_sounds")) and snapshot(poor) == before, "Unaffordable Research preserves all state")
	var odd := fixture()
	odd._feature_offers[&"recorded_sounds"].base_price_cents = 101
	odd.record_resolved_feature(ProjectState.new(30), &"text", &"design")
	check(odd.get_feature_store_offer(&"recorded_sounds").price_cents == 90, "Odd-cent quote rounds only after percentage")
	q = odd.get_feature_research_quote(&"recorded_sounds")
	check(q.down_cents == 51 and q.due_cents == 45, "Odd-cent deposit and installment exact")
	_graph_checks()
	_checkpoint_parity()
	await _ui_checks()
	print("Feature parents: %d checks, %d failures" % [checks, failures])
	quit(failures)

func _fresh_session() -> RefCounted:
	var session := Bootstrap.create_fresh_session({"schema_version":1,"studio_id":"parents_fixture","studio_name":"Parents","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase"))
	session.run.finalize_starter_selection()
	_apply_fixture(session.run)
	return session

func _apply_fixture(run: RunState) -> void:
	run._feature_offers[&"recorded_sounds"] = run._feature_offers[&"recorded_sounds"].duplicate(true)
	run._feature_offers[&"recorded_sounds"].purchase_parents = ["8_bit_sound", "text"]

func _checkpoint_parity() -> void:
	var session := _fresh_session()
	var codec := StudioCheckpoint.new()
	var native := codec.hydrate(codec.capture(session.run))
	check(native != null, "Real fresh Studio checkpoint hydrates")
	if native == null: return
	_apply_fixture(native)
	for kind in [&"admit_research", &"research"]:
		var quote := native.get_feature_research_quote(&"recorded_sounds")
		var native_ok := native.admit_feature_research(quote) if kind == &"admit_research" else native.research_feature(quote)
		var result: Dictionary = session.execute(session.command(kind,{"quote":session.run.get_feature_research_quote(&"recorded_sounds")}))
		check(native_ok and result.ok and snapshot(native) == snapshot(session.run), "Native/headless all-state equality " + str(kind))
		var payload := codec.capture(native)
		var restored := codec.hydrate(payload)
		check(not payload.is_empty() and restored != null and snapshot(restored) == snapshot(native), "Checkpoint exact state " + str(kind) + ": " + codec.error)

func _restart_probe(mode: String) -> void:
	var codec := StudioCheckpoint.new()
	var run: RunState
	if mode == "initial": run = _fresh_session().run
	else:
		run = codec.hydrate(JSON.parse_string(FileAccess.get_file_as_string("user://parents.json")))
		check(run != null, "Cold hydration " + mode + ": " + codec.error)
		if run == null: return
		check(JSON.stringify(codec.capture(run)) == FileAccess.get_file_as_string("user://parents.json"), "Fresh process reproduces exact checkpoint")
		_apply_fixture(run) # Same test-only definition in each process; no identity edits.
	if mode == "admit": check(run.admit_feature_research(run.get_feature_research_quote(&"recorded_sounds")), "Cold admission")
	elif mode == "complete": check(run.research_feature(run.get_feature_research_quote(&"recorded_sounds")), "Cold completion")
	elif mode == "owned": check(run.owns_feature(&"recorded_sounds") and run.get_feature_research_queue().is_empty(), "Cold ownership and payment history retained")
	var payload := codec.capture(run)
	check(not payload.is_empty(), "Capture " + mode + ": " + codec.error)
	FileAccess.open("user://parents.json",FileAccess.WRITE).store_string(JSON.stringify(payload))
	print("Parent restart %s: %d checks, %d failures" % [mode,checks,failures])

func _graph_checks() -> void:
	var run := fixture()
	run._cash_cents = 0
	run.create_studio_with_traits("Parent path", &"action", [])
	run.finalize_starter_selection()
	# Diamond: the two named parents share one grandparent.
	var definitions := {&"root":{}, &"left":{}, &"right":{}, &"child":{}}
	var offers := {&"left":{"purchase_parent":"root"}, &"right":{"purchase_parent":"root"}, &"child":{"purchase_parents":["left","right"]}}
	var graph := FeatureStoreCatalog.graph(definitions, offers)
	check(not graph.has("error") and FeatureStoreCatalog.ordered_ancestors([&"child"],graph.parents).order == [&"root",&"left",&"right",&"child"], "DAG visits shared ancestor once in dependency order")
	for invalid in [{"purchase_parents":["text","text"]},{"purchase_parents":["text","missing"]},{"purchase_parents":["recorded_sounds","text"]},{"purchase_parents":[]},{"purchase_parents":"text"},{"purchase_parents":[42]},{"purchase_parents":["8_bit_sound","text"],"gameplay_features_required":3},{"purchase_parents":["text","8_bit_sound"],"purchase_parent":"8_bit_sound"}]:
		var bad := fixture()
		bad._feature_offers[&"recorded_sounds"].erase("purchase_parent")
		bad._feature_offers[&"recorded_sounds"].merge(invalid, true)
		var before := snapshot(bad)
		check(bad.get_feature_store_offer(&"recorded_sounds").is_empty() and not bad.get_feature_acquisition_quote(&"recorded_sounds").available and not bad.purchase_feature(&"recorded_sounds") and snapshot(bad) == before, "Invalid graph fails closed: " + str(invalid))
	offers[&"root"] = {"purchase_parent":"child"}
	check(FeatureStoreCatalog.graph(definitions, offers).has("error"), "Indirect cycle rejected before quote")
	var path := run.get_feature_acquisition_quote(&"recorded_sounds")
	check(path.steps.size() == 3 and path.steps[0].id == &"8_bit_sound" and path.steps[1].id == &"text", "Live acquisition includes both named parents")
	var starters := FeatureStoreCatalog.starting_features()
	var entries := FeatureStoreCatalog.entries()
	check(FeatureStoreCatalog.validate_entries(starters,entries).is_empty(), "Current catalog remains valid")
	entries[0].purchase_parents = [str(entries[0].id)]
	check(not FeatureStoreCatalog.validate_entries(starters,entries).is_empty(), "Startup catalog graph rejects invalid reference")

func _ui_checks() -> void:
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		var run: RunState = _fresh_session().run
		run._owned_features.erase(&"8_bit_sound");run._owned_features.erase(&"text")
		var store := FeatureStore.new()
		root.add_child(store)
		store.setup(run)
		store.open_store()
		await process_frame
		await process_frame
		await process_frame
		store._select_node(&"recorded_sounds")
		await create_timer(0.65).timeout
		check(store._nodes.size() == run._feature_definitions.size() and store._nodes[&"recorded_sounds"].has_node("AndGate"), "One node and visible AND badge at " + str(dimensions))
		store._buy.pressed.emit()
		# Expansion reframes the camera, opens the menu, then staggers links.
		# Wait for the real readiness condition before exercising keyboard input.
		for attempt in range(150):
			if store._map.parent_links.get_child_count()==2 and store._map.parent_links.get_children().all(func(button):return button.focus_mode==Control.FOCUS_ALL):break
			await create_timer(0.02).timeout
		check(store._map.parent_links.get_child_count() == 2 and store._buy.tooltip_text.contains("shared 50% cap"), "Missing-parent chooser offers both targets; credits remain on hover")
		check(store._map.popup.visible and store.get_global_rect().encloses(store._map.popup.get_global_rect()), "Visible detail fits viewport")
		var link: Button = store._map.parent_links.get_child(1)
		link.grab_focus()
		await process_frame
		check(link.has_focus(), "Parent navigation accepts keyboard focus")
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.pressed = true
		root.push_input(event, true)
		await process_frame
		event = InputEventKey.new()
		event.keycode = KEY_ENTER
		root.push_input(event, true)
		await create_timer(0.65).timeout
		check(store._selected == &"text", "Keyboard/controller action navigates cross-lane parent; selected=" + str(store._selected))
		store._select_node(&"recorded_sounds")
		await create_timer(0.65).timeout
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://two-parent-%d.png" % dimensions.x)
		run._owned_features[&"8_bit_sound"]=true;run._owned_features[&"text"]=true
		store._refresh()
		store._purchase()
		check(is_instance_valid(store._admission_dialog) and store._admission_dialog.dialog_text.contains("irreversible"), "Actual admission confirmation retained")
		store._admission_dialog.hide()
		store.queue_free()
		await process_frame
