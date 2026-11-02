extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var adapter:=StudioCheckpoint.new()
	var payload: Dictionary=pair.player
	var schema:=CheckpointSchema.root(true,false)
	var reference: Dictionary=CheckpointCodec.new().decode(payload,schema)
	for i in 3:adapter._decode_payload(payload)
	print("DECODE_CACHE_STATE entries=",StudioCheckpoint._decode_proofs.size()," bytes=",StudioCheckpoint._decode_proof_bytes," schema_bytes=",var_to_bytes(schema).size())
	var fast_start:=Time.get_ticks_usec()
	adapter._decode_current_payload(payload,false)
	print("DECODE_HELPER_US ",Time.get_ticks_usec()-fast_start)
	var direct: Array=[];var reused: Array=[]
	for i in 12:
		var codec:=CheckpointCodec.new();var start:=Time.get_ticks_usec()
		codec.decode(payload,schema)
		direct.append(Time.get_ticks_usec()-start)
		start=Time.get_ticks_usec()
		var actual:=adapter._decode_payload(payload)
		reused.append(Time.get_ticks_usec()-start)
		check(var_to_bytes(actual)==var_to_bytes(reference),"Reused decode matches complete native values and types")
	direct.sort();reused.sort()
	check(float(reused[6])<float(direct[6])*.75,"Warm typed decoding avoids repeated full schema work")
	var copy:=adapter._decode_payload(payload);copy.run.cash_cents+=99
	check(var_to_bytes(adapter._decode_payload(payload))==var_to_bytes(reference),"Caller cannot mutate retained decoded data")
	for mode in ["sequence","cash","extra"]:
		var bad:=payload.duplicate(true)
		if mode=="sequence":bad.sequence="01"
		elif mode=="cash":bad.run.cash_cents=123
		else:bad.run["unexpected"]=false
		check(adapter._decode_payload(bad).is_empty(),"Malformed payload cannot inherit type proof: "+mode)
	var changed:=payload.duplicate(true);changed.run.cash_cents=str(int(changed.run.cash_cents)+1)
	check(adapter._decode_payload(changed).run.cash_cents==reference.run.cash_cents+1,"Changed well-typed field is decoded freshly")
	check(not adapter.validate(changed).is_empty(),"Typed decoding never waives semantic finance validation")
	check(var_to_bytes(adapter._decode_payload(payload))==var_to_bytes(reference),"Valid original still decodes after rejected input")
	print("CONTRACT_DECODE_REUSE checks=%d failures=%d direct_us=%d warm_us=%d"%[checks,failures,direct[6],reused[6]])
	quit(1 if failures else 0)
