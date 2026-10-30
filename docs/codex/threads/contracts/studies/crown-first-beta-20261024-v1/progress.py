from setup import HERE,RAW
import json
for name in ['qa-simulation-4522','qa-simulation-4521','replay','cold']:
    folder=RAW/name
    if not folder.exists():continue
    report=folder/'run-report.json'
    receipt=HERE/(name+('-driver.json' if name.startswith('qa-') else '-exit.json'))
    if report.exists() and receipt.exists():
        data=json.loads(report.read_text(encoding='utf-8-sig'))
        print(json.dumps({'folder':name,'complete_report':True,'ok':data.get('ok'),'error':data.get('error')}));continue
    path=folder/'profile/APPDATA/Godot/app_userdata/Patch Notes/logs/godot.log'
    if not path.exists():print(json.dumps({'folder':name,'stage':'preparing/importing'}));continue
    with path.open('rb') as f:
        f.seek(0,2);f.seek(max(0,f.tell()-300000));lines=f.read().decode('utf-8',errors='replace').splitlines()
    for line in reversed(lines):
        if not line.startswith('FOLLOWUP '):continue
        try:n=json.loads(line[9:])
        except json.JSONDecodeError:continue
        print(json.dumps({'folder':name,**{k:n[k] for k in ['case','cycle','releases','phase']}}));break
