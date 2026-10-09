extends SceneTree
var store: StudioCheckpointStore
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	store = StudioCheckpointStore.new(args[1],func(_p):return "")
	if args[0]=="hold":
		if not store.acquire():print("BLOCKED: another application writer already owns the lease");quit(2);return
		FileAccess.open(args[2],FileAccess.WRITE).store_string("ready")
		return
	var result := store.save({"cash":"100"})
	var expected := &"writer_busy" if args[0]=="contend" else &"saved"
	print("PASS: " if result.status==expected else "FAIL: ",args[0]," ",result)
	quit(0 if result.status==expected else 1)
