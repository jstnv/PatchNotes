extends "res://scripts/debug/verify_publisher_connections.gd"

func _run() -> void:
	for resolution: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		var run := ready_run([&"publisher_connections"])
		var studio: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
		root.add_child(studio)
		var db := PrimitiveSnapshotDatabase.new()
		db.load_ledgers()
		studio.setup(null,run,db)
		studio._open_contracts()
		for i in 5: await process_frame
		var label: Label = studio._contract_detail.find_child("ContractDetailText",true,false)
		var button: Button = studio._contract_detail.find_child("AcceptContractButton",true,false)
		expect(label.text.contains("$550.00") and label.text.contains("$1850.00") and label.text.contains("$2,400.00"),"Offer shows actual advance, remainder and cap")
		expect(button.get_global_rect().position.y>=0 and button.get_global_rect().end.y<=resolution.y,"Accept remains visible at "+str(resolution))
		var before := snapshot(run)
		studio._close_contract_detail()
		expect(snapshot(run)==before and run.get_primitive_contract()==null,"Cancel pays nothing and preserves eligibility")
		studio._contract_detail.show()
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../docs/codex/findings/publisher-connections-v1/offer-%dx%d.png" % [resolution.x,resolution.y])
		studio.queue_free()
		await process_frame
	print("Publisher Connections UI: %d failures" % failures)
	quit(failures)
