extends SceneTree

const Design := preload("res://scripts/simulation/design_hand_command.gd")
const Alpha := preload("res://scripts/simulation/alpha_hand_command.gd")
const Production := preload("res://scripts/simulation/production_hand.gd")
const STATS := {&"graphics":0,&"sound":1,&"technology":2,&"design":3}
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ",label)
	else: failures += 1; push_error("FAIL: "+label)

func _initialize() -> void: _run.call_deferred()

func definition(phase: String) -> Dictionary:
	return {"id":"synthetic_three_core","name":"Three Core Test","type":"feature","phase":phase,"department":"gameplay","scope":3,"renewable":false,"core_contributions":[{"stat":"graphics","value":3},{"stat":"sound","value":3},{"stat":"technology","value":3}]}

func _run() -> void:
	root.size = Vector2i(1280,720)
	var db := root.get_node("CardDatabase")
	var entry := definition("design")
	check(db.validate_card_definition(entry).is_empty(), "Ordered definition accepted")
	var invalid: Array = [[], [{"stat":"graphics","value":1},{"stat":"graphics","value":2}], [{"stat":"bad","value":1}], [{"value":1}], [{"stat":"graphics","value":0}], [{"stat":"graphics","value":-1}], [{"stat":"graphics","value":1.5}], [{"stat":"graphics","value":9223372036854775807}], [{"stat":"graphics","value":1},{"stat":"sound","value":1},{"stat":"technology","value":1},{"stat":"design","value":1}]]
	for bad: Variant in invalid:
		var malformed := entry.duplicate(true); malformed.core_contributions = bad
		check(not db.validate_card_definition(malformed).is_empty() and db._create_card(malformed)==null, "Malformed ordered definition rejects before creation")
	for field in ["primary_stat","primary_value","secondary_stat","secondary_value"]:
		var mixed := entry.duplicate(true); mixed[field]=1
		check(not db.validate_card_definition(mixed).is_empty(), "Mixed legacy field rejects "+field)
	for phase in ["beta","studio"]:
		var excluded := entry.duplicate(true); excluded.phase=phase
		check(not db.validate_card_definition(excluded).is_empty(), "Nonproduction phase rejects "+phase)
	var priorities := {0:10,1:20,2:30,3:40}
	for phase in ["design","alpha"]:
		var card: CardData = db._create_card(definition(phase))
		check(card.core_contributions().size()==3 and card.primary_stat==&"graphics", "Preserve authored order "+phase)
		var detached := card.core_contributions(); detached[0].value=999
		check(card.primary_value==3 and card.core_contributions()[0].value==3, "Accessor returns detached entries")
		check(WeightedCandidateMath.calculate_printed_score_weight(card,priorities,STATS)==180.0, "All three scores contribute exact weight180 "+phase)
		var project := ProjectState.new(30)
		var command: RefCounted = Design.new() if phase=="design" else Alpha.new()
		command._project_state=project;command._deal_rng=RandomNumberGenerator.new();command._deal_rng.seed=4417
		command.active=true;command.priorities=priorities
		command._pass_definitions.assign(db.get_cards_by_phase_and_types(&"design",[&"pass"] as Array[StringName]))
		# Design removes finite cards from available supply when dealt; Alpha
		# retains them and excludes current/exhausted instances during refill.
		command._available_features.assign([card] if phase=="alpha" else [])
		command._candidate_cards.assign([card,db.get_card(&"design_pass"),db.get_card(&"design_pass"),db.get_card(&"design_pass")])
		command.candidate_ids.assign([0,1,2,3]);command.next_candidate_id=4
		var pressure: float = command._calculate_feature_bug_pressure(card) if phase=="design" else command._calculate_feature_alpha_bug_pressure(card)
		check(is_equal_approx(pressure,1.5), "Raw three-score pressure1.5 "+phase)
		var accepted: Dictionary = command.execute(command.command([0,1,2,3] as Array[int]))
		check(accepted.ok,"Three-score hand commits "+phase+str(accepted.get("error","")))
		check(project.get_core_score(0)==3 and project.get_core_score(1)==3 and project.get_core_score(2)==3 and project.get_core_score(3)==6 and project.get_current_scope()==3,"Each score and one Scope committed "+phase)
		var exhausted: Dictionary = command._exhausted_card_ids if phase=="design" else command._exhausted_feature_ids
		check(exhausted.has(card.id) and not command._candidate_cards.has(card),"Finite feature exhausts once "+phase)
	var larger := definition("design");larger.core_contributions[1].value=7
	var ordered: CardData = db._create_card(larger)
	check(ordered.primary_stat==&"graphics" and WeightedCandidateMath.calculate_printed_score_weight(ordered,priorities,STATS)==260.0,"Largest contribution is not promoted to primary")
	var specialized := Production.calculate([{&"primary_stat":&"graphics"},{&"primary_stat":&"graphics"},{&"primary_stat":&"graphics"},{&"primary_stat":&"graphics"}],{0:3,1:7,2:3},true)
	check(specialized.score_additions[1]==11 and specialized.score_additions[2]==5,"One specialization multiplier includes later entries with existing rounding")
	for card: CardData in db.get_all_cards():
		if card.phase not in [&"design",&"alpha"]: continue
		var expected: float = priorities[STATS[card.primary_stat]]*card.primary_value
		if not card.secondary_stat.is_empty(): expected += priorities[STATS[card.secondary_stat]]*card.secondary_value
		check(WeightedCandidateMath.calculate_printed_score_weight(card,priorities,STATS)==expected,"Legacy weight unchanged "+str(card.id))
		check(card.printed_core_total()==card.primary_value+card.secondary_value,"Legacy raw score unchanged "+str(card.id))
	var view: CardView = load("res://scenes/cards/card_view.tscn").instantiate()
	view.set_card(ordered);root.add_child(view)
	await process_frame
	for size in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=size;await process_frame
		check(view.third_score.visible and view.third_score.text=="+3 TECH" and view.input_button.tooltip_text.contains("+3 Technology"),"Third score visible and accessible "+str(size))
		check(Rect2(Vector2.ZERO,Vector2(240,336)).encloses(view.third_score.get_rect()),"Third score remains inside card")
	view.set_card(db.get_card(&"sprites"));check(not view.third_score.visible,"Reused legacy card hides third field")
	view.queue_free();await process_frame
	print("Three-Core foundation: %d failures"%failures);quit(failures)
