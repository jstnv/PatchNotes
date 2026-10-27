"""Verify the complete source-fenced queue closeout, retaining all failed attempts."""
from pathlib import Path
import hashlib, importlib.util, json, subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = Path('C:/Users/64jus/AppData/Local/Temp/pn-queue-closeout-20261024-v1')
load = lambda path: json.loads(path.read_text(encoding='utf-8'))
spec = importlib.util.spec_from_file_location('queue_closeout_sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
checks = 0


def check(value, message):
    global checks
    assert value, message
    checks += 1


def main():
    before = load(RAW / 'full/canonical-source.json')
    current = sim.source_hashes(ROOT / 'patch-notes')
    delta = [p for p in sorted(before.keys() | current.keys()) if before.get(p) != current.get(p)]
    check(delta == ['scripts/debug/verify_market_browser.gd'], 'one exact verifier-only canonical delta')
    production = lambda manifest: {p: h for p, h in manifest.items() if not p.startswith('scripts/debug/')}
    check(production(before) == production(current), 'every non-debug runtime source unchanged')
    full = load(RAW / 'full/result.json')
    follow = load(RAW / 'corrected-continuation/result.json')
    check(len(full['checks']) == 182 and not full.get('missing'), 'full maintained inventory executed')
    check({r['name'] for r in full['checks'] if not r['pass']} == {
        'verify_alpha_shop_pack_cold', 'verify_market_browser', 'verify_market_release_index_cold'}, 'retained diagnosed initial failures only')
    check(follow['pass'] and follow['canonical_unchanged'] and len(follow['checks']) == 8, 'corrected eight-suite continuation')
    check(load(RAW / 'corrected-continuation/canonical-source.json') == current, 'continuation exact current source')
    coverage = {}
    for label, report in [('full', full), ('corrected-continuation', follow)]:
        for row in report['checks']:
            if not row['pass']:
                continue
            name = row['name']
            command = RAW / label / (name + '.command.json')
            log = RAW / label / (name + '.log')
            record = load(command)
            check(record['exit'] == 0 and not record['errors'], name + ' successful command receipt')
            check(sim.sha(Path(row['wrapper']['path'])) == row['wrapper']['sha256'], name + ' exact retained wrapper')
            coverage[name] = {'run': label, 'command': str(command), 'command_sha256': sim.sha(command),
                              'log': str(log), 'log_sha256': sim.sha(log), 'wrapper': row['wrapper']}
    check(len(coverage) == 182, 'all maintained suites have passing receipts')
    campaign = load(RAW / 'campaign/cases/sports-1112/result.json')
    replay = load(RAW / 'campaign-replay/replay-report.json')
    check(campaign['ok'] and campaign['commands'] == campaign['accepted_commands'] == 98 and campaign['final_release_count'] == 4 and campaign['final_run_cycle'] == 42, 'fresh legal four-release campaign')
    check(replay['ok'] and replay['final_state'] == campaign['final_state'] and len(replay['steps']) == 98 and replay['telemetry_verified'] and replay['telemetry_samples'] == 99, 'exact fresh-process campaign replay and telemetry')
    crown = load(HERE / 'crown-analysis.json')
    check(crown['status'] == 'PASS' and len(crown['rows']) == 30 and len(crown['pairs']) == 15, 'Crown complete paired evidence')
    for label, case in [('bridge', 'balanced_safe-action-4418-cult'), ('fresh', 'balanced_safe-action-4521-none'), ('failed', 'balanced_safe-puzzle-4521-none')]:
        original = load(RAW / 'crown-conservative/cases' / case / 'result.json')
        replayed = load(RAW / ('crown-replay-' + label) / 'replay-report.json')
        check(replayed['ok'] and replayed['final_state'] == original['final_state'] and len(replayed['steps']) == original['commands'], 'Crown exact ' + label + ' replay')
    prior = load(RAW / 'crown-conservative/cases/balanced_safe-action-4418-cult/result.json')
    cold = load(RAW / 'crown-cold-v2/cases/crown-cold-4418/result.json')
    check(cold['ok'] and cold['initial_state'] == prior['final_state'] and cold['initial_rng'] == prior['final_rng'] and cold['initial_release_count'] == 6 and cold['final_release_count'] == 7, 'private same-source cold Studio identity/RNG and next release')
    package = load(RAW / 'package-v2/result.json')
    build = load(RAW / 'package-v2/build-manifest.json')
    check(package['pass'] and package['canonical_unchanged'] and package['pack_entries'] == 383, 'fresh package and isolated release EXE startup')
    for path, expected in build['included'].items():
        check(sim.sha(ROOT / 'patch-notes' / path) == expected, 'exact export input ' + path)
    check((ROOT / '.codex-godot-temp').exists(), 'preserved shared temp directory')
    report = {'pass': True, 'checks': checks, 'branch': subprocess.check_output(['git', 'branch', '--show-current'], cwd=ROOT, text=True).strip(),
              'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'production_unchanged': True, 'canonical_delta': delta, 'maintained_suites': 182,
              'coverage_scope': 'One full immutable run plus eight corrected checks. All production source matches; one verifier expectation changed. Not one uninterrupted all-green invocation.',
              'coverage': coverage, 'campaign': {'commands': 98, 'releases': 4, 'cycles': 42, 'exact_replay': True, 'telemetry': 99},
              'crown': {'cases': 30, 'pairs': 15, 'audit_checks': crown['checks'], 'same_source_cold_commands': cold['commands'], 'fresh_predecessor_migration': 'NOT TESTED / unsupported candidate schema'},
              'package': package, 'release_ready': False, 'commit_push': 'NOT RUN'}
    sim.write_json(HERE / 'source.json', current)
    sim.write_json(HERE / 'audit.json', report)
    selected = [p for folder in ['full', 'corrected-continuation', 'campaign', 'campaign-replay', 'crown-control', 'crown-conservative',
                 'crown-replay-bridge', 'crown-replay-fresh', 'crown-replay-failed', 'crown-cold', 'crown-cold-v2', 'package', 'package-v2']
                for p in (RAW / folder).glob('*') if p.is_file() and p.suffix in ['.json', '.log']]
    # The shell may still be writing this audit's redirected stdout; exclude
    # those self-referential driver logs from the completed-artifact manifest.
    selected += [p for p in RAW.glob('*.log') if not p.name.startswith('closeout-audit')]
    sim.write_json(HERE / 'external-artifacts.json', {'root': str(RAW), 'selected': {str(p.relative_to(RAW)): sim.sha(p) for p in selected},
                   'scope': 'Includes original failing attempts and final passing evidence; no player profile or existing evidence overwritten.'})
    print(json.dumps({k: v for k, v in report.items() if k not in ['coverage', 'package']}))


if __name__ == '__main__':
    main()
