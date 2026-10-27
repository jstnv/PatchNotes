from run_checks import *
import shutil
owner=ROOT/'docs/codex/threads/ai-competitors'
variant=owner/'simulators/market-variety-implementation-v1'
old=owner/'simulators/market-shadow-theme-v3/project'
changes=['scripts/market/rival_trial.gd','scripts/market/ai_market_pressure_trial.gd','scripts/debug/verify_rival_trial_activation.gd']
for name in changes:shutil.copy2(old/name,variant/'project'/name)
sim.write_json(BASE/'variety-port.json',{name:sim.sha(variant/'project'/name) for name in changes})
out=BASE/'ai-variety-run-v2'
subprocess.run([sys.executable,'-X','utf8',str(ROOT/'tools/simulate.py'),'run','--variant',str(variant),'--config',str(owner/'2026-10-17-foundation-smoke-v1.json'),'--output',str(out),'--godot',str(GODOT),'--timeout','240'],check=True)
for attempt in [1,2]:
 with socket.socket() as s:s.bind(('127.0.0.1',0));port=str(s.getsockname()[1])
 subprocess.run([sys.executable,'-X','utf8',str(owner/'run_rival_verifier_v2.py'),'--bundle',str(out),'--output',str(BASE/('ai-variety-rivals-'+str(attempt))),'--godot',str(GODOT),'--script','verify_rival_trial_activation.gd','--test-port',port,'--timeout','240'],check=True)
subprocess.run([sys.executable,'-X','utf8',str(ROOT/'tools/simulate.py'),'replay','--bundle',str(out),'--case','foundation-legal-action-4417','--output',str(BASE/'ai-variety-replay-v1'),'--godot',str(GODOT),'--timeout','240'],check=True)
