extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var path:=OS.get_environment("PN_PRIOR_SAVE")
	var hash:=FileAccess.get_sha256(path)
	var source:=FileAccess.get_file_as_string(path)
	if source.is_empty():push_error("Missing checkpoint");quit(2);return
	var rows: Array=[]
	for index in 3:
		var codec:=CheckpointCodec.new()
		var start:=Time.get_ticks_usec()
		var payload: Dictionary=codec.open_envelope(source)
		var elapsed:=Time.get_ticks_usec()-start
		rows.append({"us":elapsed,"error":codec.error,"position":codec._pos,"nodes":codec._nodes,"digest":var_to_bytes(payload).hex_encode().sha256_text(),"source_identity":payload.get("rival_world",{}).get("source_identity","")})
	var result: Dictionary={"input_sha256":hash,"unchanged":FileAccess.get_sha256(path)==hash,"rows":rows}
	var output:=FileAccess.open(OS.get_environment("PN_PROFILE_REPORT"),FileAccess.WRITE)
	if output==null:quit(2);return
	output.store_string(JSON.stringify(result))
	print("ASCII_CODEC_PROFILE ",JSON.stringify(result))
	quit(0 if result.unchanged and rows.all(func(row):return row.error.is_empty() and row.source_identity==OS.get_environment("PN_EXPECTED_SOURCE")) else 1)
