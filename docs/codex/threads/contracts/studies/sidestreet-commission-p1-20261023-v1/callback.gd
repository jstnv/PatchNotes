extends SceneTree
const Begin := preload("res://scripts/simulation/begin_project.gd")
func _initialize() -> void: execute.call_deferred()
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var run := StudioCheckpoint.new().hydrate(envelope.studio_payload)
	if run == null: print("PREFIX_INVALID");quit(2);return
	var snapshots := PrimitiveSnapshotDatabase.new()
	if not snapshots.load_ledgers(): quit(2);return
	var quote := run.get_commission_quote("Callback test",&"sports",&"fantasy")
	var original := quote.duplicate(true)
	var ready := func(_p: ProjectState) -> bool:
		quote.required_scope+=1
		return true
	var result := Begin.execute(run,snapshots,"Callback test",&"sports",&"fantasy",ready,[],quote)
	var ok: bool = result.ok and run._commission_deals[original.project_id].terms == original
	print("CALLBACK_QUOTE_FROZEN=",ok)
	quit(0 if ok else 1)
