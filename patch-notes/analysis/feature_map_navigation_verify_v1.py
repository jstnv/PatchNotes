"""Run native input routing, existing Store regressions, and optional render QA."""
import json,os,subprocess,sys,tempfile
from pathlib import Path
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/feature-map-navigation-v1'
if '--render' in sys.argv:
    profile=Path(tempfile.mkdtemp(prefix='pn-map-navigation-render-'))
    env=os.environ.copy()
    for key in ['APPDATA','LOCALAPPDATA']:
        p=profile/key;p.mkdir();env[key]=str(p)
    command=[v.GODOT,'--path',str(v.ROOT),'--rendering-method','gl_compatibility','--position','-5000,-5000',
             '--script','res://scripts/debug/verify_feature_store_navigation.gd','--','--capture']
    p=subprocess.run(command,env=env,capture_output=True,timeout=120)
    (v.OUT/'render.log').write_bytes(p.stdout+p.stderr)
    r=dict(command=command,exit=p.returncode,profile=str(profile))
    (v.OUT/'render.command.json').write_text(json.dumps(r,indent=2))
    print(json.dumps(r));assert p.returncode==0
else:
    results=[v.run('editor-import',v.ROOT,['--editor','--import'])]
    names=['feature_store_navigation','feature_store','feature_store_cycle_purchase','first_studio_feature_economy','main_menu_history']
    for name in names:
        results.append(v.run('verify_'+name,v.ROOT,['--script','res://scripts/debug/verify_'+name+'.gd']))
        if results[-1]['exit']!=0 or results[-1]['errors']:break
    (v.OUT/'verification.json').write_text(json.dumps(results,indent=2))
    assert all(r['exit']==0 and not r['errors'] for r in results)
