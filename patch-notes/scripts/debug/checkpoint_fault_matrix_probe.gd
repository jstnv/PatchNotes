extends SceneTree

var failures := 0
func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1

func validate(payload: Dictionary) -> String:
	var codec := CheckpointCodec.new()
	codec.decode(payload,{"sequence":"uint","cash":"uint","kind":"text"})
	if not codec.error.is_empty(): return codec.error
	return "" if payload.kind=="studio" else "INCOMPATIBLE_CONTENT"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0]
	var store := StudioCheckpointStore.new(args[1],validate)
	# Isolated verification lease; production retains its application-wide lease.
	store._writer = TCPServer.new()
	if store._writer.listen(47413,"127.0.0.1")!=OK: quit(2); return
	var before := store.inspect()
	if mode=="initial":
		check(store.save({"cash":"100","kind":"studio"}).status==&"saved","Initial publication")
	elif mode.begins_with("fault-"):
		store.fault = StringName(mode.trim_prefix("fault-"))
		var result := store.save({"cash":"200","kind":"studio"})
		var published := store.fault in [&"after_rename",&"during_cleanup"]
		check(result.status==(&"saved" if published else &"io_error"),"Fault returns publication outcome")
		check(store.inspect().payload.cash==("200" if published else "100"),"Only complete prior or new generation visible")
		check(FileAccess.file_exists(before.path),"Previous valid generation retained")
	elif mode.begins_with("read-"):
		check(before.status==&"valid" and before.payload.cash==mode.trim_prefix("read-"),"Fresh process sees exact committed generation")
	elif mode=="corrupt":
		check(store.save({"cash":"200","kind":"studio"}).status==&"saved","Second generation")
		var current := store.inspect()
		FileAccess.open(current.path,FileAccess.WRITE).store_string("{broken")
		var damaged := FileAccess.get_sha256(current.path)
		check(store.inspect().status==&"invalid" and store.inspect().backup.payload.cash=="100","Corrupt current exposes explicit backup")
		check(store.save({"cash":"300","kind":"studio"}).status==&"invalid","Normal write refuses corruption")
		check(FileAccess.get_sha256(current.path)==damaged,"Passive inspection and rejected save preserve damaged bytes")
		check(store.recover_backup().status==&"saved","Explicit recovery publishes valid backup")
		check(FileAccess.get_sha256(current.path)==damaged,"Recovery preserves corrupt evidence")
	elif mode=="replacement-failure":
		store.fault = &"before_rename"
		check(store.replace_run({"cash":"300","kind":"studio"}).status==&"io_error","Failed replacement publication")
		check(store.inspect()==before,"Previous run survives failed replacement")
		var archives := DirAccess.get_directories_at(store.directory)
		check(archives.size()==1,"Replacement archives before attempting publication")
		if archives.size()==1:
			check(FileAccess.get_sha256(store.directory.path_join(archives[0]).path_join(before.path.get_file()))==FileAccess.get_sha256(before.path),"Archived bytes match previous run")
	elif mode=="incompatible":
		var codec := CheckpointCodec.new()
		FileAccess.open(before.path,FileAccess.WRITE).store_string(codec.envelope({"sequence":str(before.sequence),"cash":"100","kind":"future"}))
		var digest := FileAccess.get_sha256(before.path)
		check(store.inspect().status==&"incompatible","Future content refuses restore")
		check(store.save({"cash":"300","kind":"studio"}).status==&"incompatible","Future content refuses ordinary overwrite")
		check(FileAccess.get_sha256(before.path)==digest,"Incompatible bytes preserved")
	store.release_writer()
	print("Fault matrix ",mode,": ",failures," failures")
	quit(0 if failures==0 else 1)
