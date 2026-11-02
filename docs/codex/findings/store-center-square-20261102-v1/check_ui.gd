extends SceneTree
const Layout=preload("res://scripts/ui/feature_store_layout.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var failures:=0
var checks:=0
func check(ok: bool,label: String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func frames(n: int=4)->void:
 for i in n:await process_frame
func shot(tag: String)->void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OS.get_environment("PN_FOCUS_TEST_DIRECTORY").path_join(tag+".png"))
func go()->void:
 await process_frame
 var catalog=root.get_node("CardDatabase").get_development_catalog()
 var session=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"center_square","studio_name":"Square Studio","specialty":"action","traits":[],"seed":"7301"},catalog)
 var run: RunState=session.run
 var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Square Engine"))
 var store:=FeatureStore.new();root.add_child(store);store.setup(run);store.open_store(created.engine_id);await frames(8)
 var map=store._map
 check(map.get("center_square") is Rect2,"Runtime map owns empty center square")
 if failures:quit(1);return
 var frozen: Dictionary=Replay.freeze(run)
 for dimensions in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=dimensions;root.content_scale_size=dimensions;await frames(5)
  map._initial_overview();await frames(8)
  check(map.center_square.size==Vector2.ONE*5*Layout.PITCH,"Exact5x5 node-pitch square "+str(dimensions))
  for id: StringName in store._nodes:
   check(not map.center_square.intersects(map.node_footprint(store._nodes[id])),"Node/name stays outside center "+str(id))
  for header: Label in map.category_headers.values():check(not map.center_square.intersects(map.header_rect(header)),"Category label stays outside center "+header.text)
  check(map.category_paths.size()==5,"Five stems originate at square")
  var clear:=true
  for path: PackedVector2Array in map.category_paths:
   clear=clear and _on_border(map.center_square,path[0])
   for i in range(1,path.size()):
    var a:=path[i-1];var z:=path[i]
    clear=clear and not _segment_crosses_interior(a,z,map.center_square)
    for node: Control in store._nodes.values():clear=clear and not _segment_crosses_interior(a,z,map.node_footprint(node))
    for header: Label in map.category_headers.values():clear=clear and not _segment_crosses_interior(a,z,map.header_rect(header))
  check(clear,"Stems avoid square interior, nodes and headings")
  var square_screen: Rect2=map.tree.get_global_transform()*map.center_square
  check(map._map_rect().grow(0.1).encloses(square_screen),"Opening view shows the whole empty square")
  for id: StringName in [&"4_color_palette",&"8_bit_sound",&"keyboard_and_mouse",&"lives_system",&"simple_story"]:
   check(map._map_rect().encloses(store._nodes[id].get_global_rect()),"Opening frame includes nearby root "+str(id))
  var routed_clear:=true
  for path: PackedVector2Array in map.edge_routes.values():
   for i in range(1,path.size()):routed_clear=routed_clear and not _segment_crosses_interior(path[i-1],path[i],map.center_square)
  check(routed_clear,"Prerequisite routes keep the square interior empty")
  await shot("opening-"+str(dimensions.x))
  map.fit_map();await frames(5);await shot("overview-"+str(dimensions.x))
  map._focus_node(&"dynamic_sequencing")
  var end:=Time.get_ticks_msec()+5000
  while map.focusing and Time.get_ticks_msec()<end:await process_frame
  await frames()
  check(map.popup.visible and store._selected==&"dynamic_sequencing" and store._body.get_global_rect().encloses(map.popup.get_global_rect()),"Readable focused inspection remains bounded")
  await shot("detail-"+str(dimensions.x));map.dismiss()
 check(Replay.freeze(run)==frozen,"Overview/fit/focus preserve full Run, finance/history and RNG")
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity()}))
 print("STORE_SQUARE_UI checks=%d failures=%d"%[checks,failures]);quit(failures)

func _on_border(rect: Rect2, point: Vector2) -> bool:
 if not rect.grow(0.01).has_point(point): return false
 return minf(minf(absf(point.x - rect.position.x), absf(point.x - rect.end.x)), minf(absf(point.y - rect.position.y), absf(point.y - rect.end.y))) < 0.01

func _segment_crosses_interior(start: Vector2, end: Vector2, rect: Rect2) -> bool:
 var inner := rect.grow(-0.01)
 if is_equal_approx(start.x, end.x):
  return start.x > inner.position.x and start.x < inner.end.x and maxf(minf(start.y, end.y), inner.position.y) < minf(maxf(start.y, end.y), inner.end.y)
 if is_equal_approx(start.y, end.y):
  return start.y > inner.position.y and start.y < inner.end.y and maxf(minf(start.x, end.x), inner.position.x) < minf(maxf(start.x, end.x), inner.end.x)
 return true
