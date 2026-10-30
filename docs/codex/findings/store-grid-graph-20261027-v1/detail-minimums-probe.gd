extends "res://scripts/debug/verify_feature_store_navigation.gd"

func _verify_interactions(width: int, _hud: GameplayHUD) -> void:
	await _reset_view()
	var map:=store._map
	for scale_value in [0.5,1.5]:
		map.set_zoom(scale_value);await process_frame
		map._focus_node(&"text")
		for step in 8: _key(KEY_RIGHT,step>0)
		await _settle_focus()
		print("DETAIL_MINIMUMS ",width," ",store._selected," popup=",map.popup.size," minimum=",map.popup.get_combined_minimum_size()," label=",store._details.size," label-min=",store._details.get_combined_minimum_size()," label-text=",store._details.text," buy=",store._buy.size," buy-min=",store._buy.get_combined_minimum_size()," buy-text=",store._buy.text)
		expect(store.get_global_rect().encloses(map.popup.get_global_rect()),"Long Core/AND details remain inside Store at "+str(width))
