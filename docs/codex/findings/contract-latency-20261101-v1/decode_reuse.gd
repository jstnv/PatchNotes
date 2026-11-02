extends SceneTree
class OtherAdapter extends StudioCheckpoint:
	pass
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
	check(adapter.validate(payload).is_empty(),"Existing positive validation proof is established first")
	for i in 3:adapter._decode_payload(payload)
	var direct: Array=[];var reused: Array=[]
	for i in 12:
		var codec:=CheckpointCodec.new();var start:=Time.get_ticks_usec()
		# Match the actual uncached operation: it builds the trusted schema too.
		# The prebuilt schema above is solely the exact-value/type oracle.
		codec.decode(payload,CheckpointSchema.root(true,false))
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
	var generation:=payload.duplicate(true);generation.sequence="9223372036854775807"
	check(adapter.validate(generation).is_empty() and adapter._decode_payload(generation).sequence==9223372036854775807,"Normalized proof restores exact positive64 generation")
	check(adapter._validation_key(payload,false)!=adapter._validation_key(payload,true),"Active-rival mode has a separate proof identity")
	check(adapter._validation_key(payload,false)!=OtherAdapter.new()._validation_key(payload,false),"Subclass/base script identity cannot inherit another adapter proof")
	for row: Dictionary in pair.world.studios:
		if row.development==null:continue
		var rival: Dictionary=row.run
		check(adapter.validate_active_rival(rival).is_empty(),"Active rival establishes full positive predicate")
		var rival_reference: Variant=CheckpointCodec.new().decode(rival,CheckpointSchema.root(true,true))
		check(var_to_bytes(adapter._decode_payload(rival,true))==var_to_bytes(rival_reference),"Active rival DTO reuse preserves full exact native state")
		var nested:=adapter._decode_payload(rival,true);nested.rng[nested.rng.keys()[0]].state+=1
		check(var_to_bytes(adapter._decode_payload(rival,true))==var_to_bytes(rival_reference),"Nested returned RNG mutation cannot corrupt retained proof")
		break
	for i in range(StudioCheckpoint.VALIDATION_PROOF_LIMIT+2):
		var distinct:=payload.duplicate(true);distinct.run.studio_name="Decode eviction %02d"%i
		check(adapter.validate(distinct).is_empty(),"Distinct valid metadata is fully validated before retention")
	var cost:=0
	for proof: Dictionary in StudioCheckpoint._validation_proofs:
		check(proof.cost==proof.key.size()+var_to_bytes(proof.native).size(),"Byte budget includes retained native DTO")
		cost+=proof.cost
	check(StudioCheckpoint._validation_proofs.size()==StudioCheckpoint.VALIDATION_PROOF_LIMIT and cost==StudioCheckpoint._validation_proof_bytes and cost<=StudioCheckpoint.VALIDATION_PROOF_BYTES,"Count and byte bounds remain exact after eviction")
	check(var_to_bytes(adapter._decode_payload(payload))==var_to_bytes(reference),"Evicted payload decodes identically through the strict fallback")
	print("CONTRACT_DECODE_REUSE checks=%d failures=%d direct_us=%d warm_us=%d"%[checks,failures,direct[6],reused[6]])
	quit(1 if failures else 0)
