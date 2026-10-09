"""Independent integer/finance audit of the single recorded v2 attempt.

Reads evidence only. It never launches Godot, advances a route, or edits runtime.
"""
from collections import Counter
from pathlib import Path
import gzip
import hashlib
import json
import subprocess

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
OLD = REPO / 'docs/codex/threads/fanbase'
WORK = Path(r'C:/Users/64jus/.codex/worktrees/fanbase-quarter/PatchNotes')
CHECKS = 0


def check(condition, label):
    global CHECKS
    CHECKS += 1
    if not condition:
        raise AssertionError(label)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_route(path):
    return json.loads(gzip.decompress(path.read_bytes()))


def normalized(value, route):
    text = json.dumps(value, sort_keys=True)
    for index, release in enumerate(route['releases']):
        text = text.replace(release['release_id'], 'release_' + str(index + 1))
    return json.loads(text)


def git(*args):
    return subprocess.check_output(['git', '-c', 'safe.directory=' + str(WORK), '-C', str(WORK), *args])


def check_finance(state, label):
    finance = state['finance']
    check(finance['cash_cents'] == state['cash_cents'], label + ': cash agrees with ledger')
    closing = 0
    for transaction in finance['transactions']:
        check(transaction['cash_before_cents'] == closing, label + ': contiguous cash journal')
        closing += transaction['cash_delta_cents']
        check(transaction['cash_after_cents'] == closing, label + ': transaction cash conservation')
    check(closing == state['cash_cents'], label + ': journal closes to actual cash')
    previous_close = 0
    for row in finance['monthly_rows']:
        costs = sum(row[key] for key in ['feature_play_cents', 'store_cents', 'campaign_cents',
                                        'playtest_cents', 'other_expense_cents', 'interest_cents'])
        check(row['opening_cash_cents'] == previous_close, label + ': contiguous monthly cash')
        check(row['closing_cash_cents'] == row['opening_cash_cents'] + row['financing_in_cents']
              + row['other_income_cents'] + row['sales_settled_cents'] - costs
              - row['rent_paid_cents'] - row['principal_paid_cents'], label + ': monthly cash')
        check(row['net_profit_cents'] == row['sales_net_earned_cents'] + row['other_income_cents']
              - costs - row['rent_due_cents'], label + ': accrued operating result')
        check(row['rent_due_cents'] == (0 if row['partial'] else 50000), label + ': actual $500 rent')
        previous_close = row['closing_cash_cents']
    check(previous_close == state['cash_cents'], label + ': monthly rows close to actual cash')
    records = state.get('records')
    if records is not None:
        earned = sum(record['entitlement_cents'] for record in records)
        settled = sum(record['settled_cents'] for record in records)
        check(earned == sum(row['sales_net_earned_cents'] for row in finance['monthly_rows']), label + ': earned sales')
        check(settled == sum(row['sales_settled_cents'] for row in finance['monthly_rows']), label + ': settled sales')
        check(earned - settled == finance['unsettled_sales_net_cents'], label + ': unsettled entitlement')
        for record in records:
            check(record['entitlement_cents'] == record['earned_units'] * 999 * 70 // 100,
                  label + ': per-title exact 70% net cents')
            check(0 <= record['settled_cents'] <= record['entitlement_cents'], label + ': no unearned settlement')


data = load_route(HERE / 'attempt.json.gz')
check(data['valid'] and not data['errors'] and not data['discrepancies'], 'native validity')
check(data['seed'] == 1104 and data['policy'] == 'ordinary' and data['specialty'] == 'action'
      and data['contract_arm'] == 'available' and data['store_arm'] == 'none'
      and not data['campaign_sensitivity'], 'predeclared route parameters')
check(data['initial']['cash_cents'] == 570000 and data['initial']['fans'] == 0
      and data['initial']['cycle'] == 0, 'genuine $5700 creation, no injected starting Fans')
check(not data['blockers'], 'no rejected/blocking action in the completed route')
check(len(data['releases']) == 3, 'exactly three releases, no Game4 launch')
check(data['stop'] == 'two Game3 earning boundaries', 'predeclared stopping condition')
prefix = [action for action in data['actions'] if action.get('game', 0) < 3]
check(len(prefix) == 35, 'exact 35-action positive prefix')
check(len(data['live_cycles']) >= 32 and [s['cycle'] for s in data['live_cycles'][:32]] == list(range(1, 33)),
      'exact 32-cycle positive prefix')
for relative in ['quarter-trial-v1/restrained.json.gz', 'near-neutral-v1/primary.json.gz']:
    reference = load_route(OLD / relative)
    reference_prefix = [action for action in reference['actions'] if action.get('game', 0) < 3]
    check(normalized(prefix, data) == normalized(reference_prefix, reference), relative + ': full action prefix parity')
    for actual, expected in zip(data['live_cycles'][:32], reference['live_cycles'][:32]):
        check(normalized(actual, data) == normalized(expected, reference), relative + ': full cycle-state prefix parity')

weak = data['releases'][2]
weak_id = weak['release_id']
game3 = [action for action in data['actions'] if action.get('game') == 3]
check(Counter(action['phase'] for action in game3) == Counter({'predevelopment': 1, 'design': 4,
      'alpha': 4, 'beta': 4, 'launch': 1}), 'exact Game3 four/four/four hands and ordinary departure/launch')
for action in data['actions']:
    phase = action['phase']
    if phase in ['predevelopment', 'design', 'alpha', 'beta'] or phase.endswith(' hand'):
        check(action['after']['cycle'] == action['before']['cycle'] + 1, 'accepted productive action: ' + phase)
    if 'success' in action:
        check(action['success'], 'explicit successful action: ' + phase)
    if phase == 'launch':
        check(action['after']['cycle'] == action['before']['cycle'] and not action['budget_curtailed'],
              'normal zero-cycle uncurtailed launch')
check(weak['development_cycles'] == 13 and weak['departure_cycle'] == 32 and weak['cycle'] == 45,
      'Game3 ordinary departure plus twelve hands')
game4 = [action for action in data['actions'] if action.get('game') == 4]
check(game4 and game4[0]['phase'] == 'predevelopment'
      and all(action['phase'] == 'design' for action in game4[1:]), 'Game4 earns only through ordinary Design activity')
check([state['cycle'] for state in data['live_cycles']] == list(range(1, data['final']['cycle'] + 1)),
      'one contiguous state per productive cycle, no free waits')

prior_entries = {}
prior_fans = 0
boundaries = []
for state in data['live_cycles']:
    cycle = state['cycle']
    fan = state['fan_snapshot']
    records = {record['release_id']: record for record in state['records']}
    check(state['fans'] == fan['fans'] and fan['last_cycle'] == cycle, 'live Fan snapshot identity')
    check_finance(state, 'cycle ' + str(cycle))
    if cycle % 2:
        check(state['fans'] == prior_fans, 'odd cycle does not publish Fan changes')
        continue
    month = fan['months'][-1]
    check(month['month'] == cycle // 2 and month['starting'] == prior_fans, 'common pre-boundary Fan pool')
    gains = losses = 0
    expected_details = []
    for release_id in sorted(fan['releases']):
        entry = fan['releases'][release_id]
        before = prior_entries.get(release_id, {'gained': 0, 'loss_exposure_accounted': 0, 'lost': 0,
                                  'accounted_units': 0, 'neutral': {'earned_units': 0}})
        record = records[release_id]
        units = record['earned_units']
        neutral = entry['neutral']
        check(neutral['review_tenths'] == 50 and neutral['launch_awareness'] == record['launch_awareness']
              and neutral['market_bp'] == record['market_bp'], 'Review-neutral reach preserves launch inputs')
        expected_neutral_month_one = 500 * 50 * (200 + record['launch_awareness']) * record['market_bp'] // (70 * 200 * 10000)
        check(neutral['total_units'] == expected_neutral_month_one, 'independent neutral Month1 projection')
        exposure = min(entry['launch_fans'], neutral['earned_units'])
        target = exposure * 15 * max(0, 50 - entry['review_tenths']) // 1000
        gain_target = max(0, units - entry['launch_fans']) * 8 * min(30, max(0, entry['review_tenths'] - 50)) // 2000
        gain = gain_target - before['gained']
        loss = min(month['starting'] - losses, target - before['loss_exposure_accounted'])
        earned_units = units - before['accounted_units']
        check(gain >= 0 and loss >= 0 and earned_units >= 0, 'monotonic cumulative exposure/earnings')
        check(entry['gained'] == gain_target and entry['loss_exposure_accounted'] == target,
              'cumulative integer gain/loss targets, no forced minimum')
        check(entry['lost'] == before['lost'] + loss and entry['accounted_units'] == units,
              'incremental loss and units accounted once')
        gains += gain
        losses += loss
        if earned_units > 0 or gain > 0 or loss > 0:
            expected_details.append(dict(release_id=release_id, earned_units=earned_units, new_fans=gain, lost_fans=loss))
        if release_id == weak_id and cycle > weak['cycle']:
            boundaries.append(dict(cycle=cycle, month=month['month'], starting=month['starting'], earned_units=earned_units,
                cumulative_units=units, neutral_cumulative_units=neutral['earned_units'],
                incremental_neutral_units=neutral['earned_units'] - before['neutral']['earned_units'],
                exposure=exposure, new_exposure=exposure - min(entry['launch_fans'], before['neutral']['earned_units']),
                loss_target=target, title_loss=loss, title_gain=gain, other_title_gains=month['gained'] - gain,
                shared_pre_boundary_cap=month['starting'], all_gains=month['gained'], all_losses=month['lost'],
                net=month['net'], ending=month['ending'], cash_cents=state['cash_cents'],
                title_earned_cents=record['entitlement_cents'], title_settled_cents=record['settled_cents'],
                title_unsettled_cents=record['entitlement_cents'] - record['settled_cents']))
    check(month['releases'] == expected_details, 'per-title monthly delta details')
    check(month['gained'] == gains and month['lost'] == losses and month['ending'] == month['starting'] + gains - losses
          and month['net'] == gains - losses and losses <= month['starting'], 'shared monthly cap and Fan conservation')
    check(state['fans'] == month['ending'], 'published monthly Fan total')
    prior_entries = fan['releases']
    prior_fans = state['fans']

check(len(boundaries) == 2 and all(row['earned_units'] > 0 for row in boundaries), 'exactly two actual weak-title earning boundaries')
check(data['final']['cycle'] == boundaries[-1]['cycle'] and game4[-1]['after']['cycle'] == boundaries[-1]['cycle'],
      'immediate stop at second earning boundary')
check_finance(data['final'] | {'records': data['sales_records']}, 'final')
launches = []
for release in data['releases']:
    entry = data['final']['fan_snapshot']['releases'][release['release_id']]
    launch_action = next(action for action in data['actions'] if action['phase'] == 'launch'
                         and action['after']['cycle'] == release['cycle'])
    check(entry['launch_fans'] == launch_action['before']['fans'], 'Fans frozen at genuine launch')
    check(entry['review_tenths'] == round(release['final_review'] * 10), 'native Review retained')
    launches.append({key: release[key] for key in ['cycle', 'final_review', 'awareness', 'month_1_units', 'cash_cents']}
                    | {'launch_fans': entry['launch_fans'], 'fan_awareness': min(150, entry['launch_fans'] // 4)})

manifest = json.loads((HERE / 'source.json').read_text())
previous_manifest_path = OLD / 'near-neutral-v1/source.json'
previous_manifest = json.loads(previous_manifest_path.read_text())
project = Path(manifest['project'])
previous_project = Path(previous_manifest['project'])
check(manifest['head'] == 'bd450a9e4e8d83ece1478cdf5a16526432e36cce'
      and manifest['branch'] == 'codex/fanbase-quarter-trial', 'pinned source identity')
check(digest(previous_manifest_path) == manifest['previous_manifest_sha256'], 'previous source manifest unchanged')
check(digest(HERE / 'PLAN.md') == manifest['plan_sha256'], 'predeclared plan unchanged')
runtime_files = 0
for relative, expected_hash in manifest['files'].items():
    check(digest(project / relative) == expected_hash, 'captured source unchanged: ' + relative)
    if not relative.replace('\\', '/').startswith('analysis/'):
        runtime_files += 1
        check(digest(previous_project / relative) == expected_hash, 'runtime matches prior pinned capture: ' + relative)
        if relative in previous_manifest['files']:
            check(previous_manifest['files'][relative] == expected_hash, 'runtime prior manifest parity: ' + relative)
        check(digest(WORK / 'patch-notes' / relative) == expected_hash, 'branch runtime preserved: ' + relative)
check(git('rev-parse', 'HEAD').decode().strip() == manifest['head'], 'branch HEAD preserved')
check(git('branch', '--show-current').decode().strip() == manifest['branch'], 'branch name preserved')
check(git('diff') == (HERE / 'branch.patch').read_bytes(), 'branch diff preserved')
check(git('status', '--short') == (HERE / 'branch-status.txt').read_bytes(), 'branch status preserved')

summary = dict(checks=CHECKS, passed=True, prefix_actions=len(prefix), prefix_cycles=32, game3_hands=[4, 4, 4],
    target_hit=4.0 <= weak['final_review'] < 5.0, launches=launches, boundaries=boundaries,
    stop=data['stop'], blockers=data['blockers'], final_cycle=data['final']['cycle'],
    final_cash_cents=data['final']['cash_cents'], final_fans=data['final']['fans'],
    runtime_files_checked=runtime_files, captured_files_checked=len(manifest['files']),
    native_ledger_checks=data['ledger_checks'], native_row_checks=data['row_checks'])
(HERE / 'audit.json').write_text(json.dumps(summary, indent=2) + '\n')
print('PASS', CHECKS, 'independent checks')
print(json.dumps(summary, indent=2))
