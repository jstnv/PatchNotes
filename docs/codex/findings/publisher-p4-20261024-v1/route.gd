extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Finite := preload("res://scripts/simulation/finite_fixture_policy.gd")
var args: PackedStringArray
var tape: Dictionary
var stages: Array = []

func _initialize() -> void: execute.call_deferred()

func boundary(session: RefCounted, label: String) -> void:
	print("P4_BOUNDARY ",label," ",JSON.stringify(session.run.get_support_history()))
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(session.run)
	assert(not payload.is_empty(),label+": "+adapter.error)
	var revived := adapter.hydrate(payload)
	assert(revived != null,label+": "+adapter.error)
	assert(adapter.capture(revived) == payload,"exact saved fields/RNG: "+label)
	FileAccess.open(args[0]+"/"+label+".json",FileAccess.WRITE).store_string(JSON.stringify(payload))
	stages.append({"label":label,"step":tape.steps.size(),"cycle":session.run.get_completed_run_cycles(),"cash":session.run.get_cash_cents(),"standing":session.run.get_publisher_relationships(),"history":session.run.get_support_history()})

func play(session: RefCounted, deal: String, hands: Dictionary, label: String) -> void:
	var policy := Finite.factory({"genre":"sports","theme":"fantasy","name_prefix":label,"selection":"features_first","hands":hands})
	var began := false
	for index in range(130):
		if began and session.in_studio: return
		var choice: Dictionary = policy.call(session.observation())
		if choice.type == &"begin_development":
			if deal == "support":
				var quote: Dictionary = session.run.get_support_quote(choice.payload.name,StringName(choice.payload.genre),StringName(choice.payload.theme))
				assert(not quote.is_empty(),"support unavailable: "+str(session.run.get_support_history()))
				choice.payload.support_quote = quote
			elif deal == "commission":
				choice.payload.commission_quote = session.run.get_commission_quote(choice.payload.name,StringName(choice.payload.genre),StringName(choice.payload.theme))
			began = true
		var result := Replay.record(session,tape,session.command(StringName(choice.type),choice.get("payload",{})))
		assert(result.ok,str(result))
	assert(false,"bounded development failed to finish")

func execute() -> void:
	args = OS.get_cmdline_user_args()
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var recipe := {"schema_version":1,"studio_id":"commission-p1-sports-1112","studio_name":"Commission sports-1112","specialty":"sports","traits":[],"seed":"1112"}
	FileAccess.open(args[0]+"/recipe.json",FileAccess.WRITE).store_string(JSON.stringify(recipe,"\t"))
	var session := Factory.create_fresh_session(recipe,catalog)
	tape = Replay.begin(session)
	var original := Replay.load_tape(args[1]+"/route.tape.json")
	for index in range(115):
		var command: Dictionary = original.steps[index].command.duplicate(true)
		if command.payload.has("commission_quote"):
			command.payload.commission_quote = session.run.get_commission_quote(command.payload.name,StringName(command.payload.genre),StringName(command.payload.theme))
		var result := Replay.record(session,tape,command)
		assert(result.ok,"prefix%d: %s"%[index,str(result)])
	boundary(session,"pre-support")
	play(session,"support",{"design":5,"alpha":7,"beta":6},"Support success")
	boundary(session,"support-launched")
	play(session,"",{"design":2,"alpha":2,"beta":2},"Assessment bridge")
	boundary(session,"first-assessed")
	assert(session.run._support_assessments.values()[0].passed,"declared first support did not pass")
	play(session,"support",{"design":1,"alpha":1,"beta":1},"Support miss")
	boundary(session,"second-launched")
	play(session,"",{"design":2,"alpha":2,"beta":2},"Miss bridge")
	boundary(session,"second-assessed")
	assert(not session.run._support_assessments.values()[1].passed,"declared second support did not miss")
	assert(session.run.get_support_quote("No automatic renewal",&"sports",&"fantasy").is_empty(),"miss must not qualify")
	play(session,"commission",{"design":5,"alpha":7,"beta":6},"Recovery commission")
	boundary(session,"recovery-commission")
	play(session,"support",{"design":2,"alpha":2,"beta":2},"Third support")
	boundary(session,"third-launched")
	var fresh := Factory.create_fresh_session(recipe,catalog)
	var replay := Replay.replay(fresh,tape)
	assert(replay.ok and Replay.state(fresh)==Replay.state(session),"full state/RNG fresh replay: "+str(replay))
	Replay.save_tape(args[0]+"/route.tape.json",tape)
	FileAccess.open(args[0]+"/route-result.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"source":Replay.source_identity(),"steps":tape.steps.size(),"stages":stages,"exact_replay":true},"\t"))
	print("P4 legal repeated route passed: ",tape.steps.size())
	quit()
