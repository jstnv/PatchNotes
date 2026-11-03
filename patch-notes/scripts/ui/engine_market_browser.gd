## Browse market listings separately from the Studio's selected engine.
extends Control
signal closed
signal configure_requested
const Market := preload("res://scripts/engines/engine_marketplace.gd")
var run: RunState
var world: RivalWorld
var selected_id: StringName = &"legacy_engine"
var engine_list: VBoxContainer
var overview: VBoxContainer
var details: VBoxContainer
var creation: VBoxContainer
var action: Button
var status: Label
var heading: Label
var description: Label
var feedback: Label
var create_input: LineEdit
var create_button: Button
var develop_button: Button
var configure_button: Button
var skill_grid: Control
var skill_tree: VBoxContainer
var skill_page: VBoxContainer
var skill_button: Button
var skill_back: Button
var skill_feedback: Label
var skill_view_switch: HSlider
var skill_view_row: HBoxContainer
var skill_challenge_tab: Label
var skill_rewards_tab: Label
var skill_detail: Label
var skill_heading: Label
var skill_progress: ProgressBar
var skill_progress_label: Label
var skill_selected_view: StringName = &""
var skill_challenge_text := ""
var skill_reward_text := ""
var page_scroll: ScrollContainer
var buttons: Dictionary = {}

func _init() -> void:
	name="Engines"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	var host:=FolderUI.SurfaceHost.new();add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var surface:=FolderUI.surface(host);surface.set_meta("bounded_folder",true)
	var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",18);surface.add_child(layout)
	FolderUI.header(layout,"Engines","Choose an engine, review its library, or develop your own.",_back)
	var document:=FolderUI.surface(layout,true);document.size_flags_horizontal=Control.SIZE_EXPAND_FILL;document.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll=scroll;scroll.follow_focus=true
	document.add_child(scroll)
	var pages:=VBoxContainer.new();pages.size_flags_horizontal=Control.SIZE_EXPAND_FILL;pages.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.add_child(pages)
	overview=VBoxContainer.new();overview.name="EngineOverview";overview.add_theme_constant_override("separation",18);pages.add_child(overview)
	FolderUI.label(overview,"Engines",&"HeadingLabel")
	FolderUI.label(overview,"Libraries and terms are shown for each engine. New engines begin with foundation technologies and an empty Feature library.")
	develop_button=FolderUI.button(overview,"Develop New Engine",func():_show_page(&"create"));develop_button.name="DevelopNewEngine"
	develop_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	engine_list=VBoxContainer.new();engine_list.name="EngineList";engine_list.add_theme_constant_override("separation",8);overview.add_child(engine_list)
	details=VBoxContainer.new();details.name="EngineDetails";details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation",18);pages.add_child(details)
	FolderUI.button(details,"Back to Engines",func():_show_page(&"overview"))
	heading=FolderUI.label(details,"",&"HeadingLabel")
	status=FolderUI.label(details,"")
	description=FolderUI.label(details,"",&"BodyLabel")
	action=FolderUI.button(details,"",_act);action.name="EngineAction"
	action.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	configure_button=FolderUI.button(details,"Feature Implementation Tree",_configure);configure_button.name="ConfigureEngine"
	configure_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	skill_button=FolderUI.button(details,"Skill Tree",_open_skill_tree);skill_button.name="OpenEngineSkillTree"
	skill_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	details.move_child(configure_button,3);details.move_child(skill_button,4)
	feedback=FolderUI.label(details,"")
	skill_page=VBoxContainer.new();skill_page.name="EngineProgression";skill_page.add_theme_constant_override("separation",18);pages.add_child(skill_page)
	skill_back=FolderUI.button(skill_page,"Back to Engine",_back);skill_back.name="BackToEngine";skill_back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	skill_feedback=FolderUI.label(skill_page,"")
	skill_tree=VBoxContainer.new();skill_tree.name="EngineSkillTree";skill_tree.add_theme_constant_override("separation",12);skill_page.add_child(skill_tree)
	skill_page.size_flags_vertical=Control.SIZE_EXPAND_FILL;skill_tree.size_flags_vertical=Control.SIZE_EXPAND_FILL
	skill_grid=preload("res://scripts/ui/progression_tree_view.gd").new();skill_grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;skill_tree.add_child(skill_grid)
	skill_grid.ready.connect(_build_skill_details)
	skill_grid.inspected.connect(_inspect_skill_node);skill_grid.action_requested.connect(_purchase_skill_node)
	creation=VBoxContainer.new();creation.name="EngineCreation";creation.add_theme_constant_override("separation",18);pages.add_child(creation)
	FolderUI.button(creation,"Back to Engines",func():_show_page(&"overview"))
	FolderUI.label(creation,"Develop New Engine",&"HeadingLabel")
	FolderUI.label(creation,"$100 · %d maximum Scope · No royalties. Starts with four foundation technologies and no Feature cards."%run.ProprietaryEngines.CAPACITY)
	create_input=LineEdit.new();create_input.name="ProprietaryEngineName";create_input.placeholder_text="Name your engine";create_input.max_length=80
	creation.add_child(create_input)
	create_input.text_changed.connect(func(_value: String):_refresh_create())
	create_button=FolderUI.button(creation,"Create Engine · $100",_create);create_button.name="CreateEngine"
	create_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	_show_page(&"overview")
	hide()

func open(value: RunState,current_world: RivalWorld,detail_id: StringName=&"") -> void:
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
	var groups: Dictionary={"Public":[],"Licensed":[],"Owned":[],"Marketplace":[]}
	for id: StringName in state.engines:
		var row: Dictionary=state.engines[id]
		groups["Public" if row.kind==&"public" else "Licensed" if row.kind==&"rival_licensed" else "Owned"].append(id)
	for listing: Dictionary in Market.starting_listings():
		if not state.engines.has(listing.id):groups["Marketplace"].append(listing.id)
	for label: String in ["Public","Licensed","Owned","Marketplace"]:
		if groups[label].is_empty():continue
		FolderUI.label(engine_list,label,&"SectionHeading")
		for id: StringName in groups[label]:
			var row: Dictionary=state.engines.get(id,{})
			var listing:=Market.terms_for_record(id,row)
			var summary: String=str(row.get("name",listing.get("name",id)))
			if label=="Owned":summary+=" · %d Features available"%run.get_future_project_feature_ids(id).size()
			elif label=="Public":summary+=" · 27 Scope · Free · 30% royalty"
			else:summary+=" · %d Scope · %s · %d%% royalty"%[int(listing.max_scope),"Licensed" if label=="Licensed" else CashFormatter.format_exact_cents(listing.license_cents),int(listing.royalty_basis_points)/100]
			var button:=FolderUI.button(engine_list,summary,_inspect.bind(id))
			button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y=50;buttons[id]=button
	feedback.text="";_refresh_details();_refresh_create();_show_page(&"detail" if buttons.has(detail_id) else &"overview");show()
	if buttons.has(detail_id):selected_id=detail_id;_refresh_details()
	else:develop_button.grab_focus()

func _inspect(id: StringName) -> void:
	selected_id=id;feedback.text="";_refresh_details();_show_page(&"detail")

func _show_page(page: StringName) -> void:
	overview.visible=page==&"overview"
	details.visible=page==&"detail"
	creation.visible=page==&"create"
	skill_page.visible=page==&"skill"
	page_scroll.scroll_vertical=0
	page_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED if page==&"skill" else ScrollContainer.SCROLL_MODE_AUTO
	if page==&"create":_refresh_create();create_input.grab_focus()
	if page==&"skill":skill_back.grab_focus();skill_grid.focus_root.call_deferred()

func _open_skill_tree() -> void:
	if run==null or run.get_proprietary_engine_row(selected_id).is_empty():return
	skill_selected_view=&""
	skill_feedback.text="";_refresh_skill_tree();_show_page(&"skill")

func _build_skill_details() -> void:
	skill_grid.detail_width=480.0
	skill_grid.minimum_detail_height=400.0
	var header: HBoxContainer=skill_grid._title.get_parent()
	skill_grid._title.custom_minimum_size.x=88
	var close_button: Control=header.get_child(1)
	close_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	skill_view_row=HBoxContainer.new();skill_view_row.name="EngineViewSelector"
	skill_view_row.add_theme_constant_override("separation",4);skill_view_row.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header.add_child(skill_view_row);header.move_child(skill_view_row,1)
	skill_challenge_tab=FolderUI.label(skill_view_row,"Challenge",&"MetadataLabel")
	skill_challenge_tab.autowrap_mode=TextServer.AUTOWRAP_OFF;skill_challenge_tab.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;skill_challenge_tab.add_theme_font_size_override("font_size",12)
	skill_view_switch=HSlider.new();skill_view_switch.name="EngineViewSwitch"
	skill_view_switch.min_value=0;skill_view_switch.max_value=1;skill_view_switch.step=1
	skill_view_switch.custom_minimum_size=Vector2(48,32);skill_view_switch.focus_mode=Control.FOCUS_ALL;skill_view_switch.scrollable=false
	skill_view_switch.tooltip_text="Switch between challenge and rewards."
	var track:=StyleBoxFlat.new();track.bg_color=FolderUI.color(&"secondary");track.border_color=FolderUI.color(&"indigo")
	track.set_border_width_all(1);track.set_corner_radius_all(6);track.content_margin_top=4;track.content_margin_bottom=4
	skill_view_switch.add_theme_stylebox_override("slider",track)
	var knob_image:=Image.create(16,16,false,Image.FORMAT_RGBA8);knob_image.fill(Color.TRANSPARENT)
	for x in 16:
		for y in 16:
			if Vector2(x-7.5,y-7.5).length_squared()<=49.0:knob_image.set_pixel(x,y,FolderUI.color(&"mint"))
	var knob:=ImageTexture.create_from_image(knob_image)
	skill_view_switch.add_theme_icon_override("grabber",knob);skill_view_switch.add_theme_icon_override("grabber_highlight",knob)
	skill_view_row.add_child(skill_view_switch)
	skill_rewards_tab=FolderUI.label(skill_view_row,"Rewards",&"MetadataLabel")
	skill_rewards_tab.autowrap_mode=TextServer.AUTOWRAP_OFF;skill_rewards_tab.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;skill_rewards_tab.add_theme_font_size_override("font_size",12)
	skill_view_switch.value_changed.connect(func(_value: float):_render_skill_view(true));skill_view_row.hide()
	var surface:=FolderUI.surface(skill_grid.detail_extension)
	surface.add_theme_stylebox_override("panel",FolderUI.THEME.get_stylebox("normal",&"Button"));surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var inset:=MarginContainer.new();surface.add_child(inset)
	for edge in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+edge,14)
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",8);inset.add_child(body)
	skill_heading=FolderUI.label(body,"Challenge",&"SectionHeading");skill_heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	skill_detail=FolderUI.label(body,"");skill_detail.name="EngineUpgradeDetail";skill_detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	skill_progress=ProgressBar.new();skill_progress.name="EngineUpgradeProgress";skill_progress.custom_minimum_size.y=62;skill_progress.show_percentage=false;skill_progress.mouse_filter=Control.MOUSE_FILTER_IGNORE
	skill_progress.add_theme_stylebox_override("background",FolderUI.THEME.get_stylebox("normal",&"Button"));skill_progress.add_theme_stylebox_override("fill",FolderUI.THEME.get_stylebox("normal",&"ActiveFolderTab"))
	skill_grid.action_extension.add_child(skill_progress)
	skill_progress_label=FolderUI.label(skill_progress,"",&"MetadataLabel");skill_progress_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skill_progress_label.offset_left=10;skill_progress_label.offset_right=-10;skill_progress_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;skill_progress_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	skill_progress_label.add_theme_font_size_override("font_size",14);skill_progress_label.add_theme_color_override("font_color",FolderUI.color(&"text"));skill_progress_label.mouse_filter=Control.MOUSE_FILTER_IGNORE

func _render_skill_view(reset_scroll: bool=false) -> void:
	var rewards:=skill_view_switch.value>=0.5
	skill_heading.text="Rewards" if rewards else "Challenge"
	skill_detail.text=skill_reward_text if rewards else skill_challenge_text
	skill_challenge_tab.add_theme_color_override("font_color",FolderUI.color(&"muted") if rewards else FolderUI.color(&"mint"))
	skill_rewards_tab.add_theme_color_override("font_color",FolderUI.color(&"mint") if rewards else FolderUI.color(&"muted"))
	if skill_grid.popup.visible:
		if reset_scroll:skill_grid.reset_details_scroll()
		skill_grid._fit_popup.call_deferred()

func _back() -> void:
	if skill_page.visible:_show_page(&"detail");skill_button.grab_focus()
	else:closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and skill_page.visible and MenuTransitions.cancel_pressed(event):
		_back();get_viewport().set_input_as_handled()

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
		text.append("Fixed Feature library · Read only.\nTechnology Skill Tree unavailable · No available upgrades.")
		var feature_names: Array[String]=[]
		for id: StringName in listing.library:feature_names.append(str(run._feature_definitions[id].name))
		text.append("Features: "+", ".join(feature_names))
	elif listing.is_empty():
		text.append("Owned · Proprietary library" if row.get("kind")==&"proprietary" else "Owned · Fixed library")
		text.append("No license fee or royalty.")
		var owned_state: Dictionary=run.get_proprietary_engine_state().engines.get(selected_id,{})
		if not owned_state.is_empty():text.append("Foundation technologies: Text, 4-Color Palette, Keyboard & Mouse, 8-Bit Sound.")
	else:
		var creator:=str(listing.creator_id)
		if world!=null and world.studios.has(listing.creator_id):creator=world.studios[listing.creator_id].run.get_studio_name()
		text.append("Creator: %s · %s specialty"%[creator,str(listing.creator_specialty).capitalize()])
		if row.get("origin")=="legacy-access-v1":
			text.append("Existing license · Royalty: %d%% of Studio net sales"%(int(listing.royalty_basis_points)/100))
		else:
			text.append("License: %s · Royalty: %d%% of Studio net sales"%[CashFormatter.format_exact_cents(listing.license_cents),int(listing.royalty_basis_points)/100])
		text.append("Specialization: +0.1 on %s and %s"%[str(listing.dominant[0]).capitalize(),str(listing.dominant[1]).capitalize()])
		var feature_names: Array[String]=[]
		for id: StringName in listing.library:feature_names.append(str(run._feature_definitions[id].name))
		text.append("Fixed Feature library · Read only.\nFeatures: "+", ".join(feature_names))
		text.append("Technology: fixed provider engine; no player upgrades.")
	var capacity: int=int(row.get("capacity",listing.get("max_scope",ProjectState.MAX_SIGNED_INT)))
	text.append("No engine Scope cap." if capacity==ProjectState.MAX_SIGNED_INT else "Maximum played Scope: %d. Game requirement remains 30."%capacity)
	if owned and row.kind==&"proprietary":
		text.append("%d implemented · %d available for future games"%[row.implemented.size(),run.get_future_project_feature_ids(selected_id).size()])
		if run.get_future_project_feature_ids(selected_id)!=row.committed:
			text.append("Debug library active in this unsaved session. Paid implementation history is unchanged.")
		var implemented_names: Array[String]=[]
		for id: StringName in row.implemented:implemented_names.append(str(run._feature_definitions[id].name))
		text.append("Implemented Features: "+("None" if implemented_names.is_empty() else ", ".join(implemented_names)))
		var pending: Array[String]=[]
		for entry: Dictionary in run.get_feature_research_queue():
			if entry.engine_id==selected_id:pending.append(str(run._feature_definitions[entry.feature_id].name))
		text.append("Implementation queue: "+("Empty" if pending.is_empty() else ", ".join(pending)))
	text.append("Choose an available engine here, or in game/Contract setup. Started projects and accepted Contract pools stay unchanged.")
	description.text="\n\n".join(text)
	action.text="Selected" if selected_id==run.get_selected_engine_id() else "Use this engine" if owned else "License · "+CashFormatter.format_exact_cents(listing.license_cents)
	action.disabled=selected_id==run.get_selected_engine_id() if owned else world==null or not world.studios.has(listing.creator_id) or run.get_cash_cents()<int(listing.license_cents)
	action.tooltip_text="Available engines can be selected in setup." if owned else "Pays the creator once; does not automatically switch your selected engine."
	configure_button.visible=owned and row.get("kind")==&"proprietary"
	skill_button.visible=not run.get_proprietary_engine_row(selected_id).is_empty()
	_refresh_skill_tree()
	_refresh_create()

func _refresh_skill_tree() -> void:
	skill_feedback.visible=not skill_feedback.text.is_empty()
	var entries: Array=preload("res://scripts/ui/progression_tree_data.gd").engine(run,selected_id)
	skill_tree.visible=not entries.is_empty()
	if entries.is_empty():return
	skill_grid.set_rows(entries)

func _inspect_skill_node(id: StringName) -> void:
	var node: Dictionary=skill_grid.rows.get(id,{})
	if node.get("kind")!=&"skill":
		skill_selected_view=&"";skill_view_row.hide();skill_grid._copy.show();return
	if skill_selected_view!=id:
		skill_selected_view=id;skill_view_switch.set_value_no_signal(0)
	skill_view_row.show()
	var definition: Dictionary=run.ProprietaryEngines.node(node.branch,node.generation)
	var category:=str(node.branch).capitalize()
	skill_challenge_text="Use this engine in Design or Alpha and play Features that contribute %d printed %s Core in total. Primary and secondary Core both count. Pass cards, synergies and replays do not count."%[int(definition.threshold),category]
	if node.state=="locked":skill_challenge_text="First implement the Generation I %s upgrade to start this challenge.\n\n"%category+skill_challenge_text
	skill_reward_text="+20% matching Feature Core toward Pass Budget generation." if node.generation==1 else "+10% matching Pass effectiveness." if node.branch in [&"graphics",&"sound"] else "−15% matching Feature bug pressure."
	skill_reward_text+="\n\nImplementing costs %s and takes no cycle."%CashFormatter.format_exact_cents(int(node.cost_cents))
	skill_grid._copy.hide();skill_grid.use_detail_extension();_render_skill_view()
	var row: Dictionary=run.get_proprietary_engine_row(selected_id)
	var progress: int=int(definition.threshold) if node.state=="complete" else int(row.challenge_progress.get(node.branch,0)) if node.state!="locked" else 0
	skill_progress.max_value=int(definition.threshold);skill_progress.value=progress;skill_progress.show()
	skill_progress_label.text="Implemented" if node.state=="complete" else "%d / %d %s Core%s"%[progress,int(definition.threshold),category," · Locked" if node.state=="locked" else ""]
	var quote: Dictionary=run.get_engine_skill_quote(selected_id,node.branch) if node.state=="ready" else {}
	skill_grid.action_button.name="EngineSkill_%s_%d"%[node.branch,node.generation]
	skill_grid.configure_action("Implement · "+CashFormatter.format_exact_cents(int(node.cost_cents)) if node.state=="ready" else "",not quote.is_empty())
	if node.state=="ready" and quote.is_empty():
		skill_grid.set_description("Implementation unavailable: check available cash, overdue bills or the current save/action warning.");skill_grid._copy.show()
	skill_grid._fit_popup.call_deferred()

func _purchase_skill_node(id: StringName) -> void:
	var node: Dictionary=skill_grid.rows.get(id,{})
	if node.get("kind")!=&"skill":return
	var row:=run.get_proprietary_engine_row(selected_id)
	if row.is_empty() or run.ProprietaryEngines.generation(row,node.branch)+1!=node.generation:
		_refresh_skill_tree();return
	_purchase_skill(node.branch)

func _purchase_skill(branch: StringName) -> void:
	var result:=run.purchase_engine_skill(run.get_engine_skill_quote(selected_id,branch))
	feedback.text="Skill purchased." if result.get("ok",false) else str(result.get("error","Purchase unavailable"))
	skill_feedback.text=feedback.text
	_refresh_details()
	if skill_page.visible:skill_back.grab_focus()

func _refresh_create() -> void:
	if create_button==null or run==null:return
	create_button.disabled=run.get_proprietary_engine_creation_quote(create_input.text).is_empty()

func _create() -> void:
	var quote:=run.get_proprietary_engine_creation_quote(create_input.text)
	var result:=run.create_proprietary_engine(quote)
	if not result.get("ok",false):feedback.text=str(result.get("error","Engine creation unavailable"));_refresh_create();return
	var created: StringName=result.engine_id
	create_input.clear()
	open(run,world,created)
	feedback.text="Engine created. Select it for future projects or implement its Features."

func _configure() -> void:
	if run==null or not run.get_engine_feature_state().engines.has(selected_id):return
	configure_requested.emit()

func _act() -> void:
	var state:=run.get_engine_feature_state()
	if state.engines.has(selected_id):
		if not run.select_engine(selected_id):feedback.text="Engine selection is unavailable. Try again after the current action."
	elif world!=null:
		var result:=world.license_engine(selected_id)
		if result.get("ok",false):
			open(run,world,selected_id)
			feedback.text="Licensed. Choose Use this engine to select it."
			return
		feedback.text=str(result.get("error","License unavailable."))
	_refresh_details()

func _disconnect_run() -> void:
	if run==null:return
	for event: StringName in [&"cash_changed",&"engines_changed"]:
		if run.is_connected(event,_refresh_details):run.disconnect(event,_refresh_details)

func _exit_tree() -> void:_disconnect_run()
