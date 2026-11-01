## Browse market listings separately from the Studio's selected engine.
extends Control
signal closed
const Market := preload("res://scripts/engines/engine_marketplace.gd")
var run: RunState
var world: RivalWorld
var selected_id: StringName = &"legacy_engine"
var engine_list: VBoxContainer
var details: VBoxContainer
var action: Button
var status: Label
var heading: Label
var description: Label
var feedback: Label
var buttons: Dictionary = {}

func _init() -> void:
	name="Engines"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	var host:=FolderUI.SurfaceHost.new();add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var surface:=FolderUI.surface(host);surface.set_meta("bounded_folder",true)
	var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",18);surface.add_child(layout)
	FolderUI.header(layout,"Engines","Browse engines, review their terms, then choose or license one.",func():closed.emit())
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",24)
	columns.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(columns)
	var navigation:=VBoxContainer.new();navigation.custom_minimum_size.x=260
	columns.add_child(navigation)
	FolderUI.label(navigation,"Available engines",&"SectionHeading")
	engine_list=FolderUI.sidebar(navigation);engine_list.name="EngineList"
	engine_list.add_theme_constant_override("separation",8)
	var document:=FolderUI.surface(columns,true);document.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	document.add_child(scroll)
	details=VBoxContainer.new();details.name="EngineDetails";details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation",18);scroll.add_child(details)
	heading=FolderUI.label(details,"",&"HeadingLabel")
	status=FolderUI.label(details,"")
	description=FolderUI.label(details,"",&"BodyLabel")
	action=FolderUI.button(details,"",_act);action.name="EngineAction"
	action.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	feedback=FolderUI.label(details,"")
	hide()

func open(value: RunState,current_world: RivalWorld) -> void:
	if run != value:
		_disconnect_run()
		run=value
		if run!=null:
			run.cash_changed.connect(_refresh_details)
			run.engines_changed.connect(_refresh_details)
	world=current_world
	if run==null:return
	var state:=run.get_engine_feature_state()
	if not state.engines.has(selected_id) and Market.find(selected_id).is_empty():selected_id=run.get_selected_engine_id()
	for child in engine_list.get_children():
		engine_list.remove_child(child);child.queue_free()
	buttons.clear()
	var rows: Dictionary={}
	for id: StringName in state.engines:rows[id]=state.engines[id].name
	for listing: Dictionary in Market.starting_listings():rows[listing.id]=listing.name
	for id: StringName in rows:
		var button:=FolderUI.button(engine_list,rows[id],_inspect.bind(id))
		button.toggle_mode=true;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size=Vector2(240,50);buttons[id]=button
	feedback.text="";_refresh_details();show()
	if buttons.has(selected_id):buttons[selected_id].grab_focus()

func _inspect(id: StringName) -> void:
	selected_id=id;feedback.text="";_refresh_details()

func _refresh_details() -> void:
	if run==null:return
	var state:=run.get_engine_feature_state()
	var listing:=Market.terms_for_record(selected_id,state.engines.get(selected_id,{}))
	var owned: bool=state.engines.has(selected_id)
	var row: Dictionary=state.engines.get(selected_id,{})
	heading.text=str(row.get("name",listing.get("name","Engine")))
	for id: StringName in buttons:buttons[id].set_pressed_no_signal(id==selected_id)
	var selected: Dictionary=state.engines.get(run.get_selected_engine_id(),{})
	status.text="Selected for new projects: "+str(selected.get("name","Built-in Engine"))
	var text: Array[String]=[]
	if listing.get("type")==&"public":
		text.append("Public · Access provided to every new Studio; not engine ownership.")
		text.append("Action specialty · No upfront fee · 30% royalty on post-platform Studio revenue.")
		text.append("Specialization: +0.1 Graphics and Technology, added to the existing multiplier.")
		text.append("Fixed Feature library · Implementation and respec unavailable.\nTechnology Skill Tree unavailable · No available upgrades.")
		var feature_names: Array[String]=[]
		for id: StringName in listing.library:feature_names.append(str(run._feature_definitions[id].name))
		text.append("Features: "+", ".join(feature_names))
	elif listing.is_empty():
		text.append("Owned · Proprietary library" if row.get("kind")==&"proprietary" else "Owned · Fixed library")
		text.append("No license fee or royalty.")
	else:
		var creator:=str(listing.creator_id)
		if world!=null and world.studios.has(listing.creator_id):creator=world.studios[listing.creator_id].run.get_studio_name()
		text.append("Creator: %s · %s specialty"%[creator,str(listing.creator_specialty).capitalize()])
		if row.get("origin")=="legacy-access-v1":
			text.append("Existing license · Royalty: %d%% of Studio net sales"%(int(listing.royalty_basis_points)/100))
		else:
			text.append("License: %s · Royalty: %d%% of Studio net sales"%[CashFormatter.format_exact_cents(listing.license_cents),int(listing.royalty_basis_points)/100])
		text.append("Specialization: +0.1 on %s and %s"%[str(listing.dominant[0]).capitalize(),str(listing.dominant[1]).capitalize()])
	var capacity: int=int(row.get("capacity",listing.get("max_scope",ProjectState.MAX_SIGNED_INT)))
	text.append("No engine Scope cap." if capacity==ProjectState.MAX_SIGNED_INT else "Maximum played Scope: %d. Game requirement remains 30."%capacity)
	if owned:text.append("%d implemented · %d configured Features"%[row.implemented.size(),row.committed.size()])
	text.append("Choose an available engine here, or in game/Contract setup. Started projects and accepted Contract pools stay unchanged.")
	description.text="\n\n".join(text)
	action.text="Selected" if selected_id==run.get_selected_engine_id() else "Use this engine" if owned else "License · "+CashFormatter.format_exact_cents(listing.license_cents)
	action.disabled=selected_id==run.get_selected_engine_id() if owned else world==null or not world.studios.has(listing.creator_id) or run.get_cash_cents()<int(listing.license_cents)
	action.tooltip_text="Available engines can be selected in setup." if owned else "Pays the creator once; does not automatically switch your selected engine."

func _act() -> void:
	var state:=run.get_engine_feature_state()
	if state.engines.has(selected_id):
		if not run.select_engine(selected_id):feedback.text="Engine selection is unavailable. Try again after the current action."
	elif world!=null:
		var result:=world.license_engine(selected_id)
		feedback.text="Licensed. Choose Use this engine to select it." if result.get("ok",false) else str(result.get("error","License unavailable."))
	_refresh_details()

func _disconnect_run() -> void:
	if run==null:return
	for event: StringName in [&"cash_changed",&"engines_changed"]:
		if run.is_connected(event,_refresh_details):run.disconnect(event,_refresh_details)

func _exit_tree() -> void:_disconnect_run()
