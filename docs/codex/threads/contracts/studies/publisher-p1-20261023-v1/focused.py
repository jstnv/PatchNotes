from pathlib import Path
import importlib.util,json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[6]
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
project=Path(sys.argv[1]).resolve();script=sys.argv[2];label=sys.argv[3]
out=HERE/'checks'/label;out.mkdir(parents=True,exist_ok=False)
godot=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
cmd=[godot,'--headless','--path',str(project),'--script',script,'--',*sys.argv[4:]]
(out/'command.json').write_text(json.dumps(cmd,indent=2),encoding='utf-8')
start=time.monotonic()
try:
    p=subprocess.run(cmd,env=sim.isolated_environment(out/'profile'),capture_output=True,timeout=120)
    log=(p.stdout+p.stderr).decode('utf-8',errors='replace');rc=p.returncode
except subprocess.TimeoutExpired as e:
    log=((e.stdout or b'')+(e.stderr or b'')).decode('utf-8',errors='replace');rc=124
(out/'output.log').write_text(log,encoding='utf-8')
report={'exit_code':rc,'seconds':time.monotonic()-start,'errors':[line for line in log.splitlines() if 'SCRIPT ERROR' in line or line.startswith('ERROR:') or 'FAIL:' in line]}
(out/'result.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(log[-6500:]);print(json.dumps(report));sys.exit(rc or bool(report['errors']))
