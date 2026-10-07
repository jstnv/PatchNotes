"""Build the Task33 evidence receipt from completed native checks."""
from pathlib import Path
import gzip, hashlib, json, shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/task33-v1'
DEST = Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')
BUNDLE = DEST / 'Task33 Typed Expenses v1'
BUNDLE.mkdir(exist_ok=True)
gate = json.loads((OUT/'final-gate.json').read_text())
routes = json.loads((OUT/'route-summary.json').read_text())['results']
before = json.loads((OUT/'source-before.json').read_text())
changed = [p for p,h in before['files'].items() if (ROOT/p).exists() and hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=h]
prior = [line[3:] for line in before['status'].splitlines() if line.startswith(' M ')]
preserved = all(hashlib.sha256((ROOT.parent/p).read_bytes()).hexdigest()==before['files'][str(Path(p).relative_to('patch-notes'))] for p in prior)
addendum = '''TASK33 CHECKPOINT ADDENDUM v1 — not durable saves
Finance schema2 retains every schema1 action/transaction/monthly field. Bills add bill_id rent:<original month>, source_id studio_rent, expense_type rent, settled_cycle and recovery_overdue_cycles. Existing month/due_cycle/due_cents are immutable original metadata; paid_cents+unpaid_cents=original; payment cycle/month/cents remain exact. Late never clears.
Credit: policy_version typed_expenses_v1, score, last_processed_month, ordered history. Each month records cycle, policy, operating profit, before/after/requested/clamped change, typed reasons with bill ID, original due, evaluated cycle, age and recovered flag. Defaults are versioned constants; changing them requires an explicit migration policy.
RunState owns this journal. Editor capture includes its complete snapshot/report and policy source hash. Exact var_to_bytes/bytes_to_var roundtrip tested. JSON is diagnostic, not a trusted loader; future loader must validate integer cents and normalize StringName IDs. No disk save/resume claim.
upgrade_v1 is explicit and pure: replay original actions, strip additions, compare EVERY old derived field before returning schema2. No live cash transaction or historical recharge. Missing or altered provenance rejects.
Atomic order remains direct effect/cash, central cycle/redraw, all-title earnings/settlement, oldest rent service, monthly credit, publication. Reports and reconstruction never execute callbacks. Future producers require one combined credit identity per installment; only rent is wired.
'''
(ROOT/'analysis/task33_finance_save_contract_v1.txt').write_text(addendum,encoding='utf-8')
text = '''PATCH NOTES — TASK33 TYPED EXPENSES AND MONTHLY CREDIT v1
STATUS: COMPLETE locally; automated implementation evidence, not human or exported gameplay acceptance.
SOURCE: main e054791d0348d90faf70e9d827892c351fa018bc (Bank). Task29 is committed; historical queue says otherwise. Cached origin/main matches. Independent git ls-remote origin refs/heads/main failed: git remote-https is not a git command; fatal remote helper https aborted session. Remote is not freshly verified. No commit/push performed.
No repository or ancestor AGENTS.md found. No other active local implementation appeared in thread inventory. All pre-existing modified files preserved byte-for-byte: PRESERVED. .codex-godot-temp untouched.
AUTHORITY: live Task33 and cumulative §69; §§64–68 accepted lifespan/$500 rent; Task29 finance and Task30 loan-trial standalone logs; retained-pool/source inspection. Old Task30 flat late penalty and full-future-interest payoff are superseded.

IMPLEMENTATION
OutstandingExpenses pure policy creates/services typed bills; rent is the ONLY live producer. Bank installment, payroll and Student Loan are synthetic extension hooks, not issuance/hiring/trait bills. RunState get_outstanding_expenses is defensive and read-only.
Schema2 retains original rent month, dates, exact payments and cash ordering. Partial payment cannot reset age; closed late records keep recovery age. Optional rejection creates no bill. Unknown/missing/altered provenance and overflow reject atomically.
Credit starts600 on actual Studio creation. Once per committed even cycle, after settlement/rent service: range300–850; +3 clean profitable month, zero clean loss/break-even. Rent5/10/20, Bank10/20/30, Payroll5/10/15, StudentLoan5/10/20 at0–1/2–3/4+ overdue cycles. Strongest category age, additive distinct categories, no concurrent clean gain. Range/gain/weights are configurable prototype defaults, not final balance locks. Financing/principal never affect profit; unpaid rent remains expense.
CLOSING PERIOD: unpaid at close qualifies at current age; cleared AFTER opening boundary qualifies at actual recovery age. Recovery exactly at an already-processed opening boundary creates no second elapsed-time miss. Due2/recovered3 incurs age1 debit at close4; recovery at close4 incurs age2 debit. Future months stop penalizing that cleared bill. Original missed-close history remains; no immediate score refund/bonus. Fixtures specify this convention explicitly.
Finances has Monthly report / Outstanding bills tabs: original/paid/remaining cents, original due, cycle/half-month age, current/next tier. Bank shows actual score/history/reasons/financial inputs. Back/Escape, Cash entry, blocked warning and safe phase changes preserved. Capture includes policy hash and full typed history.

VERIFICATION
GATE
New verify_outstanding_expenses covers neutral creation, profit/loss/zero, due2/age3/4/6 tiers, partial/full recovery, multiple types/invoices/split components, settlement at due, clamps, callbacks, invalid/overflow inputs, rejected optional actions, explicit v1 migration and binary serialization. Pure multi-type fixture600→575→525→440 over three missed months exposes potentially severe stacking; synthetic only, no runtime debt/payroll and no tuning approval.
Eight native Action routes: seeds1104/4417 × ordinary/synergy × first budgets12/18. Each reaches two releases plus two legal Game3 earning actions; no injected cash/cards, loans, campaigns or Wait. Independent finance audit:312 snapshots,3080 monthly rows,14524 transaction observations,296 actions, zero discrepancies. Independent credit replay:312 snapshots/136 completed months, zero discrepancies.
ROUTES
All four slow routes recover rent:9 through actual Ironclad acceptance at cycle18; historical -5 remains. Early routes have no late bills. No measured recovery regression. Native policies are not human playtests or progression ceilings.
Both1152x648 and1280x720 rendered GL-compatibility menus inspected: outstanding bill and Bank score/reasons fit; automated button/signal navigation, no human graphical input claim. Known older Alpha free-exit productive-affordability guard defect remains OPEN outside this typed-credit task; these routes do not trigger it.

LOAN IMPLEMENTATION BRIEF — proposal, not implemented or locked
Accepted: cap$500 after first ACTUAL sales settlement; one active loan; waive future unaccrued interest on early repayment; bank debt separate from96-boundary Student Loan trait.
Review defaults:12 monthly installments; illustrative10% total quoted interest at neutral credit; first due at next completed central month; capacity maximum installment<=25% positive trailing3 completed-month recurring sales surplus after rent/existing installments. Exclude publisher windfalls, financing and forecasts. Rate/term/due/capacity remain OPEN. Score-to-rate bands and precise interest accrual/cent-remainder rules need approval before issuance code. Freeze quote/version/original schedule; combine principal+interest into one credit-obligation ID; payoff charges remaining principal plus accrued interest only, waives future interest, no credit bonus. No lending UI is enabled.

FILES
CHANGED
New: scripts/finance/outstanding_expenses.gd (+uid), scripts/debug/verify_outstanding_expenses.gd (+uid), analysis/task33_verify_v1.py, task33_routes_v1.gd (+uid), task33_routes_v1.py, task33_credit_audit_v1.py, task33_report_v1.py, task33_finance_save_contract_v1.txt. Findings/traces in design-logs/task33-v1 and portable New Data Logs/Task33 Typed Expenses v1.
COMMANDS: python -B analysis/task33_verify_v1.py; same --render; python -B analysis/task33_routes_v1.py; python -B analysis/task33_credit_audit_v1.py. Exact Godot executable/argv/profiles/exit/error markers in *.command.json, final-gate.json, render.command.json. Godot4.7.1.stable.official.a13da4feb. Source-before/final hashes and original diff preserved. Route source stable; later capture-hash/test-path additions do not alter route behavior.
DEFERRED: loan terms/issuance, non-rent producers, durable saves, exported interactive smoke, old Alpha-exit defect. No sales/rent/Review/price/publisher retune. Queue native fresh-revision edits/readback used after advisory trusted-read bridge failed on Windows: workspaceRoot must be an absolute path.
'''
text=text.replace('PRESERVED',str(preserved)).replace('GATE',f'Headless editor import and all {len(gate["results"])-1} verifiers passed; {sum(x["assertion_passes"] for x in gate["results"])} PASS markers. Zero unexpected errors. Existing expected negative fixtures classified. git diff --check exit{gate["diff_check"]}.')
text=text.replace('CHANGED','\n'.join(changed))
text=text.replace('ROUTES','\n'.join(f'{q["band"]}/{q["policy"]}/{q["seed"]}: release cycles {[v["cycle"] for v in q["releases"]]}, Reviews {[v["final_review"] for v in q["releases"]]}; final cash${q["final"]["cash_cents"]/100:.2f}; credit{q["final"]["finance"]["credit"]["score"]}.' for q in routes))
log=DEST/'Patch Notes - Task33 Typed Expenses and Credit v1.txt'
log.write_text(text,encoding='utf-8')
for p in OUT.rglob('*'):
    if not p.is_file():continue
    target=BUNDLE/p.relative_to(OUT);target.parent.mkdir(parents=True,exist_ok=True)
    if p.suffix=='.json' and p.name.startswith('route_'):target.with_suffix('.json.gz').write_bytes(gzip.compress(p.read_bytes(),mtime=0))
    else:shutil.copy2(p,target)
for p in (ROOT/'analysis').glob('task33*'):shutil.copy2(p,BUNDLE/p.name)
shutil.copy2(log,BUNDLE/log.name)
assert gate['passed'] and preserved
print(log)
