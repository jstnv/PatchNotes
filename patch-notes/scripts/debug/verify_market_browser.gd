extends "res://scripts/debug/verify_rival_world_foundation.gd"

const BrowserModel := preload("res://scripts/ui/market_browser_model.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")

func _initialize() -> void:
	await process_frame
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var player: RefCounted = Factory.create_fresh_session(recipe("market-player","action","1001"),catalog)
	var world: RivalWorld = Trial.create_world(player.run,catalog)
	expect(BrowserModel.query(player.run).rows.is_empty(),"New Studio has an explicit empty market")
	expect(not BrowserModel.query(null).ok,"Missing Studio reports unavailable")
	expect(not BrowserModel.query(RunState.new(),world).ok,"Mismatched world rejects without partial rows")
	var p := policy("action","A very long game title for the market browser")
	var policies := Trial.policies(world)
	for cycle in range(24):
		for step in range(12):
			if player.in_studio and player.run.get_released_game_ids().size() >= 2: break
			var choice: Dictionary = p.call(player.observation())
			var result: Dictionary = player.execute(player.command(StringName(choice.type),choice.get("payload",{})))
			expect(result.ok,"Market fixture uses legal player action")
			if not result.ok or player.run.get_completed_run_cycles() > cycle: break
		if player.run.get_completed_run_cycles() > world.cycle:
			expect(world.advance_committed_player_cycle(policies,8).ok,"Market fixture uses legal AI calendar")
		if player.in_studio and player.run.get_released_game_ids().size() >= 2: break
	var expected_releases: int=player.run.get_released_game_ids().size()
	for rival: RefCounted in world.studios.values():
		expect(not rival.run.get_released_game_ids().is_empty(),"Each actual rival has published")
		expected_releases+=rival.run.get_released_game_ids().size()
	var result := BrowserModel.query(player.run,world)
	expect(result.ok and result.rows.size()==expected_releases,"Every actual player and AI publication is visible")
	var codec := Codec.new()
	var before := Replay.digest(codec.capture(world))
	var current_id := str(player.run._bank_run_id)
	for row: Dictionary in result.rows:
		var owner: RunState = player.run if row.player_owned else world.studios[StringName(row.studio_id)].run
		var sales := owner.get_released_game_sales(StringName(row.release_id))
		expect(row.player_owned == (row.studio_id == current_id),"Ownership uses immutable Studio ID")
		expect(row.earned_units == sales.earned_units and row.entitlement_cents == sales.entitlement_cents and row.settled_cents == sales.settled_cents,"Displayed sales are actual per-owner ledgers")
	result.rows[0].cores.clear()
	expect(before == Replay.digest(codec.capture(world)),"Changing query output cannot mutate source or RNG")
	var old_run := StudioCheckpoint.new().hydrate(StudioCheckpoint.new().capture(player.run))
	var old_id: StringName = old_run.get_released_game_ids()[0]
	old_run._release_metadata[old_id].review.erase("cores")
	var old_result := BrowserModel.query(old_run)
	expect(old_result.ok and old_result.rows.any(func(row): return not row.cores_available),"Older release lacking Core vector stays browseable")
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		game.run_state = player.run
		game.rival_world = world
		root.add_child(game)
		await settle_market()
		root.size = resolution
		var studio: StudioPhase = game._active_phase
		var hud: GameplayHUD = game.get_node("%GameplayHUD")
		hud.contextual_tip.dismiss()
		await settle_market()
		expect(studio.get_global_rect().encloses(studio._market_button.get_global_rect()) and studio._market_button.get_global_rect().end.y < hud.footer_panel.get_global_rect().position.y,"Studio Market button fits between shared HUD bars")
		var output := OS.get_environment("PN_MARKET_CAPTURE")
		if not output.is_empty() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/studio-market-%dx%d.png" % [resolution.x,resolution.y])
		before = Replay.digest(codec.capture(world))
		hud.contextual_tip.show_tip("Studio tip","This stays until explicitly dismissed.")
		studio._market_button.pressed.emit()
		await settle_market()
		var browser := studio._market_browser
		expect(hud.contextual_tip.panel.visible and hud.contextual_tip.title_label.text == "Studio tip","Opening Market preserves the existing tip without replacing it with development guidance")
		hud.contextual_tip.dismiss_button.pressed.emit()
		expect(not hud.contextual_tip.panel.visible,"Explicit close dismisses the persistent Market tip")
		expect(browser.visible and not studio.get_node("%Dashboard").visible,"Market button opens the shared Studio view")
		expect(browser.rows.size()==expected_releases,"Browser lists all live player and AI games")
		var chart := hud.sales_hud.get_global_rect()
		expect(hud.get_node("PersistentHeader").get_global_rect().encloses(chart),"Market preserves chart inside existing top HUD")
		expect(not chart.intersects(browser.get_global_rect()) and browser.get_global_rect().end.y <= hud.footer_panel.get_global_rect().position.y,"Market clears top and bottom HUD")
		expect(browser.get_global_rect().encloses(browser.back_button.get_global_rect()) and browser.get_global_rect().encloses(browser.games.get_global_rect()) and browser.get_global_rect().encloses(browser.details.get_global_rect()),"Market table and controls fit viewport")
		var first := browser.games.get_root().get_first_child()
		expect(first.get_tooltip_text(0) == str(browser.rows[0].release_title),"Long names remain available in tooltips and details")
		var selected := browser._selected
		browser.refresh()
		expect(browser._selected == selected,"Refresh preserves release identity")
		for index in [1,2,0]:
			browser.filter.select(index)
			browser.filter.item_selected.emit(index)
			expect(browser.rows.all(func(row): return index == 0 or row.player_owned == (index == 1)),"Owner filter uses Studio identity")
			expect(not browser.rows.is_empty(),"Each populated owner filter displays releases")
		expect(before == Replay.digest(codec.capture(world)),"Open/select/filter/refresh preserve full world and RNG")
		if not output.is_empty() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/market-%dx%d.png" % [resolution.x,resolution.y])
		var escape := InputEventKey.new()
		# Native hover tooltips can consume Esc during GUI routing. The browser
		# must own cancel before a focused child gets that opportunity.
		browser.games.gui_input.connect(func(event: InputEvent):
			if event.is_action_pressed("ui_cancel"): browser.games.accept_event())
		browser.games.grab_focus()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		Input.parse_input_event(escape)
		await settle_market()
		expect(not browser.visible and not paused and studio._market_button.has_focus(),"Escape returns focus to Market without pausing")
		expect(before == Replay.digest(codec.capture(world)),"Close preserves checkpoint gameplay data")
		game.queue_free()
		await settle_market()
	print("MARKET_BROWSER checks=%d failures=%d" % [checks,failures])
	quit(failures)

func settle_market() -> void:
	for i in range(6): await process_frame
