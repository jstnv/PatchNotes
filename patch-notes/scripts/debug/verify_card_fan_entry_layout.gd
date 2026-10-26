extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void: execute.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("Card fan entry: " + label)

func execute() -> void:
	for final_size in [Vector2(1116,310),Vector2(1244,382)]:
		var fan := CardFan.new()
		root.add_child(fan)
		# Contract entry builds/deals before its parent Containers finish sorting.
		fan.size = Vector2(0,240)
		for i in range(7):
			var card: CardView=load("res://scenes/cards/card_view.tscn").instantiate()
			card.set_card(root.get_node("CardDatabase").get_card(&"levels" if i%2==0 else &"technology_pass"))
			fan.add_child(card)
		await process_frame
		await create_timer(0.08).timeout
		check(fan.card_views().any(func(card): return card.has_meta("fan_entering")),"Resize overlaps a real entrance animation")
		fan.size=final_size
		await create_timer(1.0).timeout
		var before: Array=[]
		for card in fan.card_views():
			before.append(card.scale)
			check(not card.has_meta("fan_entering"),"Entrance completes without stuck cards")
		# Sorting with unchanged bounds must not suddenly enlarge the initial hand.
		fan.arrange(true)
		for i in range(7):
			check(before[i].is_equal_approx(fan.card_views()[i].scale),"Completed entry already uses the settled container scale")
		check(fan.has_method("_make_custom_tooltip"),"Card details use a bounded custom tooltip")
		if fan.has_method("_make_custom_tooltip"):
			var details: String = fan.card_views()[0].input_button.tooltip_text
			var tooltip: Label = fan.call("_make_custom_tooltip",details)
			check(tooltip.text == details,"Wrapping preserves every card detail")
			check(tooltip.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART,"Long synergy explanations wrap")
			check(tooltip.custom_minimum_size.x <= root.get_visible_rect().size.x-48,"Tooltip leaves room inside the viewport")
			tooltip.free()
		fan.free()
		await process_frame
	print("CARD_FAN_ENTRY checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
