from pathlib import Path
import difflib,hashlib,json,shutil,subprocess
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-root-first-rosters-20261025-v1')
BASE=Path('C:/Users/64jus/AppData/Local/Temp/pn-studio-release-actions-20261025-v1/green/project')
def read(p):return json.loads(p.read_text(encoding='utf8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,d):p.write_text(json.dumps(d,indent=2)+'\n',encoding='utf8')
names=['overlay-red','overlay-red-v2','overlay-native','prior-exe-rosters','restore-prior-exe-rosters','eight-genre-campaigns','restore-prior-editor-world','current-world','native-store-hud','native-store-hud-v2','exe-root-rosters','exe-old-rosters','old-exe-world','exe-old-world','exe-current-world','exe-overlay-native']
manifest={}
for name in names:
 out=HERE/'receipts'/name;out.mkdir(parents=True,exist_ok=True)
 for leaf in ['receipt.json','run.log','result.json']:
  source=RAW/name/leaf
  # Large genuine-world/save payloads stay outside the synced checkout.
  if not source.exists() or (leaf=='result.json' and name in ['prior-exe-rosters','current-world','old-exe-world']):continue
  shutil.copy2(source,out/leaf)
 for source in (RAW/name).glob('*'):
  if source.is_file():manifest[str(source)]={'bytes':source.stat().st_size,'sha256':sha(source)}
for name in ['red','green','final-matrix']:
 out=HERE/'receipts'/name;out.mkdir(parents=True,exist_ok=True)
 for leaf in ['result.json','canonical-source.json']:
  source=RAW/name/leaf
  if source.exists():shutil.copy2(source,out/leaf)
 if name=='final-matrix':
  for p in (RAW/name).glob('verify_*.command.json'):shutil.copy2(p,out/p.name)
 for p in (RAW/name).glob('*.log'):manifest[str(p)]={'bytes':p.stat().st_size,'sha256':sha(p)}
audit=RAW/'audit-primitive-roots/result.json'
shutil.copy2(audit,HERE/'independent-roster-audit.json')
capture=HERE/'captures';capture.mkdir(exist_ok=True)
for source in [RAW/'native-hud-captures-v2/store-1280x720.png',RAW/'native-hud-captures-v2/store-900x600.png',RAW/'native-hud-captures-v2/debug-1280x720.png',RAW/'exe-overlay-native/capture/store-overlay-1280.png']:
 shutil.copy2(source,capture/source.name)
 manifest[str(source)]={'bytes':source.stat().st_size,'sha256':sha(source)}
files=['scripts/studio_specialties.gd','scripts/persistence/studio_checkpoint.gd','scripts/market/rival_world_checkpoint.gd','scripts/ui/feature_store.gd','scripts/ui/feature_store_map.gd','scripts/debug/verify_root_first_rosters.gd','scripts/debug/verify_store_transparent_toolbar.gd','scripts/debug/fixtures/studio_specialties_v3.json','scripts/debug/verify_studio_specialties.gd','scripts/debug/verify_studio_roster_versions.gd','scripts/debug/verify_design_phase.gd','scripts/debug/verify_design_command.gd','scripts/debug/verify_alpha_command.gd','scripts/debug/verify_beta_command.gd']
delta={};patch=[]
for rel in files:
 p=ROOT/'patch-notes'/rel;old=BASE/rel
 delta[rel]={'before':sha(old) if old.exists() else None,'after':sha(p)}
 patch.extend(difflib.unified_diff(old.read_text(encoding='utf8').splitlines(True) if old.exists() else [],p.read_text(encoding='utf8').splitlines(True),fromfile='previous/'+rel,tofile='current/'+rel))
write(HERE/'source-delta.json',delta)
(HERE/'scoped-delta.patch').write_text(''.join(patch),encoding='utf8')
matrix=read(RAW/'final-matrix/result.json');assert matrix['pass'] and len(matrix['checks'])==16
for name in names:
 if name.startswith('overlay-red'):continue
 assert read(RAW/name/'receipt.json')['pass'],name
build=read(HERE/'result.json');assert build['pass'] and build['canonical_unchanged']
for item in ['exe','zip']:assert sha(Path(build[item]['path']))==build[item]['sha256']
write(HERE/'external-artifacts.json',{'raw':str(RAW),'build_raw':build['raw'],'files':manifest})
write(HERE/'verification.json',{'pass':True,'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'branch':'main','dirty_before':170,'maintained_suites':16,'matrix_canonical_unchanged':matrix['canonical_unchanged'],'root_roster_checks':318,'historical_roster_version_checks':212,'live_headless_boundaries':106,'native_overlay_checks':87,'native_full_hud_checks':153,'actual_exe_overlay_checks':87,'exact_actual_old_exe_saves':16,'eight_genre_campaigns':read(RAW/'eight-genre-campaigns/result.json'),'build':build,'review':'One fresh read-only reviewer; no actionable findings in scoped runtime delta.','warnings':['New roster verifier exits with six ObjectDB-instance cleanup warnings; assertion/command checks pass. No leak/performance result is claimed.'],'release_ready':False})
print('Evidence/source/artifact manifest PASS')
