"""Fresh serial maintained verifier matrix against an immutable current snapshot.

Coordinator verifier wrappers use a strict selected private test port. No
runtime/save edits.
The separate, already audited P2/P3 export is not rebuilt by this runner.
"""
from pathlib import Path
import argparse, importlib.util, json, os, shutil, subprocess, time, traceback, types

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
GODOT = Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')

def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--tests', nargs='+', help='Explicit affected-suite continuation into a fresh snapshot/output')
    parser.add_argument('--port', type=int, default=47733, help='Private verifier lease; use a different port for concurrent independent runs')
    parser.add_argument('--answered-onboarding', action='store_true', help='Seed an answered tutorial preference in isolated verifier profiles for ordinary gameplay regression checks')
    args = parser.parse_args()
    if not 47700<=args.port<=47799: parser.error('--port must stay in the private verifier range47700..47799')
    out = args.output.resolve()
    out.mkdir(exist_ok=False)
    sim = module('overnight_sim', ROOT/'tools/simulate.py')
    gate = module('overnight_gate', ROOT/'tools/release_gate.py')
    checks = module('overnight_checks', ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
    before = sim.copy_snapshot(ROOT/'patch-notes', out/'project')
    sim.write_json(out/'canonical-source.json', before)
    auxiliary = {}
    for leaf in ['m2a-v1','m2b-v1','m2c-v1','m2d-v1','m3a-v1','m3b-v1']:
        for source in (ROOT/'docs/codex/threads/simulation-engine'/leaf).rglob('*'):
            if source.is_file() and source.suffix in {'.gd','.json','.uid','.tscn'}:
                rel = source.relative_to(ROOT)
                target = out/rel
                target.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(source,target)
                auxiliary[rel.as_posix()] = sim.sha(source)
    for source in (ROOT/'docs/codex/findings/education-legacy-fixtures-v1').glob('*'):
        if source.is_file() and source.suffix=='.json':
            rel=source.relative_to(ROOT);target=out/rel
            target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(source,target);auxiliary[rel.as_posix()]=sim.sha(source)
    sim.write_json(out/'auxiliary-source.json', auxiliary)
    frozen = sim.import_project(GODOT,out/'project',out,sim.isolated_environment(out/'import-profile'),180)
    checks.HERE=out; checks.REPO=out; checks.PROJECT=out/'project'; checks.GODOT=str(GODOT); checks.PROFILE=out/'profiles'
    def bounded_run(command, *, cwd, env, stdout, stderr, timeout):
        # Kill only this runner's child if a fatal script error leaves its
        # SceneTree idle. Preserve the failing log; never wait ten minutes for it.
        child=subprocess.Popen(command,cwd=cwd,env=env,stdout=stdout,stderr=stderr)
        began=time.monotonic();termination=None
        while child.poll() is None:
            if time.monotonic()-began>timeout:termination='declared timeout'
            elif 'SCRIPT ERROR' in Path(stdout.name).read_text(encoding='utf8',errors='replace'):termination='fatal script error'
            if termination:
                child.kill();break
            time.sleep(.25)
        child.wait()
        if termination:print('Own verifier child terminated:',termination,flush=True)
        return subprocess.CompletedProcess(command,child.returncode)
    checks.subprocess=types.SimpleNamespace(run=bounded_run,STDOUT=subprocess.STDOUT)
    os.environ.update(sim.isolated_environment(out/'driver-profile'))
    os.environ['PN_CHECKPOINT_TEST_PORT']=str(args.port)
    report={'pass':False,'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'checks':[], 'release_ready':False,'scope':'Fresh maintained verifiers; verifier-only writer instrumentation, not direct release EXE acceptance.'}
    sim.write_json(out/'result.json',report)
    started=time.monotonic()
    for name,path in gate.verifier_jobs():
        if args.tests and name not in args.tests: continue
        record={'name':name,'pass':False}
        try:
            os.environ.update(gate.verifier_environment(out,name))
            (out/'verifier-artifacts'/name).mkdir(parents=True,exist_ok=True)
            # Cold jobs can intentionally reuse the same parent verifier. Each
            # named job needs its own wrapper: a nondefault port rewrites only
            # that generated file, while checkpoint_wrapper retains its strict
            # immutable-content guard for repeated calls on the same path.
            wrapper,metadata=gate.checkpoint_wrapper(path,out/'wrappers'/name)
            if args.port!=47733:
                # Retain the strict dedicated-port guard in each generated
                # verifier; only its recorded test port changes. Production's
                # 62741 lease and package/runtime source remain untouched.
                wrapper.write_text(wrapper.read_text(encoding='utf8').replace('47733',str(args.port)),encoding='utf8')
                metadata['sha256']=sim.sha(wrapper)
            if args.answered_onboarding and name not in {'verify_guided_tutorial_ui','verify_guided_tutorial_preferences','verify_save_tutorial_invitation','verify_new_save_loading'}:
                content=wrapper.read_text(encoding='utf8')
                marker='func _initialize() -> void:\n'
                assert content.count(marker)==1
                wrapper.write_text(content.replace(marker,marker+'\tassert(preload("res://scripts/tutorial/onboarding_preferences.gd").new().answer(true))\n'),encoding='utf8')
                metadata['answered_onboarding_fixture']=True
                metadata['sha256']=sim.sha(wrapper)
            metadata['test_writer_port']=args.port
            record['wrapper']=metadata
            profile=gate.continuation_profile(out,'verify_rival_gameplay_activation') if name=='verify_rival_gameplay_cold_continue' else None
            checks.run(name,gate.verifier_arguments(out,name,str(wrapper)),timeout=max(600,gate.verifier_timeout(name)),profile=profile)
            record['pass']=True
        except Exception as error:
            record['error']=str(error)
            record['traceback']=traceback.format_exc()
            print('RETAINED FAILURE',name,str(error),flush=True)
        report['checks'].append(record)
        report['elapsed_seconds']=round(time.monotonic()-started,2)
        sim.write_json(out/'result.json',report)
    sim.check_snapshot(out/'project',frozen)
    report['canonical_unchanged']=sim.source_hashes(ROOT/'patch-notes')==before
    report['missing']=sorted(set(args.tests or [])-{item['name'] for item in report['checks']})
    report['pass']=report['canonical_unchanged'] and not report['missing'] and all(item['pass'] for item in report['checks'])
    sim.write_json(out/'result.json',report)
    print(json.dumps({'pass':report['pass'],'checks':len(report['checks']),'failed':[r['name'] for r in report['checks'] if not r['pass']],'canonical_unchanged':report['canonical_unchanged']}),flush=True)
    return 0 if report['pass'] else 1

if __name__=='__main__':raise SystemExit(main())
