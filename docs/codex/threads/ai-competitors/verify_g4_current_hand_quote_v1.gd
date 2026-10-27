## Analysis-only verifier run against a frozen private simulator project.
extends SceneTree

const Factory = preload("res://scripts/simulation/run_factory.gd")
const Fixture = preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay = preload("res://scripts/simulation/development_replay.gd")

var checks := 0
var failures := 0

func expect(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		return
	failures += 1
	push_error("G4 quote: " + label)

func _initialize() -> void:
	await process_frame
	create_timer(60.0).timeout.connect(func() -> void: push_error("G4 quote verifier timed out"); quit(2))
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var recipe: Dictionary = {"schema_version": 1, "studio_id": "g4-quote-audit-4417", "studio_name": "G4 Quote Audit", "specialty": "action", "traits": ["family_funding", "cult_following"], "seed": "4417"}
	var session: RefCounted = Factory.create_fresh_session(recipe, catalog)
	expect(session != null, "fresh legal Studio")
	if session == null:
		quit(1)
		return
	var fixture: Callable = Fixture.factory({"genre": "action", "theme": "fantasy", "name_prefix": "G4 Quote", "selection": "features_first", "hands": {"design": 2, "alpha": 2, "beta": 2}})
	expect(fixture.is_valid(), "current fixture policy")
	if not fixture.is_valid():
		quit(1)
		return
	var quoted_hands := 0
	var seen: Dictionary = {}
	for step in range(30):
		var before_state: String = Replay.digest(session.replay_state())
		var before_rng: Dictionary = session.run.random_streams.snapshot()
		var view: Dictionary = session.observation()
		var phase: String = str(view.phase)
		var current: Dictionary = view.get("development", {})
		var quote_moment: bool = phase in ["design", "alpha"] and current.get("active", false) and not current.get("finalized", false) and not current.get("confirmation_pending", false) and int(current.get("hand_revision", 0)) <= 2
		var repeated: Dictionary = session.observation()
		expect(Replay.digest(session.replay_state()) == before_state, "observation leaves full state unchanged at step %d" % step)
		expect(session.run.random_streams.snapshot() == before_rng, "observation leaves RNG unchanged at step %d" % step)
		expect(repeated == view, "repeated observation is deterministic at step %d" % step)
		var choice: Dictionary = fixture.call(view)
		var matched: Dictionary = {}
		if quote_moment:
			var quotes: Array = current.get("hand_quotes", [])
			expect(quotes.size() == 35, "35 four-card quotes at %s hand %d" % [phase, int(current.hand_revision)])
			var identities: Dictionary = {}
			for quote: Dictionary in quotes:
				var ids: Array = quote.get("candidate_ids", []).duplicate()
				ids.sort()
				identities[str(ids)] = true
				expect(int(quote.get("cost_cents", -1)) >= 0, "nonnegative exact price")
			expect(identities.size() == quotes.size(), "all quote combinations unique")
			var request: Dictionary = choice.get("payload", {}).get("request", {})
			var selected: Array = request.get("payload", {}).get("candidate_ids", []).duplicate()
			selected.sort()
			for quote: Dictionary in quotes:
				var ids: Array = quote.candidate_ids.duplicate()
				ids.sort()
				if ids == selected:
					matched = quote
					break
			expect(not matched.is_empty() and matched.get("cash_preflight_ok", false), "fixture selection has valid cash preflight")
		var result: Dictionary = session.execute(session.command(StringName(choice.type), choice.get("payload", {})))
		expect(result.get("ok", false), "fixture action accepted at step %d" % step)
		if not result.get("ok", false):
			break
		if quote_moment and not matched.is_empty():
			var receipt: Dictionary = {}
			for event: Dictionary in result.get("events", []):
				if event.get("type") == "productive_cycle" and event.has("play_cost_cents"):
					receipt = event
			expect(not receipt.is_empty(), "Feature play receipt exists")
			if not receipt.is_empty():
				expect(int(receipt.play_cost_cents) == int(matched.cost_cents), "quote equals direct play receipt")
				expect(int(receipt.cash_cents) == int(matched.next_cash_cents), "next-cash quote equals settled and serviced cash")
				expect(int(session.run.get_cash_cents()) == int(matched.next_cash_cents), "next-cash quote equals RunState cash")
				print("G4_QUOTE phase=%s hand=%d cost_cents=%d next_cash_cents=%d settlement_cents=%d bills_paid_cents=%d" % [phase, int(current.hand_revision), int(matched.cost_cents), int(matched.next_cash_cents), int(matched.settlement_cents), int(matched.bills_paid_cents)])
			quoted_hands += 1
			seen[phase] = int(seen.get(phase, 0)) + 1
		if seen.get("design", 0) >= 2 and seen.get("alpha", 0) >= 2:
			break
	expect(quoted_hands == 4, "two Design and two Alpha hands audited")
	print("G4_QUOTE_CHECKS %d failures=%d quoted_hands=%d" % [checks, failures, quoted_hands])
	quit(0 if failures == 0 else 1)
