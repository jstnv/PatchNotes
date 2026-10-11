extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("FAIL: " + label)
func box(card: CardView) -> Rect2:
	var result := Rect2(card.get_transform() * Vector2.ZERO,Vector2.ZERO)
	for corner in [Vector2(240,0),Vector2(240,336),Vector2(0,336)]: result = result.expand(card.get_transform() * corner)
	return result
func run() -> void:
	for width in [1000,1100]:
		var fan := CardFan.new();root.add_child(fan);fan.size = Vector2(width,352)
		for i in range(7):
			var card: CardView = load("res://scenes/cards/card_view.tscn").instantiate()
			card.set_card(root.get_node("CardDatabase").get_card(&"levels" if i % 2 == 0 else &"technology_pass"));fan.add_child(card)
		await create_timer(0.7).timeout
		var cards := fan.ordered_cards()
		for selected in range(1,5):
			cards[selected-1].set_selected(true);fan.arrange(true)
			for wave in range(8):
				fan._wave_time = wave * CardFan.WAVE_PERIOD / 8.0
				for card in cards: fan._apply_wave(card)
				for card in cards:
					check(box(card).position.y >= 0 and box(card).end.y <= fan.size.y,"Card inside fan")
					if card.is_selected():
						check(card.scale.x >= 0.59,"Selected hand retains larger type")
						check(fan.card_at(card.get_transform() * Vector2(210,30)) == card,"Right score corner visible and clickable")
						for other in cards:
							if other != card: check(not box(card).intersects(box(other)),"Upper cards separate from all other cards")
			check(cards.slice(selected).all(func(c): return c.input_button.disabled == (selected == 4)),"Selection limit retained")
		fan.organize_by_primary();fan.arrange(true)
		check(cards.filter(func(c): return c.is_selected()).size() == 4,"Sorting preserves selected identities")
		for card in cards: card.set_selected(false)
		fan.arrange(true);check(cards[0].scale.x > 0.7,"Deselect restores original full fan scale")
		fan.queue_free();await process_frame
	print("Upper fan checks=",checks," failures=",failures);quit(failures)
