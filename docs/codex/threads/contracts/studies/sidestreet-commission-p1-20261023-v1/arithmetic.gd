extends SceneTree
const C := preload("res://scripts/contracts/publisher_commission_trial.gd")
func _initialize() -> void:
	var failed := 0
	for row in [[30,30,60,600000,1500],[30,30,50,300000,0],[30,30,59,570000,0],[30,30,40,0,0],[30,15,60,300000,0],[30,60,100,600000,1500]]:
		var result := C.grade(row[0],row[1],row[2])
		if result.get("fee_paid_cents") != row[3] or result.get("relationship_award_bp") != row[4]: failed += 1
	for row in [[0,30,60],[30,-1,60],[30,30,101]]:
		if not C.grade(row[0],row[1],row[2]).is_empty(): failed += 1
	var run := RunState.new()
	if not run.has_method("get_commission_quote") or not run.get_commission_quote().is_empty(): failed += 1
	print("COMMISSION_ARITHMETIC checks=10 failures=",failed)
	quit(0 if failed == 0 else 1)
