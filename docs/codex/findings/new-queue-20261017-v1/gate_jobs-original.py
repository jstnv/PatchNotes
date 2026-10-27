from run_checks import *
import os

out=BASE/'maintained-gate-jobs-v1';out.mkdir()
project=out/'project';source=sim.copy_snapshot(ROOT/'patch-notes',project)
sim.write_json(out/'source.json',source)
gate_spec=importlib.util.spec_from_file_location('gate',ROOT/'tools/release_gate.py')
gate=importlib.util.module_from_spec(gate_spec);gate_spec.loader.exec_module(gate)
checks=gate.load('checks',ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
checks.HERE=out;checks.PROJECT=project;checks.PROFILE=out/'profiles';checks.GODOT=str(GODOT)
os.environ.update(sim.isolated_environment(out/'launcher-profile'))
with socket.socket() as sock:sock.bind(('127.0.0.1',0));os.environ['PN_CHECKPOINT_TEST_PORT']=str(sock.getsockname()[1])
checks.run('import',['--editor','--import','--quit'])
wanted={'verify_alpha_pack_ui','verify_alpha_shop_pack','verify_alpha_shop_pack_cold','verify_market_release_index','verify_market_release_index_cold','verify_legacy_world','verify_founder_victory_cold','verify_queue_source_migration'}
done=[]
for name,path in gate.verifier_jobs():
 if name not in wanted:continue
 artifact=out/'verifier-artifacts'/name;artifact.mkdir(parents=True)
 os.environ.update(gate.verifier_environment(out,name))
 checks.run(name,['--script','res://scripts/debug/'+path.name],timeout=gate.verifier_timeout(name))
 done.append(name)
assert set(done)==wanted
assert source==sim.source_hashes(project)
sim.write_json(out/'summary.json',{'passed':done,'source_unchanged':True,'scope':'Actual maintained-gate dependency/environment helpers, isolated snapshot and eight affected native jobs. Not a rerun of the entire release gate.'})
