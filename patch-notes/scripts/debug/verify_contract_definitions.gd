extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _run() -> void:
	var ids := ContractDefinitions.built_in_ids()
	check(ids.size() == 6 and ids.has(ContractState.CONTRACT_ID) and ids.has(ContractState.SIDESTREET_CONTRACT_ID) and ids.has(ContractDefinitions.SIDESTREET_BRIEF), "All five cash Contract IDs plus the separate approved Brief remain registered")
	for id in ids:
		var found := ContractDefinitions.definition(id)
		check(not found.is_empty() and ContractDefinitions.is_valid_definition(found), "Valid closed definition " + str(id))
		check(ContractDefinitions.required_hands(id) == (3 if id == PublisherTrialTerms.STARWAVE else 2), "Hand count preserved " + str(id))
		var original := found.duplicate(true)
		found.score.scope_cap = 999
		found.stored_terms.clear()
		check(ContractDefinitions.definition(id) == original, "Definition caller cannot mutate registry " + str(id))
	check(ContractDefinitions.definition(&"unsupported_contract").is_empty() and ContractDefinitions.evaluate(&"unsupported_contract", 0, {0:0,1:0,2:0,3:0}).is_empty(), "Unknown Contract rejects")
	var malformed := ContractDefinitions.definition(PublisherTrialTerms.CROWN)
	malformed.denominator = 1
	check(not ContractDefinitions.is_valid_definition(malformed), "Inconsistent score denominator rejects")
	check(PublisherTrialTerms.terms(PublisherTrialTerms.CROWN) == {"scope":9,"cash_cents":192000,"advance_cents":15000,"promotion":12,"denominator":66}, "Crown serialized terms unchanged")
	check(PublisherTrialTerms.terms(PublisherTrialTerms.NEON) == {"scope":10,"cash_cents":156000,"advance_cents":0,"promotion":20,"denominator":86}, "Neon serialized terms unchanged")
	check(PublisherTrialTerms.terms(PublisherTrialTerms.STARWAVE) == {"scope":14,"cash_cents":224000,"advance_cents":0,"promotion":0,"denominator":112,"required_hands":3}, "Starwave serialized terms unchanged")
	var zero := {0:0,1:0,2:0,3:0}
	check(ContractDefinitions.evaluate(ContractDefinitions.IRONCLAD, 12, {0:12,1:12,2:12,3:12}).payout_cents == 240000, "Ironclad full cash preserved")
	check(ContractDefinitions.evaluate(ContractDefinitions.IRONCLAD, 0, zero, -1, 55000).payout_cents == 55000, "Publisher Connections advance override preserved")
	check(ContractDefinitions.evaluate(ContractDefinitions.SIDESTREET, 12, {0:12,1:12,2:12,3:12}).payout_cents == 120000, "SideStreet full cash preserved")
	check(ContractDefinitions.evaluate(PublisherTrialTerms.CROWN, 9, {0:8,1:8,2:8,3:8}).payout_cents == 192000, "Crown full cash preserved")
	check(ContractDefinitions.evaluate(PublisherTrialTerms.NEON, 10, {0:18,1:4,2:4,3:4}, 0).promotion == 20, "Neon full Promotion preserved")
	check(ContractDefinitions.evaluate(PublisherTrialTerms.STARWAVE, 14, {0:14,1:14,2:14,3:14}).payout_cents == 224000, "Starwave full cash preserved")
	check(ContractDefinitions.evaluate(PublisherTrialTerms.NEON, 10, zero).is_empty(), "Neon without a frozen focus rejects")
	check(ContractDefinitions.evaluate(PublisherTrialTerms.CROWN, -1, zero).is_empty(), "Negative Scope rejects")
	check(ContractDefinitions.evaluate(PublisherTrialTerms.CROWN, 0, {0:0,1:0,2:0}).is_empty(), "Incomplete Core map rejects")
	check(ContractDefinitions.evaluate(PublisherTrialTerms.CROWN, 0, {0:0,1:0,2:0,3:-1}).is_empty(), "Negative Core rejects")
	print("Contract definition foundation: %d failures" % failures)
	quit(0 if failures == 0 else 1)
