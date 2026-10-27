extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size = Vector2i(1152,648); root.content_scale_size = root.size
	var view := GuidedProductionTutorial.new()
	root.add_child(view)
	assert(view.start_practice())
	await process_frame
	var failures := 0
	# Presentation-only fixture: four and seven candidates, no resolution/advancement.
	for lesson in [GuidedProductionModel.Lesson.CORE,GuidedProductionModel.Lesson.REDRAW]:
		view.model.lesson = lesson
		view.model._deal(); view._deal_views(); view._refresh()
		await create_timer(.8).timeout
		for i in 4: view._select(view.fan.card_views()[i])
		await create_timer(.3).timeout
		for card in view.fan.card_views():
			var bounds := Rect2(card.get_global_transform()*Vector2.ZERO,Vector2.ZERO)
			for corner in [Vector2(240,0),Vector2(240,336),Vector2(0,336)]: bounds = bounds.expand(card.get_global_transform()*corner)
			if not view.stage.get_global_rect().encloses(bounds):
				failures += 1
				print("FAIL: Visible card clipped: ",card.card_data.id," ",bounds," stage ",view.stage.get_global_rect())
	view.free()
	print("Four/seven-candidate bounds failures: ",failures)
	quit(failures)
