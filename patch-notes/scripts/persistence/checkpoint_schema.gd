class_name CheckpointSchema
extends RefCounted

## All schemas originate in code. Disk records cannot select constructors or
## supply a schema. Alternative records are a closed, trusted union.
static func fields(names: String, kind: String = "uint") -> Dictionary:
	var result := {}
	for key in names.split(" ", false): result[key] = kind
	return result

static func array_of(item: Variant) -> Dictionary: return {"array":item}
static func map_of(key: Variant, value: Variant) -> Dictionary: return {"map":[key,value]}
static func optional(item: Variant) -> Dictionary: return {"nullable":item}
static func union_of(items: Array) -> Dictionary: return {"one_of":items}

static func finance() -> Dictionary:
	var schedule := fields("schema_version principal_cents term_months accepted_cycle first_due_cycle last_due_cycle maximum_installment_cents total_interest_cents total_payment_cents")
	var quote := fields("older_sales_cents latest_sales_cents basis_cents rent_cents obligations_cents capacity_cents maximum_principal_cents revision")
	quote.merge(fields("eligible accepted", "bool"))
	quote.merge(fields("run_id loan_id quote_id", "id"))
	quote.reason = "text"
	quote.schedule = schedule
	var hire := fields("revision fee_cents wage_cents hire_cycle first_due_cycle")
	hire.merge(fields("type run_id employee_id", "id"))
	var payoff := fields("revision principal_cents interest_cents total_cents")
	payoff.merge(fields("type loan_id", "id"))
	var action := fields("cycle cash_before sales_earned settled")
	action.direct_delta = "int"
	action.merge(fields("kind source_id", "id"))
	action.productive = "bool"
	var ordinary_action := action.duplicate(true)
	action.operation = union_of([{}, {"type":"id","quote":quote}, hire, payoff])
	var transaction := fields("sequence cycle month amount_cents cash_before_cents cash_after_cents due_month")
	transaction.cash_delta_cents = "int"
	transaction.merge(fields("kind source_id", "id"))
	var row := fields("month")
	for key in StudioFinanceLedger.NONNEGATIVE_ROW_FIELDS: row[key] = "uint"
	row.merge(fields("cash_change_cents net_profit_cents", "int"))
	row.partial = "bool"
	var bill := fields("month due_cycle due_cents paid_cents unpaid_cents")
	bill.merge(fields("bill_id source_id expense_type", "id"))
	bill.merge(fields("settled_cycle recovery_overdue_cycles", "int"))
	bill.merge(fields("paid_on_time late", "bool"))
	bill.payments = array_of(fields("cycle month cents"))
	var bank_bill := bill.duplicate(true)
	bank_bill.merge(fields("principal_cents interest_cents principal_paid_cents interest_paid_cents"))
	var reason := fields("due_cycle evaluated_cycle overdue_cycles")
	reason.merge(fields("type bill_id", "id"))
	reason.points = "int"
	reason.recovered = "bool"
	var history := fields("month cycle before after")
	history.merge(fields("operating_profit_cents requested_change change", "int"))
	history.policy_version = "text"
	history.reasons = array_of(union_of([reason,{"type":"id","points":"int"}]))
	var credit := fields("score last_processed_month")
	credit.policy_version = "text"
	credit.history = array_of(history)
	var loan := fields("issued principal_paid_cents interest_paid_cents")
	loan.merge(fields("loan_id run_id quote_id", "id"))
	loan.merge(fields("closed early_payoff", "bool"))
	loan.closed_cycle = "int"
	loan.schedule = schedule
	var employee := fields("wage_cents hire_cycle first_due_cycle issued")
	employee.employee_id = "id"
	var result := fields("schema_version initial_cash_cents monthly_rent_cents last_cycle cash_cents unsettled_sales_net_cents")
	result.merge({"monthly_rows":array_of(row),"obligations":array_of(union_of([bill,bank_bill])),"transactions":array_of(transaction),"actions":array_of(union_of([ordinary_action,action])),"credit":credit,"bank_loans":array_of(loan),"employees":array_of(employee)})
	return result

static func employees() -> Dictionary:
	var hand := fields("project_cycle cycle")
	hand.merge(fields("type project_id phase", "id"))
	hand.cards = array_of(fields("id type primary secondary", "id"))
	hand.before = map_of("uint","uint")
	hand.proposed = map_of("uint","uint")
	var employee := fields("employee_id owner type", "id")
	employee.hire_cycle = "uint"
	employee.trained = "bool"
	employee.projects = map_of("id", {"trained_action":"id","used_action":"id","actions":array_of("id")})
	return {"schema_version":"uint","owner":"id","employees":map_of("id",employee),"events":array_of(union_of([{"type":"id","employee_id":"id","cycle":"uint"},hand]))}

static func sales() -> Dictionary:
	var result := fields("total_units earned_cycles total_earned_cycles earned_units entitlement_cents settled_cents campaign_count organic_awareness_scaled active_awareness_scaled monthly_units release_year")
	result.merge(fields("last_processed_run_cycle last_settlement_run_cycle review_tenths launch_awareness market_bp", "int"))
	result.merge(fields("exhausted later_enabled", "bool"))
	result.merge(fields("base_name release_title", "text"))
	result.release_id = "id"
	result.campaign_months = map_of("uint","uint")
	return result

static func metadata() -> Dictionary:
	var review := fields("scope required_scope development_cycles remaining_bugs awareness launch_marketing projected_units projected_gross_cents projected_net_cents")
	review.merge(fields("final_review production_rating scope_completion", "float"))
	review.cores = array_of("uint")
	review.standards = array_of("uint")
	review.merge(fields("forecast_id competitor_id", "id"))
	review.forecast_multiplier = "text"
	review.competitor_target_cycle = "int"
	return {"base_name":"text","genre":"id","theme":"id","genre_ratios":array_of("uint"),"release_title":"text","release_year":"uint","release_cycle":"uint","review":review}

static func contract() -> Dictionary:
	return {"publisher_connections":"bool","contract_id":"id","offer_id":"id","source_release_id":"id","eligible":map_of("id","bool"),"scope":"uint","cores":map_of("uint","uint"),"hands":"uint","exhausted":map_of("id","bool"),"priorities":map_of("uint","uint"),"upfront":"bool","paid":"bool","trial_terms":union_of([{},fields("scope cash_cents advance_cents promotion denominator")]),"neon_focus":"int","result":{"scope":"uint","cores":map_of("uint","uint"),"numerator":"uint","payout":"uint","remainder":"uint","upfront":"uint","denominator":"uint","promotion":"uint"}}

static func root() -> Dictionary:
	var traits := fields("version starting_points spent_points refunded_points remaining_points point_cash_cents family_funding_cents")
	traits.merge({"valid":"bool","reason":"text","trait_ids":array_of("id"),"active_ids":array_of("id"),"effects_mode":"id"})
	var run := fields("cash_cents completed_run_cycles available_redraws next_project_serial")
	run.merge(fields("cash_initialized first_studio_economy starter_selection_confirmed ironclad_completion_committed", "bool"))
	run.studio_name = "text"
	run.merge(fields("studio_specialty first_tutorial_project_id bank_run_id", "id"))
	for key in ["owned_features","unlocked_publishers","seen_tutorial_topics"]: run[key] = map_of("id","bool")
	run.resourceful_claims = map_of("uint","id")
	run.feature_research = array_of(FeatureResearch.schema())
	run.familiarity = map_of("id","uint")
	run.credited_projects = map_of("id",map_of("id","bool"))
	run.released_games = map_of("id",sales())
	run.release_metadata = map_of("id",metadata())
	run.primitive_contract = optional(contract())
	run.publisher_offers = map_of("id",{"publisher_id":"id","source_release_id":"id","state":optional(contract())})
	run.promotion_awards = map_of("id","uint")
	run.promotion_consumed = map_of("id","id")
	run.sidestreet_entitlements = map_of("id",{"offer_id":"id","state":optional(contract())})
	run.sidestreet_results = map_of("id",{"offer_id":"id","release_id":"id","scope":"uint","core_half_units":map_of("uint","uint"),"completion_numerator":"uint","payout_cents":"uint"})
	run.pending_publisher_notifications = array_of("id")
	run.studio_traits = union_of([{},traits])
	run.lean_savings = map_of("id","uint")
	run.first_game_tutorial = optional({"stage":"uint","first_stat":"id","second_stat":"id","first_pool_published":"bool","second_pool_published":"bool"})
	run.studio_finance = finance()
	run.employees = employees()
	return {"checkpoint_kind":"text","run_id":"id","sequence":"uint","source_build":"text","content_revision":"text","rng_algorithm":"text","run":run,"rng":map_of("id",{"seed":"int","state":"int"})}
