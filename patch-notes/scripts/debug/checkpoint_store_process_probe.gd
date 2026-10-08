extends SceneTree
func validate(payload: Dictionary) -> String:
	var codec := CheckpointCodec.new()
	codec.decode(payload,{"sequence":"uint","cash":"uint","kind":"text"})
	return codec.error
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0]
	var store := StudioCheckpointStore.new(args[1],validate)
	var result: Dictionary
	match mode:
		"read": result=store.inspect()
		"hold": result={"acquired":store.acquire()}
		"flush":
			store.fault=&"after_flush"
			result=store.save({"cash":"9007199254740993","kind":"studio"})
		_: result=store.save({"cash":"9007199254740993","kind":"studio"})
	FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify(result))
	if mode in ["hold","flush","publish_hold"]:
		await create_timer(120).timeout
	quit()
