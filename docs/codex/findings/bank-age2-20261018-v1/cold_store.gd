extends "res://scripts/debug/verify_primitive_branches.gd"

func _initialize() -> void:
	await process_frame
	catalog=root.get_node("CardDatabase").get_development_catalog()
	var args:=OS.get_cmdline_user_args()
	if args.size()!=2:quit(2);return
	var base:=OS.get_environment("PN_BANK_AGE_DIR")
	var input:=base.path_join(args[1])
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(input))
	var mapper:=StudioCheckpoint.new()
	var store:=StudioCheckpointStore.new(base.path_join(args[1]+".store"),mapper.validate)
	if args[0]=="save":
		var result:=store.save(saved.studio_payload)
		print("STORE_RESULT ",JSON.stringify(result))
		check(result.status==&"saved","actual Studio generation published into isolated store")
		store.release_writer()
	else:
		var found:=store.inspect()
		check(found.status==&"valid","cold process reads valid Studio generation")
		if found.status!=&"valid":quit(1);return
		var run:=StudioCheckpoint.new().hydrate(found.payload)
		check(run!=null,"cold Studio maps without replaying transactions")
		if run==null:quit(1);return
		var expected: Dictionary=saved.studio_payload.duplicate(true);expected.sequence=found.payload.sequence
		check(found.payload==expected,"all stored fields match committed Studio payload")
		var after:=StudioCheckpoint.new().capture(run);after.sequence=found.payload.sequence
		check(after==found.payload,"cash/bills/loan/payment/credit/RNG survive exactly")
	var out:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"input":input,"source":Replay.source_identity(),"mode":args[0],"checks":checks,"failures":failures},"\t"))
	print("BANK_COLD checks=%d failures=%d mode=%s"%[checks,failures,args[0]]);quit(failures)
