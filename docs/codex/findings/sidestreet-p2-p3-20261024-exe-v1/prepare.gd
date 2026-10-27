extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Finite := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var args: PackedStringArray
var guide: Array=[]
var stages: Array=[]
class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null:return true
		_writer=TCPServer.new()
		return _writer.listen(47733,"127.0.0.1")==OK
func _initialize() -> void: execute.call_deferred()
func save_boundary(session: RefCounted,label: String) -> void:
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(session.run)
	assert(not payload.is_empty())
	var store := PrivateStore.new(args[0]+"/"+label,adapter.validate)
	var saved := store.save(payload)
	assert(saved.status==&"saved",str(saved))
	store.release_writer()
	FileAccess.open(args[0]+"/"+label+".state.json",FileAccess.WRITE).store_string(JSON.stringify(payload))
	stages.append({"label":label,"step":guide.size(),"cycle":session.run.get_completed_run_cycles(),"cash":session.run.get_cash_cents(),"releases":session.run.get_released_game_ids().size(),"relationships":session.observation().publisher_relationships,"save":saved.path})
func execute() -> void:
	args=OS.get_cmdline_user_args()
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var recipe := {"schema_version":1,"studio_id":"commission-p1-sports-1112","studio_name":"Commission sports-1112","specialty":"sports","traits":[],"seed":"1112"}
	var session := Factory.create_fresh_session(recipe,catalog)
	var tape := Replay.begin(session)
	var prefix: RefCounted=load(args[1]).new()
	prefix.cfg={"arm":"balanced","label":"direct-exe-three-release","development_first":{"genre":"sports","theme":"fantasy","name_prefix":"Commission Study","selection":"features_first","hands":{"design":3,"alpha":5,"beta":4}},"development_later":{"genre":"sports","theme":"fantasy","name_prefix":"Commission Study","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}}}
	prefix.first=Finite.factory(prefix.cfg.development_first);prefix.later=Finite.factory(prefix.cfg.development_later)
	var full: RefCounted=load(args[2]).new()
	full.cfg={"label":"direct-exe-three-release","research":["maps","sprites","general_combat"],"commission":true,"development":{"genre":"sports","theme":"fantasy","name_prefix":"Scope Gate","selection":"features_first","hands":{"design":5,"alpha":7,"beta":6}}}
	full.play=Finite.factory(full.cfg.development)
	var prebrief := false
	var prequote := false
	var postcommission := false
	for index in range(350):
		var view: Dictionary=session.observation()
		var releases: int=view.releases.size()
		var reputation: int=view.get("publisher_relationships",{}).get(&"sidestreet",{}).get("reputation_bp",0)
		if session.in_studio and releases==3 and not prebrief:
			prebrief=true;save_boundary(session,"prebrief")
		if session.in_studio and releases==4 and not postcommission:
			postcommission=true;save_boundary(session,"postcommission")
			full.cfg.commission=false;full.cfg.research=[];full.cfg.development.hands={"design":2,"alpha":2,"beta":2};full.play=Finite.factory(full.cfg.development)
		if session.in_studio and releases==5:
			save_boundary(session,"later-sales");break
		var choice: Dictionary=prefix.choose(view) if releases<3 or reputation<2000 or view.phase==&"contract" else full.choose(view)
		if choice.type==&"quote_commission" and not prequote:
			prequote=true;save_boundary(session,"prequote")
		var row := {"step":index,"phase":str(view.phase),"cycle":view.run_cycle,"choice":choice.duplicate(true)}
		if choice.type in [&"development",&"contract"]:
			row.candidates=view.contract.candidates.duplicate(true) if choice.type==&"contract" else view.development.candidates.duplicate(true)
		guide.append(row)
		var result := Replay.record(session,tape,session.command(StringName(choice.type),choice.get("payload",{})))
		if not result.ok:
			FileAccess.open(args[0]+"/failure.json",FileAccess.WRITE).store_string(JSON.stringify({"step":index,"result":result,"view":view},"\t"))
			push_error("Legal predeclared route rejected at step%d: %s"%[index,str(result)])
			quit(1);return
	assert(session.in_studio and session.run.get_released_game_ids().size()==5)
	var duplicate := Factory.create_fresh_session(recipe,catalog)
	var replay := Replay.replay(duplicate,tape)
	assert(replay.ok,str(replay))
	assert(Replay.state(duplicate)==Replay.state(session))
	Replay.save_tape(args[0]+"/route.tape.json",tape)
	FileAccess.open(args[0]+"/guide.json",FileAccess.WRITE).store_string(JSON.stringify(guide,"\t"))
	FileAccess.open(args[0]+"/result.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"source":Replay.source_identity(),"steps":guide.size(),"stages":stages,"exact_replay":replay.ok},"\t"))
	print(JSON.stringify({"pass":true,"steps":guide.size(),"stages":stages}))
	quit()
