extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1
func validate(payload: Dictionary) -> String:
	var codec := CheckpointCodec.new()
	codec.decode(payload,{"sequence":"uint","cash":"uint","kind":"text"})
	if not codec.error.is_empty(): return codec.error
	return "" if payload.kind == "studio" else "INCOMPATIBLE_CONTENT"
func _initialize() -> void:
	var path := "user://checkpoint-store-test-"+Crypto.new().generate_random_bytes(8).hex_encode()
	var store := StudioCheckpointStore.new(path,validate)
	check(store.inspect().status==&"empty","Fresh slot empty")
	check(store.save({"cash":"550000","kind":"studio"}).status==&"saved","Initial generation publishes")
	var initial := store.inspect()
	check(initial.status==&"valid" and initial.sequence==1,"Published generation validates")
	var other := StudioCheckpointStore.new(path,validate)
	check(other.save({"cash":"0","kind":"studio"}).status==&"writer_busy","Second owner refused")
	for fault in [&"before_write",&"after_flush",&"before_rename"]:
		store.fault=fault
		check(store.save({"cash":"400000","kind":"studio"}).status==&"io_error","Injected publication failure")
		check(store.inspect()==initial,"Previous generation unchanged; temp not promoted")
	store.fault=&""
	check(store.save({"cash":"400000","kind":"studio"}).sequence==2,"Retry publishes once without replaying gameplay")
	check(FileAccess.file_exists(initial.path),"Prior generation retained")
	var newest := store.inspect()
	FileAccess.open(newest.path,FileAccess.WRITE).store_string("{truncated")
	var recovery := store.inspect()
	check(recovery.status==&"invalid" and recovery.backup.sequence==1,"Corrupt current exposes separate validated backup")
	check(store.save({"cash":"1","kind":"studio"}).status==&"invalid","Normal save cannot overwrite corruption")
	var codec := CheckpointCodec.new()
	FileAccess.open(newest.path,FileAccess.WRITE).store_string(codec.envelope({"sequence":"2","cash":"400000","kind":"future"}))
	check(store.inspect().status==&"incompatible" and not store.inspect().has("backup"),"Future content does not silently fall back")
	store.release_writer()
	check(other.acquire(),"OS writer lease released")
	other.release_writer()
	print("Checkpoint store: %d checks, %d failures" % [checks,failures])
	quit(failures)
