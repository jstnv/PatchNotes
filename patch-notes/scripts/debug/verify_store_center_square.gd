extends SceneTree
const Layout=preload("res://scripts/ui/feature_store_layout.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func go()->void:
 var script=Layout.new()
 check(script.has_method("center_square"),"Feature Store has explicit empty central square geometry")
 if failures:quit(1);return
 var area: Rect2=script.center_square()
 check(area.size==Vector2.ONE*5.0*Layout.PITCH,"Center spans exactly five grid pitches on both axes")
 var used:={}
 for id: StringName in Layout.CELLS:
  var cell: Vector2i=Layout.CELLS[id]
  check(not used.has(cell),"Unique cell "+str(id));used[cell]=id
  check(abs(cell.x)>2 or abs(cell.y)>2,"Five by five center is empty of "+str(id))
 print("STORE_CENTER checks=%d failures=%d"%[checks,failures]);quit(failures)
