from pathlib import Path
p=Path('docs/codex/findings/queue-20261018-v2/run.py');s=p.read_text().replace("env['PN_ROSTER_OUTPUT'] = str(OUT)","env['PN_ROSTER_OUTPUT'] = str(OUT)\nenv['PN_GAMEPLAY_PRIOR_SAVES'] = str(ROOT/'docs/codex/findings/store-gameplay-links-20261018-v1/before/produce_gameplay_prior.json')")
p.write_bytes(s.encode())
p=Path('docs/codex/findings/queue-20261018-v2/capture_roster.gd');s=p.read_text().replace('check(menu._preview.get_line_count()==menu._preview.get_visible_line_count(),','check(menu._preview.get_global_rect().end.y <= menu._preview.get_parent().get_global_rect().end.y,')
s=s.replace('"%s-%dx%d.png"','"final-%s-%dx%d.png"');p.write_bytes(s.encode())
import subprocess,sys,json
out=p.parent.resolve(); results=[]
for label,script,args in [('cult-fixed','res://scripts/debug/verify_cult_following.gd',[]),('contracts-fixed','res://scripts/debug/verify_contract_challenge_publishers.gd',[]),('gameplay-fixed','res://scripts/debug/verify_gameplay_tree.gd',[]),('roster-final','res://scripts/debug/verify_studio_roster_versions.gd',[]),('native-final',str(p.resolve()),[])]:
    result=subprocess.run([sys.executable,str(out/'run.py'),label,script,*args],capture_output=True,text=True)
    results.append({'label':label,'exit':result.returncode,'output':result.stdout,'stderr':result.stderr})
    (out/'fix-results.json').write_text(json.dumps(results,indent=2));print(label,result.returncode,flush=True)
