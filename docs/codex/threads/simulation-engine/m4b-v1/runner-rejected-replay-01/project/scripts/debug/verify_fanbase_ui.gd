extends "res://scripts/debug/verify_fanbase_checkpoint.gd"

func _run() -> void:
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions
		root.content_scale_size=dimensions
		var run:=fan_run()
		run.register_release(fan_project(run,7.0,"Visible Fan fixture"))
		for i in range(2): run.complete_productive_action()
		var game: Control=load("res://scenes/gameplay.tscn").instantiate()
		game.run_state=run
		root.add_child(game)
		await process_frame
		var hud: GameplayHUD=game.get_node("%GameplayHUD")
		hud.tutorial_overlay.close()
		hud.contextual_tip.dismiss()
		await process_frame
		var before:=StudioCheckpoint.new().capture(run)
		expect(hud.fans_button.text=="Fans: %d"%run.get_fans(),"HUD shows authoritative Fan total")
		for button: Button in [hud.fans_button,hud.cash_button,hud.settings_button,hud.tip_button,hud.tutorial_button]:
			expect(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(button.get_global_rect()),"Footer button fits: "+button.name)
		hud.fans_button.pressed.emit()
		await process_frame
		expect(hud.fans_dialog.visible and hud.fans_dialog.dialog_text.contains("0 + 60 - 0 = 60"),"Fan dialog agrees with monthly journal")
		expect(hud.fans_dialog.size.x<=dimensions.x and hud.fans_dialog.size.y<=dimensions.y,"Fan history fits supported viewport")
		expect(StudioCheckpoint.new().capture(run)==before,"Fan history viewing costs no cash/time and changes no RNG")
		game.queue_free()
		await process_frame
		var menu:=MainMenu.new()
		menu.checkpoint_info={"status":&"valid","payload":{"run":{"studio_name":"Calendar fixture","completed_run_cycles":"28"}}}
		root.add_child(menu)
		await process_frame
		expect(menu.get_node("CenterContainer/MenuLayout/Continue").text.contains("1981, Month 15"),"Continue uses global month consistent with Studio after year rollover")
		menu.queue_free()
		await process_frame
	print("Fanbase UI: %d failures"%failures)
	quit(0 if failures==0 else 1)
