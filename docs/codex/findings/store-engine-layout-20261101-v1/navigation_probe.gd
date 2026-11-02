extends "res://scripts/debug/verify_feature_store_navigation.gd"
func _mouse(point: Vector2, pressed: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var focus:=root.gui_get_focus_owner()
	var tracing:=is_instance_valid(store) and (point.is_equal_approx(store.global_position+Vector2(2,2)) or (focus!=null and store._map._input_layer(focus)>0))
	if tracing:print("NAV_TRACE_BEFORE ",{"point":point,"pressed":pressed,"store_visible":store.visible,"popup":store._map.popup.visible,"blocked":MenuTransitions.navigation_input_blocked(store._map),"floating":store._over_floating_control(point),"focus":str(focus),"layer":store._map._input_layer(focus),"processing":store._map.is_processing_input(),"can_process":store._map.can_process(),"paused":paused,"map_layer":store._map._input_layer(store._map),"modal_windows":root.get_embedded_subwindows().filter(func(w):return w.visible).map(func(w):return [w.name,w.get_class()])})
	super._mouse(point,pressed,button)
	if tracing:print("NAV_TRACE_AFTER ",{"store_visible":store.visible,"popup":store._map.popup.visible,"focus":str(root.gui_get_focus_owner())})
