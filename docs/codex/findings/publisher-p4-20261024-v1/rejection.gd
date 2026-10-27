extends SceneTree
const Campaign := preload("res://scripts/simulation/campaign_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Policy := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Launch := preload("res://scripts/simulation/launch_settlement.gd")
const Fence := preload("res://scripts/simulation/transaction_projection.gd")
var checks: Array = []
func _initialize() -> void: execute.call_deferred()
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"label":label})
	if not ok: printerr("FAIL: ",label)
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]+"/pre-support.json"))
	var adapter := StudioCheckpoint.new()
	var snapshots := PrimitiveSnapshotDatabase.new()
	check(snapshots.load_ledgers(),"release rejection snapshots")
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var session := Campaign.new()
	check(session.initialize(adapter.hydrate(payload),catalog,snapshots),"legal Studio initializes for release guard")
	var envelope := session.export_checkpoint()
	envelope.commission_request = {"name":"Valid commission preview","genre":"sports","theme":"fantasy"}
	envelope.support_request = []
	envelope.erase("integrity")
	envelope.integrity = Replay.digest(envelope)
	var target := Campaign.new()
	var initial := Fence.authority(target)
	check(not target.restore_checkpoint(envelope,catalog,snapshots) and Fence.authority(target) == initial,"malformed support metadata rejects without partially changing commission request")
	var policy := Policy.factory({"genre":"sports","theme":"fantasy","name_prefix":"Live release guard","selection":"features_first","hands":{"design":5,"alpha":7,"beta":6}})
	for index in range(80):
		var choice: Dictionary = policy.call(session.observation())
		if choice.type == &"begin_development": choice.payload.support_quote = session.run.get_support_quote(choice.payload.name,&"sports",&"fantasy")
		if choice.type == &"launch": break
		var outcome: Dictionary = session.execute(session.command(StringName(choice.type),choice.get("payload",{})))
		check(outcome.ok,"legal support preparation step%d" % index)
		if not outcome.ok: break
	check(not session.in_studio and session.development.project.is_launch_ready(),"legal supported project reaches actual launch boundary")
	var project: ProjectState = session.development.project
	var changes := {"_required_scope":1,"_base_name":"Changed after acceptance","_genre_id":&"action","_theme_id":&"war"}
	for field: String in changes:
		var old: Variant = project.get(field)
		project.set(field,changes[field])
		var run_before := Fence.authority(session.run)
		var project_before := Fence.authority(project)
		var denied: Dictionary = Launch.new(project,session.run,snapshots).plan()
		check(denied.is_empty() and Fence.authority(session.run) == run_before and Fence.authority(project) == project_before,"live release rejects changed supported identity before state/RNG/publication: "+field)
		project.set(field,old)
	check(not Launch.new(project,session.run,snapshots).plan().is_empty(),"unchanged legal supported release remains admissible")
	var failures := checks.filter(func(row: Dictionary) -> bool:return not row["pass"]).size()
	FileAccess.open(args[0]+"/rejection-result.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity()},"\t"))
	print("P4 rejection checks ",checks.size()," failures ",failures)
	quit(0 if failures == 0 else 1)
