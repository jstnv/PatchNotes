extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const Policy:=preload("res://scripts/market/rival_career_policy.gd")
const Bank:=preload("res://scripts/finance/bank_loan.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func make(id: String,catalog: RefCounted,rival: bool) -> RefCounted:
	var recipe:={"schema_version":1,"studio_id":id,"studio_name":id,"specialty":"action","traits":["family_funding","cult_following"],"seed":"5607"}
	if rival:recipe.rival_founder_profile="rival-founder-active-1977-v2"
	return Factory.create_fresh_session(recipe,catalog)
func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog();var player:=make("ordinary",catalog,false);var before:=Replay.digest(Replay.state(player))
	check(not player.execute(player.command(&"rival_wait")).ok,"ordinary owner rejects calendar command")
	check(Replay.digest(Replay.state(player))==before,"rejected wait preserves complete state/RNG")
	var rival:=make("waiter",catalog,true);var rng: Dictionary=rival.run.random_streams.snapshot()
	for i in range(18):check(rival.execute(rival.command(&"rival_wait")).ok,"real idle tick "+str(i))
	check(rival.run.get_completed_run_cycles()==18 and rival.sequence==18,"one owner/session cycle per tick")
	check(rival.run.random_streams.snapshot()==rng,"idle consumes no RNG")
	check(rival.run.get_cash_cents()==135000,"ordinary nine rent payments")
	check(rival.run._studio_finance.actions[-1].kind==&"calendar" and rival.run._studio_finance.actions[-1].source_id==&"","idle is not project Begin")
	var quote: Dictionary=rival.run.get_bank_quote(150000,24)
	check(quote.get("accepted",false) and quote.floor_facility,"real one-time facility qualifies at low cash")
	check(rival.execute(rival.command(&"bank_borrow",{"quote":quote})).ok,"real loan accepted")
	var policy:=Policy.new(&"action");var expected: int=100000+int(Bank.installment(quote.schedule,1).payment_cents)+int(Bank.installment(quote.schedule,2).payment_cents)
	check(policy._known_dues(rival.run,4)==expected,"runway includes exact known installments")
	before=Replay.digest(Replay.state(rival))
	check(policy._funded_runway(rival.run,preload("res://scripts/market/market_transaction_trial.gd").neutral(),10000,2,4),"bounded ordinary cash-flow scenario")
	check(Replay.digest(Replay.state(rival))==before,"cash-flow forecast preserves all live authority/RNG")
	var debt_corner:=RunState.new();debt_corner._studio_finance=rival.run._studio_finance.duplicate(true);debt_corner._completed_run_cycles=rival.run.get_completed_run_cycles()
	debt_corner._studio_finance.obligations.append({"unpaid_cents":25000})
	check(policy._known_dues(debt_corner,4)==expected+25000,"dues unit: existing unpaid obligations included")
	var active:=make("active",catalog,true)
	check(active.execute(active.command(&"begin_development",{"name":"Corner","genre":"action","theme":"fantasy"})).ok,"legal active project")
	var project_cycle: int=active.development.project.get_current_cycle();var dev_sequence: int=active.development.sequence;rng=active.run.random_streams.snapshot()
	check(active.execute(active.command(&"rival_wait")).ok,"active owner calendar tick")
	check(active.development.project.get_current_cycle()==project_cycle and active.development.sequence==dev_sequence and active.run.random_streams.snapshot()==rng,"idle preserves work sequence/project clock/RNG")
	var view: Dictionary=active.observation();view.phase=&"alpha";view.development.active=true;view.development.can_exit=true;view.development.core={0:1000,1:1000,2:1000,3:1000};view.development.candidates=[{"type":"feature","cost_cents":999999999}]
	var choice: Dictionary=policy.choose(active,view)
	check(choice.type==&"development" and choice.payload.request.type==&"request_exit","policy unit: authoritative full-Scope exit wins over unaffordable finite supply")
	var classifier:=RivalWorld.new();check(classifier._productive_choice({"type":&"rival_wait","payload":{}},active),"wait is productive, never a second free tick")
	var result:={"checks":checks,"failures":failures,"source":Replay.source_identity()};FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("QUALITY_CORNERS "+JSON.stringify(result));quit(0 if failures.is_empty() else 1)
