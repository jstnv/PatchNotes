extends "res://scripts/debug/verify_design_command.gd"

func _initialize() -> void:
	for method in [&"add_core_scores_and_scope", &"add_alpha_production"]:
		for overflowing_scope in [false, true]:
			var project := ProjectState.new(30)
			var emissions := [0]
			project.values_changed.connect(func() -> void: emissions[0] += 1)
			if overflowing_scope:
				project.set("_current_scope", ProjectState.MAX_SIGNED_INT)
			else:
				project.set("_core_scores", {0:0,1:0,2:0,3:ProjectState.MAX_SIGNED_INT} as Dictionary[ProjectState.CoreScore,int])
			var before: Variant = freeze(project)
			var gains: Dictionary[ProjectState.CoreScore,int] = {0:5,1:4,2:3,3:1}
			_expect(not project.call(method,gains,1,0.25), "%s rejects %s overflow" % [method,"Scope" if overflowing_scope else "Core"])
			_expect(freeze(project) == before and emissions[0] == 0, "Rejects the whole update before Core, Scope, pressure or notifications")
		var boundary := ProjectState.new(30)
		boundary.set("_current_scope", ProjectState.MAX_SIGNED_INT-1)
		boundary.set("_core_scores", {0:ProjectState.MAX_SIGNED_INT-1,1:0,2:0,3:0} as Dictionary[ProjectState.CoreScore,int])
		var gain: Dictionary[ProjectState.CoreScore,int] = {0:1}
		_expect(boundary.call(method,gain,1,0.25), "Exact signed maximum remains representable")
		_expect(boundary.get_core_score(0)==ProjectState.MAX_SIGNED_INT and boundary.get_current_scope()==ProjectState.MAX_SIGNED_INT, "Exact integer maximum is preserved without float conversion")
		var zeros: Dictionary[ProjectState.CoreScore,int] = {0:0}
		_expect(boundary.call(method,zeros,0,0), "Zero additions at maximum remain valid")
	var direct := ProjectState.new(30)
	_expect(direct.add_core_score(0,ProjectState.MAX_SIGNED_INT) and direct.add_scope(ProjectState.MAX_SIGNED_INT), "Direct setters accept exact maximum")
	var saved: Variant = freeze(direct)
	_expect(not direct.add_core_score(0,1) and not direct.add_scope(1) and freeze(direct)==saved, "Direct setters reject overflow without mutation")
	_expect(not direct.add_core_score_and_scope(0,1,0) and freeze(direct)==saved, "Single score/Scope wrapper uses the same guard")
	print("Production integer overflow checks complete")
	quit(1 if _failures else 0)
