from run import *
cid='mean-puzzle-4522-sound_sprites'
write(HERE/'verification-addendum.json',dict(replays=[cid],reason='Verify the observed three consecutive zero awards; no extra measured cases.'))
assert execute('replay-'+cid,[sys.executable,'tools/simulate.py','replay','--bundle',str(RAW/'branches-puzzle-b'),'--case',cid,'--output',str(RAW/('replay-'+cid)),'--timeout','240','--godot',GODOT])==0
