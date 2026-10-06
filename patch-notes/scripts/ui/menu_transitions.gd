class_name MenuTransitions
extends Node

## Visual-only entrance on the existing menus. No delayed gameplay callbacks.
const MENUS := ["main_menu.gd", "predevelopment_overlay.gd", "feature_store.gd", "publisher_browser.gd", "post_game_review.gd", "monthly_sales_report.gd"]
const PANELS := ["Dashboard", "SummaryPanel", "PriorityDialog", "TutorialDialog", "ContractCompletion", "ContractDetail", "ContractPriorities", "ContractModal"]
var _motions: Dictionary = {}

func _ready() -> void:
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
	if not is_instance_valid(menu) or menu.has_meta("slide_bound"): return
	menu.set_meta("slide_bound", true)
	menu.visibility_changed.connect(func(): _slide.call_deferred(menu))
	menu.tree_exiting.connect(func():
		if _motions.has(menu):
			_motions[menu].tween.kill()
			_motions.erase(menu), CONNECT_ONE_SHOT)
	_slide.call_deferred(menu)

func _slide(menu: Variant) -> void:
	if not is_instance_valid(menu) or not menu.is_inside_tree(): return
	if _motions.has(menu):
		_motions[menu].tween.kill()
		if is_instance_valid(_motions[menu].visual): _motions[menu].visual.position.x = _motions[menu].rest_x
		_motions.erase(menu)
	if not menu.is_visible_in_tree(): return
	var visual: Control = menu
	# Keep full-screen menu bounds fixed; slide their content within the surface.
	if (menu is PanelContainer or (menu.get_script() != null and menu.get_script().resource_path.get_file() in MENUS)) and menu.get_child_count() > 0 and menu.get_child(0) is Control:
		visual = menu.get_child(0)
	# Layout may still settle vertically after opening. Never tween/restore its Y.
	var rest_x := visual.position.x
	visual.position.x = rest_x + 44
	var tween: Tween = menu.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motions[menu] = {"tween": tween, "rest_x": rest_x, "visual": visual}
	tween.tween_property(visual, "position:x", rest_x, 0.24)
	tween.tween_callback(func(): _motions.erase(menu))
