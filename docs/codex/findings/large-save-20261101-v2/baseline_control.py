"""Reproduce unrelated verifier failures with the exact pre-fix production files."""
from pathlib import Path
import importlib.util,json,shutil,subprocess,sys
out=Path(__file__).resolve().parent;root=out.parents[3];m=json.loads((out/'build-manifest.json').read_text(encoding='utf-8'))
sys.path.insert(0,str(root));from tools import simulate as sim
spec=importlib.util.spec_from_file_location('support',root/'docs/codex/findings/export-queue-v3/export.py');support=importlib.util.module_from_spec(spec);spec.loader.exec_module(support);support.OUT=out
control=Path(m['workspace'])/'baseline-control';shutil.copytree(Path(m['project']),control)
shutil.copytree(root/'patch-notes/scripts/debug',control/'scripts/debug')
originals={}
for src in (out/'before-production/scripts').rglob('*.gd'):
    rel=src.relative_to(out/'before-production');shutil.copy2(src,control/rel);originals[rel.as_posix()]=support.sha(src)
target=(control/'scripts/finance/journal_key.gd').resolve();assert target.is_relative_to(control.resolve());target.unlink()
profile=Path(m['workspace'])/'baseline-profile';profile.mkdir();env=support.isolated_export_environment(profile)
godot=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe')
support.run('baseline-import',[godot,'--headless','--path',control,'--editor','--import','--quit'],env,profile,timeout=180)
rows=[]
for name in ['verify_finance_observation','verify_bank_integration','verify_campaign_latency']:
    argv=[str(godot),'--headless','--audio-driver','Dummy','--path',str(control),'--script','res://scripts/debug/'+name+'.gd']
    p=subprocess.run(argv,cwd=control,env=env,capture_output=True,timeout=180);log=p.stdout+p.stderr
    (out/(name+'-baseline.log')).write_bytes(log)
    rows.append({'name':name,'exit':p.returncode,'errors':[line for line in log.decode('utf-8',errors='replace').splitlines() if line.startswith(('ERROR:','SCRIPT ERROR:'))]})
    print(name,p.returncode,len(rows[-1]['errors']),flush=True)
(out/'baseline-control.json').write_text(json.dumps({'project':str(control),'original_files':originals,'results':rows},indent=2),encoding='utf-8',newline='\n')
