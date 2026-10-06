## Native fixed-profile trait sales shadows. Future cycles are projections, not actions.
extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var inputs:Array=JSON.parse_string(FileAccess.get_file_as_string("res://design-logs/task22-v1/inputs.json"))
	var outputs:Dictionary={}
	for x:Dictionary in inputs:
		var f:Dictionary=x.frozen
		var aw:=int(x.awareness)
		var units:int=500*int(f.review_tenths)*(aw+200)*int(f.market_bp)/(70*200*10000)
		var rec:=ReleasedGameSales.create(StringName(x.release_id),units,int(f.review_tenths),aw,int(f.market_bp))
		var rows:Array=[]
		for cycle in range(int(x.release_cycle)+1,int(x.horizon)+1):
			var age:=cycle-int(x.release_cycle)
			var campaign:bool=age%2==1 and f.campaign_months.has(str((age+1)/2))
			rec=ReleasedGameSales.next_cycle(rec,cycle,cycle%2==0,campaign)
			if rec.is_empty():push_error("Native shadow rejected "+x.id);quit(1);return
			rows.append([cycle,rec.earned_units,rec.entitlement_cents,rec.settled_cents,rec.entitlement_cents-rec.settled_cents])
		outputs[x.id]={"month1_units":units,"rows":rows}
	FileAccess.open("res://design-logs/task22-v1/native-ledgers.json",FileAccess.WRITE).store_string(JSON.stringify(outputs))
	print("TASK22 native shadow ledgers ",outputs.size())
	quit(0)
