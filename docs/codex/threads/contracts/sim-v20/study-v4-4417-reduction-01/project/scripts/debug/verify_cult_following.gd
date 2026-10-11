extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("FAIL: " + label)
func make_run(ids: Array, version: int = 7) -> RunState:
	var run := RunState.new()
	run.initialize_cash_cents(0)
	check(run._commit_studio_creation("Cult trial", &"action", StudioTraits.evaluate_traits(ids, version)), "Creation")
	return run
func _run() -> void:
	var adapter := StudioCheckpoint.new()
	for ids: Array in [[], [&"cult_following"], [&"cult_following", &"studio_buzz"], [&"cult_following", &"family_funding"], [&"cult_following", &"resourceful", &"graduate"], [&"cult_following", &"expensive_lease"], [&"cult_following", &"unknown_name"], [&"cult_following", &"college_dropout"]]:
		var run := make_run(ids)
		var fans := 40 if ids.has(&"cult_following") else 0
		check(run.get_fans() == fans, "Seed in ordinary counter")
		check(run.get_cash_cents() == 550000 + run.get_studio_traits().point_cash_cents + run.get_studio_traits().family_funding_cents, "Exact startup finance")
		if ids == [&"cult_following"]: check(run.get_cash_cents() == 565000 and run.get_studio_traits().spent_points == 1, "Cult one point / 5650")
		var payload := adapter.capture(run)
		check(not payload.is_empty(), "Creation checkpoint: " + adapter.error)
		check(not run.create_studio_with_traits("Duplicate", &"action", ids) and adapter.capture(run) == payload, "Duplicate confirmation atomic")
		for field: String in ["fans", "seed"]:
			var bad := payload.duplicate(true)
			bad.run.fanbase[field] = "999"
			check(not adapter.validate(bad).is_empty(), "Reject injected " + field)
		var bad := payload.duplicate(true)
		bad.run.studio_traits.version = "8"
		check(not adapter.validate(bad).is_empty(), "Reject unknown version")
		bad = payload.duplicate(true); bad.content_revision = adapter._rules_revision(StudioCheckpoint.PRE_CULT_RULES)
		check(not adapter.validate(bad).is_empty(), "New traits cannot masquerade as old content")
		check(run.complete_productive_action() and run.complete_productive_action(), "Two journaled no-sales productive actions")
		check(run.get_fans() == fans and run.get_cash_cents() == int(payload.run.cash_cents) - (51500 if ids.has(&"expensive_lease") else 50000), "No recurring Fans; actual rent")
		check(not adapter.capture(run).is_empty(), "Post-rent replay checkpoint")
	for version in [3,4,5,6]:
		var old := make_run([&"cult_following"],version)
		check(old.get_fans() == 0 and old.get_cash_cents() == 570000 and not StudioTraits.is_active(old.get_studio_traits(), &"cult_following"), "Historical Cult stays preview")
		var payload := adapter.capture(old)
		payload.content_revision = adapter._rules_revision(StudioCheckpoint.PRE_CULT_RULES)
		var restored := adapter.hydrate(payload)
		check(restored != null and restored.get_fans() == 0 and restored.get_cash_cents() == 570000, "Old revision preserves previews")
		for revision: String in adapter._legacy_revisions(StudioCheckpoint.PRE_CULT_RULES):
			var legacy := payload.duplicate(true); legacy.content_revision = revision
			check(adapter.hydrate(legacy) != null, "Historical audio-credit hash preserves inactive Cult")
		var bad := payload.duplicate(true); bad.run.studio_traits.version = "7"
		check(not adapter.validate(bad).is_empty(), "Reject retroactive version activation")
	var fresh := RunState.new(); fresh.initialize_cash_cents(0)
	for invalid: Array in [[&"cult_following", &"cult_following"], [&"cult_following", &"studio_buzz", &"family_funding"], [&"cult_following", &"graduate", &"unknown_name"]]:
		check(not fresh.create_studio_with_traits("Bad", &"action", invalid) and fresh.get_fans() == 0 and fresh.get_cash_cents() == 0 and fresh.get_studio_traits().is_empty(), "Invalid confirmation atomic")
	# Constructed domain cases isolate neutrality and loss; native routes supply legal launches.
	for review in [50,40,0,70]:
		var ledger := StudioFanbase.create(40)
		var sale := ReleasedGameSales.create(&"trial", 500, review, 10, 10000)
		ledger = StudioFanbase.register_release(ledger, sale, 40)
		var records := {&"trial":sale}
		for cycle in range(1,5):
			var next := {&"trial":ReleasedGameSales.next_cycle(records.trial,cycle,cycle % 2 == 0)}
			ledger = StudioFanbase.plan(ledger, records, next, cycle); records = next
		check(ledger.fans == 40 if review == 50 else (ledger.fans < 40 if review < 50 else ledger.fans > 40), "Seed obeys normal monthly gain/loss and neutrality")
		check(ledger.months[1].lost == 0, "Already-accounted exposure not charged again")
	print("CULT T8 checks=",checks," failures=",failures)
	quit(failures)
