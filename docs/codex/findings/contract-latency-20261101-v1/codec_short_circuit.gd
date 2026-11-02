extends SceneTree
class CountingCodec extends CheckpointCodec:
	var visits:=0
	func encode(value: Variant,schema: Variant,depth: int=0) -> Variant:
		visits+=1;return super.encode(value,schema,depth)
	func decode(value: Variant,schema: Variant,depth: int=0) -> Variant:
		visits+=1;return super.decode(value,schema,depth)
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	var cases: Array=[
		[{"bad":false,"body":[1,2,3,4,5]},{"bad":"uint","body":{"array":"uint"}}],
		[[false,1,2,3,4,5],{"array":"uint"}],
		[{&"first":false,&"second":1},{"map":["id","uint"]}]]
	for pair: Array in cases:
		var codec:=CountingCodec.new();codec.encode(pair[0],pair[1])
		check(not codec.error.is_empty(),"Malformed encoding still rejects")
		check(codec.visits<=3,"Encoding stops at first failed field/element")
	for pair: Array in [[{"bad":false,"body":["1","2","3","4"]},{"bad":"uint","body":{"array":"uint"}}],[[false,"1","2","3"],{"array":"uint"}],[[{"key":"first","value":false},{"key":"second","value":"1"}],{"map":["id","uint"]}]]:
		var codec:=CountingCodec.new();codec.decode(pair[0],pair[1])
		check(not codec.error.is_empty(),"Malformed decoding still rejects")
		check(codec.visits<=3,"Decoding stops at first failed field/element")
	var encoder:=CountingCodec.new()
	encoder.encode({"body":[1,2,3,4,5],"wrong":1},{"body":{"array":"uint"},"missing":"uint"})
	check(not encoder.error.is_empty() and encoder.visits==1,"Reject missing record key before traversing an unrelated large field")
	var decoder:=CountingCodec.new()
	decoder.decode({"body":["1","2","3","4","5"],"wrong":"1"},{"body":{"array":"uint"},"missing":"uint"})
	check(not decoder.error.is_empty() and decoder.visits==1,"Decode rejects wrong union-record shape before walking its history")
	var codec:=CheckpointCodec.new()
	var schema: Dictionary={"one_of":[{"x":"uint","items":{"array":"uint"}},{"x":"bool","items":{"array":"uint"}}]}
	var value: Dictionary={"x":false,"items":[1,2,3]}
	var wire: Variant=codec.encode(value,schema)
	check(codec.error.is_empty() and wire=={"x":false,"items":["1","2","3"]},"Later valid union alternative still encodes")
	check(codec.decode(wire,schema)==value and codec.error.is_empty(),"Later valid union alternative still decodes exactly")
	print("CONTRACT_CODEC_SHORT_CIRCUIT checks=%d failures=%d"%[checks,failures]);quit(failures)
