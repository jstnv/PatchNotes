class_name MenuTransitions
extends Node

## Visual-only entrance on the existing menus. No delayed gameplay callbacks.
const MENUS := ["main_menu.gd", "predevelopment_overlay.gd", "feature_store.gd", "publisher_browser.gd", "post_game_review.gd", "monthly_sales_report.gd", "employee_panel.gd"]
const PANELS := ["Dashboard", "SummaryPanel", "PriorityDialog", "TutorialDialog", "ContractCompletion", "ContractDetail", "ContractPriorities", "ContractModal"]
const ENTRANCE_DISTANCE := 44.0
const ENTRANCE_SECONDS := 0.24
var _motions: Dictionary = {}
var _entrance_requests: Dictionary = {}
var _pending_entrances: Array[Dictionary] = []
var automatic_entrances := true
var animate := true
var busy := false
var frames: Array[Dictionary] = []
var _navigation_tween: Tween
var _input_viewport: Viewport
var _input_was_disabled := false
var _owns_input_lock := false
var _moving_view: WeakRef
var _moving_rest_x := 0.0

## Optional stack for existing menu views. Frames hold weak UI references only;
## they never contain gameplay state or reverse a committed action.
func set_root(view: Control) -> void:
	if not frames.is_empty(): return
	view.set_meta("folder_navigation_managed",true)
	frames.append({"view":weakref(view),"focus":null,"closed":Callable()})

func depth() -> int: return frames.size()

func is_top(view: Control) -> bool:
	return not frames.is_empty() and frames[-1].view.get_ref()==view

func push(view: Control, focus: Control, closed: Callable = Callable()) -> bool:
	if busy or frames.is_empty() or frames.any(func(frame): return frame.view.get_ref()==view): return false
	var previous: Control = frames[-1].view.get_ref()
	var owner := get_viewport().gui_get_focus_owner()
	frames[-1].focus = weakref(owner) if owner != null else null
	view.set_meta("folder_navigation_managed",true)
	frames.append({"view":weakref(view),"focus":null,"closed":closed})
	var rest_x := view.position.x
	_prepare_navigation_motion(view,rest_x)
	view.show()
	_lock_navigation()
	var finish := func():
		if is_instance_valid(view): view.position.x=rest_x
		if is_instance_valid(previous): previous.hide()
		_unlock_navigation()
		if is_instance_valid(focus) and focus.is_visible_in_tree(): focus.grab_focus()
	if not animate:
		finish.call()
		return true
	view.position.x=rest_x+maxf(64.0,view.size.x)
	_navigation_tween=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_navigation_tween.tween_property(view,"position:x",rest_x,ENTRANCE_SECONDS)
	_navigation_tween.tween_callback(finish)
	return true

func pop() -> bool:
	if busy or frames.size()<2: return false
	var removed: Dictionary = frames.pop_back()
	var view: Control = removed.view.get_ref()
	var previous: Control = frames[-1].view.get_ref()
	if is_instance_valid(previous): previous.show()
	_lock_navigation()
	var rest_x := view.position.x if is_instance_valid(view) else 0.0
	if is_instance_valid(view): _prepare_navigation_motion(view,rest_x)
	var focus_ref: Variant = frames[-1].focus
	var finish := func():
		if is_instance_valid(view):
			view.hide()
			view.position.x=rest_x
		if removed.closed.is_valid(): removed.closed.call()
		_unlock_navigation()
		var focus: Control = focus_ref.get_ref() if focus_ref != null else null
		if is_instance_valid(focus) and focus.is_visible_in_tree(): focus.grab_focus()
	if not animate or not is_instance_valid(view):
		finish.call()
		return true
	_navigation_tween=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_navigation_tween.tween_property(view,"position:x",rest_x+maxf(64.0,view.size.x),ENTRANCE_SECONDS)
	_navigation_tween.tween_callback(finish)
	return true

func _prepare_navigation_motion(view: Control, rest_x: float) -> void:
	_moving_view=weakref(view)
	_moving_rest_x=rest_x
	view.set_meta("folder_navigation_motion",true)

func _lock_navigation() -> void:
	busy=true
	_input_viewport=get_viewport()
	_input_was_disabled=_input_viewport.gui_disable_input
	_input_viewport.gui_disable_input=true
	_owns_input_lock=true

func _unlock_navigation() -> void:
	busy=false
	var view: Control = _moving_view.get_ref() if _moving_view != null else null
	if is_instance_valid(view):
		view.remove_meta("folder_navigation_motion")
		view.position.x=_moving_rest_x
		if view.get_parent() is Container: view.get_parent().queue_sort()
	_moving_view=null
	if _owns_input_lock and is_instance_valid(_input_viewport): _input_viewport.gui_disable_input=_input_was_disabled
	_owns_input_lock=false

func _exit_tree() -> void:
	_pending_entrances.clear()
	for motion: Dictionary in _motions.values():motion.tween.kill()
	_motions.clear()
	if _navigation_tween != null: _navigation_tween.kill()
	_unlock_navigation()

func _ready() -> void:
	if not automatic_entrances: return
	get_tree().node_added.connect(_watch)
	_scan(get_parent())

func _scan(node: Node) -> void:
	_watch(node)
	for child in node.get_children(): _scan(child)

func _watch(node: Node) -> void:
	if not node is Control: return
	var script: Script = node.get_script()
	if node.name not in PANELS and (script == null or script.resource_path.get_file() not in MENUS): return
	_bind.call_deferred(node)

func _bind(menu: Variant) -> void:
	# A deferred menu may have been freed before argument binding; check it here.
	if not is_instance_valid(menu) or menu.has_meta("slide_bound") or menu.has_meta("folder_navigation_managed"): return
	menu.set_meta("slide_bound", true)
	menu.visibility_changed.connect(func(): _slide.call_deferred(menu))
	menu.tree_exiting.connect(func():
		_entrance_requests.erase(menu)
		if _motions.has(menu):
			_motions[menu].tween.kill()
			_motions.erase(menu), CONNECT_ONE_SHOT)
	_slide.call_deferred(menu)

func _slide(menu: Variant) -> void:
	if not is_instance_valid(menu) or not menu.is_inside_tree(): return
	var request := int(_entrance_requests.get(menu, 0)) + 1
	_entrance_requests[menu] = request
	if _motions.has(menu):
		_motions[menu].tween.kill()
		if is_instance_valid(_motions[menu].visual): _motions[menu].visual.position.x = _motions[menu].rest_x
		_motions.erase(menu)
	if not menu.is_visible_in_tree(): return
	var visual: Control = menu
	# Keep full-screen menu bounds fixed; slide their content within the surface.
	if (menu is PanelContainer or (menu.get_script() != null and menu.get_script().resource_path.get_file() in MENUS)) and menu.get_child_count() > 0 and menu.get_child(0) is Control:
		visual = menu.get_child(0)
	if menu.has_method("get_menu_transition_content"):
		visual = menu.get_menu_transition_content()
	# Showing a panel queues Container layout. Its child can still be at (0,0)
	# here; capturing that as the destination erases the authored left padding.
	# Let layout settle before reading the rest position, and discard stale opens.
	var parent := visual.get_parent()
	if parent is Container: parent.queue_sort()
	_pending_entrances.append({"menu":weakref(menu),"visual":weakref(visual),"request":request,"frames":2})

## Pending layout waits belong to this Node. Freeing a scene drops them safely;
## no coroutine can resume on a destroyed MenuTransitions script instance.
func _process(_delta: float) -> void:
	var waiting:=_pending_entrances.duplicate()
	_pending_entrances.clear()
	for item: Dictionary in waiting:
		var menu: Control=item.menu.get_ref()
		var visual: Control=item.visual.get_ref()
		if menu==null or visual==null or not menu.is_inside_tree() or not menu.is_visible_in_tree() or _entrance_requests.get(menu)!=item.request:continue
		item.frames-=1
		if item.frames>0:_pending_entrances.append(item)
		else:_start_entrance(menu,visual)

func _start_entrance(menu: Control,visual: Control) -> void:
	# Layout may still settle vertically after opening. Never tween/restore its Y.
	var rest_x := visual.position.x
	visual.position.x = rest_x + ENTRANCE_DISTANCE
	var tween: Tween = menu.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motions[menu] = {"tween": tween, "rest_x": rest_x, "visual": visual}
	tween.tween_property(visual, "position:x", rest_x, ENTRANCE_SECONDS)
	tween.tween_callback(func():
		_motions.erase(menu)
		# Resizes during the entrance must finish at the current Container inset.
		if is_instance_valid(visual) and visual.get_parent() is Container:
			visual.get_parent().queue_sort())
