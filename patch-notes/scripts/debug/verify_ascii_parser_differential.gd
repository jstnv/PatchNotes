extends SceneTree
const Prior := preload("res://scripts/debug/fixtures/checkpoint_codec_before_codepoint.gd")
const Unsafe := preload("res://scripts/debug/fixtures/checkpoint_codec_unsafe_ascii.gd")
var count:=0
var failures:=0
var first: Array[String]=[]

func compare(a: RefCounted,b: RefCounted,source: String,label: String) -> void:
	var x: Variant=a.parse(source)
	var y: Variant=b.parse(source)
	count+=1
	if var_to_bytes(x)!=var_to_bytes(y) or a.error!=b.error or a._pos!=b._pos or a._nodes!=b._nodes or a._text!=b._text:
		failures+=1
		if first.size()<20:first.append(label+" old="+str([a.error,a._pos,a._nodes])+" new="+str([b.error,b._pos,b._nodes]))

func compare_string(a: RefCounted,b: RefCounted,source: String,pos: int,label: String) -> void:
	a._text=source;b._text=source;a._pos=pos;b._pos=pos;a._nodes=19;b._nodes=19;a.error="";b.error=""
	var x: Variant=a._string();var y: Variant=b._string()
	count+=1
	if var_to_bytes(x)!=var_to_bytes(y) or a.error!=b.error or a._pos!=b._pos or a._nodes!=b._nodes:
		failures+=1
		if first.size()<20:first.append(label+" old="+str([a.error,a._pos,a._nodes])+" new="+str([b.error,b._pos,b._nodes]))

func _initialize() -> void:call_deferred("run")
func run() -> void:
	var a:=Prior.new()
	var b: RefCounted=Unsafe.new() if OS.get_environment("PN_TEST_IMPL")=="unsafe" else CheckpointCodec.new()
	var mode:=OS.get_environment("PN_CASE_MODE")
	if mode=="limits":
		compare(a,b,"\"ok\"","pre-limit state")
		compare(a,b,"1"+" ".repeat(CheckpointCodec.LIMIT-1),"exact 24 MiB")
		compare(a,b,"1"+" ".repeat(CheckpointCodec.LIMIT),"over 24 MiB preserves old parser state")
		compare(a,b,"é".repeat(CheckpointCodec.LIMIT/2),"exact 24 MiB UTF-8")
		compare(a,b,"é".repeat(CheckpointCodec.LIMIT/2+1),"over 24 MiB UTF-8")
		compare(a,b,"["+"null,".repeat(CheckpointCodec.MAX_NODES-2)+"null]","exact node limit")
		compare(a,b,"["+"null,".repeat(CheckpointCodec.MAX_NODES-1)+"null]","over node limit")
	else:
		var cases: Array[String]=["", "null", "true", "false", "0", "\"\"", "\"abc 123\"", "\"a/b\"", "\"abc", "\"abc\\", "\"a\\q\"", "\"\\u0061\"", "\"\\u0x61\"", "\"\\uD800\"", "\"\\uDC00\"", "\"\\uD83D\\uDE03\"", "\"é漢😃é\"", "{\"a\":null,\"a\":false}", "{\"a\":null,\"\\u0061\":false}", "[null,false,true,\"x\"]", "[\"x\",]", "{\"x\":\"y\"} trailing", "{\"x\":1}", "[".repeat(96)+"null"+"]".repeat(96), "[".repeat(97)+"null"+"]".repeat(97)]
		for i in 128:
			cases.append("\""+String.chr(i)+"\"")
			cases.append("\"x\\"+String.chr(i)+"\"")
		for code in [0xD800,0xDC00,0x10FFFF]:cases.append("\""+String.chr(code)+"\"")
		for source: String in cases:compare(a,b,source,"fixed "+str(count))
		for source: String in ["xabc\"", "\"abc\"", "\"a\\n\"", "\"abc", ""]:compare_string(a,b,source,0,"direct string scanner")
		compare_string(a,b,"x\"offset\"",1,"direct scanner with nonzero position")
		compare_string(a,b,"x\"offset\"",0,"direct scanner without opening quote")
		compare_string(a,b,"\"x\"",-1,"direct scanner with negative position")
		compare_string(a,b,"x",1,"direct scanner at end")
		compare_string(a,b,"x",10,"direct scanner beyond end")
		var random:=RandomNumberGenerator.new();random.seed=0x51a7
		var alphabet: Array[String]=["a","Z","0"," ","\"","\\","/","{","}","[","]",":",",","n","u","\n","é","😃"]
		for iteration in 5000:
			var source:=""
			for ignored in random.randi_range(0,24):source+=alphabet[random.randi_range(0,alphabet.size()-1)]
			compare(a,b,source,"random "+str(iteration))
		for iteration in 5000:
			var codepoint: int=random.randi_range(128,0x10ffff)
			if codepoint >= 0xd800 and codepoint <= 0xdfff: codepoint=0x20ac
			var rune: String=String.chr(codepoint)
			compare(a,b,"\"prefix"+rune+"suffix\"","unicode "+str(iteration))
			compare(a,b,"\"prefix\\"+rune+"suffix\"","escaped unicode "+str(iteration))
	print("ASCII_PARSER_DIFFERENTIAL mode=",mode," checks=",count," failures=",failures," first=",JSON.stringify(first))
	quit(0 if failures==0 else 1)
