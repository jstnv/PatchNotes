from pathlib import Path
import importlib.util

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
spec = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec); spec.loader.exec_module(sim)
godot = Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
# A constructed domain fixture derived from the maintained Promotion test.
# These are not claimed to be legal played development hands.
original = ROOT / 'patch-notes/scripts/debug/verify_publisher_trial_promotion.gd'
text = original.read_text().replace('[&"studio_buzz",&"unknown_name"]', '[&"cult_following",&"studio_buzz",&"unknown_name"]')
text = text.replace('==118', '==123')
text = text.replace('var first := finished(run,"First",25)', 'expect(run.get_fans()==20 and run.get_studio_traits().version==8,"Fresh Cult8 seed")\n\tvar first := finished(run,"First",25)\n\texpect(first.get_awareness_result().get_fan_awareness()==5,"Cult contributes ordinary five Awareness")')
script = HERE / 'cult20_awareness_probe.gd'
script.write_text(text)
folder = HERE / 'awareness-stage-order-01'; folder.mkdir()
project = HERE / 'new-project-02'
before = sim.source_hashes(project)
sim.write_json(folder / 'source-before.json', before)
sim.write_json(folder / 'fixture-source.json', {'maintained_fixture': str(original), 'sha256': sim.sha(original), 'probe_sha256': sim.sha(script)})
sim.run_process('probe', [str(godot), '--headless', '--path', str(project), '--script', str(script)], folder, sim.isolated_environment(folder / 'profile'), 90)
sim.check_snapshot(project, before)
log = (folder / 'probe.log').read_text(errors='replace')
sim.write_json(folder / 'summary.json', {'ok': True, 'pass_lines': sum(x.startswith('PASS:') for x in log.splitlines()), 'source_unchanged': True})
print('Awareness stage order PASS', flush=True)
