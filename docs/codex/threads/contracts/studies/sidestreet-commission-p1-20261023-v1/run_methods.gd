func has_pending_commission() -> bool:
	for deal: Dictionary in _commission_deals.values():
		if deal.result == null: return true
	return false

func get_commission_quote(base_name: String = "", genre: StringName = &"", theme: StringName = &"") -> Dictionary:
	if base_name.is_empty() or _bank_run_id.is_empty() or not _first_studio_economy or _released_games.is_empty() or has_pending_commission() or get_active_contract() != null or _productive_cycle_in_progress or _publishing_cycle or _feature_purchase_in_progress or _relationship_commit_in_progress or next_project_serial == MAX_SIGNED_INT: return {}
	if not PrimitivePredevelopment.validation_error(base_name,genre,theme).is_empty(): return {}
	var standing := get_publisher_relationships()
	if standing.is_empty() or standing[&"sidestreet"].reputation_bp < 2000: return {}
	var project := PrimitivePredevelopment.prepare_project(base_name,genre,theme,self)
	if project == null or project.get_required_scope() <= 0: return {}
	var id := StringName("%s:project:%d" % [_bank_run_id,next_project_serial])
	return {"version":1,"studio_id":_bank_run_id,"publisher_id":&"sidestreet","quote_id":StringName(str(id)+":commission"),"project_id":id,"source_release_id":get_released_game_ids()[-1],"accept_cycle":_completed_run_cycles,"base_name":project.get_base_name(),"genre":genre,"theme":theme,"required_scope":project.get_required_scope(),"fee_cents":Commission.FEE,"review_target_tenths":60,"owner":&"publisher"}

func can_bind_commission_quote(quote: Dictionary, project: ProjectState) -> bool:
	if project == null or not Commission.valid_terms(quote,_bank_run_id): return false
	return quote == get_commission_quote(project.get_base_name(),project.get_genre_id(),project.get_theme_id()) and project.get_release_id() == quote.project_id and project.get_required_scope() == quote.required_scope

func _bind_commission(quote: Dictionary) -> bool:
	if not _productive_cycle_in_progress or _publishing_cycle or has_pending_commission() or _commission_deals.has(quote.project_id): return false
	_commission_deals[quote.project_id] = {"terms":quote.duplicate(true),"result":null}
	return true

func _plan_commission_release(project: ProjectState) -> Dictionary:
	var id := project.get_release_id()
	if not _commission_deals.has(id): return {"applicable":false}
	var deal: Dictionary = _commission_deals[id].duplicate(true)
	if deal.result != null: return {}
	var meta := {"base_name":project.get_base_name(),"genre":project.get_genre_id(),"theme":project.get_theme_id(),"release_cycle":_completed_run_cycles,"review":_capture_release_review(project),"owner":&"publisher","publisher_id":&"sidestreet","commission_quote_id":deal.terms.quote_id}
	deal.result = Commission.result(deal.terms,meta,id)
	if deal.result.is_empty(): return {}
	var finance := StudioFinanceLedger.plan(_studio_finance,_completed_run_cycles,_cash_cents,deal.result.fee_paid_cents,&"publisher_receipt",0,0,false,deal.terms.quote_id)
	if finance.is_empty(): return {}
	var staged := Commission.data(self).duplicate(true)
	staged.commission_deals[id] = deal
	staged.release_metadata[id] = meta
	staged.released_games[id] = _create_release_sales_record(project)
	staged.studio_finance = finance.ledger
	var request := Commission.request_for(staged,id)
	if request.is_empty(): return {}
	var resolver := func(source: Dictionary) -> Dictionary:
		return Commission.resolve(staged,source) if source.get("kind") == Commission.KIND else RelationshipRules.resolve(self,source)
	var relationship := RelationshipLedger.plan(_publisher_relationships,_bank_run_id,request,_completed_run_cycles,resolver)
	if relationship.is_empty(): return {}
	return {"applicable":true,"deal":deal,"finance":finance.ledger,"relationships":relationship.ledger}

func get_commission_deals() -> Dictionary:
	return _commission_deals.duplicate(true)

