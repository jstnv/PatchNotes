"""Select source/authored records/compact evidence; never walk simulator copies."""
from pathlib import Path
import collections,json,os,re,subprocess
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
raw=subprocess.check_output(['git','status','--porcelain=v1','-z','--untracked-files=normal'],cwd=ROOT).decode()
entries=[r for r in raw.split('\0') if r]
tracked=[p for p in subprocess.check_output(['git','diff','--name-only','-z','HEAD'],cwd=ROOT).decode().split('\0') if p]
new=[r[3:] for r in entries if r.startswith('?? ')]
excluded=collections.Counter();chosen=[];sizes={}
prune={'project','projects','profiles','profile','APPDATA','LOCALAPPDATA','.godot','.git','.codex-godot-temp','__pycache__','node_modules','captures','screenshots','source-copy','export','exports','export-copy','export-project','clean-project','isolated-project','clean-source','compiled','pck-unpacked','extracted-pack'}
bulk={'.exe','.pck','.zip','.7z','.tar','.gz','.mp4','.wav','.mp3','.png','.jpg','.jpeg','.webp','.bin','.pyc','.log','.headless','.live'}
def inspect(name):
    path=Path(name);parts=path.parts
    canonical=name.startswith(('patch-notes/','tools/'))
    if path.name.endswith(('.tmp','.bak','.partial')):return 'temporary file'
    if name.startswith('docs/'):
        if any(p in prune or p.startswith('export-smoke-') for p in parts):return 'generated directory'
        if any(p in {'before','after','baseline','baseline-project','source','prior-source','baseline-source'} for p in parts) and 'employee-courses-20261029-v1' not in parts:return 'local source snapshot'
        if path.suffix.lower() in bulk:return 'bulk/capture/log artifact'
        if path.name in {'baseline-status.txt','baseline-diff-stat.txt','status.txt','dirty.patch','worktree.diff','full.diff','stage-all-paths.nul','stage-new-paths.nul','stage-paths.nul','push-receipt.json'}:return 'local status/index artifact'
        dated=re.search(r'202610(\d{2})',name)
        if dated and int(dated.group(1))<27 and path.suffix.lower() not in {'.md','.py','.gd','.uid','.toml','.txt','.csv'}:return 'older raw experiment body'
        if name.startswith('docs/codex/threads/') and path.suffix.lower() not in {'.md','.py','.gd','.uid','.txt','.csv','.json','.toml','.yaml','.yml','.sh','.ps1'}:return 'thread raw artifact'
        if any(p in {'cases','inputs','outputs','output','runs','results','verifier-artifacts'} for p in parts) and path.suffix.lower() not in {'.md','.py','.gd','.uid','.txt','.csv','.toml','.yaml','.yml','.sh','.ps1'}:return 'nested raw experiment body'
    if canonical and any(p in prune for p in parts[1:]):return 'generated directory'
    return None
def visit(name):
    reason=inspect(name)
    if reason:excluded[reason]+=1;return
    p=ROOT/name
    if p.is_dir():
        # A generated game copy may have an arbitrary folder name.
        if name.startswith('docs/') and (p/'project.godot').is_file():excluded['generated Godot copy']+=1;return
        for child in p.iterdir():visit(child.relative_to(ROOT).as_posix())
        return
    size=p.stat().st_size
    if name.startswith('docs/') and size>5*1024*1024:excluded['large raw evidence']+=1;return
    if size>=100*1024*1024:raise RuntimeError('GitHub file limit: '+name)
    if any(x in p.name.lower() for x in ['credentials','access_token','private_key']) or p.name in {'.env','.env.local','id_rsa','id_ed25519'}:raise RuntimeError('Unexpected sensitive filename: '+name)
    chosen.append(name);sizes[name]=size
for name in new:visit(name.rstrip('/'))
chosen=sorted(set(chosen));selected=sorted(set(tracked+chosen))
report={'policy':'All tracked edits plus new canonical source/tests/import metadata, authored design/handoff/logs and compact current evidence. Generated copies, profiles, capture/log binaries, temporary files, old raw experiment bodies and files above5MiB remain local. Preserve all files and .codex-godot-temp; no deletion or candidate adoption.', 'tracked_paths':len(tracked),'new_selected_paths':len(chosen),'selected_paths':len(selected),'selected_new_bytes':sum(sizes[p] for p in chosen),'excluded_entry_counts':dict(excluded),'largest_selected':sorted([(sizes[p],p) for p in chosen],reverse=True)[:20]}
(OUT/'selected-paths.json').write_text(json.dumps(selected,indent=2),encoding='utf-8')
(OUT/'stage-paths.nul').write_bytes(b''.join(p.encode()+b'\0' for p in selected))
(OUT/'selection.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
