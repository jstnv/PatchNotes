## Explicitly initialized ownership foundation. No default formation split,
## valuation, external funding source or takeover policy is introduced here.
extends RefCounted

const Ownership := preload("res://scripts/legacy/ownership_book.gd")
const Founder := preload("res://scripts/legacy/founder_profile.gd")
const Victory := preload("res://scripts/legacy/victory_ledger.gd")
const Codec := preload("res://scripts/legacy/legacy_codec.gd")
const Session := preload("res://scripts/simulation/campaign_session.gd")

static func runs(world: RivalWorld) -> Dictionary:
	var result := {str(world.player._bank_run_id):world.player}
	for id in world.studios: result[str(id)] = world.studios[id].run
	return result

static func initialize(world: RivalWorld, founder: Dictionary, books: Dictionary) -> bool:
	if world == null or world.player == null or world._busy or not world.legacy.is_empty(): return false
	var value := {"version":2,"founder":founder.duplicate(true),"books":books.duplicate(true),"offers":{},"events":[],"operator_sequence":0,"victory":Victory.create(founder,world.cycle)}
	if not valid(value,world): return false
	world.legacy=value
	return true

static func valid(value: Dictionary, world: RivalWorld, planned_ledgers: Dictionary = {}) -> bool:
	if typeof(value.get("version"))!=TYPE_INT or value.version not in [1,2] or value.size()!=(7 if value.version==2 else 6) or not value.get("founder") is Dictionary or not value.get("books") is Dictionary or not value.get("offers") is Dictionary or not value.get("events") is Array or typeof(value.get("operator_sequence"))!=TYPE_INT or value.operator_sequence<0: return false
	if not Founder.valid(value.founder) or not Ownership.valid_world(value.books): return false
	if value.version==1:
		for milestone: String in value.founder.milestone_ids:
			if milestone.begins_with("victory:"): return false
	if value.version==2 and (not value.get("victory") is Dictionary or not Victory.valid(value.victory,value.founder,value.events,world.cycle)): return false
	var all := runs(world)
	if value.books.size()!=all.size() or value.founder.active_studio_id!=str(world.player._bank_run_id): return false
	for id in all:
		if not value.books.has(id) or all[id].get_completed_run_cycles()!=world.cycle: return false
	for id in value.founder.career_studio_ids:
		if not all.has(id): return false
	if value.version==2:
		for claim: Dictionary in value.victory.claims:
			# A frozen proof cannot introduce phantom Studios or future transactions.
			if claim.books.size()!=value.books.size(): return false
			for id in claim.books:
				if not value.books.has(id): return false
				var historical: Array=claim.books[id].transaction_ids
				if historical!=value.books[id].transaction_ids.slice(0,historical.size()): return false
	var seen := {}
	for event: Variant in value.events:
		if not event is Dictionary or event.size()!=4 or not event.get("id") is String or event.id.is_empty() or seen.has(event.id) or typeof(event.get("cycle"))!=TYPE_INT or event.cycle<0 or event.cycle>world.cycle or not event.get("target") is String or not all.has(event.target) or not event.get("cash_legs") is Array: return false
		if event.cash_legs.size()!=2: return false
		var sum := 0
		var participants := {}
		for leg: Variant in event.cash_legs:
			if not leg is Dictionary or leg.size()!=2 or not leg.get("holder") is String or not Ownership._valid_holder(leg.holder) or typeof(leg.get("delta_cents"))!=TYPE_INT: return false
			if participants.has(leg.holder) or leg.delta_cents==0: return false
			participants[leg.holder]=true
			if leg.holder.begins_with("studio:"):
				var studio_id: String=leg.holder.substr(7)
				if not all.has(studio_id): return false
				var finance: Dictionary=planned_ledgers[studio_id].ledger if planned_ledgers.has(studio_id) else all[studio_id].get_studio_finance_snapshot()
				var matches := 0
				for action: Dictionary in finance.actions:
					if action.kind==&"ownership_transfer" and str(action.source_id)==event.id:
						if action.cycle!=event.cycle or action.direct_delta!=leg.delta_cents or action.productive: return false
						matches+=1
				if matches!=1: return false
			if leg.delta_cents>0 and sum>Ownership.MAX_INT-leg.delta_cents or leg.delta_cents<0 and sum< -Ownership.MAX_INT-leg.delta_cents: return false
			sum+=int(leg.delta_cents)
		if sum!=0 or not value.books[event.target].transaction_ids.has(event.id): return false
		seen[event.id]=true
	for studio_id in all:
		var finance: Dictionary=planned_ledgers[studio_id].ledger if planned_ledgers.has(studio_id) else all[studio_id].get_studio_finance_snapshot()
		for action: Dictionary in finance.actions:
			if action.kind!=&"ownership_transfer": continue
			if not seen.has(str(action.source_id)): return false
			var matched := false
			for event: Dictionary in value.events:
				if event.id!=str(action.source_id): continue
				for leg: Dictionary in event.cash_legs:
					if leg.holder=="studio:"+studio_id: matched=true
			if not matched: return false
	for book in value.books.values():
		for id in book.transaction_ids:
			if not seen.has(id): return false
	for id in value.offers:
		var offer: Variant=value.offers[id]
		if not offer is Dictionary or offer.size()!=3 or offer.get("kind") not in ["primary","secondary"] or not offer.get("terms") is Dictionary or not offer.get("consents") is Array or offer.terms.get("tx_id")!=id or not offer.terms.get("buyer") is String or not all.has(offer.terms.get("studio_id")): return false
		if not _terms_valid(offer.kind,offer.terms): return false
		var holders := {}
		for holder: Variant in offer.consents:
			if not holder is String or not Ownership._valid_holder(holder) or holders.has(holder): return false
			holders[holder]=true
	return true

static func _terms_valid(kind: String, terms: Dictionary) -> bool:
	var fields := ["studio_id","tx_id","expected_revision","buyer","seller","units","price_cents"] if kind=="secondary" else ["studio_id","tx_id","expected_revision","buyer","investment_cents","pre_money_cents"]
	if terms.size()!=fields.size(): return false
	for field in fields:
		if field in ["studio_id","tx_id","buyer","seller"]:
			if not terms.get(field) is String or terms[field].is_empty(): return false
		elif typeof(terms.get(field))!=TYPE_INT or terms[field]<(0 if field=="expected_revision" else 1): return false
	return true

static func offer(world: RivalWorld, kind: String, terms: Dictionary) -> bool:
	if world._busy or world.legacy.is_empty() or not valid(world.legacy,world) or kind not in ["primary","secondary"]: return false
	if not _terms_valid(kind,terms): return false
	# Funding from outside the modeled Studios needs a future funding source.
	# This slice accepts only a real corporate buyer with conserved cash.
	if not terms.get("buyer") is String or not terms.buyer.begins_with("studio:") or not runs(world).has(terms.buyer.substr(7)): return false
	var request := terms.duplicate(true)
	if kind=="secondary": request.seller_consented=true
	else:
		if not world.legacy.books.has(request.get("studio_id")): return false
		request.affirmative_units=world.legacy.books[request.studio_id].issued_units
	var plan := Ownership.plan_secondary(world.legacy.books,request) if kind=="secondary" else Ownership.plan_primary(world.legacy.books,request)
	if plan.is_empty() or world.legacy.offers.has(request.tx_id): return false
	world.legacy.offers[request.tx_id]={"kind":kind,"terms":terms.duplicate(true),"consents":[]}
	return true

static func consent(world: RivalWorld, offer_id: String, holder: String) -> bool:
	if world._busy or world.legacy.is_empty() or not valid(world.legacy,world) or not world.legacy.offers.has(offer_id): return false
	var pending: Dictionary=world.legacy.offers[offer_id]
	var book: Dictionary=world.legacy.books[pending.terms.studio_id]
	if holder!=pending.terms.buyer and not book.holders.has(holder): return false
	if pending.consents.has(holder): return false
	pending.consents.append(holder)
	return true

static func commit(world: RivalWorld, offer_id: String, player_at_studio: bool = false) -> bool:
	if not player_at_studio or world._busy or world.legacy.is_empty() or not valid(world.legacy,world) or not world.legacy.offers.has(offer_id): return false
	if not world.player.can_mutate_checkpoint(): return false
	var pending: Dictionary=world.legacy.offers[offer_id]
	var request: Dictionary=pending.terms.duplicate(true)
	if not pending.consents.has(request.buyer): return false
	if pending.kind=="secondary": request.seller_consented=pending.consents.has(request.seller)
	else:
		request.affirmative_units=0
		for holder in pending.consents: request.affirmative_units+=int(world.legacy.books[request.studio_id].holders.get(holder,0))
	var plan := Ownership.plan_secondary(world.legacy.books,request) if pending.kind=="secondary" else Ownership.plan_primary(world.legacy.books,request)
	if plan.is_empty(): return false
	var all := runs(world)
	var ledgers := {}
	for leg: Dictionary in plan.cash_legs:
		if not leg.holder.begins_with("studio:"): continue
		var id: String=leg.holder.substr(7)
		if not all.has(id): return false
		var run: RunState=all[id]
		if not run._bank_action_available() or not run.checkpoint_mutations_allowed: return false
		var finance := run.get_studio_finance_snapshot()
		var due := StudioFinanceLedger._unpaid_unchecked(finance)
		if due<0 or (leg.delta_cents<0 and (due>run.get_cash_cents() or -leg.delta_cents>run.get_cash_cents()-due)): return false
		var result := StudioFinanceLedger.plan(finance,world.cycle,run.get_cash_cents(),leg.delta_cents,&"ownership_transfer",0,0,false,StringName(offer_id))
		if result.is_empty(): return false
		ledgers[id]=result
	var next := world.legacy.duplicate(true)
	next.books=plan.books
	next.offers.erase(offer_id)
	next.events.append({"id":offer_id,"cycle":world.cycle,"target":request.studio_id,"cash_legs":plan.cash_legs})
	if next.version==1:
		next.version=2
		next.victory=Victory.create(next.founder,world.cycle)
	var result := Victory.after_ownership_commit(next.victory,next.founder,next.events,next.books,world.cycle,offer_id)
	if result.is_empty(): return false
	next.victory=result.ledger
	next.founder=result.founder
	if not valid(next,world,ledgers): return false
	world._busy=true
	# Publish every cash leg and the cap table before any observer can run.
	for id in ledgers:
		all[id]._studio_finance=ledgers[id].ledger
		all[id]._cash_cents=ledgers[id].cash_cents
		all[id]._publishing_cycle=true
	world.legacy=next
	for id in ledgers:
		all[id].cash_changed.emit()
		all[id].finance_changed.emit()
	for id in ledgers: all[id]._publishing_cycle=false
	world._busy=false
	world.player.finance_changed.emit()
	return true

static func handoff(world: RivalWorld, target_id: StringName, player_at_studio: bool) -> bool:
	if world._busy or not player_at_studio or world.legacy.is_empty() or not valid(world.legacy,world) or not world.studios.has(target_id): return false
	var target: RefCounted=world.studios[target_id]
	if not target.in_studio or target.contract!=null or world.player.get_active_contract()!=null: return false
	# Campaign sessions retain the completed project for inspection after launch.
	# Only a finalized, registered Beta project is safe to leave behind here.
	if target.development!=null and (not target.development.finalized or target.development.phase_index!=2 or target.development.project.get_release_id() not in target.run.get_released_game_ids()): return false
	if StudioCheckpoint.new().capture(world.player).is_empty(): return false
	var founder: Dictionary=world.legacy.founder
	if Ownership.controller(world.legacy.books[str(target_id)])!="founder:"+founder.founder_id: return false
	var departed := Founder.finish_departure(Founder.request_departure(founder,founder.active_studio_id,"voluntary",true),world.cycle,true)
	var moved := Founder.activate(departed,str(target_id),world.cycle,true,true)
	if moved.is_empty(): return false
	var old_id := world.player._bank_run_id
	var former := Session.new()
	former.run=world.player;former.catalog=target.catalog;former.snapshots=target.snapshots
	former.in_studio=true;former.sequence=world.legacy.operator_sequence
	# Preserve titles when a former manual Studio becomes autonomous.
	for id in former.run.get_released_game_ids():
		var meta := former.run.get_release_metadata(id);var sales := former.run.get_released_game_sales(id)
		world.live_releases[id]={"studio_id":old_id,"release_id":id,"release_cycle":int(meta.release_cycle),"title":str(meta.release_title),"genre":StringName(meta.genre),"theme":StringName(meta.theme),"review_tenths":int(sales.review_tenths)}
	world.legacy.operator_sequence=target.sequence
	world.legacy.founder=moved
	world.studios.erase(target_id)
	world.studios[old_id]=former
	world.player=target.run
	return true

static func encode(value: Dictionary) -> Dictionary:
	var result := value.duplicate(true)
	result.version=str(value.version)
	result.founder=_wire(Codec.encode_founder(value.founder))
	for id in value.books: result.books[id]=_wire(Codec.encode_book(value.books[id]))
	result.operator_sequence=str(value.operator_sequence)
	# Generic checked value codec preserves exact integers in arbitrary offer
	# fields without accepting executable objects or resource paths.
	result.offers=_wire(value.offers)
	result.events=_wire(value.events)
	if value.version==2: result.victory=_wire(value.victory)
	return result

static func decode(payload: Dictionary) -> Dictionary:
	if payload.get("version") not in ["1","2"] or payload.size()!=(7 if payload.version=="2" else 6) or not payload.get("founder") is Dictionary or not payload.get("books") is Dictionary: return {}
	if not _wire_valid(payload.get("offers")) or not _wire_valid(payload.get("events")): return {}
	if not _wire_valid(payload.founder) or not _wire_valid(payload.books): return {}
	if payload.version=="2" and (not payload.get("victory") is Dictionary or not _wire_valid(payload.victory)): return {}
	var result := payload.duplicate(true)
	result.version=int(payload.version)
	result.founder=Codec.decode_founder(_unwire(payload.founder))
	if result.founder.is_empty(): return {}
	for id in payload.books:
		if not payload.books[id] is Dictionary: return {}
		result.books[id]=Codec.decode_book(_unwire(payload.books[id]))
		if result.books[id].is_empty(): return {}
	result.operator_sequence=Codec._integer(payload.get("operator_sequence"))
	result.offers=_unwire(payload.get("offers"))
	result.events=_unwire(payload.get("events"))
	if result.version==2: result.victory=_unwire(payload.victory)
	return result

static func _wire_valid(value: Variant) -> bool:
	if value is Array:
		for item in value:
			if not _wire_valid(item): return false
		return true
	if value is Dictionary:
		if value.has("integer"):
			return value.size()==1 and value.integer is String and value.integer.is_valid_int() and str(int(value.integer))==value.integer
		for key in value:
			if not key is String or not _wire_valid(value[key]): return false
		return true
	return value is String or value is bool or value==null

static func _wire(value: Variant) -> Variant:
	if value is int: return {"integer":str(value)}
	if value is Array: return value.map(_wire)
	if value is Dictionary:
		var out := {}
		for key in value: out[key]=_wire(value[key])
		return out
	return value

static func _unwire(value: Variant) -> Variant:
	if value is Array: return value.map(_unwire)
	if value is Dictionary:
		if value.size()==1 and value.has("integer"): return Codec._integer(value.integer)
		var out := {}
		for key in value: out[key]=_unwire(value[key])
		return out
	return value
