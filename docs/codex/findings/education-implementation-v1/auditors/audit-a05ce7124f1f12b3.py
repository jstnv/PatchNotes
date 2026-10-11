"""Independent exact-cent education/accounting audit; never invokes Godot.

Raw outputs are read-only. Constructed accounting fixtures are not legal-route
balance evidence. Native run provenance is checked separately from arithmetic.
"""
from pathlib import Path
from collections import defaultdict
import argparse
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
APPROVED = ROOT / 'patch-notes/design-logs/threads/studio-traits/2026-10-06-education-debt-amortization-options-results-v1.json'
CHECKS = 0
CONTEXT = ''
DIRECT = {'development', 'priority_change', 'contract_hand', 'calendar',
          'feature_play', 'store', 'campaign', 'playtest', 'other_expense',
          'principal_paid', 'interest', 'publisher_receipt', 'beta_income',
          'other_income', 'financing_in'}
DEBT = {'bank_installment', 'student_loan'}
PAYMENT = {'rent': 'rent_payment', 'payroll': 'payroll_payment',
           'bank_installment': 'bank_payment', 'student_loan': 'education_payment'}
WEIGHTS = {'rent': [5, 10, 20], 'payroll': [5, 10, 15],
           'bank_installment': [10, 20, 30], 'student_loan': [5, 10, 20]}


def check(value, message):
    global CHECKS
    CHECKS += 1
    if not value:
        raise AssertionError(f'{CONTEXT}: {message}')


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def education_rows(trait):
    opening, regular = {'college_dropout': (500000, 7068), 'graduate': (2000000, 28273)}[trait]
    rows = []
    for number in range(1, 97):
        interest = (opening + 75) // 150
        payment = regular if number < 96 else opening + interest
        principal = payment - interest
        rows.append(dict(number=number, due_cycle=24 + 2 * number,
                         opening_principal_cents=opening, principal_cents=principal,
                         interest_cents=interest, payment_cents=payment))
        opening -= principal
    check(opening == 0, 'education schedule clears exactly')
    return rows


def audit_schedule(native=None):
    records = {r['trait']: r for r in read(APPROVED)['scenarios'] if not r['capitalize_grace']}
    for trait, record in records.items():
        rows = education_rows(trait)
        check(len(record['payments']) == 96, 'approved schedule has 96 lines')
        for expected, approved in zip(rows, record['payments']):
            mapped = dict(number=approved['payment_number'], due_cycle=2 * approved['due_month_from_creation'],
                          opening_principal_cents=approved['opening_cents'], principal_cents=approved['principal_cents'],
                          interest_cents=approved['interest_cents'], payment_cents=approved['due_cents'])
            check(expected == mapped, 'independent schedule equals approved exact-cent line')
        if native is not None:
            actual = native[trait]
            if isinstance(actual, dict):
                actual = actual['installments'] if 'installments' in actual else actual['rows']
            check(actual == rows, 'all native schedule lines equal independent approved schedule')
    return 192


def bank_rows(schedule):
    principal, term = schedule['principal_cents'], schedule['term_months']
    regular, extra = divmod(principal, term)
    opening = principal
    result = []
    for number in range(1, term + 1):
        amount = regular + (number <= extra)
        interest = (opening + 50) // 100
        result.append(dict(number=number, due_cycle=schedule['first_due_cycle'] + 2 * (number - 1),
                           opening_principal_cents=opening, principal_cents=amount,
                           interest_cents=interest, payment_cents=amount + interest))
        opening -= amount
    check(opening == 0, 'Bank schedule principal')
    return result


def audit_ledger(finance):
    f = finance
    check(f['schema_version'] == 6, 'current typed finance schema')
    txs, bills, rows = f['transactions'], f['obligations'], f['monthly_rows']
    check(len({b['bill_id'] for b in bills}) == len(bills), 'unique original bill identities')
    cash = 0
    for number, tx in enumerate(txs, 1):
        check(tx['sequence'] == number and tx['cash_before_cents'] == cash, 'journal sequence/opening cash')
        cash += tx['cash_delta_cents']
        check(tx['cash_after_cents'] == cash and cash >= 0, 'journal closing cash remains nonnegative')
    check(cash == f['cash_cents'], 'ledger cash matches journal')
    rent = [b for b in bills if b['expense_type'] == 'rent']
    check([b['due_cycle'] for b in rent] == list(range(2, f['last_cycle'] + 1, 2)), 'one rent bill per completed calendar month')
    check(all(b['due_cents'] == f['monthly_rent_cents'] and b['bill_id'] == f"rent:{b['month']}" for b in rent), 'unchanged contracted rent and identity')

    month_principal, month_interest = defaultdict(int), defaultdict(int)
    for bill in bills:
        check(bill['month'] == bill['due_cycle'] // 2, 'original due month')
        check(bill['paid_cents'] + bill['unpaid_cents'] == bill['due_cents'], 'bill exact unpaid remainder')
        check(sum(p['cents'] for p in bill['payments']) == bill['paid_cents'], 'bill payment history sum')
        payments = [t for t in txs if t['kind'] == PAYMENT[bill['expense_type']]
                    and t['due_month'] == bill['month']
                    and (bill['expense_type'] == 'rent' or t['source_id'] == bill['source_id'])]
        check([(t['cycle'], t['month'], t['amount_cents']) for t in payments]
              == [(p['cycle'], p['month'], p['cents']) for p in bill['payments']], 'journal/bill payment provenance')
        check(all(t['cash_delta_cents'] == -t['amount_cents'] for t in payments), 'bill payments are cash outflows')
        paid_interest = 0
        for p in bill['payments']:
            check(p['cycle'] >= bill['due_cycle'] and (p['cycle'] - 1) // 2 + 1 <= p['month'] <= p['cycle'] // 2 + 1,
                  'payment actual month and original due bounds')
            if bill['expense_type'] in DEBT:
                interest = min(p['cents'], bill['interest_cents'] - paid_interest)
                paid_interest += interest
                month_interest[p['month']] += interest
                month_principal[p['month']] += p['cents'] - interest
        if bill['expense_type'] in DEBT:
            check(bill['interest_paid_cents'] == paid_interest and bill['principal_paid_cents'] == bill['paid_cents'] - paid_interest,
                  'interest-before-principal allocation')
        on_time = sum(p['cents'] for p in bill['payments'] if p['cycle'] == bill['due_cycle'] and p['month'] == bill['month']) == bill['due_cents']
        check(bill['paid_on_time'] == on_time and bill['late'] == (not on_time), 'actual due-boundary late history')
        if bill['unpaid_cents']:
            check(bill['settled_cycle'] == -1 and bill['recovery_overdue_cycles'] == -1, 'unpaid bill retains open recovery')
        else:
            check(bill['settled_cycle'] == bill['payments'][-1]['cycle']
                  and bill['recovery_overdue_cycles'] == bill['settled_cycle'] - bill['due_cycle'], 'recovery keeps original age')

    for tx in txs:
        if tx['kind'] in {'bank_payoff', 'education_payoff', 'principal_paid'}:
            month_principal[tx['month']] += tx['amount_cents']
        if tx['kind'] == 'interest':
            month_interest[tx['month']] += tx['amount_cents']
    previous = 0
    for number, row in enumerate(rows, 1):
        month = row['month']; month_txs = [t for t in txs if t['month'] == month]
        check(month == number and row['opening_cash_cents'] == previous, 'monthly continuity')
        movement = sum(t['cash_delta_cents'] for t in month_txs)
        check(row['cash_change_cents'] == movement and row['closing_cash_cents'] == previous + movement, 'actual payment-month cash')
        previous = row['closing_cash_cents']
        mapping = {'sales_net_earned_cents': ['sales_earned'], 'sales_settled_cents': ['sales_settlement'],
                   'financing_in_cents': ['starting_funding', 'financing_in'], 'publisher_income_cents': ['publisher_receipt'],
                   'beta_income_cents': ['beta_income'], 'miscellaneous_income_cents': ['other_income'],
                   'other_income_cents': ['publisher_receipt', 'beta_income', 'other_income']}
        for kind in ['feature_play', 'store', 'campaign', 'playtest', 'other_expense']:
            mapping[kind + '_cents'] = [kind]
        for field, kinds in mapping.items():
            check(row[field] == sum(t['amount_cents'] for t in month_txs if t['kind'] in kinds), 'monthly field follows actual journal: ' + field)
        for category in ['rent', 'payroll']:
            original = [b for b in bills if b['expense_type'] == category and b['month'] == month]
            check(row[category + '_due_cents'] == sum(b['due_cents'] for b in original), 'original due-month expense')
            check(row[category + '_unpaid_cents'] == sum(b['unpaid_cents'] for b in original), 'original due-month arrears')
            check(row[category + '_paid_cents'] == sum(t['amount_cents'] for t in month_txs if t['kind'] == PAYMENT[category]), 'actual bill payment-month total')
        accrued = sum(b['interest_cents'] for b in bills if b['expense_type'] in DEBT and b['month'] == month)
        accrued += sum(t['amount_cents'] for t in month_txs if t['kind'] == 'interest')
        check(row['interest_cents'] == accrued, 'scheduled interest expensed once in original due month')
        check(row['interest_paid_cents'] == month_interest[month] and row['principal_paid_cents'] == month_principal[month], 'actual payment-month debt cash split')
        expenses = sum(row[k] for k in ['feature_play_cents', 'store_cents', 'campaign_cents', 'playtest_cents', 'other_expense_cents', 'rent_due_cents', 'interest_cents', 'payroll_due_cents'])
        revenue = row['sales_net_earned_cents'] + row['other_income_cents']
        check(row['operating_expenses_cents'] == expenses and row['operating_revenue_cents'] == revenue and row['net_profit_cents'] == revenue - expenses,
              'accrual profit excludes principal repayment')

    accounts = list(f['bank_loans'])
    if f['education']: accounts.append(f['education'])
    for account in accounts:
        is_education = 'trait_id' in account
        source = account['account_id'] if is_education else account['loan_id']
        schedule = education_rows(account['trait_id']) if is_education else bank_rows(account['schedule'])
        category = 'student_loan' if is_education else 'bank_installment'
        issued = [b for b in bills if b['expense_type'] == category and b['source_id'] == source]
        cutoff = account['closed_cycle'] if account['closed'] else f['last_cycle']
        check(len(issued) == account['issued'] == sum(d['due_cycle'] <= cutoff for d in schedule), 'exact scheduled issue count and closure cutoff')
        check(account['schedule']['total_interest_cents'] == sum(d['interest_cents'] for d in schedule), 'contract scheduled interest')
        check(account['schedule']['total_payment_cents'] == sum(d['payment_cents'] for d in schedule), 'contract scheduled total')
        for number, (bill, due) in enumerate(zip(issued, schedule), 1):
            check(bill['bill_id'] == f'{source}:{number}', 'stable debt installment ID')
            check(all(bill[k] == due[k] for k in ['due_cycle', 'principal_cents', 'interest_cents']) and bill['due_cents'] == due['payment_cents'], 'scheduled debt amounts never follow actual arrears')
            accrual = [t for t in txs if t['kind'] == ('education_interest_due' if is_education else 'bank_interest_due') and t['source_id'] == source and t['due_month'] == bill['month']]
            check(len(accrual) == 1 and accrual[0]['cycle'] == bill['due_cycle'] and accrual[0]['amount_cents'] == due['interest_cents'] and accrual[0]['cash_delta_cents'] == 0, 'once-only original interest accrual')
        payoffs = [t for t in txs if t['kind'] == ('education_payoff' if is_education else 'bank_payoff') and t['source_id'] == source]
        check(len(payoffs) <= 1 and all(t['cash_delta_cents'] == -t['amount_cents'] for t in payoffs), 'single residual-principal payoff')
        principal_paid = sum(b['principal_paid_cents'] for b in issued) + sum(t['amount_cents'] for t in payoffs)
        check(account['principal_paid_cents'] == principal_paid and account['interest_paid_cents'] == sum(b['interest_paid_cents'] for b in issued), 'account and original bills reconcile')
        check(0 <= principal_paid <= account['schedule']['principal_cents'] and account['closed'] == (principal_paid == account['schedule']['principal_cents']), 'debt exact principal closure')
        if is_education:
            check(source == account['run_id'] + ':education' and account['schema_version'] == 1, 'education ownership and schema')
            check(not any(t['kind'] == 'financing_in' and t['source_id'] == source for t in txs), 'education principal never paid as funding')
    audit_action_order(f)
    audit_credit(f)


def audit_action_order(f):
    """Replay only cash allocation across real original bills, independently."""
    groups = []
    for tx in f['transactions'][1:]:
        if tx['kind'] in DIRECT: groups.append([])
        check(bool(groups), 'all generated transactions belong to an action')
        groups[-1].append(tx)
    check(len(groups) == len(f['actions']), 'one direct transaction per atomic action')
    outstanding = {}
    principal_paid = defaultdict(int)
    for index, (action, group) in enumerate(zip(f['actions'], groups)):
        opening = group[0]
        month = (action['cycle'] - 1) // 2 + 1 if action['productive'] else action['cycle'] // 2 + 1
        check((opening['kind'], opening['cycle'], opening['month'], opening['cash_before_cents'], opening['cash_delta_cents'], opening['source_id']) ==
              (action['kind'], action['cycle'], month, action['cash_before'], action['direct_delta'], action['source_id']), 'direct atomic action provenance')
        operation = action.get('operation', {}).get('type', '')
        old_blocking = sum(b['remaining'] for b in outstanding.values() if b['bill']['expense_type'] != 'student_loan')
        if action['productive']:
            for bill in f['obligations']:
                if bill['due_cycle'] == action['cycle']:
                    check(bill['bill_id'] not in outstanding, 'original bill issued once')
                    outstanding[bill['bill_id']] = {'bill': bill, 'remaining': bill['due_cents'], 'interest': 0}
        available = action['cash_before'] + action['direct_delta'] + action['settled']
        q = action.get('operation', {})
        if operation in {'education_payoff', 'payoff'}:
            is_education = operation == 'education_payoff'
            account = f['education'] if is_education else next(x for x in f['bank_loans'] if x['loan_id'] == q['loan_id'])
            source = account['account_id'] if is_education else account['loan_id']
            principal = account['schedule']['principal_cents'] - principal_paid[source]
            interest = sum(s['bill']['interest_cents'] - s['interest'] for s in outstanding.values()
                           if s['bill']['source_id'] == source)
            other = sum(s['remaining'] for s in outstanding.values() if s['bill']['expense_type'] != 'student_loan') if is_education else sum(s['remaining'] for s in outstanding.values() if s['bill']['expense_type'] in {'rent', 'payroll'})
            check((q['principal_cents'], q['interest_cents'], q['total_cents']) == (principal, interest, principal + interest), 'payoff excludes future interest and avoids double-counted arrears')
            check(available >= principal + interest + other, 'payoff fully covers current required cash')
            if is_education:
                check((q['other_due_cents'], q['required_cash_cents']) == (other, other + principal + interest), 'education payoff reserves only due noneducation balances')
        order = [b for b in outstanding.values() if b['remaining'] and not (operation == 'payoff' and b['bill']['expense_type'] == 'student_loan')]
        def key(b):
            bill = b['bill']; category = bill['expense_type']
            rank = {'rent': 0, 'payroll': 1, 'bank_installment': 2, 'student_loan': 3 if operation == 'education_payoff' else 2}[category]
            return rank, bill['due_cycle'], category != 'bank_installment', bill['bill_id']
        expected = []
        for state in sorted(order, key=key):
            bill = state['bill']; payment = min(available, state['remaining'])
            state['remaining'] -= payment
            available -= payment
            if payment:
                expected.append((PAYMENT[bill['expense_type']], bill['source_id'] if bill['expense_type'] != 'rent' else '', bill['month'], payment))
                if bill['expense_type'] in DEBT:
                    interest = min(payment, bill['interest_cents'] - state['interest'])
                    state['interest'] += interest
                    principal_paid[bill['source_id']] += payment - interest
        actual = [(t['kind'], t['source_id'], t['due_month'], t['amount_cents']) for t in group if t['kind'] in PAYMENT.values()]
        check(actual == expected, 'ordinary mixed due order / elective payoff order and exact cash allocations')
        if action['productive'] and old_blocking:
            check(not any(s['remaining'] for s in outstanding.values() if s['bill']['expense_type'] != 'student_loan'), 'existing production recovery gate clears actual blocking debts')
        if operation in {'education_payoff', 'payoff'}:
            is_education = operation == 'education_payoff'
            account = f['education'] if is_education else next(x for x in f['bank_loans'] if x['loan_id'] == q['loan_id'])
            source = account['account_id'] if is_education else account['loan_id']
            residual = account['schedule']['principal_cents'] - principal_paid[source]
            actual_payoff = [t for t in group if t['kind'] == ('education_payoff' if is_education else 'bank_payoff')]
            check(len(actual_payoff) == 1 and actual_payoff[0]['amount_cents'] == residual, 'payoff collects future residual principal once')
            check(q['revision'] == index and not action['productive'] and action['direct_delta'] == 0, 'passive payoff bound to atomic revision')
            available -= residual
            principal_paid[source] += residual
        check(available == group[-1]['cash_after_cents'], 'atomic action closes with exact allocated cash')
    check(all(s['remaining'] == s['bill']['unpaid_cents'] for s in outstanding.values()), 'all replayed unpaid balances match final bills')


def audit_credit(f):
    score = 600
    for number, row in enumerate(f['credit']['history'], 1):
        cycle = number * 2
        factors = {}
        for b in f['obligations']:
            if b['due_cycle'] > cycle or not b['late']: continue
            if b['unpaid_cents'] == 0 and b['settled_cycle'] <= cycle - 2: continue
            evaluated = cycle if b['unpaid_cents'] else min(cycle, b['settled_cycle'])
            points = WEIGHTS[b['expense_type']][min((evaluated - b['due_cycle']) // 2, 2)]
            factors[b['expense_type']] = max(factors.get(b['expense_type'], 0), points)
        profit = f['monthly_rows'][number - 1]['net_profit_cents']
        change = -sum(factors.values()) if factors else (3 if profit > 0 else 0)
        after = min(850, max(300, score + change))
        check((row['month'], row['cycle'], row['before'], row['requested_change'], row['after'], row['change'], row['operating_profit_cents']) ==
              (number, cycle, score, change, after, after - score, profit), 'independent original-due credit and recovery period')
        score = after
    check(f['credit']['score'] == score and f['credit']['last_processed_month'] == f['last_cycle'] // 2 == len(f['credit']['history']), 'credit exactly once per completed month')


def audit_vector(vector):
    """Explicit private-plan vectors: validate only the isolated transition.

    These deliberately override cash without a journal receipt. They are not
    valid RunState ledgers, legal income, native routes, or restart evidence.
    """
    check(vector.get('isolated_payment_plan') is True, 'private-vector scope is explicit')
    before, after, quote = vector['before'], vector['after'], vector['quote']
    check(before['last_cycle'] == after['last_cycle'] and before['credit'] == after['credit'], 'isolated payoff is zero-cycle with no credit bonus')
    check(after['actions'][:-1] == before['actions'] and after['actions'][-1]['operation'] == quote, 'one isolated payoff operation')
    delta = after['transactions'][len(before['transactions']):]
    check(after['transactions'][:len(before['transactions'])] == before['transactions'], 'isolated prior journal preserved')
    education = quote['type'] == 'education_payoff'
    account = before['education'] if education else next(x for x in before['bank_loans'] if x['loan_id'] == quote['loan_id'])
    source = account['account_id'] if education else account['loan_id']
    principal = account['schedule']['principal_cents'] - account['principal_paid_cents']
    interest = sum(b['interest_cents'] - b['interest_paid_cents'] for b in before['obligations'] if b['source_id'] == source)
    other = sum(b['unpaid_cents'] for b in before['obligations'] if b['expense_type'] != 'student_loan') if education else sum(b['unpaid_cents'] for b in before['obligations'] if b['expense_type'] in {'rent', 'payroll'})
    check((quote['principal_cents'], quote['interest_cents'], quote['total_cents']) == (principal, interest, principal + interest), 'isolated payoff independent amount')
    if education:
        check((quote['other_due_cents'], quote['required_cash_cents']) == (other, other + principal + interest), 'isolated education reserve includes every due noneducation bill once')
    check(before['cash_cents'] >= other + principal + interest and before['cash_cents'] - after['cash_cents'] == other + principal + interest, 'isolated payoff exact total cash')
    expected = []
    selected = [b for b in before['obligations'] if b['unpaid_cents'] and (education or b['expense_type'] != 'student_loan')]
    for bill in sorted(selected, key=lambda b: ({'rent': 0, 'payroll': 1, 'bank_installment': 2, 'student_loan': 3}[b['expense_type']], b['due_cycle'], b['bill_id'])):
        expected.append((PAYMENT[bill['expense_type']], bill['source_id'] if bill['expense_type'] != 'rent' else '', bill['month'], bill['unpaid_cents']))
    actual = [(t['kind'], t['source_id'], t['due_month'], t['amount_cents']) for t in delta if t['kind'] in PAYMENT.values()]
    check(actual == expected, 'isolated elective precedence is distinct from ordinary monthly order')
    for old, new in zip(before['obligations'], after['obligations']):
        check(old['bill_id'] == new['bill_id'] and old['due_cycle'] == new['due_cycle'] and old['month'] == new['month'] and old['late'] == new['late'], 'isolated original bill identity and prior late history preserved')
        if old['expense_type'] == 'student_loan' and not education:
            check(old == new, 'existing Bank payoff does not service education')
        else:
            check(new['unpaid_cents'] == 0 and new['paid_cents'] == new['due_cents'], 'included due bills are fully serviced')
    check((after['education']['closed'] if education else next(x for x in after['bank_loans'] if x['loan_id'] == source)['closed']), 'isolated target account closes')


def audit_command(path):
    record = read(path)
    label = Path(path).name.removesuffix('.command.json')
    check(record['exit'] == 0 and not record['errors'], 'accepted native process succeeds')
    check(record['source_unchanged'] and record['driver_unchanged'] and not record['changed_source_paths'], 'native source and runner remained unchanged')
    before = HERE / (label + '.source-before.json')
    after = HERE / (label + '.source-after.json')
    check(sha(before) == record['source_before_sha256'] and sha(after) == record['source_after_sha256'], 'source manifest hashes')
    manifest = read(before)
    check(manifest == read(after) and len(manifest) == record['source_files'], 'complete pre/post source identity')
    check(all(sha(ROOT / name) == digest for name, digest in manifest.items()), 'accepted sources match current reviewed files')
    check(sha(HERE / 'run.py') == record['driver_sha256'], 'accepted native runner identity')
    log = HERE / (label + '.log')
    check(sha(log) == record['log_sha256'], 'native log hash')
    errors = [line for line in log.read_text(encoding='utf8').splitlines()
              if re.search(r'SCRIPT ERROR:|\bERROR:|\bFAIL(?:ED|URE)?\b', line, re.I)
              and line.strip() != 'ERROR: Failed to read the root certificate store.']
    check(not errors, 'only exact known certificate diagnostic is exempt')
    check(bool(record.get('outputs')), 'accepted native process produced captured output')
    for name, digest in record['outputs'].items():
        check(sha(HERE / name) == digest, 'native captured output hash')
    # The runner records this when a named output is expected; no stale reuse.
    freshness = record.get('output_fresh', record.get('outputs_fresh'))
    if isinstance(freshness, dict): freshness = bool(freshness) and all(freshness.values())
    check(freshness is True, 'expected native output was freshly written')
    return {'command_sha256': sha(path), 'source_manifest_sha256': sha(before), 'outputs': record['outputs']}


def ledgers_in(value):
    if isinstance(value, dict):
        if value.get('schema_version') == 6 and all(k in value for k in ['actions', 'transactions', 'education', 'monthly_rows']):
            yield value
        else:
            for child in value.values(): yield from ledgers_in(child)
    elif isinstance(value, list):
        for child in value: yield from ledgers_in(child)


def audit_e4(directory):
    """Actual old-schema bytes, new-schema cold restores, and negative copies."""
    global CONTEXT
    directory = Path(directory)
    old = directory.parent / 'education-legacy-fixtures-v1'
    summary = read(directory / 'summary.json')
    source = read(directory / 'source-before.json')
    check(summary['passed'] and summary['processes'] == 16, 'declared seven restore pairs plus rejection/recovery processes')
    check(source == read(directory / 'source-after.json'), 'E4 frozen runtime and drivers')
    check(all(sha(ROOT / 'patch-notes' / p) == h for p, h in source['files'].items()), 'E4 runtime matches current reviewed source')
    check(all(sha(directory / p) == h for p, h in source['drivers'].items()), 'E4 driver hashes')
    check(sha(old / 'source-before.json') == source['old_source'], 'original fixture source identity')
    reports = {}
    for record in summary['records']:
        name = record['name']; CONTEXT = 'E4/' + name
        manifest = read(directory / (name + '.manifest.json'))
        check(manifest['source_sha256'] == sha(directory / 'source-before.json'), 'native E4 source binding')
        for ext, digest in manifest['artifacts'].items():
            check(sha(directory / (name + '.' + ext)) == digest, 'native E4 raw artifact hash')
        for kind in ['inputs', 'outputs']:
            for path, digest in manifest[kind].items(): check(sha(path) == digest, 'E4 preserved input/output bytes')
        before = read(directory / (name + '.before.json'))
        after = read(directory / (name + '.after.json'))
        command = read(directory / (name + '.command.json'))
        check(before['source'] == after == source and before['command'] == command['command'] and command['exit_code'] == 0, 'E4 exact command and source before/after')
        log = (directory / (name + '.log')).read_text(encoding='utf8')
        errors = [line for line in log.splitlines() if re.search(r'SCRIPT ERROR:|\bERROR:|\bFAIL(?:ED|URE)?\b|E4_ASSERT:', line, re.I) and line.strip() != 'ERROR: Failed to read the root certificate store.']
        check(not errors, 'no unclassified E4 runtime/assertion errors')
        report = read(directory / (name + '.result.json'))
        check(report['passed'] and not report['failures'] and report['checks'] == record['checks'], 'E4 native assertions passed')
        reports[name] = report
    fixtures = [f'v{v}-{t}' for v in (3, 4, 5) for t in ('college_dropout', 'graduate')] + ['v5-ordinary']
    def normalized(value):
        value = json.loads(json.dumps(value)); value['sequence'] = '1'; return value
    for name in fixtures:
        CONTEXT = 'E4/original/' + name
        manifest = read(old / (name + '.manifest.json'))
        for ext, digest in manifest['files'].items(): check(sha(old / (name + '.' + ext)) == digest, 'authentic prior fixture immutable')
        for ext, digest in source['fixtures'][name].items(): check(sha(old / (name + '.' + ext)) == digest, 'E4 input exactly authentic old fixture')
        original = read(old / (name + '.payload.json'))
        envelope = read(old / (name + '.checkpoint.json'))
        check(hashlib.sha256(envelope['payload_utf8'].encode()).hexdigest() == envelope['payload_sha256'] and json.loads(envelope['payload_utf8']) == original, 'original strict envelope checksum and payload')
        migrate, cold = reports[name + '-migrate'], reports[name + '-verify']
        capture = migrate['capture']; projection = normalized(capture)
        check(projection['run']['studio_finance'].pop('education') == {}, 'migration adds only empty education account')
        projection['run']['studio_finance']['schema_version'] = '5'
        projection['content_revision'] = original['content_revision']
        check(projection == normalized(original) == normalized(migrate['original']), 'every original field preserved under explicit schema projection')
        check(cold['capture'] == capture and normalized(migrate['stored']) == capture == normalized(cold['stored']), 'published and cold-loaded payloads exactly match')
        check(migrate['files_before']['checkpoint.1.json'] == sha(old / (name + '.checkpoint.json')) and migrate['files_after']['checkpoint.1.json'] == migrate['files_before']['checkpoint.1.json'], 'migration preserves original generation bytes')
        check(migrate['files_after'] == cold['files_before'] == cold['files_after'], 'cold Continue has no save side effects')
        traits = capture['run']['studio_traits']
        check(traits['version'] == name[1] and traits['refunded_points'] == '0' and traits['point_cash_cents'] == '20000' and capture['run']['cash_cents'] == '570000', 'inactive preview keeps original version and point funding')
        check(not any(t in traits['active_ids'] for t in ['college_dropout', 'graduate']), 'prior education IDs never become active')
        check(cold['component_fixture'] and cold['synthetic_income_per_even_cycle_cents'] == 50000, 'detached component funding is explicitly synthetic')
        check(set(cold['component_boundaries']) == {'24', '26', '28'}, 'declared grace/first/second due component boundaries')
        for cycle, ledger in cold['component_boundaries'].items():
            CONTEXT = 'E4/detached/' + name + '/' + cycle
            audit_ledger(ledger)
            check(ledger['last_cycle'] == int(cycle) and not ledger['education'] and ledger['cash_cents'] == 570000, 'detached old preview still has no debt or extra funding')
            check(not any(b['expense_type'] == 'student_loan' for b in ledger['obligations']), 'no retroactive education bills')
            receipts = [a for a in ledger['actions'] if a['source_id'] == 'studio_trait_unspent_points_v1']
            check(len(receipts) == 1 and receipts[0]['direct_delta'] == 20000 and receipts[0]['cycle'] == 0, 'no retroactive point receipt')
    negative = reports['rejections']['records']; recovered = reports['recovery-cold']['records']
    check(set(negative) == set(recovered) == {'unsupported_revision', 'checksum', 'numeric_cash', 'extra_education', 'old_version6', 'cash_discontinuity', 'retroactive_refund'}, 'exact seven negative-copy controls')
    for name, row in negative.items():
        CONTEXT = 'E4/rejection/' + name
        check(row['classification'] == ('incompatible' if name == 'unsupported_revision' else 'invalid') and bool(row['reason']), 'invalid versus unsupported classification')
        check(all(row['rejected_directory_after'][p] == digest for p, digest in row['before'].items()), 'all rejected input bytes retained')
        if name == 'unsupported_revision': check(row['before'] == row['rejected_directory_after'], 'unsupported saves never overwritten by backup recovery')
        else: check('checkpoint.3.json' in row['rejected_directory_after'], 'invalid-copy explicit recovery produced generation3')
        check(row['capture'] == recovered[name]['capture'] and row['recovery_files'] == recovered[name]['files'], 'recovery survives fresh process without mutation')
    return dict(processes=16, authentic_fixtures=7, negative_copies=7, detached_component_boundaries=21,
                source_manifest_sha256=sha(directory / 'source-before.json'), summary_sha256=sha(directory / 'summary.json'))


def main():
    global CONTEXT
    parser = argparse.ArgumentParser()
    parser.add_argument('--focused', type=Path, default=HERE / 'focused-cases.json')
    parser.add_argument('--output', type=Path, default=HERE / 'audit-focused.json')
    parser.add_argument('--edges', type=Path)
    parser.add_argument('--native', type=Path)
    parser.add_argument('--command', type=Path, action='append', default=[])
    parser.add_argument('--e4', type=Path)
    args = parser.parse_args()
    data = read(args.focused)
    check(data['failures'] == 0, 'accepted focused output has no native failures')
    lines = audit_schedule(data.get('schedules'))
    summaries = []
    for name, finance in data['cases'].items():
        CONTEXT = name
        audit_ledger(finance)
        summaries.append(dict(case=name, cycle=finance['last_cycle'], cash_cents=finance['cash_cents'],
                              issued=finance['education'].get('issued', 0), closed=finance['education'].get('closed', False)))
    inputs = {str(args.focused): sha(args.focused)}
    vectors = 0
    if args.edges:
        edge = read(args.edges)
        check(edge['failures'] == 0, 'accepted edge output has no native failures')
        inputs[str(args.edges)] = sha(args.edges)
        for name, finance in edge['cases'].items():
            CONTEXT = 'edges/' + name
            audit_ledger(finance)
            summaries.append(dict(case=CONTEXT, cycle=finance['last_cycle'], cash_cents=finance['cash_cents'], issued=finance['education'].get('issued', 0), closed=finance['education'].get('closed', False)))
        for name, vector in edge.get('ordering_vectors', {}).items():
            CONTEXT = 'private-vector/' + name
            audit_vector(vector)
            vectors += 1
    native_ledgers = 0
    if args.native:
        inputs[str(args.native)] = sha(args.native)
        seen = set()
        for ledger in ledgers_in(read(args.native)):
            identity = hashlib.sha256(json.dumps(ledger, sort_keys=True).encode()).hexdigest()
            if identity in seen: continue
            seen.add(identity)
            CONTEXT = 'native-ledger/' + str(native_ledgers)
            audit_ledger(ledger)
            native_ledgers += 1
    bindings = {}
    for command in args.command:
        CONTEXT = 'provenance/' + command.name
        bindings[command.name] = audit_command(command)
    compatibility = audit_e4(args.e4) if args.e4 else {}
    result = dict(passed=True, checks=CHECKS, scope='constructed accounting fixtures; not player balance evidence',
                  approved_schedule_lines=lines, native_schedule_lines=192 if 'schedules' in data else 0,
                  cases=len(summaries), isolated_private_vectors=vectors, native_ledgers=native_ledgers,
                  input_sha256=sha(args.focused), input_files=inputs, auditor_sha256=sha(__file__), provenance=bindings, legacy_compatibility=compatibility,
                  approved_reference_sha256=sha(APPROVED), summaries=summaries,
                  limits=['Native source provenance and separate-process/legacy acceptance require their companion audit; this result alone does not establish them.'])
    args.output.write_text(json.dumps(result, indent=2), encoding='utf8')
    print(json.dumps({k: v for k, v in result.items() if k not in ['summaries', 'limits']}, indent=2))


if __name__ == '__main__':
    main()
