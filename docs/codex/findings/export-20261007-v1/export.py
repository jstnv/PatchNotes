"""Pinned, clean-profile Windows demo export. No gameplay source rewriting."""
from pathlib import Path
import argparse, hashlib, json, os, shutil, subprocess, tempfile, urllib.request, zipfile

ROOT = Path(__file__).resolve().parents[4] / 'patch-notes'
OUT = Path(__file__).resolve().parent
VERSION = '4.7.1.stable'
ARCHIVE = 'Godot_v4.7.1-stable_export_templates.tpz'
URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.1-stable/' + ARCHIVE
SHA256 = '86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72'
GODOT = Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')

def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda:f.read(8*1024*1024), b''): h.update(block)
    return h.hexdigest()

def run(name, argv, env, cwd, timeout=180):
    try:
        p = subprocess.run([str(x) for x in argv], env=env, cwd=cwd, capture_output=True, timeout=timeout)
        code, output = p.returncode, p.stdout+p.stderr
    except subprocess.TimeoutExpired as e:
        code, output = 'timeout', (e.stdout or b'')+(e.stderr or b'')
    (OUT/(name+'.log')).write_bytes(output)
    result = dict(command=[str(x) for x in argv], cwd=str(cwd), exit=code,
        profile={k:env.get(k) for k in ['APPDATA','LOCALAPPDATA']},
        errors=[s for s in ['SCRIPT ERROR','Parse Error','FAIL:','Assertion failed','Export failed'] if s.encode() in output])
    (OUT/(name+'.command.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(name, code, result['errors'],flush=True)
    if code != 0 or result['errors']: raise RuntimeError(name+' failed; see evidence')
    return result

def main():
    global GODOT
    parser=argparse.ArgumentParser();parser.add_argument('--download',action='store_true');parser.add_argument('--godot',type=Path,default=GODOT);args=parser.parse_args()
    GODOT=args.godot
    OUT.mkdir(parents=True,exist_ok=True);(OUT/'.gdignore').touch()
    cache=Path(tempfile.gettempdir())/'patch-notes-godot-4.7.1-cache';cache.mkdir(exist_ok=True)
    archive=cache/ARCHIVE
    if args.download and not archive.exists(): urllib.request.urlretrieve(URL,archive)
    if not archive.exists(): raise RuntimeError('Missing template archive; rerun with --download')
    if sha(archive)!=SHA256: raise RuntimeError('Template SHA256 mismatch')
    version=subprocess.check_output([str(GODOT),'--version'],text=True).strip()
    if not version.startswith(VERSION+'.'): raise RuntimeError('Editor version mismatch: '+version)
    workspace=Path(tempfile.mkdtemp(prefix='patch-notes-demo-20261007-'))
    project=workspace/'source';project.mkdir();artifact=workspace/'demo';artifact.mkdir()
    env=os.environ.copy()
    for key in ['APPDATA','LOCALAPPDATA']:
        profile=workspace/key;profile.mkdir();env[key]=str(profile)
    templates=Path(env['APPDATA'])/'Godot/export_templates'/VERSION;templates.mkdir(parents=True)
    members=['version.txt','windows_debug_x86_64.exe','windows_release_x86_64.exe']
    hashes={}
    with zipfile.ZipFile(archive) as z:
        for name in members:
            target=templates/name;target.write_bytes(z.read('templates/'+name));hashes[name]=sha(target)
    if (templates/'version.txt').read_text().strip()!=VERSION: raise RuntimeError('Template internal version mismatch')
    manifest={'version':version,'editor_sha256':sha(GODOT),'template_url':URL,'archive_sha256':SHA256,
              'template_files':hashes,'workspace':str(workspace),'included':{},'excluded_roots':['analysis','design-logs','scripts/debug','builds','Godot','.godot','.codex-godot-temp','.codex-specialization-output-temp','export_templates','source-only documentation']}
    # Positive allowlist; no copy of local analysis, debug scripts, caches or logs.
    for path in ROOT.rglob('*'):
        if not path.is_file(): continue
        rel=path.relative_to(ROOT); parts=rel.parts
        include=(str(rel) in ['project.godot','export_presets.cfg','icon.svg'] or
                 (parts[0] in ['scripts','scenes','data','assets','resources','autoload'] and
                  not (parts[0]=='scripts' and len(parts)>1 and parts[1]=='debug') and
                  path.suffix.lower() in ['.gd','.uid','.tscn','.tres','.res','.json','.png','.svg','.jpg','.webp','.ogg','.wav','.ttf','.otf']))
        if not include: continue
        dest=project/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
        manifest['included'][rel.as_posix()]=sha(path)
    # Working display label only, build-local; runtime mechanics untouched.
    config=project/'project.godot';config.write_text(config.read_text(encoding='utf-8').replace('config/name="Patch Notes"','config/name="Patch Notes Demo"'),encoding='utf-8')
    manifest['build_only_override']='application/config/name=Patch Notes Demo'
    (OUT/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    run('clean-import',[GODOT,'--headless','--path',project,'--editor','--import','--quit'],env,workspace)
    exe=artifact/'Patch Notes Demo.exe'
    run('export-release',[GODOT,'--headless','--path',project,'--export-release','Windows Desktop',exe],env,workspace)
    manifest['artifacts']={p.name:{'sha256':sha(p),'bytes':p.stat().st_size} for p in artifact.iterdir() if p.is_file()}
    manifest['status']='exported; package inspection and executable smoke still required'
    (OUT/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print(json.dumps({'workspace':str(workspace),'artifacts':manifest['artifacts']},indent=2),flush=True)

if __name__=='__main__':main()
