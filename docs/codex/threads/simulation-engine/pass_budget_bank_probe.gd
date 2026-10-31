extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")

func _initialize() -> void:
	var definitions: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var recipe := {"schema_version":1,"studio_id":"pass-bank-probe","studio_name":"Pass Bank Probe","specialty":"action","traits":[],"seed":"4417"}
	var session: RefCounted = Factory.create_fresh_session(recipe,definitions)
	if session == null:
		print("Fresh session unavailable")
		quit(1)
		return
	for principal in [200000,500000,1000000]:
		var quote: Dictionary = session.quote_bank(principal,24)
		print(JSON.stringify({"principal":principal,"accepted":quote.get("accepted",false),"reasons":quote.get("reasons",[]),"schedule":quote.get("schedule",{})}))
	quit(0)
