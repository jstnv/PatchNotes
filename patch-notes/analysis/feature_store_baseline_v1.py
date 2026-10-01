"""Read-only source manifest and isolated-profile current Godot regression gate."""
from pathlib import Path
import concurrent.futures, hashlib, json, os, subprocess, tempfile, time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/feature-store-staged-v1'
GODOT = Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    files = sorted(p for folder in ['scripts','data','scenes'] for p in (ROOT/folder).rglob('*') if p.is_file()) + [ROOT/'project.godot']
    manifest = {'head':git('rev-parse','HEAD'),'branch':git('branch','--show-current'),'tracking':git('rev-parse','origin/main'),'status':git('status','--short'),'captured_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'files':{str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
    (OUT/'baseline_source_manifest.json').write_text(json.dumps(manifest,indent=2))
    (OUT/'baseline_worktree.diff').write_bytes(subprocess.check_output(['git','diff'],cwd=ROOT))
    profile = Path(tempfile.mkdtemp(prefix='patchnotes-feature-baseline-'))
    env = os.environ.copy()
    env['APPDATA']=str(profile/'roaming'); env['LOCALAPPDATA']=str(profile/'local')
    Path(env['APPDATA']).mkdir(); Path(env['LOCALAPPDATA']).mkdir()
    def run(name,args):
        cmd=[str(GODOT),'--headless','--path',str(ROOT),*args]
        p=subprocess.run(cmd,env=env,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=180)
        output=p.stdout+'\n'+p.stderr
        (OUT/(name+'.log')).write_text(output,encoding='utf-8')
        result={'name':name,'command':cmd,'exit':p.returncode,'error_markers':[s for s in ['SCRIPT ERROR','Parse Error','Assertion failed','FAIL:'] if s in output]}
        print(json.dumps(result),flush=True)
        return result
    results=[run('baseline_import',['--editor','--import'])]
    if results[0]['exit']==0 and not results[0]['error_markers']:
        tests=sorted((ROOT/'scripts/debug').glob('verify_*.gd'))
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
            results += list(pool.map(lambda p:run(p.stem,['--script','res://scripts/debug/'+p.name]),tests))
    check=subprocess.run(['git','diff','--check'],cwd=ROOT,capture_output=True,text=True)
    report={'source':manifest['head'],'profile':str(profile),'tests':results,'script_count':len(results)-1,'all_pass':all(r['exit']==0 and not r['error_markers'] for r in results),'diff_check_exit':check.returncode}
    (OUT/'baseline_results.json').write_text(json.dumps(report,indent=2))
    print(json.dumps({k:v for k,v in report.items() if k!='tests'}),flush=True)
    raise SystemExit(0 if report['all_pass'] and check.returncode==0 else 1)

if __name__=='__main__': main()
