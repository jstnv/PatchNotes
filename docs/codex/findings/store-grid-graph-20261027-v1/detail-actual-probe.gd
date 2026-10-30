extends "res://scripts/debug/verify_feature_store_navigation.gd"

func _verify_interactions(width: int, _hud: GameplayHUD) -> void:
	await _reset_view()
	var map:=store._map
	for scale_value in [0.5,1.5]:
		map.set_zoom(scale_value);await process_frame
		map._focus_node(&"character_skill_checks")
		await _settle_focus()
		print("DETAIL_MINIMUMS ",width," ",store._selected," popup=",map.popup.size," minimum=",map.popup.get_combined_minimum_size()," label=",store._details.size," label-min=",store._details.get_combined_minimum_size()," label-text=",store._details.text," buy=",store._buy.size," buy-min=",store._buy.get_combined_minimum_size()," buy-text=",store._buy.text)
		expect(store._selected==&"character_skill_checks","Exact long-description target selected")
		expect(store.get_global_rect().encloses(map.popup.get_global_rect()),"Long Core/AND details remain inside Store at "+str(width))
		expect(map.popup.get_global_rect().encloses(store._buy.get_global_rect()) and map.popup.get_global_rect().encloses(map._back.get_global_rect()),"Back and prerequisite actions stay visible")
		expect("1988" in store._details.text and "qualifying" in store._details.text,"Full separate date and qualifying-release explanation retained")
		var old_zoom:=map.zoom
		var wheel:=InputEventMouseButton.new()
		wheel.position=map.description_scroll.get_global_rect().get_center()
		wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true
		root.push_input(wheel,true)
		for frame in 3: await process_frame
		expect((map.description_scroll.size.y>=store._details.size.y or map.description_scroll.scroll_vertical>0) and map.zoom==old_zoom,"Description wheel reveals remaining lock text without zooming map")
