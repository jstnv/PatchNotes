"""Read-only audit of the predeclared current-source Crown access pairs."""
from pathlib import Path
from collections import defaultdict
import hashlib, importlib.util, json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = Path('C:/Users/64jus/AppData/Local/Temp/pn-queue-closeout-20261024-v1')
load = lambda p: json.loads(p.read_text(encoding='utf-8'))
checks = 0


def check(condition, message):
    global checks
    assert condition, message
    checks += 1


def grade(scope, cores):
    completion = 10000 * (2 * min(scope, 9) + sum(min(v, 8) for v in cores) + 2 * min(min(cores), 8)) // 66
    promise = max(0, 10000 - 1250 * max(0, max(cores) - min(cores) - 4))
    return min(completion, promise)


def main():
    declared = load(HERE / 'crown-predeclared.json')
    notes = defaultdict(lambda: defaultdict(list))
    rows = []
    identities = set()
    for bundle in ['crown-control', 'crown-conservative']:
        folder = RAW / bundle
        report = load(folder / 'run-report.json')
        check(report['case_count'] == 15, bundle + ' complete declared inventory')
        identities.add(report['frozen_source_identity'])
        for line in (folder / 'experiment.log').read_text(encoding='utf-8').splitlines():
            if line.startswith('PN_CB_'):
                kind, payload = line.split(' ', 1)
                item = json.loads(payload)
                notes[item['case']][kind[6:]].append(item)
        for recipe in declared['cases']:
            case = recipe['case_id']
            path = folder / 'cases' / case / 'result.json'
            if not path.exists():
                continue
            result = load(path)
            n = notes[case]
            check(not n['FAIL'], case + ' no policy invariant failure')
            check(result['commands'] <= 200, case + ' command bound')
            check(result['accepted_commands'] == result['commands'] - (0 if result['ok'] else 1), case + ' retained rejected command')
            total = 0
            for event in n['RESULT']:
                value = grade(event['scope'], event['cores'])
                check(value == event['grade'] and value // 10 == event['award'], case + ' independent unchanged grade/award')
                total += event['award']
                check(total == event['total'], case + ' exact cumulative standing')
            for event in n['SAFE_MONOTONE']:
                check(event['after'] >= event['before'], case + ' conservative realized grade preserved')
            exhausted = defaultdict(set)
            for hand in n['HAND']:
                visible = {x['token']: x for x in hand['visible']}
                check(len(hand['chosen']) == len(set(hand['chosen'])) == 4 and all(t in visible for t in hand['chosen']), case + ' four distinct visible instances')
                for token in hand['chosen']:
                    card = visible[token]
                    if not card['renewable']:
                        check(card['definition'] not in exhausted[hand['offer']], case + ' finite Feature is not reused')
                        exhausted[hand['offer']].add(card['definition'])
            views = n['VIEW']
            crown_unlocked = None
            check(bool(views), case + ' observations present')
            check(int(views[-1]['reputation']) == total, case + ' final observed P1 credit')
            if result['ok']:
                check(result['final_release_count'] == 6 and result['outcome']['in_studio'], case + ' legal completed Studio boundary')
                checkpoint = load(path.parent / 'studio_checkpoint.json')
                pairs = lambda values: {x['key']: x['value'] for x in values}
                run = checkpoint['studio_payload']['run']
                crown_unlocked = 'crown_quill' in pairs(run['unlocked_publishers'])
                if not n['ACCEPT']:
                    check(not crown_unlocked, case + ' distinguish no unlock from an ignored unlocked offer')
                saved = pairs(run['crown_briefs'])
                events = run['publisher_relationships']['events']
                check(len(events) == len(n['RESULT']), case + ' exact event coverage')
                check(all(x['publisher_id'] == 'crown_quill' and int(x['credited_investment_bp']) == 0 for x in events), case + ' no cross-publisher/Investment awards')
                for item in n['RESULT']:
                    frozen = saved[item['offer']]['state']['result']
                    check(all(int(frozen[k]) == 0 for k in ['payout', 'promotion', 'bonus_cash_cents', 'bonus_promotion']), case + ' no money/Promotion rewards')
            rows.append({**recipe, 'ok': result['ok'], 'error': result['error'], 'commands': result['commands'],
                         'accepted_commands': result['accepted_commands'], 'initial_state': result['initial_state'],
                         'initial_rng': result['initial_rng'], 'final_state': result['final_state'],
                         'final_cycle': result['final_run_cycle'], 'releases': result['final_release_count'],
                         'cash_cents': result['outcome']['cash_cents'], 'overdue_cents': result['outcome']['finance']['total_overdue_cents'],
                         'briefs': len(n['RESULT']), 'reputation_bp': total, 'r20': n['R20'],
                         'crown_unlocked_at_final_studio': crown_unlocked,
                         'reviews': [x['metadata']['review']['final_review'] for x in result['outcome']['releases']],
                         'redraws': len(n['REDRAW']), 'grades': [x['grade'] for x in n['RESULT']],
                         'first_accept': n['ACCEPT'][0]['view_hash'] if n['ACCEPT'] else None})
    check(len(identities) == 1, 'same frozen candidate and policy across batches')
    check(len(rows) == len(declared['cases']) == 30, 'all cases including access failures retained')
    paired = []
    for control in [x for x in rows if x['arm'] == 'balanced']:
        candidate = next(x for x in rows if x['arm'] == 'balanced_safe' and x['case_id'].removeprefix('balanced_safe-') == control['case_id'].removeprefix('balanced-'))
        check(control['initial_state'] == candidate['initial_state'] and control['initial_rng'] == candidate['initial_rng'], control['case_id'] + ' exact equal-state/RNG pair')
        check(control['first_accept'] == candidate['first_accept'], control['case_id'] + ' shared pre-Brief boundary')
        if control['first_accept'] is None:
            check(control['final_state'] == candidate['final_state'], control['case_id'] + ' exact unchanged access-failure prefix')
        paired.append({'control': control['case_id'], 'candidate': candidate['case_id'],
                       'reputation_delta_bp': candidate['reputation_bp'] - control['reputation_bp'],
                       'cash_delta_cents': candidate['cash_cents'] - control['cash_cents'],
                       'cycle_delta': candidate['final_cycle'] - control['final_cycle']})
    independent = ROOT / 'docs/codex/threads/contracts/studies/crown-lookahead-20261024-v1/policy_audit.py'
    spec = importlib.util.spec_from_file_location('frozen_crown_policy_audit', independent)
    audit = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(audit)
    audit.audit(notes, check)
    result = {'status': 'PASS', 'checks': checks, 'source': next(iter(identities)), 'rows': rows, 'pairs': paired,
              'policy_audit_sha256': hashlib.sha256(independent.read_bytes()).hexdigest(),
              'scope': 'Private current-source Crown access evidence; failed routes retained, no gameplay adoption or final balance approval.'}
    (HERE / 'crown-analysis.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'status': 'PASS', 'checks': checks, 'cases': len(rows), 'completed': sum(x['ok'] for x in rows),
                      'fresh_completed': sum(x['ok'] for x in rows if x['cohort'] == 'fresh'),
                      'fresh_r20': sum(bool(x['r20']) for x in rows if x['cohort'] == 'fresh')}))


if __name__ == '__main__':
    main()
