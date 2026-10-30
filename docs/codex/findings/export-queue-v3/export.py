"""Pinned, clean-profile Windows demo export. No gameplay source rewriting."""
from pathlib import Path
import argparse, hashlib, json, os, re, shutil, subprocess, tempfile, urllib.request, zipfile

ROOT = Path(__file__).resolve().parents[4] / 'patch-notes'
OUT = Path(__file__).resolve().parent
VERSION = '4.7.1.stable'
ARCHIVE = 'Godot_v4.7.1-stable_export_templates.tpz'
URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.1-stable/' + ARCHIVE
SHA256 = '86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72'
GODOT = Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')

def windows_export_preset(path):
    # Godot options may contain multiline shell strings, so an INI parser is
    # insufficient. Read only the two single-line fields in preset headers.
    presets = []
    fields = None
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        line = line.strip()
        if line.startswith('[') and line.endswith(']'):
            fields = {} if re.fullmatch(r'\[preset\.\d+\]', line) else None
            if fields is not None: presets.append(fields)
        elif fields is not None:
            key, separator, value = line.partition('=')
            if separator and key.strip() in ('name', 'platform'):
                key = key.strip()
                if key in fields: raise ValueError('Duplicate preset field: '+key)
                fields[key] = json.loads(value.strip())
    names = []
    for fields in presets:
        if fields.get('platform') == 'Windows Desktop':
            name = fields.get('name')
            if not isinstance(name, str) or not name: raise ValueError('Windows preset has no name')
            names.append(name)
    if len(names) != 1: raise ValueError('Expected exactly one Windows Desktop preset: '+repr(names))
    return names[0]

def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda:f.read(8*1024*1024), b''): h.update(block)
    return h.hexdigest()

def isolated_export_environment(workspace):
    env = os.environ.copy()
    for key in ['APPDATA', 'LOCALAPPDATA']:
        profile = workspace / key
        profile.mkdir()
        env[key] = str(profile)
    # Godot writes tmpproject.binary through the OS temp directory during export.
    # Keep it writable and private to this build, including simultaneous builds.
    temporary = workspace / 'temp'
    temporary.mkdir()
    for key in ['TMP', 'TEMP', 'TMPDIR']:
        env[key] = str(temporary)
    return env

def run(name, argv, env, cwd, timeout=180):
    try:
        p = subprocess.run([str(x) for x in argv], env=env, cwd=cwd, capture_output=True, timeout=timeout)
        code, output = p.returncode, p.stdout+p.stderr
    except subprocess.TimeoutExpired as e:
        code, output = 'timeout', (e.stdout or b'')+(e.stderr or b'')
    (OUT/(name+'.log')).write_bytes(output)
    errors = [line for line in output.decode('utf-8', errors='replace').splitlines()
              if ('ERROR:' in line or any(marker in line for marker in
                  ['SCRIPT ERROR','Parse Error','FAIL:','Assertion failed','Export failed']))
              and 'root certificate store' not in line]
    result = dict(command=[str(x) for x in argv], cwd=str(cwd), exit=code,
        profile={k:env.get(k) for k in ['APPDATA','LOCALAPPDATA','TMP','TEMP','TMPDIR']},
        errors=errors)
    (OUT/(name+'.command.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(name, code, result['errors'],flush=True)
    if code != 0 or result['errors']: raise RuntimeError(name+' failed; see evidence')
    return result

def main():
    global GODOT
    parser=argparse.ArgumentParser();parser.add_argument('--download',action='store_true');parser.add_argument('--godot',type=Path,default=GODOT);args=parser.parse_args()
    GODOT=args.godot
    OUT.mkdir(parents=True,exist_ok=True);(OUT/'.gdignore').touch()
    cache=OUT/'template-cache';cache.mkdir(exist_ok=True)
    archive=cache/ARCHIVE
    if not archive.exists(): archive=Path(r'C:/Users/64jus/AppData/Local/Temp/patch-notes-godot-4.7.1-cache')/ARCHIVE
    if args.download and not archive.exists(): urllib.request.urlretrieve(URL,archive)
    if not archive.exists(): raise RuntimeError('Missing template archive; rerun with --download')
    if sha(archive)!=SHA256: raise RuntimeError('Template SHA256 mismatch')
    version=subprocess.check_output([str(GODOT),'--version'],text=True).strip()
    if not version.startswith(VERSION+'.'): raise RuntimeError('Editor version mismatch: '+version)
    workspace=Path(tempfile.mkdtemp(prefix='patch-notes-demo-20261007-',dir=OUT))
    project=workspace/'source';project.mkdir();artifact=workspace/'demo';artifact.mkdir()
    env=isolated_export_environment(workspace)
    templates=Path(env['APPDATA'])/'Godot/export_templates'/VERSION;templates.mkdir(parents=True)
    members=['version.txt','windows_debug_x86_64.exe','windows_release_x86_64.exe']
    hashes={}
    with zipfile.ZipFile(archive) as z:
        for name in members:
            target=templates/name;target.write_bytes(z.read('templates/'+name));hashes[name]=sha(target)
    if (templates/'version.txt').read_text().strip()!=VERSION: raise RuntimeError('Template internal version mismatch')
    manifest={'version':version,'editor_sha256':sha(GODOT),'template_url':URL,'archive_sha256':SHA256,
              'template_files':hashes,'workspace':str(workspace),'temporary_directory':env['TMP'],'included':{},'excluded_roots':['analysis','design-logs','scripts/debug','builds','Godot','.godot','.codex-godot-temp','.codex-specialization-output-temp','export_templates','source-only documentation']}
    # Positive allowlist; no copy of local analysis, debug scripts, caches or logs.
    for path in ROOT.rglob('*'):
        if not path.is_file(): continue
        rel=path.relative_to(ROOT); parts=rel.parts
        # Font rasterization settings are source inputs, not disposable cache.
        # Keep them in the clean project without treating them as PCK payloads.
        if parts[0]=='assets' and path.name.endswith(('.ttf.import','.otf.import')):
            dest=project/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
            manifest.setdefault('import_settings',{})[rel.as_posix()]=sha(path)
            continue
        include=(str(rel) in ['project.godot','export_presets.cfg','icon.svg'] or
                 (parts[0] in ['scripts','scenes','data','assets','resources','autoload','queries'] and
                  not (parts[0]=='scripts' and len(parts)>1 and parts[1]=='debug') and
                  path.suffix.lower() in ['.gd','.uid','.tscn','.tres','.res','.json','.png','.svg','.jpg','.webp','.ogg','.wav','.ttf','.otf','.ico']))
        if not include: continue
        dest=project/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
        manifest['included'][rel.as_posix()]=sha(path)
    # Working display label only, build-local; runtime mechanics untouched.
    config=project/'project.godot';config.write_text(config.read_text(encoding='utf-8').replace('config/name="Patch Notes"','config/name="Patch Notes Demo"'),encoding='utf-8')
    manifest['build_only_override']='application/config/name=Patch Notes Demo'
    manifest['export_preset']=windows_export_preset(project/'export_presets.cfg')
    manifest['export_helper_sha256']=sha(Path(__file__))
    (OUT/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    run('clean-import',[GODOT,'--headless','--path',project,'--editor','--import','--quit'],env,workspace)
    exe=artifact/'Patch Notes Demo.exe'
    # Export serializes already imported fonts; no editor text layout is needed.
    # Avoid the editor text server's extra allocations on constrained hosts.
    # Clean import and the shipped runtime retain their normal text drivers.
    run('export-release',[GODOT,'--headless','--text-driver','Dummy','--path',project,'--export-release',manifest['export_preset'],exe],env,workspace)
    # Ship the bundled font's original license alongside the executable.
    if (ROOT/'assets/card_frame_kit/fonts/Tiny5-Regular.ttf').exists():
        license_path=ROOT/'assets/card_frame_kit/fonts/OFL.txt'
        shutil.copy2(license_path,artifact/'Tiny5-OFL.txt')
        manifest['license_sources']={'Tiny5-OFL.txt':{'source':license_path.relative_to(ROOT).as_posix(),'sha256':sha(license_path)}}
    manifest['artifacts']={p.name:{'sha256':sha(p),'bytes':p.stat().st_size} for p in artifact.iterdir() if p.is_file()}
    manifest['status']='exported; package inspection and executable smoke still required'
    (OUT/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print(json.dumps({'workspace':str(workspace),'artifacts':manifest['artifacts']},indent=2),flush=True)

if __name__=='__main__':main()
