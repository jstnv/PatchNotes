from pathlib import Path
import importlib.util
ROOT=Path(__file__).resolve().parents[4]
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
out=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-adoption-20261023-p1-fixture-v1');out.mkdir(exist_ok=False)
sim.run_process('write-p1',[str(Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')),'--headless','--path','C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-adoption-20261023-red-v1/project','--script',str(Path(__file__).with_name('write_p1.gd')),'--',str(out/'current-p1.json')],out,sim.isolated_environment(out/'profile'),120)
