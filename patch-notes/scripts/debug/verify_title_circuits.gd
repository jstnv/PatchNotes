extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize()->void:run.call_deferred()
func run()->void:
	create_timer(30).timeout.connect(func():push_error("Circuit verifier timed out");quit(2))
	var script_path:="res://scripts/ui/menu_circuit_background.gd"
	check(ResourceLoader.exists(script_path),"Full-screen circuit background replaces the panel using the existing observer")
	if not ResourceLoader.exists(script_path):quit(failures);return
	var Graph=load("res://scripts/ui/circuit_geometry.gd")
	var Model=load("res://scripts/ui/circuit_pulse_field.gd")
	var Config=load("res://scripts/ui/circuit_flow_settings.gd")
	var graph=Graph.new()
	for dimensions in [Vector2(1152,648),Vector2(1280,720),Vector2(1920,1080),Vector2(2560,1080),Vector2(720,600),Vector2(360,800),Vector2(360,1280),Vector2(320,1440)]:
		graph.rebuild(dimensions)
		check(graph.routes.size()==11 and graph.forks.size()==3,"Eight full routes and three functional forks at "+str(dimensions))
		var mesh:ArrayMesh=graph.ribbon_mesh();var arrays:=mesh.surface_get_arrays(0)
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var triangles:PackedInt32Array=arrays[Mesh.ARRAY_INDEX];var folded:=0
		for index in range(0,triangles.size(),3):
			var a:=vertices[triangles[index]];var b:=vertices[triangles[index+1]];var c:=vertices[triangles[index+2]]
			if Vector2(b.x-a.x,b.y-a.y).cross(Vector2(c.x-a.x,c.y-a.y))>.01:folded+=1
		check(folded==0,"Cached glow ribbon has no folded triangles at "+str(dimensions)+" folded="+str(folded))
		for id in graph.routes.size():
			var curve:Curve2D=graph.routes[id];var baked:=curve.get_baked_points();var monotonic:=true;var in_height:=true
			for i in range(1,baked.size()):
				monotonic=monotonic and baked[i].x>=baked[i-1].x
				in_height=in_height and baked[i].y>0 and baked[i].y<dimensions.y
			check(baked[0].x<0 and baked[-1].x>dimensions.x and monotonic and in_height,"Route%d crosses the full viewport with strictly rightward flow"%id)
			var angles:=true;var raw:PackedVector2Array=graph.raw_routes[id]
			for i in range(1,raw.size()):
				var delta:=raw[i]-raw[i-1]
				angles=angles and delta.x>0 and (absf(delta.y)<.01 or absf(absf(delta.y)-delta.x)<.01)
			check(angles,"Route%d uses horizontal segments and45-degree changes before rounding"%id)
		for source in graph.forks:
			var fork:Dictionary=graph.forks[source];var shared:=true
			for offset in range(0,int(fork.distance),17):
				shared=shared and graph.routes[source].sample_baked(offset).distance_to(graph.routes[fork.target].sample_baked(offset))<.25
			check(shared,"Split route%d preserves incoming trail at %s"%[source,dimensions])
	graph.rebuild(Vector2(1280,720))
	var config=Config.new();var quiet=Model.new();quiet.bind(graph,config)
	var bass=Model.new();bass.bind(graph,config);var mid=Model.new();mid.bind(graph,config);var treble=Model.new();treble.bind(graph,config)
	var neutral=Model.new();neutral.bind(graph,config)
	seed(991);var expected_random:=randf();seed(991)
	var started:=Time.get_ticks_usec();var builds:int=graph.builds
	for step in 240:
		quiet.step(1.0/60,Vector3.ONE,false);neutral.step(1.0/60,Vector3.ZERO,true)
		bass.step(1.0/60,Vector3(1,0,0),true);mid.step(1.0/60,Vector3(0,1,0),true);treble.step(1.0/60,Vector3(0,0,1),true)
	print("MODEL_FIVE_FIELDS_240_STEPS_US=",Time.get_ticks_usec()-started)
	check(is_equal_approx(randf(),expected_random),"Circuit presentation does not consume gameplay RNG")
	check(graph.builds==builds,"Simulation never rebuilds geometry")
	check(quiet.fallback and quiet.count()>0 and quiet.speed>0 and quiet.luminosity<.2,"Missing/muted spectrum keeps subdued continuous fallback flow")
	check(bass.tail>neutral.tail and bass.luminosity>neutral.luminosity and bass.thickness>neutral.thickness and bass.bloom>neutral.bloom,"Bass increases tail length, brightness, thickness and bloom")
	check(mid.speed>neutral.speed and mid.total_spawned>neutral.total_spawned,"Mids increase continuous speed and spawn frequency")
	check(treble.total_spawned>neutral.total_spawned,"Treble introduces bounded secondary pulses")
	var branches=Model.new();var branch_config=Config.new();branch_config.branching_probability=1;branches.bind(graph,branch_config)
	for i in 6:branches.spawn(1,1)
	for i in 5:branches.pulses[i].active=false
	var parent=branches.pulses[5];parent.distance=graph.forks[1].distance-1
	branches.fallback=false;branches._spawn_clock=10;branches.step(.05,Vector3(.5,.3,0),true)
	var child=branches.pulses[0]
	check(child.active and child.route==graph.forks[1].target and child.color_index==parent.color_index,"Fork creates a real connected branch with inherited color")
	check(is_equal_approx(child.distance,parent.distance),"A newly split child advances exactly once even when reusing an earlier pool slot")
	check(child.split and child.strength<parent.strength,"Split children are smaller and cannot recursively multiply")
	for i in 100:branches.spawn(0,i%2)
	check(branches.count()==branch_config.max_pulses,"Hard pulse cap bounds simultaneous flow")
	branch_config.max_pulses=4;branches.step(.016,Vector3.ONE,true)
	check(branches.count()<=4,"Lowering the live tuning cap also bounds existing pulses")
	branches._spawn_clock=200
	for i in 7200:branches.step(1.0/60,Vector3.ZERO,false)
	check(branches.count()==0,"Pulses and tails retire naturally beyond the right edge")
	var repeat_a=Model.new();var repeat_b=Model.new();repeat_a.bind(graph,config);repeat_b.bind(graph,config)
	for i in 600:
		var input:=Vector3(.4,.3,.8 if i%80<5 else .1)
		repeat_a.step(1.0/60,input,true);repeat_b.step(1.0/60,input,true)
	var same:=true
	for i in repeat_a.pulses.size():
		var a=repeat_a.pulses[i];var b=repeat_b.pulses[i]
		same=same and a.active==b.active and a.route==b.route and a.color_index==b.color_index and is_equal_approx(a.distance,b.distance)
	check(same,"The same input produces identical deterministic pulse simulation")
	var node=load(script_path).new();root.add_child(node);node.size=Vector2(1280,720);await process_frame
	check(node.get_script().get_base_script().resource_path=="res://scripts/ui/menu_audio_visualizer.gd","Circuits inherit and reuse the existing spectrum observer")
	check(node.mouse_filter==Control.MOUSE_FILTER_IGNORE and node.focus_mode==Control.FOCUS_NONE,"Circuit background never intercepts native menu input")
	node.free()
	print("TITLE_CIRCUITS checks=%d failures=%d"%[checks,failures]);quit(failures)
