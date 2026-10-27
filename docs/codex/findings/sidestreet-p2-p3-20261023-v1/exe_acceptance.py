"""Launch only an isolated real EXE profile; preserve the user's running game."""
from pathlib import Path
import importlib.util,json,shutil,socket,subprocess
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
def main():
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    out=HOME/'actual-exe-v2';out.mkdir(exist_ok=False)
    exe=Path(sim.read_json(HOME/'export-v4/build-manifest.json')['workspace'])/'demo/Patch Notes Demo.exe'
    env=sim.isolated_environment(out/'profile')
    # The first native attempt reached this exact Studio but its injected key
    # missed Begin. It retains the real pre-quote generation later pruned by
    # successful route saves. This does not relabel the failed driver as PASS.
    saves=HOME/'native-1152/profile/APPDATA/Godot/app_userdata/Patch Notes/parity/sidestreet-native-1152'
    candidates=[]
    for path in saves.glob('checkpoint.*.json'):
        payload=json.loads(sim.read_json(path)['payload_utf8'])
        if len(payload['run']['released_games'])==4 and not payload['run']['commission_deals']:candidates.append((int(path.name.split('.')[1]),path))
    sequence,source=max(candidates)
    destination=Path(env['APPDATA'])/'Godot/app_userdata/Patch Notes Demo/saves/studio'/source.name
    destination.parent.mkdir(parents=True);shutil.copy2(source,destination)
    port_free=True
    with socket.socket() as sock:
        try:sock.bind(('127.0.0.1',62741))
        except OSError:port_free=False
    command=[str(exe),'--rendering-method','gl_compatibility']
    with (out/'exe.log').open('wb') as log:
        process=subprocess.Popen(command,cwd=exe.parent,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        sim.write_json(out/'process.json',{'pid':process.pid,'command':command,'profile':str(out/'profile'),'production_writer_available':port_free,'copied_save':str(source),'destination':str(destination),'original_sha256':sim.sha(source),'copied_sha256':sim.sha(destination),'exe_sha256':sim.sha(exe),'pck_sha256':sim.sha(exe.with_suffix('.pck'))})
        print('Actual isolated EXE launched; production writer available:',port_free,flush=True)
        code=process.wait()
    assert sim.sha(source)==sim.sha(destination),'Original isolated generation changed'
    sim.write_json(out/'exit.json',{'exit':code,'original_generation_preserved':True,'writer_conflict_is_not_successful_continue':not port_free})
if __name__=='__main__':main()
