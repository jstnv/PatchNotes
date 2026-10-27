from pathlib import Path
import os,subprocess,json
BASE=Path(__file__).resolve().parent;ROOT=BASE.parents[3]
env=os.environ.copy()
for key in ('APPDATA','LOCALAPPDATA'):
 p=ROOT/'.codex-godot-temp/bank-final-age-v1'/key;p.mkdir(parents=True,exist_ok=True);env[key]=str(p)
env['PN_SAVED_EVIDENCE']=str(BASE.parent/'queue-completion-20261011-v1/checkpoints/education-distressed-committed/checkpoint.33.json')
env['PN_PROBE_OUTPUT']=str(BASE/'legal-age-probe.json')
cmd=[r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe','--headless','--audio-driver','Dummy','--path',str(BASE.parent/'queue-execution-20261017-v2/final-ui-wire-v7/project'),'--script',str(BASE/'legal_age_probe.gd')]
(BASE/'probe-command.json').write_text(json.dumps({'command':cmd,'input':env['PN_SAVED_EVIDENCE'],'policy':'Neon, first four visible candidates, at most eight commands'},indent=2))
with (BASE/'probe.log').open('wb') as log:r=subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=180)
print((BASE/'probe.log').read_text(encoding='utf-8',errors='replace'));raise SystemExit(r.returncode)
