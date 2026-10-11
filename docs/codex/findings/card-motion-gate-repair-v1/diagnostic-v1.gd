extends "./wrappers/verify_card_motion.gd"

var forced_frame_delay:=false
var observations:Array=[]

func find_map(node:Node)->FeatureStoreMap:
	if node is FeatureStoreMap:return node
	for child:Node in node.get_children():
		var found:=find_map(child)
		if found!=null:return found
	return null

func settle(seconds:=0.70)->void:
	var sample:=is_equal_approx(seconds,0.20)
	var map:=find_map(root) if sample else null
	var row:Dictionary={}
	if sample:
		row={"forced_frame_delay":forced_frame_delay,"timer_seconds":seconds,"wall_start_usec":Time.get_ticks_usec(),"start_zoom":map.zoom,"start_focusing":map.focusing,"tween_before":map._focus_tween.get_total_elapsed_time()}
		if forced_frame_delay:OS.delay_msec(400)
	await create_timer(seconds).timeout
	if sample:
		row.merge({"wall_elapsed_seconds":(Time.get_ticks_usec()-row.wall_start_usec)/1000000.0,"zoom":map.zoom,"focusing":map.focusing,"tween_elapsed":map._focus_tween.get_total_elapsed_time(),"menu_alpha":map.popup.modulate.a})
		observations.append(row);print("OLD_STORE_TIMING ",JSON.stringify(row))

func _verify()->void:
	root.size=Vector2i(1152,648)
	for delayed in [false,true]:
		forced_frame_delay=delayed
		await _store(1152)
	FileAccess.open("res://../docs/codex/findings/card-motion-gate-repair-v1/old-timing.json",FileAccess.WRITE).store_string(JSON.stringify({"observations":observations,"native_assertion_failures":failures}))
	print("Old timing diagnostic failures=",failures);quit(failures)
