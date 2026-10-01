"""Independent exact-cent reconciliation of completed Stage 2 and Stage 3 traces.

Run: python -B analysis/feature_store_cash_audit_v1.py
Read-only with respect to gameplay; writes cash_audit_v1.json and short notes.
All amounts are signed Python integers. Nested summaries are never receipts.
"""
from __future__ import annotations
import collections
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/feature-store-staged-v1'
START_CENTS = 550000
RIVAL_PAYOUT_CENTS = 100000
CAMPAIGN_COST_CENTS = 10000

def integer(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or int(value) != value:
        raise ValueError(f'Expected exact integer cents, got {value!r}')
    return int(value)

def settled(state):
    records = state['sales']
    ids = [r['release_id'] for r in records]
    if len(ids) != len(set(ids)): raise ValueError('Duplicate release IDs in one sales snapshot')
    return sum(integer(r['settled_cents']) for r in records)

def settlement_delta(before, after):
    return settled(after) - settled(before)

def contract_receipts(row):
    # Only authoritative top-level Contract logs. The actions list and long_run
    # summaries also describe these hands; adding them would double-count cash.
    logs = [(key, value) for key, value in row.items()
            if (key == 'ironclad' or key.startswith('sidestreet_'))
            and isinstance(value, dict) and 'hands' in value and 'completion' in value]
    ids = [value['offer_id'] for _, value in logs]
    if len(ids) != len(set(ids)): raise ValueError('Duplicate completed Contract offer ID')
    return logs

def command_records():
    found = {}
    for path in sorted(OUT.glob('*_results.json')):
        try: values = json.loads(path.read_text(encoding='utf-8'))
        except (OSError, json.JSONDecodeError): continue
        if not isinstance(values, list): continue
        for value in values:
            if not isinstance(value, dict) or 'spec' not in value: continue
            spec = value['spec']
            filename = 'stage2_' + str(spec.get('policy', 'ordinary')) + '_' + str(spec.get('arm', 'none'))
            if spec.get('tag'): filename += '_' + str(spec['tag'])
            if integer(spec.get('start', 0)) != 0: filename += '_' + str(spec['start'])
            found[filename + '.json'] = {'command_filename': str(path.relative_to(ROOT)),
                'command': value.get('command'), 'command_exit': value.get('returncode')}
    for path in sorted(OUT.glob('stage3_*_command.json')):
        try: value = json.loads(path.read_text(encoding='utf-8'))
        except (OSError, json.JSONDecodeError): continue
        found[path.name.replace('_command.json', '.json')] = {
            'command_filename': str(path.relative_to(ROOT)), 'command': value.get('command'),
            'command_exit': value.get('exit')}
    return found

def audit_row(row, stage):
    final = row.get('final_state') if stage == 2 else row.get('final')
    if not isinstance(final, dict):
        return {'case': row.get('case'), 'status': 'not_completed', 'errors': row.get('errors', []),
                'reason': 'No final authoritative state; excluded from completed cash denominator.'}
    errors = []
    boundaries = []
    def boundary(label, before, after, direct_cents):
        direct_cents = integer(direct_cents)
        delta = integer(after['cash_cents']) - integer(before['cash_cents'])
        settlement = settlement_delta(before, after)
        residual = delta - direct_cents - settlement
        item = {'boundary': label, 'before_cycle': integer(before['cycle']), 'after_cycle': integer(after['cycle']),
                'cash_delta_cents': delta, 'direct_delta_cents': direct_cents,
                'settlement_delta_cents': settlement, 'residual_cents': residual}
        boundaries.append(item)
        if residual != 0: errors.append(item)
        return item

    acquisitions = row.get('starter_purchases', []) + row.get('trial_purchases', []) if stage == 2 else row.get('purchases', [])
    acquisition_cents = 0
    for index, item in enumerate(acquisitions):
        success = bool(item.get('bought', item.get('success', False)))
        price = integer(item['quote']['price_cents']) if 'quote' in item else integer(item['price_cents'])
        if success: acquisition_cents += price
        boundary(f'acquisition:{index}:{item["id"]}', item['before'], item['after'], -price if success else 0)

    production_cents = 0
    beta_rival_cents = 0
    for index, action in enumerate(row['actions']):
        if 'before' not in action or 'after' not in action: continue
        phase = action.get('phase')
        before, after = action['before'], action['after']
        succeeded = integer(after['cycle']) > integer(before['cycle'])
        if phase in ('design', 'alpha'):
            cost = integer(action.get('cost_cents', 0)) if succeeded else 0
            production_cents += cost
            boundary(f'production:{index}:{phase}', before, after, -cost)
        elif phase == 'beta':
            payout = action.get('selected', []).count('playtest_rival_games') * RIVAL_PAYOUT_CENTS if succeeded else 0
            beta_rival_cents += payout
            boundary(f'beta:{index}', before, after, payout)
        elif phase in ('predevelopment', 'design_priority', 'alpha_priority', 'beta_priority', 'launch', 'zero_hand_transitions_launch'):
            boundary(f'action:{index}:{phase}', before, after, 0)
        # *_hand Contract actions are duplicate presentation logs, not new receipts.

    contract_cents = 0
    contracts = contract_receipts(row)
    contract_attribution = []
    for label, receipt in contracts:
        payout = integer(receipt['completion']['payout_cents'])
        contract_cents += payout
        boundary(label + ':accept', receipt['before'], receipt['after_accept'], integer(receipt['completion']['upfront_cents']))
        for index, hand in enumerate(receipt['hands']):
            boundary(label + f':hand:{index + 1}', hand['before'], hand['after'], integer(hand.get('planned_remainder_cents', 0)))
        if 'priority_commit' in receipt:
            adjustment = receipt['priority_commit']
            boundary(label + ':priority', adjustment['before'], adjustment['after'], 0)
        whole = boundary(label + ':complete_segment', receipt['before'], receipt['after_dismiss'], payout)
        contract_attribution.append({'offer_id': receipt['offer_id'], 'payout_cents': payout,
            'cash_delta_cents': whole['cash_delta_cents'], 'settlement_delta_cents': whole['settlement_delta_cents']})

    campaign_cents = 0
    campaign = row.get('campaign_sensitivity')
    if isinstance(campaign, dict):
        campaign_cents = CAMPAIGN_COST_CENTS if campaign.get('bought') else 0
        boundary('campaign', campaign['before'], campaign['after'], -campaign_cents)

    settled_cents = settled(final)
    expected = START_CENTS - acquisition_cents - production_cents - campaign_cents + beta_rival_cents + contract_cents + settled_cents
    actual = integer(final['cash_cents'])
    if actual != expected: errors.append({'boundary': 'full_run', 'residual_cents': actual - expected})
    calendar_checks = 0
    if isinstance(row.get('cycle_rows'), list):
        # Stage3 records every calendar notification. Passive cash (starter
        # purchases and Ironclad acceptance) appears in the next notification.
        # Aggregate Contract segments are already represented by accept/hand
        # receipts and must not be counted again here.
        direct_at_cycle = collections.defaultdict(int)
        for item in boundaries:
            if item['boundary'].endswith(':complete_segment'): continue
            before_cycle, after_cycle = item['before_cycle'], item['after_cycle']
            target = after_cycle if after_cycle > before_cycle else after_cycle + 1
            direct_at_cycle[target] += item['direct_delta_cents']
        previous = {'cycle': 0, 'cash_cents': START_CENTS, 'sales': []}
        for state in row['cycle_rows']:
            cycle = integer(state['cycle'])
            residual = integer(state['cash_cents']) - integer(previous['cash_cents']) - direct_at_cycle[cycle] - settlement_delta(previous, state)
            calendar_checks += 1
            if cycle != integer(previous['cycle']) + 1 or residual != 0:
                errors.append({'boundary': 'calendar_notification', 'cycle': cycle,
                    'previous_cycle': integer(previous['cycle']), 'residual_cents': residual})
            previous = state
    return {'case': row.get('case'), 'seed': row.get('seed'), 'policy': row.get('policy'),
        'route_valid': row.get('valid'), 'status': 'pass' if not errors else 'fail',
        'start_cash_cents': START_CENTS, 'acquisitions_cents': acquisition_cents,
        'feature_play_cents': production_cents, 'campaign_cents': campaign_cents,
        'beta_rival_payout_cents': beta_rival_cents, 'contract_payout_cents': contract_cents,
        'settled_sales_cents': settled_cents, 'expected_final_cash_cents': expected,
        'actual_final_cash_cents': actual, 'residual_cents': actual - expected,
        'boundary_checks': len(boundaries), 'calendar_notification_checks': calendar_checks, 'boundary_errors': errors,
        'contract_attribution': contract_attribution}

def main():
    commands = command_records()
    files = []
    exceptions = []
    skipped = []
    for path in sorted([*OUT.glob('stage2_*.json'), *OUT.glob('stage3_*.json')]):
        if path.name.endswith('_command.json'): continue
        if path.name.startswith('stage2_') and not path.name.startswith(('stage2_cautious_', 'stage2_ordinary_', 'stage2_optimizer_')):
            skipped.append({'filename': path.name, 'reason': 'Aggregate export, not a raw policy trace.'})
            continue
        try:
            data_bytes = path.read_bytes()
            payload = json.loads(data_bytes)
            if not isinstance(payload, dict) or not isinstance(payload.get('rows'), list) or payload.get('policy') not in ('cautious', 'ordinary', 'optimizer'):
                skipped.append({'filename': path.name, 'reason': 'Not a raw trace with rows; no cohort denominator.'})
                continue
            stage = 2 if path.name.startswith('stage2_') else 3
            audited = []
            for index, row in enumerate(payload['rows']):
                try: audited.append(audit_row(row, stage))
                except Exception as error:
                    exceptions.append({'filename': path.name, 'row_index': index, 'case': row.get('case'), 'error': repr(error)})
                    audited.append({'case': row.get('case'), 'status': 'exception', 'error': repr(error)})
            files.append({'filename': str(path.relative_to(ROOT)), 'sha256': hashlib.sha256(data_bytes).hexdigest(),
                'stage': stage, 'declared_count': payload.get('count'), 'stored_row_count': len(payload['rows']),
                'command_record': commands.get(path.name, {'command_filename': None, 'note': 'No matching completed launch manifest found; raw trace retained.'}),
                'rows': audited})
        except Exception as error:
            exceptions.append({'filename': path.name, 'error': repr(error)})
    statuses = collections.Counter(r['status'] for f in files for r in f['rows'])
    boundaries = sum(r.get('boundary_checks', 0) for f in files for r in f['rows'])
    calendar_checks = sum(r.get('calendar_notification_checks', 0) for f in files for r in f['rows'])
    boundary_errors = sum(len(r.get('boundary_errors', [])) for f in files for r in f['rows'])
    stage_counts = {str(stage): collections.Counter(r['status'] for f in files if f['stage'] == stage for r in f['rows']) for stage in (2, 3)}
    report = {'version': 1, 'source_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'audit_command': [sys.executable, '-B', 'analysis/feature_store_cash_audit_v1.py'],
        'script_filename': 'analysis/feature_store_cash_audit_v1.py',
        'identity': '550000 - acquisition payments - resolved Feature fees - campaign fees + Beta Rival payouts + completed Contract payouts + settled sales',
        'files': files, 'exceptions': exceptions, 'skipped_non_raw': skipped,
        'counts': {'raw_files': len(files), 'stored_rows': sum(len(f['rows']) for f in files),
            'status': dict(statuses), 'stage_status': {k: dict(v) for k, v in stage_counts.items()},
            'boundary_checks': boundaries, 'calendar_notification_checks': calendar_checks, 'boundary_errors': boundary_errors},
        'denominator_note': 'Stored completed trace rows include smoke, repeated controls and sensitivity arms. Counts are cash checks, not unique seeds or independent gameplay samples.',
        'passed': not exceptions and statuses['fail'] == 0 and statuses['exception'] == 0}
    (OUT / 'cash_audit_v1.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    notes = f'''# Feature Store trial cash audit v1

Independent audit of {len(files)} raw files and {sum(len(f['rows']) for f in files)} stored route rows. Statuses: {dict(statuses)}. Action-boundary checks: {boundaries}; Stage3 calendar-notification checks: {calendar_checks}; discrepancies: {boundary_errors}; exceptions: {len(exceptions)}. These include smoke, repeated controls and trial arms; they are not independent-seed counts. The JSON preserves every filename, trace hash, case, matching launch-command record when available, failure and exception.

The exact-cent identity is starting $5,500 minus successful starter/later purchases, committed Feature play fees (including recorded trial fees), and campaigns, plus Beta Playtest Rival Games payouts, completed Contract payouts, and per-release settled sales. Earned-but-unsettled sales are excluded from spendable cash. Python integers preserve signed cents exactly. Top-level Contract logs are receipts; repeated actions/long-run summaries are not added again.

Playtest Rival Games pays the existing **$1,000** when actually committed. It must remain a separate cash source: assigning that income to shopping, Review, or SideStreet would distort policy comparisons. A Contract's cash increase can exceed its payout when an older game settles during the same cycles; each audited Contract segment reports its direct payout and separate settlement increase. The audit also checks individual production, Beta, purchase, Contract, priority, launch, Pre-Development and campaign cash boundaries available in the traces.

Reproduce from `patch-notes`: `python -B analysis/feature_store_cash_audit_v1.py`. It reads currently completed raw Stage2/Stage3 outputs, writes only this note and `cash_audit_v1.json`, and exits nonzero for any mismatch or exception. Missing final states are reported and excluded from the completed denominator. Re-run after additional batches finish. No gameplay file or state is changed.
'''
    (OUT / 'cash_audit_v1.md').write_text(notes, encoding='utf-8')
    print(json.dumps({'passed': report['passed'], **report['counts'], 'exceptions': exceptions}, indent=2))
    raise SystemExit(0 if report['passed'] else 1)

if __name__ == '__main__': main()
