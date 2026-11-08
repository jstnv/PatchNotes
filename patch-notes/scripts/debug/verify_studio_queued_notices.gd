extends SceneTree

var checks := 0
var failures := 0

class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		_writer = TCPServer.new()
		return _writer.listen(49187, "127.0.0.1") == OK

func check(value: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if value else "FAIL: ") + label)
	if not value: failures += 1

func wait_for(test: Callable, seconds := 20.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not test.call() and Time.get_ticks_msec() < deadline: await process_frame
	return test.call()

func _initialize() -> void: verify.call_deferred()

func verify() -> void:
	root.size = Vector2i(1152,648)
	root.content_scale_size = root.size
	node_added.connect(func(node: Node):
		if node is CheckpointCoordinator: node.store = PrivateStore.new("user://queue-test",node._validate_payload))
	var game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._onboarding.answer(true)
	var pair: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_NOTICE_FIXTURE")))
	game.checkpoints.rival_catalog = root.get_node("CardDatabase").get_development_catalog()
	var payload: Dictionary = pair.player.duplicate(true)
	payload["rival_world"] = pair.world
	var publication: Dictionary = game.checkpoints.store.save(payload)
	check(publication.status == &"saved", "Private fixture save succeeds: " + str(publication))
	if publication.status != &"saved": quit(1); return
	game._continue_checkpoint()
	check(await wait_for(func(): return game._active_phase is StudioPhase and not game._transition_in_progress), "Continue reaches Studio")
	var controller = game.focused_guidance
	var studio: StudioPhase = game._active_phase
	check(not controller._safe(), "Pending awards prevent Studio notifications")
	# This fixture has an outstanding ceremony. Suppress that independent
	# lifecycle only in this isolated presentation test, not in game source.
	game.checkpoints.debug_session = true
	if game._awards_waiting: game._clear_annual_awards()
	controller.preferences._studios.clear()
	controller.notices._pending.clear()
	controller._suspend_notice()
	controller.automatic_enabled = false
	controller._enqueue_notice({"id":"a","kind":"progress","title":"First","body":"First message"})
	controller._enqueue_notice({"id":"b","kind":"publisher","title":"Publisher unlocked","body":"Neon Circuit"})
	var producer_count: int = controller.notices.count()
	game.get_node("%GameplayHUD").challenge_notices.enqueue_all([{"title":"Course progress","message":"1 / 4 hands"}])
	game.get_node("%GameplayHUD").notice_requested.emit({"key":"queue-fixture","title":"Studio tip","body":"Tip body"})
	check(controller.notices.count() == producer_count + 2, "Progress and contextual guidance enter the same queue")
	var queue_before: Dictionary = game.run_state.get_studio_notice_state()
	var checkpoint_adapter := StudioCheckpoint.new()
	var rollback_checkpoint: Dictionary = checkpoint_adapter.capture(game.run_state)
	check(not rollback_checkpoint.is_empty(), "Real queued progress and publisher notices are checkpointed")
	var future_queue: Dictionary = queue_before.duplicate(true)
	var removed: Dictionary = future_queue.pending.pop_front()
	if not removed.id.is_empty(): future_queue.dismissed.append(removed.id)
	check(game.run_state.set_studio_notice_state(future_queue), "Future notice dismissal is accepted")
	var rolled_back: RunState = checkpoint_adapter.hydrate(rollback_checkpoint)
	check(rolled_back != null and rolled_back.get_studio_notice_state() == queue_before, "Rollback preserves real event queue without future dismissals")
	check(game.run_state.set_studio_notice_state(queue_before), "Restore isolated test runtime queue")
	print("DEBUG queue=",controller.notices.count()," studio=",controller._queue_studio," run=",controller._run," safe=",controller._safe()," phase=",game._active_phase," dashboard=",studio.get_node("%Dashboard").is_visible_in_tree()," selected=",studio._hub.selected," requested=",studio._hub.requested," depth=",studio._hub_motion.depth())
	print("DEBUG paused=",paused," transition=",game._transition_in_progress," loading=",game._loading_checkpoint," startup=",game._startup_panel," guided=",game.guided_tutorial," awards=",game.annual_awards_blocking()," dialog=",game._checkpoint_dialog_visible()," hub_busy=",studio._hub_motion.busy," hub_transition=",studio._hub.transitioning," returning=",studio._returning_destination)
	var shown: bool = await wait_for(func(): return controller._presenting_notice, 8.0)
	check(shown, "First queued notice appears on the isolated Studio hub")
	if not shown: quit(1); return
	await create_timer(0.5).timeout
	if DisplayServer.get_name() != "headless" and not OS.get_environment("PN_NOTICE_CAPTURE").is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("PN_NOTICE_CAPTURE").path_join("studio-queue-1152.png"))
	var initial_count: int = controller.notices.count()
	check(initial_count >= 2 and controller.view.title.text == "First", "Only the first notice is presented")
	var hud = game.get_node("%GameplayHUD")
	check(hud.notice_button.visible and not hud.notice_button.disabled and hud.notice_list.item_count == initial_count - 1, "Notification button lists only unopened items")
	print("DEBUG_LAYOUT notice=",hud.notice_button.get_global_rect()," sales=",hud.sales_hud.get_global_rect()," sales_visible=",hud.sales_hud.is_visible_in_tree())
	check(hud.notice_button.get_global_rect().end.x <= hud.sales_hud.get_global_rect().position.x + 1, "Notification button sits to the left of the sales graph")
	hud.notice_button.pressed.emit()
	check(hud.notice_list.visible, "The notification button opens the unread list")
	hud.notice_list.hide()
	hud.notice_list.id_pressed.emit(1)
	check(await wait_for(func(): return controller._presenting_notice and controller.view.title.text == "Publisher unlocked"), "Selecting an unread item opens that notice")
	hud.notice_list.id_pressed.emit(1)
	check(await wait_for(func(): return controller._presenting_notice and controller.view.title.text == "First"), "Selecting another item preserves the rest")
	var rect: Rect2 = controller.view.panel.get_global_rect()
	check(rect.position.y >= game.get_node("%GameplayHUD").scoreboard.get_global_rect().end.y and rect.size.y < 360 and root.get_visible_rect().encloses(rect), "Notice fits below the bar graph without excessive height")
	studio._show_group(&"market")
	check(await wait_for(func(): return not controller._presenting_notice), "Opening a Studio group hides and preserves the notice")
	check(controller.notices.count() == initial_count, "Navigating away does not dismiss an unread notice")
	studio._hub.close_group()
	check(await wait_for(func(): return controller._presenting_notice), "Returning to isolated Studio shows the same notice")
	controller.view.dismiss.pressed.emit()
	check(await wait_for(func(): return controller._presenting_notice and controller.view.title.text == "Publisher unlocked"), "Dismissing a notice advances to the publisher")
	await create_timer(0.5).timeout
	rect = controller.view.panel.get_global_rect()
	check(rect.size.y < 360 and root.get_visible_rect().encloses(rect), "Publisher notice sizes to its content")
	controller.view.dismiss.pressed.emit()
	check(await wait_for(func(): return controller.notices.count() == initial_count - 2), "Dismissing publisher advances exactly one item")
	controller._enqueue_notice({"id":"publisher:action-test","kind":"publisher","title":"Publisher unlocked","body":"Neon Circuit"})
	controller._select_notice(controller.notices.count() - 1)
	check(await wait_for(func(): return controller._presenting_notice and controller.notices.peek().get("id", "") == "publisher:action-test"), "Publisher action notice appears")
	controller.view.primary.pressed.emit()
	check(await wait_for(func(): return is_instance_valid(studio._publisher_browser) and studio._publisher_browser.is_visible_in_tree()), "Show me opens the publisher browser")
	await controller.return_to_studio_root()
	var adapter := StudioCheckpoint.new()
	var before_tour: Dictionary = adapter.capture(game.run_state)
	check(not before_tour.is_empty(), "Capture before a real Bank tour")
	check(await controller.start_tour(&"bank"), "Bank Show me tour opens")
	check(controller.view.is_open() and controller.view._tour, "Bank tour is visible and owns its input")
	controller.dismiss()
	await controller.return_to_studio_root()
	var after_tour: Dictionary = adapter.capture(game.run_state)
	if before_tour.has("run"): before_tour.run.erase("studio_notice_state")
	if after_tour.has("run"): after_tour.run.erase("studio_notice_state")
	check(not before_tour.is_empty() and before_tour == after_tour, "Real tour preserves player finance, history, engines and RNG")
	print("Studio queued notices: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await process_frame
	quit(failures)
