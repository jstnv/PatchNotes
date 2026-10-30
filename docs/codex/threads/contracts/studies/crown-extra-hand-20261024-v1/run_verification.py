from setup import HERE, ROOT, VAR, RAW, write
from run import PY, GODOT
import json, subprocess
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))

def execute(name,args):
    write(HERE/(name+'-command.json'),args)
    print('START '+name,flush=True)
    result=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    (HERE/(name+'-driver.log')).write_text(result.stdout+'\n'+result.stderr,encoding='utf-8')
    write(HERE/(name+'-exit.json'),{'exit_code':result.returncode})
    print('END '+name+' exit '+str(result.returncode),flush=True)
    return result.returncode

def main():
    rows=load(HERE/'analysis.json')['rows']
    eligible=[r for r in rows if r['ok'] and r['arm']=='extra']
    selected=next((r for r in eligible if r['case']=='extra-simulation-4522'),eligible[0])
    write(HERE/'verification-selection.json',{'pair':selected['pair'],'case':selected['case']})
    bundle=RAW/selected['pair']
    execute('replay',[PY,'tools/simulate.py','replay','--bundle',str(bundle),'--case',selected['case'],'--output',str(RAW/'replay'),'--timeout','600','--godot',GODOT])
    code=execute('prepare-cold',[PY,'docs/codex/threads/simulation-engine/examples/prepare-continuation.py','--bundle',str(bundle),'--case',selected['case'],'--case-id','extra-hand-cold-next','--target-release-count','7','--max-commands','80','--output',str(HERE/'cold.json')])
    if code==0:execute('cold',[PY,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/'cold.json'),'--output',str(RAW/'cold'),'--timeout','600','--godot',GODOT])
    failures=[r for r in rows if r['accepted_commands']<r['commands']]
    if failures:
        r=failures[0]
        execute('reduce',[PY,'tools/reduce_simulation.py','--bundle',str(RAW/r['pair']),'--case',r['case'],'--kind','rejection','--output',str(RAW/'reduced-failure'),'--timeout','600','--max-commands','1000','--godot',GODOT])

if __name__=='__main__':main()
