extends SceneTree
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
 await process_frame
 var packet: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/calendar-acceptance-20261031-v2/genuine-current-capture/report.json"))
 check(packet.source=="5717e5e2573ea90a83ac8fe2bc87bbd3c6c10da3fe67524603ae57d3286cf54a","Exact pre-closeout source")
 var a:=StudioCheckpoint.new()
 for row: Dictionary in packet.studios:
  var old:=a.hydrate(row.player)
  check(old!=null,"Preceding Studio restores: "+a.error)
  if old==null:continue
  check(a.capture(old)==row.player,"All dates, finances, histories, engine access and RNG stay exact")
  var same:=a.hydrate(a.capture(old));check(same!=null and a.capture(same)==row.player,"Repeated Continue is idempotent")
 var cat=root.get_node("CardDatabase").get_development_catalog()
 var codec=preload("res://scripts/market/rival_world_checkpoint.gd").new();var p:=a.hydrate(packet.world_player)
 var w=codec.restore(packet.world,packet.world_player,p,cat)
 check(w!=null,"Exact5717 paired world admission: "+codec.error)
 if w!=null:
  check(w.calendars_aligned() and a.capture(p)==packet.world_player,"All preceding player calendar fields/RNG preserved")
  for row: Dictionary in packet.world.studios:check(a.capture(w.studios[StringName(row.id)].run,w.studios[StringName(row.id)].project_id() if not w.studios[StringName(row.id)].in_studio else &"")==row.run,"Preceding rival unchanged "+row.id)
  var current: Dictionary=codec.capture(w);var pp:=a.capture(p)
  check(not current.is_empty() and codec.restore(JSON.parse_string(JSON.stringify(current)),pp,a.hydrate(pp),cat)!=null,"Current paired generation re-saves and cold-restores")
  var bad:=current.duplicate(true);bad.source_identity="unknown-calendar-closeout"
  check(codec.restore(bad,pp,a.hydrate(pp),cat)==null,"Unknown source still rejected")
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
