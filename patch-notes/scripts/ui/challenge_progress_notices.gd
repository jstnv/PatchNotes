## Presentation-only observations of committed player progress. No saved state.
extends Control
signal notice_requested(notice: Dictionary)

const ENTER_SECONDS:=0.22
const HOLD_SECONDS:=3.5
const EXIT_SECONDS:=0.24
const MAX_VISIBLE:=3
const WIDTH:=320.0
const HEIGHT:=88.0
const GAP:=4.0
const EngineRules:=preload("res://scripts/engines/proprietary_engine_state.gd")

var run: RunState
var footer: Control
var _employees: Dictionary={}
var _engines: Dictionary={}
var _pending: Array[Dictionary]=[]
var _visible: Array[Control]=[]
var _animations: Dictionary={}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index=60
	resized.connect(_layout_cards)
	set_process(false)

func _process(_delta: float) -> void:
	# Unlock guidance can arrive or leave while a notice is on screen.
	_layout_cards()

func configure(footer_control: Control) -> void:
	if is_instance_valid(footer) and footer.resized.is_connected(_layout_cards):footer.resized.disconnect(_layout_cards)
	footer=footer_control
	if is_instance_valid(footer):footer.resized.connect(_layout_cards)

func bind_run(value: RunState) -> void:
	if run==value:return
	_disconnect_run();run=value
	_pending.clear()
	for animation: Tween in _animations.values():
		if animation.is_valid():animation.kill()
	_animations.clear()
	for card: Control in _visible:
		if is_instance_valid(card):card.queue_free()
	_visible.clear()
	set_process(false)
	if run==null:return
	_employees=_employee_snapshot(run._employees);_engines=run.get_proprietary_engine_state()
	run.calendar_changed.connect(_observe);run.employees_changed.connect(_observe);run.engines_changed.connect(_observe)

func _disconnect_run() -> void:
	if run==null:return
	for signal_name: StringName in [&"calendar_changed",&"employees_changed",&"engines_changed"]:
		if run.is_connected(signal_name,_observe):run.disconnect(signal_name,_observe)

func _exit_tree() -> void:_disconnect_run()

func _observe() -> void:
	if run==null:return
	var next_employees:=_employee_snapshot(run._employees)
	var next_engines:=run.get_proprietary_engine_state()
	var changes:=progress_changes(_employees,next_employees,_engines,next_engines)
	_employees=next_employees;_engines=next_engines
	enqueue_all(changes)

static func _employee_snapshot(roster: Dictionary) -> Dictionary:
	# Do not duplicate the growing employee event journal or QA RNG/project data
	# on every productive cycle. The observer needs only the counters below.
	var result:={"employees":{}}
	for id in roster.get("employees",{}):
		var employee: Dictionary=roster.employees[id]
		var row:={"type":employee.get("type",&"")}
		if row.type==&"qa":
			row.courses=employee.get("courses",{}).duplicate(true)
			for key: String in ["mixed_count","search_count","debug_count"]:row[key]=int(employee.get(key,0))
		elif employee.has("career"):
			var career: Dictionary=employee.career
			row.career={"courses":career.get("courses",{}).duplicate(true),"games":career.get("games",{}).duplicate(true),"projects":{}}
			for project_id in career.get("projects",{}):
				var p: Dictionary=career.projects[project_id]
				row.career.projects[project_id]={"design":[true] if not p.get("design",[]).is_empty() else [],"alpha":[true] if not p.get("alpha",[]).is_empty() else [],"specializations":p.get("specializations",[]).duplicate()}
		result.employees[id]=row
	return result

static func _name(role: StringName) -> String:
	return {&"production":"Production Specialist",&"qa":"QA Specialist",&"project_manager":"Project Manager"}.get(role,str(role).capitalize())

static func _course_name(course: StringName) -> String:
	return {&"mixed":"Search & Fix",&"pure":"QA Versatility",&"production_planning":"Production Planning",&"pass_alignment":"Pass Alignment"}.get(course,"Project Management "+str(course).get_slice("_",1))

static func _notice(title: String,message: String) -> Dictionary:
	return {"title":title,"message":message}

static func progress_changes(old_roster: Dictionary,new_roster: Dictionary,old_engines: Dictionary,new_engines: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var previous: Dictionary=old_roster.get("employees",{})
	for id in new_roster.get("employees",{}):
		if not previous.has(id):continue
		var old: Dictionary=previous[id];var current: Dictionary=new_roster.employees[id]
		var role: StringName=current.get("type",&"")
		var old_courses: Dictionary=old.get("courses",{}) if role==&"qa" else old.get("career",{}).get("courses",{})
		var courses: Dictionary=current.get("courses",{}) if role==&"qa" else current.get("career",{}).get("courses",{})
		for course: StringName in courses:
			if not old_courses.has(course) or int(old_courses[course].get("completed_cycle",-1))>=0:continue
			var title:=_name(role)+" · "+_course_name(course)
			var complete:=int(courses[course].get("completed_cycle",-1))>=0
			if complete:
				result.append(_notice(title,"Completed · Reward earned"));continue
			if role==&"qa":
				if course==&"mixed" and int(current.get("mixed_count",0))>int(old.get("mixed_count",0)):
					result.append(_notice(title,"%d / 4 qualifying hands"%int(current.mixed_count)))
				elif course==&"pure" and (int(current.get("search_count",0))>int(old.get("search_count",0)) or int(current.get("debug_count",0))>int(old.get("debug_count",0))):
					result.append(_notice(title,"Search %d / 3 · Debug %d / 3"%[int(current.search_count),int(current.debug_count)]))
				continue
			var before_career: Dictionary=old.get("career",{})
			var after_career: Dictionary=current.get("career",{})
			if role==&"project_manager" and course==&"manager_1":
				var before_hands:=EmployeeRoster.Career.manager_one_hands({"career":before_career})
				var after_hands:=EmployeeRoster.Career.manager_one_hands({"career":after_career})
				if after_hands>before_hands:result.append(_notice(title,"%d / 4 pairs · %d / 2 hands"%[after_hands/2,after_hands%2]))
				continue
			if role==&"project_manager":
				var before_games: Array=before_career.get("games",{}).get(course,[])
				var after_games: Array=after_career.get("games",{}).get(course,[])
				if after_games.size()>before_games.size():result.append(_notice(title,"%d / 4 qualifying games released"%after_games.size()))
			for project_id in after_career.get("projects",{}):
				var p: Dictionary=after_career.projects[project_id]
				var prior: Dictionary=before_career.get("projects",{}).get(project_id,{})
				if role==&"project_manager":
					var n: int=p.get("specializations",[]).size();var old_n: int=prior.get("specializations",[]).size()
					if n>old_n:result.append(_notice(title,"%d / 2 specializations · release this game to count"%n))
				elif course==&"pass_alignment":
					for phase: String in ["design","alpha"]:
						if not p.get(phase,[]).is_empty() and prior.get(phase,[]).is_empty():
							result.append(_notice(title,"%s match recorded · release this game to count"%phase.capitalize()))
	var previous_engines: Dictionary=old_engines.get("engines",{})
	for id in new_engines.get("engines",{}):
		if not previous_engines.has(id):continue
		var old: Dictionary=previous_engines[id];var current: Dictionary=new_engines.engines[id]
		for branch: StringName in EngineRules.BRANCHES:
			var generation:=EngineRules.generation(current,branch)
			if generation!=EngineRules.generation(old,branch) or generation>=2:continue
			var before:=int(old.get("challenge_progress",{}).get(branch,0))
			var progress:=int(current.get("challenge_progress",{}).get(branch,0))
			if progress<=before:continue
			var node: Dictionary=EngineRules.node(branch,generation+1)
			var suffix:=" · ready to implement" if progress>=int(node.threshold) else ""
			result.append(_notice(str(current.name)+" · "+str(node.name),"%s %d / %d Core%s"%[str(branch).capitalize(),progress,int(node.threshold),suffix]))
	return result

func active_count() -> int:return _visible.size()

func enqueue_all(changes: Array) -> void:
	if notice_requested.get_connections().size() > 0:
		for change: Dictionary in changes: notice_requested.emit(change)
		return
	for change: Dictionary in changes:_pending.append(change)
	_show_pending()

func _show_pending() -> void:
	if not is_inside_tree():return
	while not _pending.is_empty() and _visible.size()<MAX_VISIBLE:
		var entry: Dictionary=_pending.pop_front()
		var slot:=Control.new();slot.name="ChallengeProgressSlot";slot.mouse_filter=Control.MOUSE_FILTER_IGNORE;slot.clip_contents=true;slot.size=Vector2(WIDTH,HEIGHT);add_child(slot)
		var card:=FolderUI.surface(slot);card.name="ChallengeProgressNotice";card.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.custom_minimum_size=Vector2(WIDTH,HEIGHT);card.size=Vector2(WIDTH,HEIGHT)
		var box:=VBoxContainer.new();box.custom_minimum_size.x=WIDTH-32;box.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_theme_constant_override("separation",3);card.add_child(box)
		var heading:=FolderUI.label(box,str(entry.title),&"SectionHeading");heading.add_theme_font_size_override("font_size",14);heading.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var message:=FolderUI.label(box,str(entry.message),&"BodyLabel");message.add_theme_font_size_override("font_size",13);message.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_visible.append(slot);_layout_cards();card.modulate.a=0.0;card.position.y=-slot.size.y
		_start_card(weakref(slot))
	set_process(not _visible.is_empty())

func _start_card(reference: WeakRef) -> void:
	# Let wrapped labels settle before choosing the offscreen start point.
	await get_tree().process_frame
	var slot:=reference.get_ref() as Control
	if not is_instance_valid(slot) or slot.get_child_count()==0:return
	var card:=slot.get_child(0) as Control
	card.reset_size()
	slot.size=card.size
	card.position.y=-slot.size.y
	_layout_cards()
	var animation:=create_tween().set_parallel();animation.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation.tween_property(card,"modulate:a",1.0,ENTER_SECONDS)
	animation.tween_property(card,"position:y",0.0,ENTER_SECONDS)
	animation.chain().tween_interval(HOLD_SECONDS)
	animation.chain().tween_property(card,"modulate:a",0.0,EXIT_SECONDS)
	animation.chain().tween_callback(_finish_card.bind(reference))
	_animations[slot]=animation
	if not slot.visible:animation.pause()

func _finish_card(reference: WeakRef) -> void:
	var card:=reference.get_ref() as Control
	if card!=null:_remove_card(card)

func _layout_cards() -> void:
	var top:=8.0
	if is_instance_valid(footer):
		var header:=footer.get_parent().get_node_or_null("PersistentHeader") as Control
		if is_instance_valid(header) and header.visible:top=maxf(top,header.position.y+header.size.y+8.0)
	var rightmost:=maxf(8.0,size.x-WIDTH-16.0)
	var obstacles: Array[Rect2]=[]
	# The persistent tip and synergy banner live on a separate CanvasLayer
	# above this HUD. Use their actual visible bounds, not the HUD z-index.
	if is_instance_valid(footer):
		var hud:=footer.get_parent()
		for item: Array in [["ContextualTip","panel"],["SynergyNotification","banner"]]:
			var layer:=hud.get_node_or_null(item[0])
			if not layer is CanvasLayer or not layer.visible:continue
			var panel: Variant=layer.get(item[1])
			if is_instance_valid(panel) and panel.is_visible_in_tree():obstacles.append(panel.get_global_rect())
	for overlay in get_tree().get_nodes_in_group(&"focused_guidance_overlay"):
		if not overlay is CanvasLayer or not overlay.visible:continue
		var panel: Variant=overlay.get("panel")
		if not is_instance_valid(panel) or not panel.is_visible_in_tree():continue
		obstacles.append(panel.get_global_rect())
	# Prefer the uppermost unobstructed column; ties keep the normal right dock.
	# This lets a persistent tip remain open without indefinitely suppressing
	# notices, while still clearing simultaneous guidance and synergy banners.
	var candidates: Array[float]=[rightmost]
	for bounds: Rect2 in obstacles:
		for x: float in [bounds.position.x-WIDTH-GAP,bounds.end.x+GAP]:
			if x>=8.0 and x<=rightmost:candidates.append(x)
	var left:=rightmost
	var best_top:=INF
	for x: float in candidates:
		var candidate_top:=top
		for bounds: Rect2 in obstacles:
			if bounds.end.x>x and bounds.position.x<x+WIDTH:
				candidate_top=maxf(candidate_top,bounds.end.y+GAP)
		if candidate_top<best_top:
			left=x;best_top=candidate_top
	top=best_top
	var bottom:=size.y-GAP
	if is_instance_valid(footer) and footer.visible:bottom=footer.position.y-GAP
	var overflow:=false
	for i in _visible.size():
		var slot: Control=_visible[i]
		var fits:=not overflow and top+slot.size.y<=bottom
		if not fits:overflow=true
		if slot.visible!=fits:
			slot.visible=fits
			var animation: Variant=_animations.get(slot)
			if animation is Tween and animation.is_valid():
				if fits:animation.play()
				else:animation.pause()
		if not fits:continue
		slot.position=Vector2(left,top)
		top+=slot.size.y+GAP

func _remove_card(card: Control) -> void:
	var animation: Variant=_animations.get(card)
	if animation is Tween and animation.is_valid():animation.kill()
	_animations.erase(card)
	_visible.erase(card)
	if is_instance_valid(card):card.queue_free()
	_layout_cards();_show_pending()
