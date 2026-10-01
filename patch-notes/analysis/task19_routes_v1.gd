## Read-only recapture on Task 21; reuse the exact legal action replay.
extends "res://analysis/task21_route_v1.gd"

func _run() -> void:
	for index in range(int(_arg("--count=", "6"))):
		live_cycles=[]
		random_inputs.seed=290929000+index
		var row := await _one("synergy",index)
		rows.append(row)
		if not row.valid: failures+=1
	var file := FileAccess.open("res://design-logs/task19-v1/routes_"+_arg("--tag=","short")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"rows":rows},"  "))
	print("TASK19 routes=",rows.size()," failures=",failures)
	quit(0 if failures==0 else 1)
