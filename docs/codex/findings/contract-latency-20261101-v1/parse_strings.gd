extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	await process_frame
	var previous_script:=GDScript.new()
	previous_script.source_code=FileAccess.get_file_as_string("res://../docs/codex/findings/contract-latency-20261101-v1/before-production/scripts/persistence/checkpoint_codec.gd").replace("class_name CheckpointCodec\n","")
	check(previous_script.reload()==OK,"Exact preceding strict parser compiles anonymously")
	var prior: RefCounted=previous_script.new()
	var current:=CheckpointCodec.new()
	var cases: Array[String]=["null","true","false","{}","[]","{\"a\":\"1\",\"\\u0061\":\"2\"}","[1]","[true,]","{\"a\":null,}","\"unterminated","\"a\\","\"\\q\"","\"\\uD800\"","\"\\uD800\\uDC00\"","\"é🥭中文\"","{} trailing","[".repeat(100)+"null"+"]".repeat(100)]
	for i in 32:
		cases.append('"a'+String.chr(i)+'b"')
		cases.append('"a\\'+String.chr(i)+'b"')
	var random:=RandomNumberGenerator.new();random.seed=1221
	var pieces: Array[String]=['a','"','\\','\n','\t','🥭','é','中','/',String.chr(0)]
	for i in 200:
		var value:=""
		for n in 16:value+=pieces[random.randi_range(0,pieces.size()-1)]
		cases.append(JSON.stringify({"key":value,"other":[value,true,null]}))
	for source in cases:
		var expected: Variant=prior.parse(source);var actual: Variant=current.parse(source)
		check(current.error==prior.error and (not current.error.is_empty() or var_to_bytes(actual)==var_to_bytes(expected)),"Strict parser preserves prior rejection and exact decoded values")
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var payload: Dictionary=pair.player.duplicate(true);payload["rival_world"]=pair.world
	var envelope:=CheckpointCodec.new().envelope(payload)
	var old_times: Array=[];var new_times: Array=[]
	for i in 3:
		var start:=Time.get_ticks_usec();var expected: Dictionary=prior.open_envelope(envelope);old_times.append(Time.get_ticks_usec()-start)
		start=Time.get_ticks_usec();var actual:=current.open_envelope(envelope);new_times.append(Time.get_ticks_usec()-start)
		check(current.error.is_empty() and prior.error.is_empty() and var_to_bytes(actual)==var_to_bytes(expected),"Full genuine envelope/checksum decode remains exact")
	old_times.sort();new_times.sort()
	check(new_times[1]<old_times[1]*.65,"String scanning removes most per-character interpreter work")
	print("CONTRACT_PARSE_STRINGS checks=%d failures=%d prior_us=%d current_us=%d"%[checks,failures,old_times[1],new_times[1]]);quit(failures)
