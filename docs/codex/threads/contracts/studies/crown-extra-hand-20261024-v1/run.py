from setup import HERE, ROOT, VAR, RAW, write
import subprocess, sys, time
from concurrent.futures import ThreadPoolExecutor

PY='C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
PAIRS=['simulation-4522', 'puzzle-4521', 'action-4521', 'simulation-4521', 'action-4522', 'puzzle-4522']

def run(pair):
    args=[PY,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/(pair+'.json')),'--output',str(RAW/pair),'--timeout','600','--godot',GODOT]
    write(HERE/(pair+'-command.json'),args)
    began=time.time()
    print('START '+pair,flush=True)
    result=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    (HERE/(pair+'-driver.log')).write_text(result.stdout+'\n'+result.stderr,encoding='utf-8')
    write(HERE/(pair+'-driver.json'),{'exit_code':result.returncode,'wall_seconds':time.time()-began})
    print('END '+pair+' exit '+str(result.returncode),flush=True)
    return result.returncode

if __name__=='__main__':
    mode=sys.argv[1]
    if mode=='first':run(PAIRS[0])
    elif mode=='remaining':
        with ThreadPoolExecutor(max_workers=2) as pool:list(pool.map(run,PAIRS[1:]))
    else:raise ValueError(mode)
