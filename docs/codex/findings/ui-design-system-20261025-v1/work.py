from pathlib import Path
import argparse,importlib.util
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('ui_checks',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-ui-design-system-20261025-v1')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['prior','prior-pack','cold','cold-pack','native','geometry','integration','guided']);p.add_argument('--project',type=Path);p.add_argument('--verifier',type=Path);p.add_argument('--name');a=p.parse_args()
name=a.name or a.mode
project=a.project or c.RAW/('red' if a.mode=='prior' else 'green')/'project'
script=project/'scripts/debug/verify_ui_folder_navigation.gd' if a.mode=='native' else HERE.parent/'store-prerequisite-links-20261024-v1/world_probe.gd'
if a.mode=='geometry': script=HERE/'layout_probe.gd'
if a.mode=='integration': script=HERE/'integration_probe.gd'
if a.mode=='guided': script=project/'scripts/debug/verify_guided_tutorial_ui.gd'
if a.verifier: script=a.verifier.resolve()
args=['--input='+str(c.RAW/('prior-pack' if a.mode=='cold-pack' else 'prior')/'result.json')] if a.mode in ['cold','cold-pack'] else []
pack=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Paper Icon/Patch Notes v0.02 - Paper Icon.exe') if a.mode=='prior-pack' else None
r=c.run(name,project,script,args,native=a.mode in ['native','integration'],reuse=pack is None,pack=pack)
raise SystemExit(0 if r['pass'] else 1)
