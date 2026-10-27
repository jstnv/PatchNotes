## Headless reference for the direct EXE's explicitly weak first-four route.
extends SceneTree
const Campaign := preload("res://scripts/simulation/campaign_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var session: RefCounted
var tape: Dictionary
var args: PackedStringArray
func _initialize() -> void: execute.call_deferred()
func command(kind: StringName,payload: Dictionary = {}) -> void:
	var outcome := Replay.record(session,tape,session.command(kind,payload))
	assert(outcome.ok,str(outcome))
func dev(kind: StringName,payload: Dictionary = {}) -> void:
	command(&"development",{"request":session.development.command(kind,payload)})
func save_state(label: String) -> void:
	var record := StudioCheckpoint.new().capture(session.run)
	assert(not record.is_empty())
	FileAccess.open(args[0]+"/"+label+".json",FileAccess.WRITE).store_string(JSON.stringify(record))
func execute() -> void:
	args = OS.get_cmdline_user_args()
	var adapter := StudioCheckpoint.new()
	var run := adapter.hydrate(JSON.parse_string(FileAccess.get_file_as_string(args[1]+"/pre-support.json")))
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var snapshots := PrimitiveSnapshotDatabase.new()
	assert(snapshots.load_ledgers())
	session = Campaign.new()
	assert(session.initialize(run,catalog,snapshots))
	tape = Replay.begin(session)
	save_state("prequote")
	command(&"quote_support",{"name":"s","genre":"sports","theme":"fantasy"})
	command(&"begin_development",{"name":"s","genre":"sports","theme":"fantasy","support_quote":run.get_support_quote("s",&"sports",&"fantasy")})
	var selections: Array = []
	for phase in range(3):
		dev(&"begin")
		var ids: Array[int] = []
		var labels: Array = []
		for slot in range(4):
			ids.append(session.development.hand.candidate_ids[slot])
			labels.append(session.development.hand._candidate_cards[slot].card_name)
		selections.append({"phase":phase,"ids":ids,"names":labels})
		dev(&"play",{"candidate_ids":ids})
		dev(&"request_exit")
		if session.development.awaiting_confirmation: dev(&"confirm_exit")
		if phase < 2: dev(&"enter_next_phase")
	command(&"launch")
	save_state("postsupport")
	command(&"campaign",{"release_id":&"commission-p1-sports-1112:project:3"})
	save_state("later-sales")
	var report := run.get_released_game_monthly_report(&"commission-p1-sports-1112:project:5")
	assert(report.units>0 and report.support.rights.publisher_recoup_cents>0 and report.studio_net_cents>0)
	FileAccess.open(args[0]+"/support-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	FileAccess.open(args[0]+"/reference-result.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"source":Replay.source_identity(),"steps":tape.steps.size(),"selections":selections,"scope":"One first-four hand per phase; early launch is intentionally weak, not full success evidence."},"\t"))
	Replay.save_tape(args[0]+"/route.tape.json",tape)
	quit()
