"""Run the unmodified P4 EXE against an isolated, legally produced Studio slot."""
from pathlib import Path
import argparse,importlib.util,json,shutil,socket,subprocess
ROOT=Path(__file__).resolve().parents[4]
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--tag',required=True);parser.add_argument('--stage',default='prebrief');parser.add_argument('--width',type=int,default=1152);parser.add_argument('--resume-profile',type=Path);parser.add_argument('--source-save',type=Path);parser.add_argument('--preferences',type=Path)
    args=parser.parse_args()
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    out=HOME/args.tag;out.mkdir(exist_ok=False)
    exe=Path(sim.read_json(HOME/'p4-build-v1/p2-p3-export/build-manifest.json')['workspace'])/'demo/Patch Notes Demo.exe'
    env=sim.isolated_environment(args.resume_profile or out/'profile')
    original=args.source_save or HOME/'p2-p3-route-v2'/args.stage/'checkpoint.1.json'
    original_hash=sim.sha(original)
    sequence=json.loads(sim.read_json(original)['payload_utf8'])['sequence']
    destination=Path(env['APPDATA'])/'Godot/app_userdata/Patch Notes Demo/saves/studio'/f'checkpoint.{sequence}.json'
    if not args.resume_profile:
        destination.parent.mkdir(parents=True,exist_ok=False);shutil.copy2(original,destination)
        assert sim.sha(destination)==original_hash
        if args.preferences:
            settings=args.preferences.read_text(encoding='utf8')
            assert 'width=1280' in settings and 'height=720' in settings
            settings=settings.replace('width=1280',f'width={args.width}').replace('height=720',f'height={args.width*9//16}')
            target=destination.parents[2]/'preferences-v1.cfg';target.write_text(settings,encoding='utf8')
            sim.write_json(out/'preferences-seed.json',{'source':str(args.preferences),'source_sha256':sim.sha(args.preferences),'destination':str(target),'destination_sha256':sim.sha(target),'width':args.width,'height':args.width*9//16,'scope':'Fresh isolated test-profile display configuration only; source settings and checkpoint bytes untouched.'})
    with socket.socket() as lease:lease.bind(('127.0.0.1',62741))
    command=[str(exe),'--rendering-method','gl_compatibility','--resolution',f'{args.width}x{args.width*9//16}']
    with (out/'exe.log').open('wb') as log:
        process=subprocess.Popen(command,cwd=exe.parent,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        sim.write_json(out/'process.json',{'pid':process.pid,'command':command,'profile':str(args.resume_profile or out/'profile'),'stage':args.stage,'original':str(original),'original_sha256':original_hash,'copied_destination':str(destination),'exe_sha256':sim.sha(exe),'pck_sha256':sim.sha(exe.with_suffix('.pck'))})
        print('Isolated unmodified EXE launched',process.pid,flush=True)
        code=process.wait()
    assert sim.sha(original)==original_hash
    sim.write_json(out/'exit.json',{'exit':code,'original_fixture_preserved':True,'source_sha256':original_hash})
if __name__=='__main__':main()
