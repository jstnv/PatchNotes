## Pure, deterministic Store geometry. Positions never depend on current ownership,
## zoom, category bounds or RNG. Every card uses the same integer-cell lattice.
extends RefCounted

const PITCH := 212.0
const CELLS := {
	&"4_color_palette":Vector2i(-3,-2), &"text":Vector2i(-3,-1),
	&"sprites":Vector2i(-4,-2), &"animated_sprites":Vector2i(-5,-2),
	&"colored_text":Vector2i(-4,-1), &"8_color_palette":Vector2i(-4,-3),
	&"scrolling":Vector2i(-4,0), &"multi_directional_scrolling":Vector2i(-6,-2),
	&"8_bit_sound":Vector2i(3,-2), &"16_bit_sound":Vector2i(4,-3),
	&"main_theme":Vector2i(4,-2), &"recorded_sounds":Vector2i(4,-1),
	&"multiple_soundtracks":Vector2i(5,-2), &"instrumental_sounds":Vector2i(5,-1),
	&"dynamic_sequencing":Vector2i(6,-2),
	&"menu_system":Vector2i(-1,-3), &"keyboard_and_mouse":Vector2i(0,-3),
	&"controller":Vector2i(1,-3), &"save_files":Vector2i(-1,-4),
	&"branching_nodes":Vector2i(-1,-5), &"split_screen":Vector2i(-2,-6),
	&"player_level_editor":Vector2i(1,-6),
	&"lives_system":Vector2i(-3,2), &"enemies":Vector2i(-4,2),
	&"general_combat":Vector2i(-5,2), &"turn_based_combat":Vector2i(-7,2),
	&"character_classes":Vector2i(-7,3), &"timer_system":Vector2i(-3,4),
	&"categorized_scores":Vector2i(-5,4), &"power_ups":Vector2i(-7,4),
	&"score_system":Vector2i(-3,6), &"high_scores":Vector2i(-4,6),
	&"local_leaderboards":Vector2i(-5,6), &"inventory_system":Vector2i(-3,7),
	&"scripted_ai":Vector2i(-5,8), &"difficulty_levels":Vector2i(-8,6),
	&"controls":Vector2i(-3,8),
	&"simple_story":Vector2i(3,2), &"dialogue":Vector2i(4,2),
	&"character_backstories":Vector2i(4,3), &"branching_dialogue":Vector2i(5,2),
	&"character_development":Vector2i(5,3), &"multiple_endings":Vector2i(7,2),
	&"switchable_protagonists":Vector2i(7,4), &"levels":Vector2i(3,6),
	&"maps":Vector2i(4,6), &"exploration":Vector2i(4,7),
	&"secrets":Vector2i(5,7), &"ability_gated_exploration":Vector2i(7,8),
	&"character_skill_checks":Vector2i(8,7),
}

static func center_square() -> Rect2:
	# Five cells on each axis for category labels, never Feature cards.
	return Rect2(Vector2(64,86)-Vector2.ONE*PITCH*2.5,Vector2.ONE*PITCH*5.0)

static func cells(ids: Array) -> Dictionary:
	if ids.size()!=CELLS.size(): return {"error":"Store grid coverage differs from catalog"}
	var used := {}
	var result := {}
	for id: StringName in ids:
		if not CELLS.has(id): return {"error":"Missing Store cell: "+str(id)}
		var cell: Vector2i=CELLS[id]
		if used.has(cell): return {"error":"Occupied Store cell: "+str(cell)}
		used[cell]=id
		result[id]=cell
	return {"cells":result}

## A half-cell corridor separates every 144x172 card/name footprint. Compute
## routes once when the map is built, never during drawing or Research refresh.
## One shared A* grid with fixed insertion order makes every path repeatable.
static func routes(cells_by_id: Dictionary, footprints: Dictionary, edges: Array, origin: Vector2, headers: Array[Rect2], reserved: Rect2=Rect2()) -> Dictionary:
	var low:=Vector2i(0,0)
	var high:=Vector2i(0,0)
	for cell: Vector2i in cells_by_id.values():
		low=low.min(cell*2)
		high=high.max(cell*2)
	var grid:=AStarGrid2D.new()
	grid.region=Rect2i(low-Vector2i(4,4),high-low+Vector2i(9,9))
	grid.cell_size=Vector2.ONE*PITCH/2.0
	grid.offset=origin+Vector2(64,86)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.default_compute_heuristic=AStarGrid2D.HEURISTIC_MANHATTAN
	grid.default_estimate_heuristic=AStarGrid2D.HEURISTIC_MANHATTAN
	grid.update()
	for cell: Vector2i in cells_by_id.values(): grid.set_point_solid(cell*2,true)
	# Inflating headings by half a corridor catches thin rotated label surfaces
	# between grid points, including their surrounding line/arrow clearance.
	for x in range(grid.region.position.x,grid.region.end.x):
		for y in range(grid.region.position.y,grid.region.end.y):
			var cell:=Vector2i(x,y)
			var point:=grid.get_point_position(cell)
			if reserved.has_area() and reserved.has_point(point):grid.set_point_solid(cell,true)
			for header: Rect2 in headers:
				if header.grow(60).has_point(point): grid.set_point_solid(cell,true)
	var result := {}
	for edge: Array in edges:
		var a: Vector2i=cells_by_id[edge[0]]*2
		var b: Vector2i=cells_by_id[edge[1]]*2
		grid.set_point_solid(a,false);grid.set_point_solid(b,false)
		var path:=grid.get_point_path(a,b)
		grid.set_point_solid(a,true);grid.set_point_solid(b,true)
		if path.size()<2: return {"error":"No Store route: "+str(edge)}
		var last:=path.size()-1
		path[0]=port(footprints[edge[0]],(path[1]-path[0]).normalized())
		path[last]=port(footprints[edge[1]],(path[last-1]-path[last]).normalized())
		var compact:=PackedVector2Array([path[0]])
		for index in range(1,last):
			if not (path[index]-compact[-1]).normalized().is_equal_approx((path[index+1]-path[index]).normalized()): compact.append(path[index])
		compact.append(path[last])
		result[str(edge[0])+"->"+str(edge[1])]=compact
	return {"routes":result}

static func port(rect: Rect2, direction: Vector2) -> Vector2:
	var half:=rect.size/2.0
	var reach:=minf(half.x/maxf(absf(direction.x),0.001),half.y/maxf(absf(direction.y),0.001))
	return rect.get_center()+direction*(reach+8.0)
