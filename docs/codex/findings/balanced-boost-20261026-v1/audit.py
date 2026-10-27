from pathlib import Path
import hashlib,json,subprocess

out=Path(__file__).resolve().parent
root=out.parents[3]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

labels=['arithmetic-final','design-v2','alpha-v2','design-commands','alpha-commands',
        'command-parity','characterization-v3','overflow','tutorial-model',
        'tutorial-native','music-grid','baseline','cold-final']
receipts={}
for label in labels:
    p=out/(label+'-run.json'); r=json.loads(p.read_text())
    assert r['exit']==0 and not r['errors'],(label,r)
    receipts[label]={'receipt_sha256':sha(p),'command':r['command'],'exit':r['exit']}
before=json.loads((out/'before.json').read_text())
assert sha(root/'patch-notes/scripts/ui/hand_presentation.gd')==before['scripts/ui/hand_presentation.gd']
assert sha(root/'patch-notes/scripts/simulation/production_hand.gd')==before['scripts/simulation/production_hand.gd']
paths=['scripts/cards/balanced_production.gd','scripts/market/rival_world_checkpoint.gd',
       'scripts/phases/design_phase.gd','scripts/phases/alpha_phase.gd']
paths += ['scripts/ui/'+s+'.gd' for s in ['how_to_play_content','phase_workspace',
          'gameplay_hud','tutorial_overlay','guided_production_tutorial']]
paths += ['scripts/debug/'+s+'.gd' for s in ['verify_balanced_boost','verify_balanced_boost_parity',
          'verify_design_phase','verify_alpha_phase','verify_design_command','verify_alpha_command',
          'verify_guided_tutorial_model','verify_production_extraction','verify_soundtrack_sync']]
docs=['CURRENT_STATE.md','TODO.md','DECISIONS.md','design/core-and-studio.md',
      'logs/2026-10-26-balanced-boost-v1.md']
targets=['patch-notes/'+p for p in paths]+['docs/codex/'+p for p in docs]
check=subprocess.run(['git','-c','core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol',
                      'diff','--check','--',*targets],cwd=root,capture_output=True,text=True)
assert check.returncode==0,check.stdout+check.stderr
result={'date':'2026-10-26','branch':subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip(),
        'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
        'source_sha256':{p:sha(root/p) for p in targets},'receipts':receipts,
        'before_sha256':before,'motion_and_production_dispatch_unchanged':True,
        'diff_check':check.returncode}
(out/'source-pin.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'passing_runs':len(receipts),'pinned_files':len(targets),'diff_check':check.returncode}))
