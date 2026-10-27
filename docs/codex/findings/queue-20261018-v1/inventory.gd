extends SceneTree
func _initialize() -> void:
	await process_frame
	var run:=RunState.new()
	var rows:=[]
	var graph:=FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
	for genre:StringName in StudioSpecialties.RULES:
		var row:=StudioSpecialties.preview(genre)
		row.exceptions=[]
		for id:StringName in row.ids:
			for parent:StringName in graph.parents[id]:
				if not row.ids.has(parent):row.exceptions.append({"child":id,"missing_parent":parent})
		rows.append(row)
	FileAccess.open(OS.get_environment("PN_INVENTORY"),FileAccess.WRITE).store_string(JSON.stringify({"rows":rows,"graph":graph,"definitions":run._feature_definitions},"\t"))
	quit()
