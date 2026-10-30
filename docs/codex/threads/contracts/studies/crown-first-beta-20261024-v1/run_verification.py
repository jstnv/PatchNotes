from setup import HERE,ROOT,RAW,VAR,PY,GODOT,PAIRS,write
import subprocess,json
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def execute(name,args):
    write(HERE/(name+'-command.json'),args);print('START '+name,flush=True)
    p=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    (HERE/(name+'-driver.log')).write_text(p.stdout+'\n'+p.stderr,encoding='utf-8')
    write(HERE/(name+'-exit.json'),{'exit_code':p.returncode});print('END '+name+' '+str(p.returncode),flush=True)
    return p.returncode
def main():
    pair=PAIRS[0];cid='candidate-'+pair;original=load(RAW/pair/'cases'/cid/'result.json')
    execute('replay',[PY,'tools/simulate.py','replay','--bundle',str(RAW/pair),'--case',cid,'--output',str(RAW/'replay'),'--timeout','600','--godot',GODOT])
    selections=[{'pair':pair,'case':cid,'original_ok':original['ok'],'folder':'replay'}]
    if not original['ok']:
        pair=next(p for p in PAIRS if load(RAW/p/'cases'/('candidate-'+p)/'result.json')['ok']);cid='candidate-'+pair
        execute('replay-complete',[PY,'tools/simulate.py','replay','--bundle',str(RAW/pair),'--case',cid,'--output',str(RAW/'replay-complete'),'--timeout','600','--godot',GODOT])
        selections.append({'pair':pair,'case':cid,'original_ok':True,'folder':'replay-complete'})
    write(HERE/'verification-selection.json',selections)
    if execute('prepare-cold',[PY,'docs/codex/threads/simulation-engine/examples/prepare-continuation.py','--bundle',str(RAW/pair),'--case',cid,'--case-id','first-cold-next','--target-release-count','7','--max-commands','80','--output',str(HERE/'cold.json')])==0:
        execute('cold',[PY,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/'cold.json'),'--output',str(RAW/'cold'),'--timeout','600','--godot',GODOT])
if __name__=='__main__':main()
