from pathlib import Path
import sys
H=Path(__file__).resolve().parent;R=H.parents[5]
sys.path.insert(0,str(R/'tools'));import simulate as sim
out=H/'orphan-red-v1';out.mkdir()
g='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
try:sim.run_process('orphan',[g,'--headless','--path',str(H/'assembly-v1/project'),'--script',str(H/'orphan_red.gd')],out,sim.isolated_environment(out/'profile'),600)
except RuntimeError as e:print(e)
r=sim.read_json(out/'orphan.command.json');assert r['exit']==1
assert 'ORPHAN_RECEIPT_REJECTED=false' in (out/'orphan.log').read_text()
print('Orphan receipt RED reproduced')
