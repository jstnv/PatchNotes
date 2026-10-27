"""Sequential isolated P1 evidence runner; never touches player saves."""
from pathlib import Path
import importlib.util, json, subprocess, sys

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
GODOT = r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'

def run(label, script=None, project=None, args=(), graphical=False, profile=None, extra_env=None, main_pack=None):
    command = [GODOT, '--audio-driver', 'Dummy']
    command += ['--main-pack',str(main_pack)] if main_pack else ['--path', str(project or ROOT/'patch-notes')]
    command += ['--rendering-method', 'gl_compatibility'] if graphical else ['--headless']
    command += ['--script', script] if script else ['--editor', '--import', '--quit']
    if args: command += ['--', *map(str,args)]
    environment=sim.isolated_environment(profile or OUT/(label+'-profile'))
    environment.update(extra_env or {})
    with (OUT/(label+'.log')).open('wb') as log:
        p = subprocess.run(command, env=environment,
                           stdout=log, stderr=subprocess.STDOUT, timeout=300)
    text = (OUT/(label+'.log')).read_text(encoding='utf8', errors='replace')
    errors = [line for line in text.splitlines() if ('SCRIPT ERROR' in line or line.startswith('ERROR:')) and 'root certificate store' not in line]
    result = dict(command=command, exit=p.returncode, errors=errors, extra_environment=extra_env or {},
                  summary=[line for line in text.splitlines() if any(s in line.lower() for s in ['checks=', 'failures', 'assertions', 'pass', 'failed'])][-20:])
    sim.write_json(OUT/(label+'.json'), result)
    print(label, json.dumps(result, ensure_ascii=False), flush=True)
    return result

if __name__ == '__main__':
    run(sys.argv[1], sys.argv[2] if len(sys.argv)>2 else None, args=sys.argv[3:])
