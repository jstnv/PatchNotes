import json,os,subprocess
import run_checks as v
env=os.environ.copy()
for key in ('APPDATA','LOCALAPPDATA'):
 path=v.PROFILE/'render'/key;path.mkdir(parents=True,exist_ok=True);env[key]=str(path)
command=[v.GODOT,'--path',str(v.PROJECT),'--rendering-method','gl_compatibility','--position','-5000,-5000','--script','res://scripts/debug/verify_bank_integration.gd','--','--capture']
result=subprocess.run(command,env=env,capture_output=True,timeout=120)
output=result.stdout+result.stderr
(v.HERE/'render.log').write_bytes(output)
errors=[s for s in output.decode('utf-8',errors='replace').splitlines() if ('ERROR:' in s or 'FAIL:' in s) and 'root certificate store' not in s]
(v.HERE/'render.command.json').write_text(json.dumps(dict(command=command,exit=result.returncode,errors=errors),indent=2))
print(result.returncode,errors)
raise SystemExit(0 if result.returncode==0 and not errors else 1)
