extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")

var checks := 0
var failures := 0
var late_revision_probes := 0
var short_pool_checked := false
var cash_block_checked := false
var disabled_tie_checked := false

func expect(ok: bool, label: String) -> void:
	checks += 1
	if ok: return
	failures += 1
	push_error("RIVAL_FEATURE_EXHAUSTION: " + label)

func request_kind(choice: Dictionary) -> StringName:
	if choice.get("type", &"") != &"development": return StringName(choice.get("type", &""))
	return StringName(choice.get("payload", {}).get("request", {}).get("type", &""))

func feasible_count(session: RefCounted, current: Dictionary) -> int:
	var hand: RefCounted = session.development.hand
	var cards: Array = current.candidates
	var best := 0
	for a in range(cards.size() - 3):
		for b in range(a + 1, cards.size() - 2):
			for c in range(b + 1, cards.size() - 1):
				for d in range(c + 1, cards.size()):
					var selected: Array[CardData] = []
					var feature_count := 0
					for card: Dictionary in [cards[a], cards[b], cards[c], cards[d]]:
						var index: int = hand.candidate_ids.find(int(card.token))
						if index < 0: break
						selected.append(hand._candidate_cards[index])
						if card.type == "feature": feature_count += 1
					if selected.size() != 4 or feature_count <= best: continue
					if not hand.calculate_base(selected).get("valid", false): continue
					var cost: int = session.run.primitive_feature_hand_cost_cents(selected, session.development.project.get_release_id())
					if cost >= 0 and cost <= int(current.cash_cents): best = feature_count
	return best

func selected_feature_count(current: Dictionary, choice: Dictionary) -> int:
	var count := 0
	var ids: Array = choice.get("payload", {}).get("request", {}).get("payload", {}).get("candidate_ids", [])
	if ids.size() != 4: return -1
	for card: Dictionary in current.candidates:
		if int(card.token) in ids and card.type == "feature": count += 1
	return count

func stable_max_tokens(session: RefCounted, current: Dictionary, maximum: int) -> Array[int]:
	var hand: RefCounted = session.development.hand
	var cards: Array = current.candidates
	var best: Array[int] = []
	for a in range(cards.size() - 3):
		for b in range(a + 1, cards.size() - 2):
			for c in range(b + 1, cards.size() - 1):
				for d in range(c + 1, cards.size()):
					var selected: Array[CardData] = []
					var tokens: Array[int] = []
					var features := 0
					for card: Dictionary in [cards[a], cards[b], cards[c], cards[d]]:
						var index: int = hand.candidate_ids.find(int(card.token))
						if index < 0: break
						selected.append(hand._candidate_cards[index])
						tokens.append(int(card.token))
						if card.type == "feature": features += 1
					if selected.size() != 4 or features != maximum: continue
					if not hand.calculate_base(selected).get("valid", false): continue
					var cost: int = session.run.primitive_feature_hand_cost_cents(selected, session.development.project.get_release_id())
					if cost < 0 or cost > int(current.cash_cents): continue
					tokens.sort()
					if best.is_empty() or Trial._tokens_less(tokens, best): best = tokens
	return best

func _initialize() -> void:
	await process_frame
	create_timer(100.0).timeout.connect(func() -> void: push_error("Rival feature verifier timed out"); quit(2))
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var player: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"feature-check-player","studio_name":"Feature Check Player","specialty":"action","traits":[],"seed":"4417"}, catalog)
	expect(player != null, "fresh player session")
	if player == null: quit(1); return
	expect(player.run.add_cash_cents(10000000), "funded legal player calendar fixture")
	var world: RivalWorld = Trial.create_world(player.run, catalog)
	expect(world != null, "fresh trial world")
	if world == null: quit(1); return
	# Fund only this long selector/mechanics fixture. The separate low-cash
	# world below retains ordinary cash and validates genuine affordability.
	# This is not evidence of AI recurring-income or campaign solvency.
	for session: RefCounted in world.studios.values():expect(session.run.add_cash_cents(1000000),"Controlled rival selector fixture funding")
	for cycle in range(56):
		var policies: Dictionary = Trial.policies(world)
		for id: StringName in world.studios:
			var session: RefCounted = world.studios[id]
			var view: Dictionary = session.observation()
			if view.phase not in [&"design", &"alpha"]: continue
			var current: Dictionary = view.development
			if not current.active or current.finalized or current.confirmation_pending: continue
			var maximum := feasible_count(session, current)
			var choice: Dictionary = policies[id].call(view)
			if maximum > 0:
				expect(request_kind(choice) == &"play", "visible affordable Feature prevents Design/Alpha exit")
				expect(selected_feature_count(current, choice) == maximum, "selected hand has maximum feasible Features")
				if late_revision_probes == 0:
					var later_view: Dictionary = view.duplicate(true)
					later_view.development.hand_revision = 3
					var later_choice: Dictionary = policies[id].call(later_view)
					expect(request_kind(later_choice) == &"play" and selected_feature_count(current, later_choice) == maximum, "old two-hand count cannot force exit with a feasible current hand")
					late_revision_probes += 1
				if not disabled_tie_checked:
					var stable: Array[int] = stable_max_tokens(session, current, maximum)
					var disabled: Dictionary = Trial._feature_maximal_choice(view, session, str(session.run.get_studio_specialty()), session.run.get_studio_name(), false)
					expect(disabled.payload.request.payload.candidate_ids == stable, "G4-disabled choice keeps stable maximum-Feature tie")
					disabled_tie_checked = true
			else:
				expect(request_kind(choice) == (&"request_exit" if current.can_exit else &"blocked"), "empty feasible pool exits or blocks explicitly")
			if not short_pool_checked:
				var short_view: Dictionary = view.duplicate(true)
				short_view.development.candidates = current.candidates.slice(0, 3)
				short_view.development.can_exit = true
				expect(request_kind(policies[id].call(short_view)) == &"request_exit", "short visible pool exits without Pass farming")
				short_view.development.can_exit = false
				var no_exit: Dictionary = policies[id].call(short_view)
				expect(request_kind(no_exit) == &"blocked" and str(no_exit.payload.reason).contains("phase exit unavailable"), "short pool with illegal exit returns specific blocked reason")
				short_pool_checked = true
		expect(player.run.complete_productive_action(Callable(), 0, cycle), "legal player calendar boundary %d" % cycle)
		var report: Dictionary = world.advance_committed_player_cycle(policies, Trial.ZERO_STEPS)
		expect(report.ok, "rival world advances one legal player cycle %d" % cycle)
		if not report.ok: break
	expect(late_revision_probes > 0, "post-two-hand observation branch exercised")
	expect(short_pool_checked, "short-pool branch exercised")
	var low_cash_player: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"feature-cash-player","studio_name":"Feature Cash Player","specialty":"action","traits":[],"seed":"4418"}, catalog)
	var low_cash_world: RivalWorld = Trial.create_world(low_cash_player.run, catalog)
	for cycle in range(3):
		var low_policies: Dictionary = Trial.policies(low_cash_world)
		expect(low_cash_player.run.complete_productive_action(Callable(), 0, cycle), "cash fixture player boundary")
		var low_result: Dictionary = low_cash_world.advance_committed_player_cycle(low_policies, Trial.ZERO_STEPS)
		expect(low_result.ok, "cash fixture world boundary")
		if not low_result.ok: break
		for id: StringName in low_cash_world.studios:
			var session: RefCounted = low_cash_world.studios[id]
			var view: Dictionary = session.observation()
			if view.phase not in [&"design", &"alpha"]: continue
			var current: Dictionary = view.get("development", {})
			if not current.get("active", false) or not current.has("candidates"): continue
			expect(session.run.spend_cash_cents(session.run.get_cash_cents()), "legal cash exhaustion")
			current.cash_cents = session.run.get_cash_cents()
			view["development"] = current
			expect(feasible_count(session, current) == 0, "zero cash blocks visible Feature hand")
			var choice: Dictionary = low_policies[id].call(view)
			expect(request_kind(choice) == (&"request_exit" if view.development.can_exit else &"blocked"), "cash-blocked Feature exits or blocks explicitly")
			if request_kind(choice) == &"blocked":
				var prior: int = low_cash_player.run.get_completed_run_cycles()
				expect(low_cash_player.run.complete_productive_action(Callable(), 0, prior), "cash-block fixture next player boundary")
				var blocked_result: Dictionary = low_cash_world.advance_committed_player_cycle(Trial.policies(low_cash_world), Trial.ZERO_STEPS)
				expect(blocked_result.ok, "cash-blocked rival settles one idle calendar cycle")
				if blocked_result.ok:
					for row: Dictionary in blocked_result.studios:
						if row.studio_id != id: continue
						expect(row.blocked_reason == "No legal affordable visible Feature hand; phase exit unavailable" and not row.productive and row.actions.is_empty(), "real cash-blocked rival reports specific reason without Pass play")
			cash_block_checked = true
			break
		if cash_block_checked: break
	expect(cash_block_checked, "cash-blocked live session exercised")
	expect(disabled_tie_checked, "G4-disabled tie branch exercised")
	var blocked_player: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"policy-block-player","studio_name":"Policy Block Player","specialty":"action","traits":[],"seed":"4419"}, catalog)
	var blocked_world: RivalWorld = Trial.create_world(blocked_player.run, catalog)
	var blocked_policies := {}
	for id: StringName in blocked_world.studios:
		blocked_policies[id] = func(_view: Dictionary) -> Dictionary: return {"type":&"blocked","payload":{"reason":"Explicit policy block"}}
	expect(blocked_player.run.complete_productive_action(Callable(), 0, 0), "blocked fixture player boundary")
	var blocked_report: Dictionary = blocked_world.advance_committed_player_cycle(blocked_policies, Trial.ZERO_STEPS)
	expect(blocked_report.ok, "blocked policy settles one world calendar cycle")
	if blocked_report.ok:
		expect(blocked_report.studios.all(func(row: Dictionary) -> bool: return row.blocked_reason == "Explicit policy block" and not row.productive and row.actions.is_empty()), "world reports explicit block without Pass or gameplay command")
	print("RIVAL_FEATURE_EXHAUSTION checks=%d failures=%d late_revision_probes=%d short_pool=%s cash_block=%s disabled_tie=%s" % [checks, failures, late_revision_probes, short_pool_checked, cash_block_checked, disabled_tie_checked])
	quit(0 if failures == 0 else 1)
