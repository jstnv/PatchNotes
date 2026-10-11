"""Independent bounded-study evidence audit; reads artifacts, never game state."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
CHECKS = []


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def check(condition, label):
    CHECKS.append({'check': label, 'ok': bool(condition)})
    if not condition:
        raise AssertionError(label)


def main():
    summaries = []
    comparisons = []
    for seed in ('4417', '90210'):
        config = read(HERE / ('store-' + seed + '-input.json'))
        bundle = HERE / ('store-' + seed + '-01')
        prefix = read(HERE / 'store-prefix-01/cases' / ('action-' + seed) / 'result.json')
        prefix_checkpoint = read(HERE / 'store-prefix-01/cases' / ('action-' + seed) / 'studio_checkpoint.json')
        cases = config['cases']
        check(cases[0]['initial'] == cases[1]['initial'] == {'checkpoint': prefix_checkpoint}, seed + ': exact unchanged common checkpoint')
        check(cases[0]['study']['pair_id'] == cases[1]['study']['pair_id'], seed + ': declared matched pair')
        check(cases[0]['policy']['config']['development'] == cases[1]['policy']['config']['development'], seed + ': same explicit development policy')
        first_result = None
        for case in cases:
            arm = case['study']['arm']
            case_dir = bundle / 'cases' / case['case_id']
            result = read(case_dir / 'result.json')
            telemetry = read(case_dir / 'telemetry.json')
            samples = telemetry['samples']
            if first_result is None:
                first_result = result
            check(result['initial_rng'] == first_result['initial_rng'] == prefix['final_rng'], seed + '/' + arm + ': original RNG streams retained')
            check(result['initial_state'] == first_result['initial_state'], seed + '/' + arm + ': identical restored initial-state digest')
            check(result['source_identity'] == prefix['source_identity'] == prefix_checkpoint['source_identity'], seed + '/' + arm + ': unchanged rules identity')
            check(result['study'] == case['study'], seed + '/' + arm + ': study metadata retained')
            check(hashlib.sha256((case_dir / 'telemetry.json').read_bytes()).hexdigest() == result['telemetry_sha256'], seed + '/' + arm + ': telemetry hash')
            check(len(samples) == result['commands'] + 1, seed + '/' + arm + ': one sample per executed command plus initial')
            check(all(row['step'] == i for i, row in enumerate(samples)), seed + '/' + arm + ': contiguous telemetry samples')
            check(all(row['run_cycle'] <= samples[i + 1]['run_cycle'] for i, row in enumerate(samples[:-1])), seed + '/' + arm + ': no calendar reversal')
            check(result['commands'] <= case['max_commands'] == 100, seed + '/' + arm + ': declared command bound')
            rejected = [row for row in samples if row['accepted'] is False]
            if result['ok']:
                check(result['status'] == 'completed' and result['final_release_count'] == 2 and samples[-1]['in_studio'], seed + '/' + arm + ': exact Studio release horizon')
                check(not rejected, seed + '/' + arm + ': no hidden rejected retry')
            else:
                check(result['status'] in ('rejected_policy_action', 'command_bound'), seed + '/' + arm + ': allowed retained censor only')
                if rejected:
                    check(len(rejected) == 1 and rejected[0] == samples[-1], seed + '/' + arm + ': stopped at first rejected action')
            store_samples = [row for row in samples if row['command_type'] in ('admit_research', 'research')]
            if arm == 'defer':
                check(not store_samples, seed + ': defer never admits or researches')
                check(all('recorded_sounds' not in row['owned_features'] and not row['research_queue'] for row in samples), seed + ': defer no target acquisition or queue')
                check(all(row['command_type'] in ('', 'begin_development', 'development', 'launch') for row in samples), seed + ': genuine development only')
            else:
                accepted_store = [row for row in store_samples if row['accepted']]
                check([row['command_type'] for row in accepted_store] == ['admit_research', 'research'], seed + ': one admission and one successful research')
                admission, research = accepted_store
                aq = admission['request']['payload']['quote']
                rq = research['request']['payload']['quote']
                check(aq['feature_id'] == rq['feature_id'] == 'recorded_sounds' and aq['can_admit'] and rq['can_research'] and rq['head'], seed + ': explicit public legal target and FIFO quotes')
                before = samples[admission['step'] - 1]
                check(admission['run_cycle'] == before['run_cycle'] and int(before['cash_cents']) - int(admission['cash_cents']) == aq['down_cents'], seed + ': exact admission payment at zero cycles')
                check('recorded_sounds' not in admission['owned_features'] and admission['research_queue'][0]['feature_id'] == 'recorded_sounds', seed + ': admission is queue membership not ownership')
                check(research['run_cycle'] == admission['run_cycle'] + 1 and 'recorded_sounds' in research['owned_features'] and not research['research_queue'], seed + ': one research cycle grants final ownership')
                check(next(row['step'] for row in samples if row['command_type'] == 'begin_development') > research['step'], seed + ': completes research before next project')
                checkpoint = read(case_dir / 'studio_checkpoint.json')
                record = next(item for item in checkpoint['studio_payload']['run']['feature_research'] if item['feature_id'] == 'recorded_sounds')
                payment = record['payments'][0]
                for field in ('nominal_cents', 'discount_percent', 'saving_cents'):
                    check(int(payment[field]) == int(rq[field]), seed + ': retained payment ' + field)
                check(int(payment['paid_cents']) == rq['due_cents'] and int(payment['cycle']) == research['run_cycle'], seed + ': exact installment receipt')
                actions = checkpoint['studio_payload']['run']['studio_finance']['actions']
                admit_action = next(item for item in actions if item['source_id'] == aq['entry_id'] + ':admit')
                research_action = next(item for item in actions if item['source_id'] == rq['entry_id'] + ':' + str(rq['completed']))
                check(int(admit_action['direct_delta']) == -aq['down_cents'] and admit_action['productive'] is False and admit_action['kind'] == 'store', seed + ': admission journal matches quote')
                check(int(research_action['direct_delta']) == -rq['due_cents'] and research_action['productive'] is True and research_action['kind'] == 'store', seed + ': research journal matches quote')
            replay_dir = HERE / ('store-' + seed + '-' + arm + '-replay-01')
            replay = read(replay_dir / 'replay-report.json')
            check(replay['ok'] and replay['telemetry_verified'] and replay['telemetry_samples'] == len(samples), seed + '/' + arm + ': fresh-process full telemetry replay')
            check(read(replay_dir / 'run-report.json')['ok'], seed + '/' + arm + ': fresh replay runner passed')
            lows = [int(row['cash_cents']) for row in samples]
            lows += [int(row['transaction_cash_low_cents']) for row in samples if row['transaction_cash_low_cents'] is not None]
            summaries.append({'seed': seed, 'arm': arm, 'case_id': case['case_id'], 'status': result['status'], 'commands': result['commands'], 'final_cycle': result['final_run_cycle'], 'review': samples[-1]['releases'][-1]['review'], 'cash_cents': samples[-1]['cash_cents'], 'study_cash_low_cents': str(min(lows)), 'arrears_cents': samples[-1]['overdue_cents'], 'fans': samples[-1]['fans'], 'telemetry_samples': len(samples), 'first_blocked_action': rejected[0] if rejected else None})
        output = HERE / ('store-' + seed + '-comparison-01')
        argv = [sys.executable, str(ROOT / 'tools/compare_simulations.py'), '--bundle', str(bundle), '--left', cases[0]['case_id'], '--right', cases[1]['case_id'], '--output', str(output)]
        process = subprocess.run(argv, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        (HERE / ('store-' + seed + '-comparison.orchestration.log')).write_bytes(process.stdout)
        comparisons.append({'argv': argv, 'cwd': str(ROOT), 'exit': process.returncode})
        (HERE / 'store-comparison-commands.json').write_text(json.dumps(comparisons, indent=2) + '\n', encoding='utf-8')
        check(process.returncode == 0, seed + ': source-pinned paired reporter passed')
    output = {'ok': all(item['ok'] for item in CHECKS), 'check_count': len(CHECKS), 'checks': CHECKS, 'summaries': summaries, 'scope': 'Two explicit test seeds; one Feature; one additional release. No balance approval, shopping advice, universal success or audiovisual acceptance.'}
    (HERE / 'store-study-audit.json').write_text(json.dumps(output, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'ok': output['ok'], 'checks': len(CHECKS), 'summaries': summaries}, indent=2))


if __name__ == '__main__':
    main()
