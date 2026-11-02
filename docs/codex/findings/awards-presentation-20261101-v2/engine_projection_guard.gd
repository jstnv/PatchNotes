extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_AWARDS_UI_FIXTURE")))
	var codec=load("res://scripts/market/rival_world_checkpoint.gd").new()
	var adapter:=StudioCheckpoint.new()
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	for fields in [["_engine_id"],["_engine_capacity"],["_engine_id","_engine_capacity"]]:
		var bad: Dictionary=pair.world.duplicate(true)
		var active: Array=bad.studios.filter(func(row: Dictionary):return row.development!=null)
		check(not active.is_empty(),"Genuine predecessor has active frozen projects")
		var project: Dictionary=active[0].development.project
		for field in fields:
			check(project.has(field),"Genuine source contains required frozen field: "+field)
			project.erase(field)
		check(codec.restore(bad,pair.player,adapter.hydrate(pair.player),catalog)==null,"Exact predecessor cannot omit frozen engine fields: "+str(fields))
	print("AWARDS_ENGINE_PROJECTION_GUARD source=%s checks=%d failures=%d"%[pair.world.source_identity,checks,failures])
	quit(1 if failures else 0)
