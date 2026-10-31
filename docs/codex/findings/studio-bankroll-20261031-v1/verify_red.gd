extends SceneTree
var issues: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:issues.append(label)
func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted=load("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"cleanup-red","studio_name":"Cleanup","specialty":"action","traits":[],"seed":"4417"},catalog)
	var studio: StudioPhase=load("res://scenes/phases/studio_phase.tscn").instantiate()
	check(studio.setup(null,session.run,session.snapshots),"Studio fixture")
	root.add_child(studio);await process_frame
	check(studio.get_node_or_null("%MarketInfoButton")!=null,"Market Info groups the root actions")
	check(studio.get_node_or_null("%StartProductionButton")!=null,"Start Production group exists")
	check(studio.has_method("get_live_rival_rows"),"Rival Info has a live-only projection")
	var beta: BetaPhase=load("res://scenes/phases/beta_phase.tscn").instantiate();root.add_child(beta)
	check(beta.get_node("%LaunchWarningDialog").get_script()==load("res://scripts/ui/quit_confirmation.gd"),"Launch warning uses shared menu")
	var ledger:=StudioFinanceLedger.create(0)
	for cycle in [1,2]:ledger=StudioFinanceLedger.plan(ledger,cycle,0,0,&"calendar",0,0,true).ledger
	check(not StudioFinanceLedger.plan(ledger,3,0,0,&"contract_hand",0,0,true,&"recovery").is_empty(),"Zero-cash Contract can work through existing bills")
	check(not StudioFinanceLedger.plan(ledger,3,0,10000,&"contract_receipt",0,0,true,&"recovery").is_empty(),"Partial Contract payout remains payable in arrears")
	check(StudioFinanceLedger.plan(ledger,3,0,0,&"development",0,0,true).is_empty(),"Ordinary production arrears guard remains")
	check(ResourceLoader.exists("res://scripts/ui/cash_feedback.gd"),"Cash feedback presentation exists")
	var path:=""
	for item: String in OS.get_cmdline_user_args():
		if item.begins_with("--output="):path=item.trim_prefix("--output=")
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":issues},"\t"))
	print("CLEANUP_RED "+JSON.stringify({"checks":checks,"failures":issues}))
	beta.free();studio.free();quit(0 if issues.is_empty() else 1)
