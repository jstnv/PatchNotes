extends SceneTree

const SCENE := preload("res://scenes/cards/card_view.tscn")
const RECTS := {
	"PrimaryScoreValue": Rect2(10,12,40,30), "PrimaryScoreType": Rect2(10,46,40,16),
	"CardName": Rect2(70,18,100,34), "SecondaryScoreValue": Rect2(190,12,40,30),
	"SecondaryScoreType": Rect2(190,46,40,16), "RenewabilitySlot": Rect2(10,296,42,32),
	"Renewability": Rect2(19,300,24,24), "Department": Rect2(70,300,100,24),
	"ScopeValue": Rect2(188,296,42,32),
}
var failures := 0
var checks := 0
var fits: Array = []
var abbreviated: Array = []

func _initialize() -> void:
	_verify.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func _verify() -> void:
	var database := root.get_node("CardDatabase")
	var cards: Array[CardData] = database.get_all_cards()
	for entry: Dictionary in FeatureStoreCatalog.entries():
		var card: CardData = database.get_card(StringName(entry.id))
		if card != null and card not in cards: cards.append(card)
	var view: CardView = SCENE.instantiate()
	root.add_child(view)
	for card in cards:
		var before := _signature(card)
		view.set_card(card)
		await process_frame
		for field in RECTS:
			var control: Control = view.get_node("%" + field)
			check(Rect2(control.global_position-view.global_position, control.size) == RECTS[field], "%s %s exact rectangle: %s; minimum %s" % [card.id,field,Rect2(control.global_position-view.global_position, control.size),control.get_combined_minimum_size()])
		check(view.size == Vector2(240,336) and view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Native bounds and nearest filtering")
		check(view.get_node("CardFrame").texture.resource_path.ends_with("card_frame_complete.png"), "Only complete frame selected")
		check(not view.has_node("NameFrame") and not view.has_node("ArtworkFallback") and not view.has_node("Scope/ScopeLabel"), "Obsolete plate nodes absent")
		check(view.get_node("Background").get_index() < view.artwork.get_index() and view.artwork.get_index() < view.get_node("CardFrame").get_index() and view.get_node("CardFrame").get_index() < view.get_node("RenewabilitySlot").get_index() and view.get_node("RenewabilitySlot").get_index() < view.card_name_label.get_index(), "Background/art/frame/icon/text draw order")
		check(view.renewability_icon.texture == (view.renewable_texture if card.renewable else view.nonrenewable_texture), "Correct lifecycle texture")
		check(view.renewability_icon.texture.resource_path.ends_with("/renewable_icon.png" if card.renewable else "/finite_icon.png") and view.renewability_icon.texture.get_size() == Vector2(24,24), "Lifecycle uses the correct kit asset at native size")
		if card.phase == CardData.PHASE_BETA:
			check(view.primary_score_value.text == "V%d" % card.beta_value and not view.scope_display.visible, "Beta value/scope semantics preserved")
			check(view.primary_score_type.text == ("MKTG" if card.beta_category == &"marketing" else str(card.beta_category).to_upper()), "Beta category remains identifiable in its type field")
		else:
			check(view.primary_score_value.text == "+%d" % card.primary_value and view.scope_value.text == "S%d" % card.scope, "Primary and Scope bind to card data")
			check(view.primary_score_type.text == {&"graphics":"GFX",&"technology":"TECH"}.get(card.primary_stat,str(card.primary_stat).to_upper()), "Primary stat identity displayed")
		if card.secondary_stat.is_empty():
			check(view.secondary_score_value.text.is_empty() and view.secondary_score_type.text.is_empty(), "Absent secondary clears reused view fields")
		else:
			check(view.secondary_score_value.text == "+%d" % card.secondary_value and view.secondary_score_type.text == {&"graphics":"GFX",&"technology":"TECH"}.get(card.secondary_stat,str(card.secondary_stat).to_upper()), "Secondary binds its own score and identity")
		for field in ["CardName","PrimaryScoreValue","PrimaryScoreType","SecondaryScoreValue","SecondaryScoreType","Department","ScopeValue"]:
			var label: Label = view.get_node("%"+field)
			var font := label.get_theme_font("font")
			var font_size := label.get_theme_font_size("font_size")
			var lines := label.text.split("\n")
			for line in lines: check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x <= RECTS[field].size.x, "%s %s width fits" % [card.id,field])
			check(font.get_height(font_size)*lines.size() <= RECTS[field].size.y, "%s %s height fits" % [card.id,field])
			fits.append({"id":str(card.id),"field":field,"text":label.text,"font_size":font_size,"abbreviated":label.get_meta("text_abbreviated",false)})
			if label.get_meta("text_abbreviated",false): abbreviated.append(fits[-1])
		check(before == _signature(card), "Presentation never changes card/scoring data")
	# A wide unknown future label is bounded and its full text remains accessible.
	var future := CardData.new()
	future.id = &"fit_fixture"
	future.phase = CardData.PHASE_ALPHA
	future.card_name = "Supercalifragilisticexpialidocious World Generation"
	future.department = &"advanced_world_design_department"
	future.primary_stat = &"technology"
	future.primary_value = 7
	view.set_card(future)
	await process_frame
	check(view.card_name_label.get_meta("text_abbreviated") and view.department_label.get_meta("text_abbreviated"), "Unbounded future text has deliberate abbreviation fallback")
	check(view.input_button.tooltip_text.contains(future.card_name) and view.input_button.tooltip_text.contains("Advanced World Design Department"), "Full long wording retained in tooltip")
	view.set_selected(true)
	check(view.selection_outline.visible and view.is_selected(), "Selection remains visible")
	view.set_selected(false)
	view.set_card(database.get_card(&"split_screen"))
	view.set_card(database.get_card(&"graphics_pass"))
	check(view.secondary_score_value.text.is_empty() and view.secondary_score_type.text.is_empty(), "Explicit two-score to one-score recycling clears values")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty():
		var file := FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"catalog_cards":cards.size(),"abbreviated_catalog_fields":abbreviated,"fit":fits},"\t"))
	view.free()
	print("Card frame verification: %d checks, %d failures, %d catalog cards, %d abbreviated catalog fields" % [checks,failures,cards.size(),abbreviated.size()])
	quit(failures)

func _signature(card: CardData) -> Array:
	return [card.id,card.card_name,card.card_type,card.phase,card.department,card.primary_stat,card.primary_value,card.secondary_stat,card.secondary_value,card.scope,card.renewable,card.beta_category,card.beta_value,card.qa_operation,card.artwork_path]
