extends SceneTree
func _initialize() -> void: _run.call_deferred()
func totals(ids: Array, definitions: Dictionary) -> Dictionary:
	var core := [0,0,0,0]
	var scope := 0
	for id in ids:
		var card: Dictionary=definitions[id]
		scope+=int(card.scope)
		for prefix in ["primary","secondary"]:
			var index := ["graphics","sound","technology","design"].find(card.get(prefix+"_stat",""))
			if index>=0:core[index]+=int(card.get(prefix+"_value",0))
	return {"count":ids.size(),"scope":scope,"core":core}
func _run() -> void:
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var definitions := {}
	var offers := {}
	for card: Dictionary in FeatureStoreCatalog.starting_features()+FeatureStoreCatalog.entries():
		definitions[StringName(card.id)]=card
	for card: Dictionary in FeatureStoreCatalog.entries():offers[StringName(card.id)]=card
	var graph := FeatureStoreCatalog.graph(definitions,offers)
	assert(not graph.has("error"),str(graph.get("error","")))
	var results := {}
	for genre in StudioSpecialties.RULES:
		var old: Array=StudioSpecialties.preview(genre,2).ids
		var missing := {}
		for id in old:
			for parent in graph.parents[id]:
				if not old.has(parent):missing[str(id)]=str(parent)
		var proposed := old.duplicate()
		var steps := []
		for round in 200:
			var changed := false
			for id in proposed.duplicate():
				var absent: Array=graph.parents[id].filter(func(parent):return not proposed.has(parent))
				if absent.is_empty():continue
				proposed.erase(id)
				# A replacement follows the authored branch anchor. A converged
				# child does not grant a second free research branch to satisfy AND.
				var earlier=graph.parents[id][0]
				# Later Store ancestors have unapproved play fees. Keep the fixed
				# Primitive grant boundary and walk back to its authored ancestor.
				while not StudioSpecialties.PRIMITIVE_IDS.has(str(earlier)):
					assert(not graph.parents[earlier].is_empty(),"No approved Primitive ancestor")
					earlier=graph.parents[earlier][0]
				if not proposed.has(earlier):proposed.append(earlier)
				steps.append({"remove":str(id),"replace":[earlier]})
				changed=true
				break
			if not changed:break
		assert(proposed.all(func(id):return graph.parents[id].all(func(parent):return proposed.has(parent))))
		proposed.sort()
		results[str(genre)]={"before":old,"before_totals":totals(old,definitions),"missing":missing,"proposed":proposed,"proposed_totals":totals(proposed,definitions),"removed":old.filter(func(id):return not proposed.has(id)),"added":proposed.filter(func(id):return not old.has(id)),"steps":steps}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"rosters":results,"parents":graph.parents},"  "))
	for genre in results:print(genre," ",results[genre].before_totals," -> ",results[genre].proposed_totals," removed=",results[genre].removed," added=",results[genre].added)
	quit()
