extends RefCounted
## Curated horizontal routes, baked only at resize. All forks form a directed DAG.
const BASE_ROUTES:=8
var routes:Array[Curve2D]=[]
var raw_routes:Array[PackedVector2Array]=[]
var paint_paths:Array[PackedVector2Array]=[]
var forks:Dictionary={}
var junctions:PackedVector2Array=[]
var area:=Vector2.ZERO
var builds:=0
var unit:=1.0
var _height:=0.0
var _top:=0.0
func rebuild(dimensions:Vector2)->void:
	if area==dimensions:return
	area=dimensions;builds+=1;unit=clampf(area.y/720.0,0.5,2.0)
	_height=minf(maxf(1,area.y-48),area.x*0.62);_top=(area.y-_height)*0.5
	routes.clear();raw_routes.clear();paint_paths.clear();forks.clear();junctions.clear()
	_add(_route(.175,[[.36,.075]]))
	_add(_route(.235,[[.21,.31],[.43,.235],[.85,.155]]))
	_add(_route(.275,[[.16,.38],[.33,.455],[.63,.35]]))
	_add(_merge(.435,[[.22,.38]],2,.24))
	_add(_merge(.53,[[.14,.48],[.44,.455]],2,.48))
	_add(_route(.595,[[.17,.695],[.37,.665],[.52,.605],[.73,.565],[.94,.50]]))
	_add(_route(.775,[[.29,.735],[.44,.695],[.70,.79]]))
	_add(_route(.92,[[.11,.86],[.35,.82],[.80,.88]]))
	_branch(1,.48,2,.72)
	_branch(2,.39,5,.58)
	_branch(5,.56,6,.76)
	for pair in [[0,.37],[3,.24],[4,.48],[7,.30]]:
		junctions.append(_at_x(raw_routes[pair[0]],area.x*pair[1]))
func _route(start_y:float,turns:Array)->PackedVector2Array:
	var points:=PackedVector2Array([Vector2(-40*unit,_top+start_y*_height)])
	for turn in turns:
		var end:=Vector2(float(turn[0])*area.x,_top+float(turn[1])*_height)
		var last:Vector2=points[-1]
		points.append(Vector2(end.x-absf(end.y-last.y),last.y));points.append(end)
	points.append(Vector2(area.x+40*unit,points[-1].y));return points
func _at_x(points:PackedVector2Array,x:float)->Vector2:
	for i in range(1,points.size()):
		if points[i].x>=x:return points[i-1].lerp(points[i],(x-points[i-1].x)/(points[i].x-points[i-1].x))
	return points[-1]
func _prefix(points:PackedVector2Array,x:float)->PackedVector2Array:
	var result:=PackedVector2Array()
	for point in points:
		if point.x<x:result.append(point)
	result.append(_at_x(points,x));return result
func _suffix(points:PackedVector2Array,x:float)->PackedVector2Array:
	var result:=PackedVector2Array([_at_x(points,x)])
	for point in points:
		if point.x>x:result.append(point)
	return result
func _merge(start:float,turns:Array,destination:int,join_x:float)->PackedVector2Array:
	var points:=_route(start,turns);points.remove_at(points.size()-1)
	points.append_array(_suffix(raw_routes[destination],join_x*area.x));return points
func _curve(points:PackedVector2Array)->Curve2D:
	var curve:=Curve2D.new();curve.bake_interval=3*unit
	curve.add_point(points[0])
	for i in range(1,points.size()-1):
		var incoming:Vector2=(points[i]-points[i-1]).normalized()
		var outgoing:Vector2=(points[i+1]-points[i]).normalized()
		if incoming.dot(outgoing)>0.999:
			curve.add_point(points[i]);continue
		var trim:=minf(minf(14*unit,area.x*.012),minf(points[i].distance_to(points[i-1]),points[i].distance_to(points[i+1]))*.3)
		var enter:=points[i]-incoming*trim;var leave:=points[i]+outgoing*trim
		curve.add_point(enter,Vector2.ZERO,incoming*trim*(2.0/3.0))
		curve.add_point(leave,-outgoing*trim*(2.0/3.0),Vector2.ZERO)
	curve.add_point(points[-1]);return curve
func _add(points:PackedVector2Array)->void:
	raw_routes.append(points);var curve:=_curve(points);routes.append(curve)
	paint_paths.append(curve.get_baked_points())
func _branch(source:int,fork_fraction:float,destination:int,join_fraction:float)->void:
	var start:=_at_x(raw_routes[source],fork_fraction*area.x)
	var end:=_at_x(raw_routes[destination],join_fraction*area.x)
	var margin:=minf(20*unit,(end.x-start.x-absf(end.y-start.y))*.35)
	var connector:=PackedVector2Array([start,Vector2(end.x-margin-absf(end.y-start.y),start.y),Vector2(end.x-margin,end.y),end])
	var complete:=_prefix(raw_routes[source],start.x)
	complete.append_array(connector.slice(1));complete.append_array(_suffix(raw_routes[destination],end.x).slice(1))
	var target:=routes.size();routes.append(_curve(complete));raw_routes.append(complete)
	paint_paths.append(_curve(connector).get_baked_points())
	forks[source]={"distance":routes[source].get_closest_offset(start),"target":target,"point":start}
	junctions.append(start);junctions.append(end)

func ribbon_mesh()->ArrayMesh:
	var vertices:=PackedVector3Array();var uvs:=PackedVector2Array()
	var colors:=PackedColorArray();var indices:=PackedInt32Array()
	for route in routes.size():
		var points:=routes[route].get_baked_points();var distance:=0.0;var base:=vertices.size()
		# Inner offsets cannot exceed local curvature radius. Include neighboring
		# samples so the width is already bounded when entering a rounded join.
		var limits:=PackedVector2Array();limits.resize(points.size())
		for i in points.size():
			limits[i]=Vector2.ONE*48*unit
			for j in range(maxi(1,i-3),mini(points.size()-1,i+4)):
				var incoming:=points[j]-points[j-1];var outgoing:=points[j+1]-points[j]
				var turn:=incoming.cross(outgoing)
				if absf(turn)<.0001:continue
				var radius:=incoming.length()*outgoing.length()*(points[j+1]-points[j-1]).length()/(2*absf(turn))
				if turn>0:limits[i].y=minf(limits[i].y,radius*.72)
				else:limits[i].x=minf(limits[i].x,radius*.72)
		for i in points.size():
			if i>0:distance+=points[i].distance_to(points[i-1])
			var direction:Vector2=(points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
			var normal:=Vector2(-direction.y,direction.x)
			for side:float in [-1.0,1.0]:
				var width:=limits[i].x if side<0 else limits[i].y
				var point:=points[i]+normal*(width*side)
				vertices.append(Vector3(point.x,point.y,0));uvs.append(Vector2(distance,width*side))
				colors.append(Color(float(route)/16.0,limits[i].x/(48*unit),limits[i].y/(48*unit),1))
			if i>0:
				var a:=base+(i-1)*2;var b:=base+i*2
				indices.append_array(PackedInt32Array([a,a+1,b,b,a+1,b+1]))
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh
