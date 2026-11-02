extends SceneTree
var issues: Array=[]
func audit(value: Variant,path: String) -> void:
	if value is Dictionary:
		if value.is_typed():issues.append([path,"typed dictionary"])
		for key: Variant in value:
			if typeof(key)!=TYPE_STRING:issues.append([path,str(key),"key",typeof(key)])
			audit(value[key],path+"."+str(key))
	elif value is Array:
		if value.is_typed():issues.append([path,"typed array",value.get_typed_builtin()])
		for i in value.size():audit(value[i],path+"[%d]"%i)
	elif typeof(value) not in [TYPE_NIL,TYPE_BOOL,TYPE_STRING]:issues.append([path,"scalar",typeof(value)])
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_AWARDS_UI_FIXTURE")))
	var adapter:=StudioCheckpoint.new()
	var codec=load("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var run:=adapter.hydrate(pair.player)
	var world=codec.restore(pair.world,pair.player,run,catalog)
	assert(world!=null,codec.error)
	var payload:=adapter.capture(run)
	payload.rival_world=codec.capture(world)
	audit(payload,"")
	var store:=StudioCheckpointStore.new("user://wire-diagnosis")
	print("WIRE_NODES ",store._wire_nodes(payload)," issues=",issues)
	FileAccess.open(OS.get_environment("PN_AWARDS_REPORT_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(issues,"\t"))
	quit()
