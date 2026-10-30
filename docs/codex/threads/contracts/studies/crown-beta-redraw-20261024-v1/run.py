from setup import HERE, ROOT, RAW, VAR, PAIRS, PY, GODOT, write
import subprocess,sys,time
from concurrent.futures import ThreadPoolExecutor

def run(pair):
    args=[PY,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/(pair+'.json')),'--output',str(RAW/pair),'--timeout','600','--godot',GODOT]
    write(HERE/(pair+'-command.json'),args);start=time.time();print('START '+pair,flush=True)
    p=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    (HERE/(pair+'-driver.log')).write_text(p.stdout+'\n'+p.stderr,encoding='utf-8')
    write(HERE/(pair+'-driver.json'),{'exit_code':p.returncode,'wall_seconds':time.time()-start});print('END '+pair+' '+str(p.returncode),flush=True)
    return p.returncode

if __name__=='__main__':
    if sys.argv[1]=='first':run(PAIRS[0])
    elif sys.argv[1]=='remaining':
        with ThreadPoolExecutor(max_workers=2) as pool:list(pool.map(run,PAIRS[1:]))
