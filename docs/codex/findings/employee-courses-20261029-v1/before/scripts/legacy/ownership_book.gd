## Pure corporate ownership planner. A plan is not a committed transaction:
## its cash legs must be settled with Studio finance in the same world commit.
extends RefCounted

const MAX_INT: int = 9223372036854775807

static func create(studio_id: String, holders: Dictionary) -> Dictionary:
	var book := {"studio_id": studio_id, "revision": 0, "issued_units": 0, "holders": holders.duplicate(true), "transaction_ids": []}
	for units in holders.values():
		if typeof(units) != TYPE_INT or units < 0 or units > MAX_INT - book.issued_units: return {}
		book.issued_units += units
	return book if valid(book) else {}

static func valid(book: Dictionary) -> bool:
	if book.size()!=5: return false
	if typeof(book.get("studio_id")) != TYPE_STRING or book.studio_id.is_empty(): return false
	if typeof(book.get("revision")) != TYPE_INT or book.revision < 0: return false
	if typeof(book.get("issued_units")) != TYPE_INT or book.issued_units <= 0: return false
	if typeof(book.get("holders")) != TYPE_DICTIONARY or typeof(book.get("transaction_ids")) != TYPE_ARRAY: return false
	var total := 0
	for holder in book.holders:
		if typeof(holder) != TYPE_STRING or not _valid_holder(holder) or holder == "studio:" + book.studio_id: return false
		var units: Variant = book.holders[holder]
		if typeof(units) != TYPE_INT or units <= 0 or units > MAX_INT - total: return false
		total += units
	var seen := {}
	for tx_id in book.transaction_ids:
		if typeof(tx_id) != TYPE_STRING or tx_id.is_empty() or seen.has(tx_id): return false
		seen[tx_id] = true
	return total == book.issued_units

static func valid_world(books: Dictionary) -> bool:
	for studio_id in books:
		if typeof(studio_id) != TYPE_STRING or typeof(books[studio_id]) != TYPE_DICTIONARY: return false
		if not valid(books[studio_id]) or books[studio_id].studio_id != studio_id: return false
		for holder in books[studio_id].holders:
			if holder.begins_with("studio:") and not books.has(holder.substr(7)): return false
	var visiting := {}
	var visited := {}
	for studio_id in books:
		if not _acyclic(studio_id, books, visiting, visited): return false
	return true

static func controller(book: Dictionary) -> String:
	if not valid(book): return ""
	for holder in book.holders:
		if book.holders[holder] > book.issued_units / 2: return holder
	return ""

static func plan_secondary(books: Dictionary, request: Dictionary) -> Dictionary:
	if not valid_world(books) or not _common_request(request): return {}
	if not books.has(request.studio_id) or _transaction_used(books, request.tx_id): return {}
	for field in ["seller", "buyer", "units", "price_cents", "seller_consented"]:
		if not request.has(field): return {}
	if typeof(request.seller) != TYPE_STRING or typeof(request.buyer) != TYPE_STRING or not _valid_holder(request.seller) or not _valid_holder(request.buyer) or request.seller == request.buyer: return {}
	if typeof(request.units) != TYPE_INT or typeof(request.price_cents) != TYPE_INT or typeof(request.seller_consented) != TYPE_BOOL: return {}
	if request.units <= 0 or request.price_cents <= 0 or not request.seller_consented: return {}
	var original: Dictionary = books[request.studio_id]
	if not _fresh(original, request) or int(original.holders.get(request.seller, 0)) < request.units: return {}
	var candidate: Dictionary = original.duplicate(true)
	candidate.holders[request.seller] -= request.units
	if candidate.holders[request.seller] == 0: candidate.holders.erase(request.seller)
	var prior: int = candidate.holders.get(request.buyer, 0)
	if prior > MAX_INT - request.units: return {}
	candidate.holders[request.buyer] = prior + request.units
	candidate.revision += 1
	candidate.transaction_ids.append(request.tx_id)
	var new_world := books.duplicate(true)
	new_world[request.studio_id] = candidate
	if not valid_world(new_world): return {}
	return {"books": new_world, "cash_legs": _secondary_legs(request), "transaction_id": request.tx_id,
		"target_studio_id": request.studio_id, "issued_units": candidate.issued_units,
		"controller_before": controller(original), "controller_after": controller(candidate)}

static func plan_primary(books: Dictionary, request: Dictionary) -> Dictionary:
	if not valid_world(books) or not _common_request(request): return {}
	if not books.has(request.studio_id) or _transaction_used(books, request.tx_id): return {}
	for field in ["buyer", "investment_cents", "pre_money_cents", "affirmative_units"]:
		if not request.has(field): return {}
	if typeof(request.buyer) != TYPE_STRING or not _valid_holder(request.buyer): return {}
	for field in ["investment_cents", "pre_money_cents", "affirmative_units"]:
		if typeof(request[field]) != TYPE_INT: return {}
	if request.investment_cents <= 0 or request.pre_money_cents <= 0: return {}
	var original: Dictionary = books[request.studio_id]
	if not _fresh(original, request) or request.affirmative_units <= original.issued_units / 2 or request.affirmative_units > original.issued_units: return {}
	if original.issued_units > MAX_INT / request.investment_cents: return {}
	var numerator: int = original.issued_units * request.investment_cents
	var units := _round_nearest_even(numerator, request.pre_money_cents)
	if units <= 0 or units > MAX_INT - original.issued_units or request.investment_cents > MAX_INT - request.pre_money_cents: return {}
	var candidate: Dictionary = original.duplicate(true)
	var prior: int = candidate.holders.get(request.buyer, 0)
	if prior > MAX_INT - units: return {}
	candidate.holders[request.buyer] = prior + units
	candidate.issued_units += units
	candidate.revision += 1
	candidate.transaction_ids.append(request.tx_id)
	var new_world := books.duplicate(true)
	new_world[request.studio_id] = candidate
	if not valid_world(new_world): return {}
	return {"books": new_world, "cash_legs": _primary_legs(request), "transaction_id": request.tx_id,
		"target_studio_id": request.studio_id, "new_units": units, "pre_money_cents": request.pre_money_cents,
		"post_money_cents": request.pre_money_cents + request.investment_cents,
		"controller_before": controller(original), "controller_after": controller(candidate)}

static func _common_request(request: Dictionary) -> bool:
	for field in ["studio_id", "tx_id", "expected_revision"]:
		if not request.has(field): return false
	return typeof(request.studio_id) == TYPE_STRING and not request.studio_id.is_empty() and typeof(request.tx_id) == TYPE_STRING and not request.tx_id.is_empty() and typeof(request.expected_revision) == TYPE_INT

static func _fresh(book: Dictionary, request: Dictionary) -> bool:
	return book.revision < MAX_INT and book.revision == request.expected_revision and not book.transaction_ids.has(request.tx_id)

static func _transaction_used(books: Dictionary, tx_id: String) -> bool:
	for book in books.values():
		if book.transaction_ids.has(tx_id): return true
	return false

static func _valid_holder(holder: String) -> bool:
	for prefix in ["founder:", "studio:", "outside:"]:
		if holder.begins_with(prefix) and holder.length() > prefix.length(): return true
	return false

static func _acyclic(studio_id: String, books: Dictionary, visiting: Dictionary, visited: Dictionary) -> bool:
	if visiting.has(studio_id): return false
	if visited.has(studio_id): return true
	visiting[studio_id] = true
	for holder in books[studio_id].holders:
		if holder.begins_with("studio:") and not _acyclic(holder.substr(7), books, visiting, visited): return false
	visiting.erase(studio_id)
	visited[studio_id] = true
	return true

static func _round_nearest_even(numerator: int, denominator: int) -> int:
	var quotient: int = numerator / denominator
	var remainder: int = numerator % denominator
	if remainder > denominator / 2 or (denominator % 2 == 0 and remainder == denominator / 2 and quotient % 2 == 1): return quotient + 1
	return quotient

static func _secondary_legs(request: Dictionary) -> Array:
	return [{"holder": request.buyer, "delta_cents": -request.price_cents}, {"holder": request.seller, "delta_cents": request.price_cents}]

static func _primary_legs(request: Dictionary) -> Array:
	return [{"holder": request.buyer, "delta_cents": -request.investment_cents}, {"holder": "studio:" + request.studio_id, "delta_cents": request.investment_cents}]
