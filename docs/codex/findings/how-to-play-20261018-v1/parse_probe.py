from run import *
stage = OUT / 'parse-v1'
cmd = [GODOT,'--headless','--audio-driver','Dummy','--path',str(stage/'project'),
       '--check-only','--script','res://scripts/ui/how_to_play_content.gd']
result = subprocess.run(cmd, env=sim.isolated_environment(stage/'profile-probe'), capture_output=True, timeout=60)
(stage/'content-parse.log').write_bytes(result.stdout+result.stderr)
print((result.stdout+result.stderr).decode('utf-8',errors='replace'))
print('exit',result.returncode)
