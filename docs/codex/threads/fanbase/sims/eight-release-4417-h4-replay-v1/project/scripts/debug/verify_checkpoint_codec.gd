extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures += 1
func _initialize() -> void:
	var codec := CheckpointCodec.new()
	for number in [0,1,9007199254740993,9223372036854775807,-1,-9223372036854775807-1]:
		codec.error = ""
		check(codec.integer(str(number),true)==number and codec.error.is_empty(),"Exact signed64 " + str(number))
	for bad in ["", "00", "01", "-0", "+1", " 1", "1 ", "1.0", "1e2", "--1", "9223372036854775808", "-9223372036854775809", "１２", null,1.0]:
		codec.error = ""
		codec.integer(bad,true)
		check(not codec.error.is_empty(),"Reject noncanonical/overflow " + str(bad))
	codec.error = ""
	codec.integer("-1")
	check(not codec.error.is_empty(),"Unsigned field rejects negative")
	var schema := {"cash":"uint","rng":"int","id":"id","text":"text","flag":"bool","score":"float","weights":{"map":["uint","uint"]},"ids":{"array":"id"},"absent":{"nullable":"text"}}
	var value := {"cash":9223372036854775807,"rng":-9223372036854775807-1,"id":&"studio_1","text":"123","flag":true,"score":7.3,"weights":{0:25,1:25,2:25,3:25},"ids":[&"text",&"controls"],"absent":null}
	var encoded: Variant = codec.encode(value,schema)
	check(codec.error.is_empty() and encoded.cash=="9223372036854775807" and encoded.text=="123","Schema distinguishes integer and numeric-looking text")
	var envelope := codec.envelope(encoded)
	var payload := codec.open_envelope(envelope)
	check(codec.error.is_empty() and codec.decode(payload,schema)==value,"Envelope/typed map/ID/full precision roundtrip")
	check(codec.encode(1.0,"float")=={"f64":"3ff0000000000000"},"Canonical IEEE754 big-endian hex")
	check(codec.encode(-0.0,"float")=={"f64":"8000000000000000"},"Negative zero float bits preserved")
	for bad in [{"f64":"7ff0000000000000"},{"f64":"7ff8000000000000"},{"f64":"3FF0000000000000"},{"f64":"0"}]:
		codec.decode(bad,"float")
		check(not codec.error.is_empty(),"Reject invalid/nonfinite float")
	for bad in ["{\"a\":\"1\",\"a\":\"2\"}","{\"a\":true,\"\\u0061\":false}","[1]","{\"n\":1e3}","[true,]","{\"x\":null,}","[", "{} trailing", "\"raw\nnewline\"", "[NaN]"]:
		codec.parse(bad)
		check(not codec.error.is_empty(),"Strict JSON rejects duplicate/token/truncation")
	codec.open_envelope(envelope.replace("studio_1","studio_2"))
	check(codec.error=="CHECKSUM_MISMATCH","Corrupt payload rejected before typed hydration")
	codec.open_envelope(envelope.replace('"schema_version":"1"','"schema_version":"2"'))
	check(codec.error=="INCOMPATIBLE_SCHEMA","Future envelope preserved as incompatible")
	var duplicate: Array = [{"key":"0","value":"25"},{"key":"0","value":"75"}]
	codec.decode(duplicate,{"map":["uint","uint"]})
	check(not codec.error.is_empty(),"Repeated typed map identity rejected")
	codec.decode({"extra":"1"},{"required":"uint"})
	check(not codec.error.is_empty(),"Missing/extra record fields reject")
	var forbidden := Node.new()
	codec.encode(forbidden,"text")
	check(not codec.error.is_empty(),"Objects cannot enter typed fields")
	forbidden.free()
	codec.parse("[".repeat(100)+"null"+"]".repeat(100))
	check(not codec.error.is_empty(),"Bounded nesting")
	print("Checkpoint codec: %d checks, %d failures" % [checks,failures])
	quit(failures)
