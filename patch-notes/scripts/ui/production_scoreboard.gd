class_name ProductionScoreboard
extends PanelContainer

## Shared read-only score display for live production and scripted practice.
var row: HBoxContainer
var stats: Array[Label] = []
var header_title: Label
var hidden_bugs: Label
var show_hidden_bugs := false
var _punches: Dictionary = {}

func punch(deltas: Dictionary) -> void:
	var indices := {}
	for key in deltas:
		if int(deltas[key]) == 0: continue
		var index := [&"graphics", &"sound", &"technology", &"design"].find(key) + 1
		if key == &"scope": index = 5
		elif key == &"marketing": index = 0
		elif key in [&"fixed", &"discovered"]: index = 6
		elif index == 0: continue
		indices[index] = true
	for index in indices:
		if _punches.has(index): _punches[index].kill()
		var tween := animate_number(stats[index])
		_punches[index] = tween
		tween.finished.connect(func():
			if _punches.get(index) == tween: _punches.erase(index))

static func animate_number(label: Label) -> Tween:
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2.ONE * 0.9
	label.rotation = -0.025
	label.self_modulate = Color("#f5ce69")
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "scale", Vector2.ONE * 1.18, 0.075).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "rotation", 0.025, 0.075)
	tween.chain().tween_property(label, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "rotation", 0.0, 0.22)
	tween.parallel().tween_property(label, "self_modulate", Color.WHITE, 0.22)
	return tween

func reset_punches() -> void:
	for tween in _punches.values(): tween.kill()
	_punches.clear()
	for label in stats:
		label.scale = Vector2.ONE
		label.rotation = 0.0
		label.self_modulate = Color.WHITE

func _ready() -> void:
	row = HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	add_child(row)
	header_title = Label.new()
	header_title.name = "HeaderTitle"
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_title.add_theme_font_size_override("font_size",22)
	header_title.hide()
	row.add_child(header_title)
	for text: String in ["Employees\n—","Graphics\n0","Sound\n0","Technology\n0","Design\n0","Scope\n0 / 30","Bug Pressure\n0.00"]:
		var label := Label.new()
		label.theme_type_variation=&"MetadataLabel"
		label.text = text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		stats.append(label)
	for index in 4:
		stats[index+1].mouse_filter = Control.MOUSE_FILTER_PASS
		stats[index+1].tooltip_text = [
			"Graphics measures visual quality. Cards add Graphics points.\nHigher Core scores improve production quality at Review.",
			"Sound measures audio quality. Cards add Sound points.\nHigher Core scores improve production quality at Review.",
			"Technology measures the quality of your technical systems.\nCards add Technology points. Higher Core scores improve\nproduction quality at Review.",
			"Design measures gameplay quality. Cards add Design points.\nHigher Core scores improve production quality at Review.",
		][index]
	stats[5].mouse_filter = Control.MOUSE_FILTER_PASS
	stats[5].tooltip_text = "Scope measures how much game you have built.\nFeature cards add their printed Scope. Core scores measure quality.\nSynergies increase Core gains without increasing Scope."
	hidden_bugs = Label.new()
	hidden_bugs.theme_type_variation=&"MetadataLabel"
	hidden_bugs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hidden_bugs.hide()
	row.add_child(hidden_bugs)

func render(project: ProjectState, context: StringName, presented: Dictionary = {}) -> void:
	var profile := PrimitiveReviewCalculator.get_project_profile(project)
	for index in 4:
		var category: String = ["Graphics","Sound","Technology","Design"][index]
		var score: int = presented.get(HandPresentation.CORE[index],project.get_core_score(index))
		var target := project.get_review_result().get_standard(index) if project.has_review_result() else profile.get_standard(index) if profile != null else 0
		stats[index+1].text = category+"\n"+("%d / %d"%[score,target] if target>0 else str(score))
		stats[index+1].tooltip_text = "%s score / this project's target.\nMeeting all four targets gives 8/10 production quality.\n125%% of each target gives 10/10.\nScope, Bugs and variance determine the final Review."%category
		stats[index+1].tooltip_text += "\n"+preload("res://scripts/market/market_transaction_trial.gd").describe(project.get_market_details())
	stats[0].text = "Marketing\n%d"%presented.get(&"marketing",project.get_marketing_output()) if context==&"beta" else "Employees\n—"
	stats[5].text = "Scope\n%d / %d"%[presented.get(&"scope",project.get_current_scope()),project.get_required_scope()]
	stats[5].tooltip_text = "Scope measures how much game you have built: %d of the %d target.\nFeature cards add their printed Scope. Reaching the target completes\nScope for Review; Core quality is judged separately.\nSynergies do not increase Scope."%[project.get_current_scope(),project.get_required_scope()]
	if context in [&"beta",&"studio",&"review",&"contract"]:
		var fixed: int = presented.get(&"fixed",project.get_fixed_bugs())
		var known := maxi(0,int(presented.get(&"discovered",project.get_known_bugs()+project.get_fixed_bugs()))-fixed)
		stats[6].text = "Known / Fixed\n%d / %d"%[known,fixed]
	else:
		stats[6].text = "Bug Pressure\n%.2f"%presented.get("_alpha_pressure" if context==&"alpha" else "_design_pressure", project.get_accumulated_alpha_bug_pressure() if context==&"alpha" else project.get_accumulated_bug_pressure())
	hidden_bugs.visible = show_hidden_bugs and context==&"beta"
	if hidden_bugs.visible:
		var hidden: int = maxi(0,int(presented._bug_total)-int(presented.discovered)) if presented.has("_bug_total") else project.get_hidden_bugs()
		hidden_bugs.text = "Hidden Bugs\n%d"%hidden
