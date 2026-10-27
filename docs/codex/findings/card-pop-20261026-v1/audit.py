from pathlib import Path
import hashlib,json,subprocess,zipfile
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
paths=['patch-notes/scripts/ui/hand_presentation.gd','patch-notes/scripts/ui/card_play_burst.gd','patch-notes/scripts/market/rival_world_checkpoint.gd','patch-notes/scripts/debug/verify_card_pop.gd','docs/codex/logs/2026-10-26-card-pop-v1.md']
receipts={}
for name in ['baseline','pop-red','pop-green','pop-green-v2','pop-final','pop-drained','music-sync','native','tutorial','cold-final','search-first']:
 p=OUT/(name+'-run.json');r=json.loads(p.read_text())
 if name in ['baseline','pop-drained','music-sync','native','tutorial','cold-final']:
  assert r['exit']==0 and not r['errors'],name
 receipts[name]={'sha256':sha(p),'exit':r['exit'],'errors':r['errors'],'command':r['command']}
captures={str(p.relative_to(OUT)):sha(p) for p in sorted((OUT/'native').glob('*.png'))}
assert len(captures)==6
pair=json.loads((OUT/'before-pair.json').read_text())
assert pair['rival_world']['source_identity']=='a4d9fc318694ef143ea9d59147ae8c5e33a823d31d05a68b35d74203025b51c5'
archive=ROOT/'docs/codex/threads/contracts/handoffs/crown-feedback-20261026-v1/base-source.zip'
with zipfile.ZipFile(archive) as z:
 changes=[]
 for name in z.namelist():
  if name.startswith('scripts/') and not name.startswith('scripts/debug/'):
   p=ROOT/'patch-notes'/name
   if z.read(name)!=p.read_bytes():changes.append(name)
 assert sorted(changes)==['scripts/market/rival_world_checkpoint.gd','scripts/ui/hand_presentation.gd'],changes
 # One added non-debug helper, and only the two intended existing runtime edits.
 additions=[str(p.relative_to(ROOT/'patch-notes')).replace('\\','/') for p in (ROOT/'patch-notes/scripts').rglob('*.gd') if not str(p.relative_to(ROOT/'patch-notes')).replace('\\','/').startswith('scripts/debug/') and str(p.relative_to(ROOT/'patch-notes')).replace('\\','/') not in z.namelist()]
 assert additions==['scripts/ui/card_play_burst.gd'],additions
result={'date':'2026-10-26','branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'source_sha256':{p:sha(ROOT/p) for p in paths},'existing_runtime_edits':changes,'added_runtime_scripts':additions,'receipts':receipts,'native_capture_sha256':captures,'before_pair_sha256':sha(OUT/'before-pair.json'),'player_build_rebuilt':False,'committed':False,'pushed':False}
(OUT/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
print('PASS: three intended runtime paths; preserved prior runtime edits; six captures; focused/music/tutorial/native/restore receipts verified')
