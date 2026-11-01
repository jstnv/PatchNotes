extends SceneTree
const R=preload("res://scripts/market/rival_trial.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
 await process_frame
 var packet: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/calendar-four-cycle-20261031-v1/preceding-odd-world-v2/report.json"))
 check(packet.source=="eea06deffab0895c9a80adacc7f6238cbef5cc313cd03d2f93f6b3d2e1603b3e","Exact1207-file preceding build captured odd world")
 var cat=root.get_node("CardDatabase").get_development_catalog()
 var a:=StudioCheckpoint.new();var c=preload("res://scripts/market/rival_world_checkpoint.gd").new()
 var player:=a.hydrate(packet.player)
 var world=c.restore(packet.world,packet.player,player,cat)
 check(world!=null,"Genuine c9 eight-rival paired restore: "+c.error)
 if world!=null:
  check(world.calendars_aligned() and world.cycle==9 and player.get_current_month()==5,"Old second half becomes Week3 without rescaling raw9")
  for cycle in [10,11]:
   check(player.complete_productive_action(),"Player future legal calendar action")
   var tick:=world.advance_committed_player_cycle(R.policies(world),R.ZERO_STEPS)
   check(tick.ok,"Future rival scheduler at raw"+str(cycle)+": "+str(tick))
  check(world.market_snapshot.version==5 and world.market_snapshot.cycle_start==11,"New month proof may begin at odd raw11")
  var pp:=a.capture(player);var ww: Dictionary=c.capture(world)
  check(not pp.is_empty() and not ww.is_empty(),"Odd modern Market/factor capture: "+a.error+c.error)
  if not pp.is_empty() and not ww.is_empty():
   var cold=c.restore(JSON.parse_string(JSON.stringify(ww)),JSON.parse_string(JSON.stringify(pp)),a.hydrate(pp),cat)
   check(cold!=null,"Odd-boundary modern factors cold restore: "+c.error)
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
