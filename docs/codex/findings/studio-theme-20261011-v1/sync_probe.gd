extends SceneTree
func _initialize():
 run.call_deferred()
func run():
 var s = AudioStreamSynchronized.new()
 s.stream_count = 2
 for i in range(2):
  var w = load("res://assets/audio/crunch_time_70/crunch_time_A_jazz.wav").duplicate()
  w.loop_mode = AudioStreamWAV.LOOP_FORWARD
  w.loop_end = roundi(w.get_length() * w.mix_rate)
  s.set_sync_stream(i,w)
 s.set_sync_stream_volume(1,-100)
 var p = AudioStreamPlayer.new()
 root.add_child(p)
 p.stream = s
 p.play()
 await create_timer(0.25).timeout
 print("SYNC length=",s.get_length()," position=",p.get_playback_position())
 p.seek(s.get_length()-0.1)
 await create_timer(0.3).timeout
 print("WRAP position=",p.get_playback_position()," loops=",p.get_stream_playback().get_loop_count())
 p.stop()
 quit()
