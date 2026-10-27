"""Inventory source/docs separately from retained local generated evidence."""
from pathlib import Path
import subprocess,os,json,hashlib
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-v003-publication-20261025-v1');RAW.mkdir(exist_ok=True)
tracked=set(subprocess.check_output(['git','ls-files','-z'],cwd=ROOT).decode().split('\0'))
changed=[p for p in subprocess.check_output(['git','diff','--name-only','-z'],cwd=ROOT).decode().split('\0') if p]
skip_names={'.git','.godot','.codex-godot-temp','__pycache__','APPDATA','LOCALAPPDATA','profiles','profile','import-profile','sims','node_modules','Godot','export_templates'}
extensions={'.md','.txt','.json','.py','.gd','.uid','.tscn','.tres','.res','.gdshader','.cfg','.png','.jpg','.webp','.svg','.ico','.ogg','.wav','.ttf','.otf','.import','.csv','.patch','.diff','.ps1','.js','.toml','.yml','.yaml'}
new=[];excluded=[];generated=[]
for top in ['docs','tools','patch-notes','queries']:
 if not (ROOT/top).exists():continue
 for d,dirs,files in os.walk(ROOT/top):
  rel=Path(d).relative_to(ROOT).as_posix()
  if top=='docs' and ('project.godot' in files or ('run-report.json' in files and ('project' in dirs or 'workspace-source-manifest.json' in files))):
   generated.append(rel+'/');dirs[:]=[];continue
  dirs[:]=[x for x in dirs if x not in skip_names and not x.startswith('export-smoke-') and not (top=='patch-notes' and x in {'analysis','design-logs','builds'})]
  for name in files:
   p=Path(d)/name;r=p.relative_to(ROOT).as_posix()
   if r in tracked:continue
   if p.suffix.lower() not in extensions and name not in {'.gdignore','.gitignore'}:continue
   size=p.stat().st_size
   reason=''
   if top=='docs':
    if p.suffix.lower() in {'.png','.jpg','.webp','.wav','.ttf','.otf','.res','.tscn','.uid','.import','.godot'}:reason='local generated media/import/scene copy'
    elif size>524288:reason='large local evidence; compact source/report retained'
    elif name in {'telemetry.json','replay.tape.json','git-provenance.json','source.diff.patch'}:reason='raw replay/provenance; compact source/report retained'
   if reason:excluded.append({'path':r,'bytes':size,'reason':reason});continue
   new.append(r)
for name in ['.gitignore','.gitattributes','README.md','AGENTS.md']:
 if (ROOT/name).is_file() and name not in tracked:new.append(name)
# Respect all existing ignore rules without losing track of skipped local files.
candidate=sorted(set(changed+new));query='\0'.join(candidate)+'\0'
ignored=subprocess.run(['git','check-ignore','-z','--stdin'],cwd=ROOT,input=query.encode(),stdout=subprocess.PIPE).stdout.decode().split('\0')
ignored=set(ignored);candidate=[x for x in candidate if x not in ignored or x in tracked]
files=[]
for r in candidate:
 p=ROOT/r
 if p.is_file():files.append({'path':r,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
assert not any(x['bytes']>=100_000_000 for x in files),'GitHub single-file limit requires a different artifact destination'
manifest={'files':files,'count':len(files),'bytes':sum(x['bytes'] for x in files),'generated_source_roots_retained_local':generated,'excluded_large_or_generated_files':excluded,'scope':'All changed tracked files plus current authored application/tools/docs. Full private imported projects, caches, binary builds, bulky traces and raw simulation bundles remain local; nothing deleted.'}
(RAW/'publication-manifest.json').write_text(json.dumps(manifest,indent=2))
(RAW/'paths.nul').write_bytes(('\0'.join(candidate)+'\0').encode())
(HERE/'publication-summary.json').write_text(json.dumps({k:v for k,v in manifest.items() if k not in {'files','excluded_large_or_generated_files'}},indent=2))
print(json.dumps({'files':len(files),'bytes':manifest['bytes'],'local_generated_roots':len(generated),'local_evidence_files':len(excluded),'largest':sorted(files,key=lambda x:-x['bytes'])[:8]}))
