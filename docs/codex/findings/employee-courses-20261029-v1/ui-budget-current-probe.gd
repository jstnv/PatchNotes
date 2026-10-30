extends SceneTree
var failures:=0
func _initialize() -> void: _run.call_deferred()
func check(ok:bool,message:String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures+=1
func _run() -> void:
	check(PriorityAllocation.MIN_PRIORITY==20 and BetaPriorityAllocation.MIN_PRIORITY==40,"Untrained Core20–40 and Beta40–60 floors match the Manager trial")
	var historic:Dictionary={0:50,1:5,2:20,3:25}
	check(PriorityAllocation.is_valid_distribution(historic) and not PriorityAllocation.is_valid_new_distribution(historic),"Historic five-percent weights remain readable but cannot be newly committed")
	var path:="res://scripts/ui/priority_budget_feedback.gd"
	check(FileAccess.file_exists(path),"Shared budget feedback exists")
	if FileAccess.file_exists(path):
		var group:=Node.new();root.add_child(group)
		var sliders:Array=[]
		for i in 4:
			var slider:=VSlider.new();slider.min_value=10;slider.max_value=50;slider.value=25;group.add_child(slider);sliders.append(slider)
		var feedback:Node=load(path).new();group.add_child(feedback);feedback.bind_controls(sliders)
		sliders[0].value=30
		check(feedback.over_budget and is_zero_approx(feedback.intensity),"Crossing 100 starts red filter at zero")
		feedback.advance(0.35)
		check(feedback.intensity>0 and feedback.intensity<1,"Red filter rises gradually")
		var rising:float=feedback.intensity
		feedback.advance(0.35);check(is_equal_approx(feedback.intensity,1),"Filter reaches full red")
		feedback.advance(0.35);check(is_equal_approx(feedback.intensity,rising),"Filter falls gradually")
		for slider in sliders:check(slider.self_modulate==sliders[0].self_modulate,"All sliders share filter phase")
		sliders[0].value=25;check(not feedback.over_budget and sliders[0].self_modulate==Color.WHITE,"Corrected budget clears filter")
		sliders[1].value=30;check(is_zero_approx(feedback.intensity),"Second over-budget crossing restarts at zero")
		group.queue_free();await process_frame
	# The contract UI is inspected without changing the live game or its profile.
	var phase:=ContractPhase.new();root.add_child(phase);await process_frame
	check(phase._priority_inputs.size()==4,"Contract has four priority controls")
	for input in phase._priority_inputs.values():check(input is VSlider and input.min_value==20 and input.max_value==40,"Contract uses current untrained vertical slider bounds")
	check(phase._priority_chart!=null,"Contract uses the shared influence pie chart")
	phase.queue_free();await process_frame
	print("Usability priorities: %d failures"%failures);quit(failures)
