## Shared free selection of owned/licensed engines before a pool is frozen.
extends VBoxContainer

signal selection_changed(engine_id: StringName)
var choices: OptionButton
var summary: Label
var run: RunState
var _refreshing := false

func _init() -> void:
	name = "EnginePicker"
	add_theme_constant_override("separation",6)
	FolderUI.label(self,"Engine",&"BodyLabel")
	choices = OptionButton.new()
	choices.name = "EngineOptions"
	choices.fit_to_longest_item = false
	choices.custom_minimum_size = Vector2(220,42)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(choices)
	summary = FolderUI.label(self,"")
	summary.name = "EngineSupply"
	choices.item_selected.connect(_choose)

func bind(value: RunState) -> void:
	if run != value:
		if run != null:
			for event: StringName in [&"engines_changed",&"features_changed"]:
				if run.is_connected(event,refresh):run.disconnect(event,refresh)
		run = value
		if run != null:
			run.engines_changed.connect(refresh)
			run.features_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if _refreshing:return
	_refreshing = true
	choices.clear()
	choices.disabled = run == null
	summary.text = ""
	if run != null:
		var state := run.get_engine_feature_state()
		var entitlements := run.get_engine_entitlements()
		for id: StringName in entitlements.owned_ids+entitlements.licensed_ids:
			if not state.engines.has(id):continue
			choices.add_item(state.engines[id].name)
			choices.set_item_metadata(choices.item_count-1,id)
			if id == run.get_selected_engine_id():choices.select(choices.item_count-1)
		var row: Dictionary = state.engines.get(run.get_selected_engine_id(),{})
		if not row.is_empty():
			var scope := 0
			var ids := run.get_future_project_feature_ids()
			for id: StringName in ids:scope += int(run._feature_definitions[id].scope)
			var cap := "No engine Scope cap" if int(row.capacity)==ProjectState.MAX_SIGNED_INT else "Max %d Scope"%int(row.capacity)
			summary.text = "%s · %d configured Features · %d printed Scope"%[cap,ids.size(),scope]
	_refreshing = false

func _choose(index: int) -> void:
	if _refreshing or run == null or index<0 or index>=choices.item_count:return
	var id: StringName = choices.get_item_metadata(index)
	if id == run.get_selected_engine_id():return
	if run.select_engine(id):selection_changed.emit(id)
	refresh()

func _exit_tree() -> void:
	if run != null:
		for event: StringName in [&"engines_changed",&"features_changed"]:
			if run.is_connected(event,refresh):run.disconnect(event,refresh)
