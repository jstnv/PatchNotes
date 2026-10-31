## Controlled mechanics regression; not a funded career.
extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Dev=preload("res://scripts/simulation/development_session.gd")
const Codec=preload("res://scripts/market/rival_world_checkpoint.gd")
const Policy=preload("res://scripts/market/rival_career_policy.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"pb-regression","studio_name":"PB Regression","specialty":"action","traits":[],"seed":"4417"},catalog)
	var project:=ProjectState.new(30)
	check(project.configure_predevelopment("Regression",&"action",&"fantasy",session.run.get_future_project_feature_ids()),"Valid project identity")
	var dev:=Dev.new();check(dev.initialize(project,session.run,catalog,session.snapshots),"Real shared development initializes")
	session.development=dev;session.in_studio=false
	dev.hand._budget_printed=8;dev.hand._budget_spent=1
	var snapshot: Dictionary=Codec.new()._snapshot_development(session)
	var budget: Dictionary=snapshot.get("pass_budget",{})
	check(budget.get("printed",-1)==8 and budget.get("spent",-1)==1,"Active owner checkpoint persists exact Pass counters")
	check(dev.observation().has("pass_budget"),"Decision observation exposes available budget without future RNG")
	# Small fully scoped Alpha with no remaining legal hand; exact scope is a
	# controlled fixture to isolate the exit decision, not balance evidence.
	project.add_core_scores_and_scope({} as Dictionary[ProjectState.CoreScore,int],30,0)
	project.finalize_design_bugs(false,0,[&"text"] as Array[StringName],[] as Array[StringName])
	dev.phase_index=1;dev._create_phase(false);dev.hand.active=true
	dev.hand._candidate_cards.clear();dev.hand.candidate_ids.clear();dev.hand._available_features.clear();dev.hand._budget_spent=2
	var view: Dictionary=dev.observation()
	check(view.can_exit,"Exhausted Alpha can legally finish")
	var policy:=Policy.new();var decision: Dictionary=policy.choose(session,{"phase":&"alpha","project_id":project.get_release_id(),"development":view,"releases":[]})
	check(decision.get("type")==&"development" and decision.get("payload",{}).get("request",{}).get("type")==&"request_exit","Rival exits exhausted Alpha instead of borrowing/waiting for unattainable Review")
	# A stranded final Feature cannot by itself make the required four-card hand.
	session.run._rival_founder_profile=&"rival-founder-active-1977-v2"
	dev.hand._available_features.assign([catalog.get_card(&"main_theme")] as Array[CardData])
	check(dev.actions.can_finalize(),"Whole-supply gate accounts for complete feasible hand, not lone affordable card")
	var output:=OS.get_cmdline_user_args()[0].trim_prefix("--output=")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity()},"\t"))
	print("PB_REGRESSION ",checks," ",failures);quit(0 if failures.is_empty() else 1)
