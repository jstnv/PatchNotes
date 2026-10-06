"""Final stable-source gate, extra middling continuation, and rendered report."""
import concurrent.futures,json,os,subprocess,tempfile,sys
from pathlib import Path
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/lifespan-verification-v2'
if __name__=='__main__':
    (v.OUT/'additional-continuation-plan.json').write_text(json.dumps({'policy':'ordinary','case':5,'first_review':5.9,'reason':'nearest first-game Review to 6; adds a middling case to the previously selected cohort median 7.7','games':5,'productive_action_limit':120}),encoding='utf-8')
    if '--gate-only' not in sys.argv:
        v.run('continuation-middling',v.ROOT,['--script','res://analysis/lifespan_verify_routes_v2.gd','--','--policy=ordinary','--case=5','--games=5','--limit=120'])
    results=[v.run('final-import',v.ROOT,['--editor','--import'])]
    if results[0]['exit']!=0 or results[0]['errors']:raise RuntimeError('Import failed')
    suites=sorted((v.ROOT/'scripts/debug').glob('verify_*.gd'))
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results+=list(pool.map(lambda p:v.run('final-'+p.stem,v.ROOT,['--script','res://scripts/debug/'+p.name]),suites))
    diff=subprocess.run(['git','diff','--check'],cwd=v.ROOT,capture_output=True)
    (v.OUT/'final-diff-check.log').write_bytes(diff.stdout+diff.stderr)
    (v.OUT/'final-gate.json').write_text(json.dumps({'suite_count':len(suites),'results':results,'diff_check':diff.returncode,'passed':all(x['exit']==0 and not x['errors'] for x in results) and diff.returncode==0},indent=2),encoding='utf-8')
    profile=Path(tempfile.mkdtemp(prefix='pn-lifespan-render-'));env=os.environ.copy()
    for k in ['APPDATA','LOCALAPPDATA']:
        (profile/k).mkdir();env[k]=str(profile/k)
    cmd=[v.GODOT,'--path',str(v.ROOT),'--script','res://scripts/debug/verify_lifespan_reporting_integrity.gd','--','--capture']
    p=subprocess.run(cmd,env=env,capture_output=True,timeout=90)
    (v.OUT/'report-render.log').write_bytes(p.stdout+p.stderr)
    (v.OUT/'report-render.command.json').write_text(json.dumps({'command':cmd,'profile':str(profile),'exit':p.returncode},indent=2),encoding='utf-8')
    print('Final gate and render done',p.returncode,flush=True)
