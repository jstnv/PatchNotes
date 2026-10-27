"""Launch only isolated acceptance profiles; byte-copy original save generations."""
import argparse,subprocess,shutil,json
from pathlib import Path
from check import ROOT,OUT,sim,GODOT

p=argparse.ArgumentParser();p.add_argument('label');p.add_argument('mode',choices=['editor','export']);p.add_argument('--save',type=Path);p.add_argument('--profile');args=p.parse_args()
profile=OUT/(args.profile or args.label+'-profile')
if not args.profile and profile.exists():raise SystemExit('Use a new profile label')
env=sim.isolated_environment(profile)
command=[GODOT,'--path',str(ROOT/'patch-notes')] if args.mode=='editor' else [str(Path(sim.read_json(OUT/'export-clean/build-manifest.json')['workspace'])/'demo/Patch Notes Demo.exe')]
copied=None
if args.save:
    name='Patch Notes' if args.mode=='editor' else 'Patch Notes Demo'
    destination=Path(env['APPDATA'])/'Godot/app_userdata'/name/'saves/studio'/args.save.name
    destination.parent.mkdir(parents=True,exist_ok=False)
    shutil.copy2(args.save,destination)
    assert sim.sha(args.save)==sim.sha(destination)
    copied=dict(source=str(args.save),destination=str(destination),sha256=sim.sha(destination))
command+=['--rendering-method','gl_compatibility']
with (OUT/(args.label+'.log')).open('wb') as log:
    proc=subprocess.Popen(command,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    sim.write_json(OUT/(args.label+'-process.json'),dict(pid=proc.pid,command=command,profile=str(profile),copied_save=copied))
    print(proc.pid,flush=True)
    sim.write_json(OUT/(args.label+'-exit.json'),dict(exit=proc.wait()))
