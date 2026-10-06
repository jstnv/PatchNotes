"""Candidate-only credit/loan trial over exact Task29 native action journals.

Run: python -B analysis/task30_credit_trial_v1.py
No gameplay files are modified. Fixed-route overlays stop at the first action
that becomes illegal; they do not advance free time or fabricate better Reviews.
"""
from __future__ import annotations

import copy
import hashlib
import json
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs/task30-v1"
MAX = 2**63 - 1
TERM = 12
FIELDS = ("opening_cash_cents closing_cash_cents sales_net_earned_cents sales_settled_cents "
          "other_income_cents publisher_income_cents beta_income_cents miscellaneous_income_cents "
          "feature_play_cents store_cents campaign_cents playtest_cents other_expense_cents "
          "rent_due_cents rent_paid_cents rent_unpaid_cents operating_revenue_cents operating_expenses_cents "
          "financing_in_cents principal_paid_cents interest_cents").split()
EXPENSE = {kind: kind + "_cents" for kind in
           ("feature_play", "store", "campaign", "playtest", "other_expense", "principal_paid", "interest")}
INCOME = {"publisher_receipt": "publisher_income_cents", "beta_income": "beta_income_cents",
          "other_income": "miscellaneous_income_cents"}
OPERATING_COSTS = ["feature_play_cents", "store_cents", "campaign_cents", "playtest_cents", "other_expense_cents"]

DECLARATION = {
    "status": "UNAPPROVED CANDIDATE; read-only analysis, no gameplay lending",
    "baseline": "Verified local Task29 $5500 funding/$500 rent and accepted lifespan coefficients",
    "seeds": [1104, 4417], "policies": ["ordinary", "synergy"], "native_first_release_cycles": [12, 18],
    "overlay_horizon": "Exact available Task29 action journal (two releases plus Game3 earning follow-up), or first counterfactual-invalid action",
    "arms": ["none", "startup_500", "startup_1000", "startup_1500", "post_sales_500", "post_sales_1000", "post_sales_1500"],
    "optional": "Single-factor $450/$550 rent or initial score550/650; no background point price; matched none/startup1000 arms",
    "wall_limit_seconds": 300,
    "score": {"initial": 600, "minimum": 300, "maximum": 850,
              "trailing_months": 3, "flow_unit_cents": 25000,
              "flow": "clamp(trunc(sum(adjusted operating CASH flow)/(n*25000)),-5,+5); use last up to3 completed months",
              "adjusted_operating_cash": "settled sales minus Feature play, Store, campaign, playtest, other operating expenses, PAID rent and interest; excludes all publisher/Beta/misc/funding receipts and loan principal",
              "payment": "+3 for all rent and loan installments paid by original due boundary, otherwise -20; one factor per calendar month regardless of loan count",
              "combined_monthly_cap": [-25, 8], "missing_history": "neutral0; no synthetic months",
              "recovery": "late flag retained; clearing arrears/early payoff grants no immediate score; later actual on-time months can earn normal bounded gain"},
    "tiers_total_interest_percent": {"300-599": 20, "600-699": 10, "700-799": 7, "800-850": 5},
    "schedule": "12 calendar-month installments: floor(principal/12), floor(floor(principal*rate/100)/12); installment12 carries both remainders",
    "first_due": "2*(origination_cycle//2+1), the end of the current calendar month; NOT a grace month or next-full-month promise",
    "payment_order": "native rent first; then oldest due bank installment, interest before principal; partial payments retain arrears",
    "startup": "One candidate exception at cycle0 before production/release, capped at arm amount; bypasses neutral empty-history capacity0; permanent used flag survives payoff",
    "regular": "After first actual sales settlement, no current arrears, at most one active loan, requested arm cap must fit capacity including maximum/final installment",
    "capacity": "max(0, floor(max(0,sum(last<=3 completed months sales NET EARNED-rent DUE))/(4*n)) - sum(existing maximum monthly installments)); no history0",
    "capacity_exclusions": "No publisher/Beta/funding/borrowing/forecast income; excludes one-off Store and Feature play costs to isolate recurring surplus, which may overstate practical affordability",
    "quote": "Zero-cycle, no application fee; exact principal, fixed rate/schedule and state revision; stale/conflicting/repeated commits reject",
    "early_payoff": "Entire remaining principal PLUS contracted remaining interest; no rebate or penalty, no extra payment-history credit",
    "shortfall": "No negative cash. Rent then bank use available cash. Existing arrears block productive actions unless that actual action clears all overdue/new due rent and bank amounts. Zero-cycle launch/navigation and real receipts remain possible. No free Wait/bailout.",
}


def clamp(x, lo, hi):
    return max(lo, min(hi, x))


def trunc_div(n: int, d: int) -> int:
    return n // d if n >= 0 else -((-n) // d)


def rate_for(score: int) -> int:
    return 20 if score < 600 else 10 if score < 700 else 7 if score < 800 else 5


def schedule(principal: int, score: int, cycle: int) -> dict:
    if type(principal) is not int or not 0 < principal <= MAX or not 300 <= score <= 850 or cycle < 0:
        raise ValueError("invalid quote inputs")
    interest = principal * rate_for(score) // 100
    if principal + interest > MAX:
        raise ValueError("contract balance overflow")
    first_due = 2 * (cycle // 2 + 1)
    if first_due + 22 > MAX:
        raise ValueError("schedule cycle overflow")
    pp, ip = principal // TERM, interest // TERM
    installments = []
    for i in range(TERM):
        p = pp if i < 11 else principal - pp * 11
        r = ip if i < 11 else interest - ip * 11
        installments.append({"number": i+1, "due_cycle": first_due+2*i,
                             "principal_cents": p, "interest_cents": r,
                             "paid_principal_cents": 0, "paid_interest_cents": 0, "late": False})
    return {"principal_cents": principal, "interest_cents": interest, "total_cents": principal+interest,
            "score_at_quote": score, "rate_percent": rate_for(score), "term_months": TERM,
            "first_due_cycle": first_due, "monthly_principal_cents": pp, "monthly_interest_cents": ip,
            "monthly_payment_cents": pp+ip, "maximum_payment_cents": max(x["principal_cents"]+x["interest_cents"] for x in installments),
            "installments": installments}


def new_row(month, opening):
    row = {k: 0 for k in FIELDS}
    row.update(month=month, partial=True, opening_cash_cents=opening, closing_cash_cents=opening,
               cash_change_cents=0, net_profit_cents=0)
    return row


class Trial:
    def __init__(self, initial=550000, rent=50000, score=600):
        self.cash, self.cycle, self.rent, self.score = initial, 0, rent, score
        self.rows = {1: new_row(1, 0)}
        self.rows[1].update(financing_in_cents=initial, closing_cash_cents=initial, cash_change_cents=initial)
        self.rent_obligations = []
        self.loans = []
        self.startup_used = False
        self.revision = 0
        self.total_settled = 0
        self.unsettled = 0
        self.credit_events = []
        self.trace = []

    def unpaid_rent(self):
        return sum(x["due"]-x["paid"] for x in self.rent_obligations)

    def bank_due(self, cycle=None):
        cycle = self.cycle if cycle is None else cycle
        return sum(x["principal_cents"]+x["interest_cents"]-x["paid_principal_cents"]-x["paid_interest_cents"]
                   for loan in self.loans for x in loan["installments"] if x["due_cycle"] <= cycle)

    def remaining_principal(self):
        return sum(x["principal_cents"]-x["paid_principal_cents"] for l in self.loans for x in l["installments"])

    def remaining_interest(self):
        return sum(x["interest_cents"]-x["paid_interest_cents"] for l in self.loans for x in l["installments"])

    def active_payment(self):
        return sum(l["maximum_payment_cents"] for l in self.loans
                   if any(x["principal_cents"] != x["paid_principal_cents"] or x["interest_cents"] != x["paid_interest_cents"] for x in l["installments"]))

    def capacity(self):
        rows = [self.rows[m] for m in sorted(self.rows) if 2*m <= self.cycle][-3:]
        surplus = sum(r["sales_net_earned_cents"]-r["rent_due_cents"] for r in rows)
        gross = max(0, surplus) // (4*len(rows)) if rows else 0
        return {"months": len(rows), "trailing_recurring_surplus_sum_cents": surplus,
                "gross_capacity_cents": gross, "existing_payment_cents": self.active_payment(),
                "available_capacity_cents": max(0, gross-self.active_payment())}

    def quote(self, principal, startup_cap=0):
        try:
            q = schedule(principal, self.score, self.cycle)
        except ValueError as e:
            return {"eligible": False, "reason": str(e)}
        cap = self.capacity()
        reason = ""
        if self.unpaid_rent() or self.bank_due(): reason = "existing arrears"
        elif self.remaining_principal() or self.remaining_interest(): reason = "one active loan limit"
        elif startup_cap:
            if self.startup_used or self.cycle != 0: reason = "startup window used or closed"
            elif principal > startup_cap: reason = "startup cap exceeded"
        elif self.total_settled == 0: reason = "no actual sales settlement"
        elif q["maximum_payment_cents"] > cap["available_capacity_cents"]: reason = "installment exceeds recurring capacity"
        if principal > MAX-self.cash: reason = "cash overflow"
        q.update(eligible=not reason, reason=reason, capacity=cap, revision=self.revision,
                 origination_cycle=self.cycle, startup_cap_cents=startup_cap)
        q["quote_id"] = hashlib.sha256(json.dumps(q, sort_keys=True).encode()).hexdigest()[:16]
        return q

    def accept(self, quote):
        if not quote.get("eligible") or quote != self.quote(quote["principal_cents"], quote["startup_cap_cents"]):
            return False
        month = self.cycle//2+1
        row = self.rows.setdefault(month, new_row(month, self.cash))
        self.cash += quote["principal_cents"]
        row["financing_in_cents"] += quote["principal_cents"]
        self.loans.append(copy.deepcopy(quote))
        if quote["startup_cap_cents"]: self.startup_used = True
        self.revision += 1
        self._totals(row)
        self.trace.append({"event": "loan_accept", "cycle": self.cycle, "quote": copy.deepcopy(quote), "cash_cents": self.cash})
        return True

    def early_payoff(self):
        p, interest = self.remaining_principal(), self.remaining_interest()
        if not p+interest or p+interest > self.cash or self.unpaid_rent(): return False
        row = self.rows.setdefault(self.cycle//2+1, new_row(self.cycle//2+1, self.cash))
        self.cash -= p+interest
        row["principal_paid_cents"] += p
        row["interest_cents"] += interest
        for loan in self.loans:
            for x in loan["installments"]:
                x["paid_principal_cents"], x["paid_interest_cents"] = x["principal_cents"], x["interest_cents"]
        self.revision += 1
        self._totals(row)
        self.trace.append({"event": "early_payoff", "cycle": self.cycle, "principal_cents": p, "interest_cents": interest, "cash_cents": self.cash})
        return True

    def _totals(self, row):
        row["operating_revenue_cents"] = row["sales_net_earned_cents"]+row["other_income_cents"]
        row["operating_expenses_cents"] = sum(row[k] for k in OPERATING_COSTS)+row["rent_due_cents"]+row["interest_cents"]
        row["net_profit_cents"] = row["operating_revenue_cents"]-row["operating_expenses_cents"]
        row["closing_cash_cents"] = self.cash
        row["cash_change_cents"] = self.cash-row["opening_cash_cents"]

    def _service(self, row):
        for x in self.rent_obligations:
            paid = min(self.cash, x["due"]-x["paid"])
            x["paid"] += paid
            self.cash -= paid
            row["rent_paid_cents"] += paid
            self.rows[x["month"]]["rent_unpaid_cents"] = x["due"]-x["paid"]
        for loan in self.loans:
            for x in loan["installments"]:
                if x["due_cycle"] > self.cycle: continue
                for key, field in (("interest", "interest_cents"), ("principal", "principal_paid_cents")):
                    paid = min(self.cash, x[key+"_cents"]-x["paid_"+key+"_cents"])
                    x["paid_"+key+"_cents"] += paid
                    row[field] += paid
                    self.cash -= paid

    def _credit_boundary(self, month):
        assert not any(e["month"] == month for e in self.credit_events)
        rows = [self.rows[m] for m in sorted(self.rows) if m <= month][-3:]
        flows = [r["sales_settled_cents"]-sum(r[k] for k in OPERATING_COSTS)-r["rent_paid_cents"]-r["interest_cents"] for r in rows]
        flow_delta = clamp(trunc_div(sum(flows), len(rows)*25000), -5, 5)
        late = bool(self.unpaid_rent() or self.bank_due())
        payment_delta = -20 if late else 3
        before = self.score
        self.score = clamp(before+clamp(flow_delta+payment_delta, -25, 8), 300, 850)
        self.credit_events.append({"month": month, "cycle": self.cycle, "score_before": before,
            "adjusted_cash_flows_cents": flows, "flow_factor": flow_delta, "payment_factor": payment_delta,
            "late": late, "score_after": self.score})

    def apply(self, action):
        """Atomic counterfactual replay of one recorded legal native action."""
        trial = copy.deepcopy(self)
        error = trial._apply(action)
        if error: return error
        self.__dict__.update(trial.__dict__)
        return ""

    def _apply(self, action):
        cycle, delta, productive = action["cycle"], action["direct_delta"], action["productive"]
        earned, settled, kind = action["sales_earned"], action["settled"], action["kind"]
        if cycle != self.cycle+int(productive): return "stale or skipped cycle"
        if delta < -self.cash: return "unaffordable direct action before settlement"
        if not productive and (earned or settled): return "passive earning/settlement"
        if not productive and delta < 0 and (self.unpaid_rent() or self.bank_due()): return "blocked external expense"
        cash_after = self.cash+delta+settled
        if not 0 <= self.cash+delta <= MAX or cash_after > MAX: return "intermediate cash overflow"
        if earned < 0 or settled < 0 or settled > self.unsettled+earned: return "invalid sales entitlement"
        due_rent = self.rent if productive and cycle%2 == 0 else 0
        if productive and (self.unpaid_rent() or self.bank_due()) and cash_after < self.unpaid_rent()+due_rent+self.bank_due(cycle):
            return "productive action cannot clear overdue rent/bank debt"
        cash_before = self.cash
        month = (cycle-1)//2+1 if productive else cycle//2+1
        row = self.rows.setdefault(month, new_row(month, self.cash))
        if delta < 0:
            if kind not in EXPENSE: return "unknown expense kind"
            row[EXPENSE[kind]] -= delta
        elif delta > 0:
            if kind == "financing_in": row["financing_in_cents"] += delta
            elif kind in INCOME:
                row["other_income_cents"] += delta
                row[INCOME[kind]] += delta
            else: return "unknown income kind"
        self.cycle, self.cash = cycle, cash_after
        self.total_settled += settled
        self.unsettled += earned-settled
        row["sales_net_earned_cents"] += earned
        row["sales_settled_cents"] += settled
        if due_rent:
            self.rent_obligations.append({"month": month, "due": due_rent, "paid": 0, "late": False})
            row["rent_due_cents"] += due_rent
        self._service(row)
        if productive and cycle%2 == 0:
            for x in self.rent_obligations:
                if x["paid"] < x["due"]: x["late"] = True
            for loan in self.loans:
                for x in loan["installments"]:
                    if x["due_cycle"] <= cycle and x["paid_principal_cents"]+x["paid_interest_cents"] < x["principal_cents"]+x["interest_cents"]: x["late"] = True
            self._credit_boundary(month)
        row["partial"] = not productive or cycle%2 != 0
        self._totals(row)
        self.revision += 1
        self.trace.append({"event": "recorded_action", "cycle": cycle, "kind": kind, "direct_delta_cents": delta,
            "sales_net_earned_cents": earned, "sales_settled_cents": settled, "cash_before_cents": cash_before, "cash_cents": self.cash,
            "rent_arrears_cents": self.unpaid_rent(), "bank_arrears_cents": self.bank_due(),
            "principal_remaining_cents": self.remaining_principal(), "interest_remaining_cents": self.remaining_interest(), "score": self.score})
        return ""

    def report(self):
        rows = copy.deepcopy(list(self.rows.values()))
        current = self.cycle//2+1
        if rows[-1]["month"] < current: rows.append(new_row(current, self.cash))
        for r in rows: r["partial"] = r["month"] == current
        return rows


def action(cycle, delta=0, kind="calendar", earned=0, settled=0, productive=True):
    return dict(cycle=cycle, direct_delta=delta, kind=kind, sales_earned=earned, settled=settled, productive=productive)


def unit_tests():
    checks = []
    def check(ok, label):
        checks.append({"case": label, "passed": bool(ok)})
        if not ok: raise AssertionError(label)
    for score in (300, 599, 600, 699, 700, 799, 800, 850):
        for principal in (1, 50000, 100000, 150000, 100001):
            q = schedule(principal, score, 1)
            check(sum(x["principal_cents"] for x in q["installments"]) == principal, f"principal exact {score}/{principal}")
            check(sum(x["interest_cents"] for x in q["installments"]) == principal*rate_for(score)//100, f"total interest exact {score}/{principal}")
            check(q["first_due_cycle"] == 2 and q["installments"][-1]["due_cycle"] == 24, f"12 scheduled dates {score}/{principal}")
    check([schedule(100000,600,c)["first_due_cycle"] for c in (0,1,2,3)] == [2,2,4,4], "origination before/after boundary")
    t = Trial()
    q = t.quote(100000,100000)
    check(q["eligible"] and q["capacity"]["available_capacity_cents"] == 0 and t.accept(q), "startup exception with neutral zero-history capacity")
    check(t.cash == 650000 and t.rows[1]["net_profit_cents"] == 0 and t.capacity()["available_capacity_cents"] == 0, "borrowing is neither income nor capacity")
    before = copy.deepcopy(t.__dict__)
    check(not t.accept(q) and t.__dict__ == before, "repeat quote commit is atomic rejection")
    other = Trial(); stale=other.quote(50000,50000)
    check(not other.apply(action(0,1,"other_income",productive=False)) and not other.accept(stale), "conflicting cash transaction invalidates quote")
    score_before=t.score
    check(t.early_payoff() and t.cash == 540000 and t.remaining_principal()==0 and t.remaining_interest()==0, "early payoff charges remaining contracted principal and interest exactly")
    check(t.score==score_before and t.startup_used and not t.quote(100000,100000)["eligible"], "payoff cannot farm history or renew startup entitlement")
    before=copy.deepcopy(t.__dict__)
    check(not t.early_payoff() and t.__dict__==before,"repeated payoff cannot debit twice")
    check(not Trial().quote(50000)["eligible"],"regular loan requires actual first settlement")
    t=Trial(initial=2000000); t.accept(t.quote(100001,100001))
    for c in range(1,25):
        check(not t.apply(action(c)),f"synthetic payment timeline cycle{c}")
    check(t.remaining_principal()==0 and t.remaining_interest()==0 and t.bank_due()==0,"12 payments retire exact loan including final remainders")
    paid_principal=sum(r["principal_paid_cents"] for r in t.rows.values());paid_interest=sum(r["interest_cents"] for r in t.rows.values())
    check(paid_principal==100001 and paid_interest==10000,"principal and interest categorized separately")
    before=copy.deepcopy(t.__dict__)
    check(bool(t.apply(action(24))) and t.__dict__==before,"duplicate monthly callback cannot repay or rescore")
    t=Trial(initial=0);t.accept(t.quote(50000,50000))
    check(not t.apply(action(1)) and not t.apply(action(2)),"first shortfall commits without negative cash")
    check(t.cash==0 and t.bank_due()==4582 and t.unpaid_rent()==0,"rent first leaves exact loan arrears")
    before=copy.deepcopy(t.__dict__);check(bool(t.apply(action(3))) and t.__dict__==before,"bank arrears block normal production")
    old_score=t.score
    check(not t.apply(action(2,5000,"publisher_receipt",productive=False)) and t.bank_due()==0 and t.cash==418,"passive legal income resolves overdue bank interest then principal")
    check(t.score==old_score and t.loans[0]["installments"][0]["late"],"recovery keeps late fact and grants no immediate score")
    t=Trial();check(not t.apply(action(1,earned=800000)) and not t.apply(action(2,settled=800000)),"regular eligibility uses observed earning/settlement")
    q=t.quote(150000);check(q["eligible"] and t.accept(q),"post-sales eligible regular loan accepted")
    fixed=copy.deepcopy(t.loans[0]["installments"])
    for c in range(3,9):check(not t.apply(action(c)),f"declining-income synthetic month cycle{c}")
    check(t.capacity()["available_capacity_cents"]==0,"fading sales reduce NEW capacity")
    check([(x["due_cycle"],x["principal_cents"],x["interest_cents"]) for x in t.loans[0]["installments"]] == [(x["due_cycle"],x["principal_cents"],x["interest_cents"]) for x in fixed],"decline never rewrites accepted contractual dues")
    for start in (300,850):
        a=Trial(score=start);a.apply(action(1));a.apply(action(2,earned=1000000,settled=1000000))
        check(300<=a.score<=850,"score remains bounded"+str(start))
    # Real paid months can increase reliability despite mild operating losses;
    # borrowing itself earns no additional factor over the same rent-only month.
    control, borrower = Trial(initial=2000000), Trial(initial=2000000)
    borrower.accept(borrower.quote(100000,100000))
    for c in range(1,25):
        control.apply(action(c));borrower.apply(action(c))
    check(control.score==612 and borrower.score==612,"on-time loan payments earn no more history than the identical rent-only year")
    check(control.credit_events[0]["flow_factor"]==-2 and control.credit_events[0]["payment_factor"]==3 and control.credit_events[0]["score_after"]==601,"no-sales paid-rent month increases score1: declared candidate reliability-over-loss tradeoff")
    low=Trial(initial=0,score=300);low.apply(action(1));low.apply(action(2))
    high=Trial(initial=2000000,score=850);high.apply(action(1));high.apply(action(2,earned=1000000,settled=1000000))
    check(low.score==300 and high.score==850,"adverse and favorable factors respect exact lower/upper clamps")
    t=Trial(initial=0);t.accept(t.quote(50000,50000));t.apply(action(1));t.apply(action(2))
    check(t.score==578,"late first month combines -2 cash flow and -20 payment factor")
    t.apply(action(2,200,"other_income",productive=False))
    first=t.loans[0]["installments"][0]
    check(first["paid_interest_cents"]==200 and first["paid_principal_cents"]==0,"partial payment services interest before principal")
    t.apply(action(2,4382,"other_income",productive=False))
    check(t.score==578 and t.bank_due()==0,"late recovery is score-neutral")
    t.apply(action(2,100000,"other_income",productive=False));t.apply(action(3));t.apply(action(4))
    check(t.score==579 and t.loans[0]["installments"][0]["late"],"future on-time month resumes bounded gain without erasing late history")
    raw=json.dumps({"schema_version":1,"candidate_state":t.__dict__})
    decoded=json.loads(raw)
    restored=Trial();restored.__dict__.update(decoded["candidate_state"])
    restored.rows={int(k):v for k,v in restored.rows.items()}
    check(restored.__dict__==t.__dict__,"candidate JSON checkpoint preserves all modeled fields; not a runtime durable-save claim")
    check(t.apply(action(5))==restored.apply(action(5)) and t.__dict__==restored.__dict__,"candidate JSON roundtrip resumes identically")
    control=Trial();control.apply(action(1,earned=800000));control.apply(action(2,settled=800000))
    old_quote=control.quote(50000)
    control.apply(action(3))
    check(old_quote["eligible"] and not control.accept(old_quote),"checkpoint-era eligible stale quote rejects after another committed action")
    for principal,cycle in ((MAX,0),(100000,MAX-1)):
        try:schedule(principal,600,cycle);rejected=False
        except ValueError:rejected=True
        check(rejected,"quote total/schedule overflow rejects"+str((principal,cycle)))
    full=Trial(initial=MAX)
    check(not full.quote(1,50000)["eligible"],"origination preflights exact cash overflow")
    before=copy.deepcopy(full.__dict__)
    check(bool(full.apply(action(1,1,"beta_income"))) and full.__dict__==before,"overflowing candidate income action rolls back")
    return checks


def replay_route(path, arm, rent=50000, starting_score=600):
    data=json.loads(path.read_text(encoding="utf-8-sig"))
    journal=data["final"]["finance"]["actions"]
    trial=Trial(data["initial"]["cash_cents"],rent,starting_score)
    decisions=[]
    if arm.startswith("startup_"):
        principal=int(arm.split("_")[-1])*100
        q=trial.quote(principal,principal);decisions.append(q)
        assert trial.accept(q)
    requested_post=arm.startswith("post_sales_")
    stop=None; cash_parity=[]
    for i,a in enumerate(journal):
        error=trial.apply(a)
        if error:
            stop={"journal_index":i,"attempted_cycle":a["cycle"],"kind":a["kind"],"reason":error,
                  "cash_cents":trial.cash,"rent_arrears_cents":trial.unpaid_rent(),"bank_arrears_cents":trial.bank_due()}
            break
        if arm=="none" and rent==50000:
            expected=journal[i+1]["cash_before"] if i+1<len(journal) else data["final"]["cash_cents"]
            cash_parity.append(trial.cash==expected)
        if requested_post and a["settled"]>0:
            principal=int(arm.split("_")[-1])*100
            q=trial.quote(principal);decisions.append(q)
            if q["eligible"]: assert trial.accept(q)
            requested_post=False
    rows=trial.report()
    native_rows=data["final_finance_report"]["rows"]
    row_parity=rows==native_rows if arm=="none" and rent==50000 and stop is None else None
    if arm=="none" and rent==50000:
        assert stop is None and all(cash_parity) and row_parity,(path.name,stop,row_parity)
    releases=[r for r in data["releases"] if r["cycle"]<=trial.cycle]
    result={"source_trace":str(path.relative_to(ROOT)),"source_sha256":hashlib.sha256(path.read_bytes()).hexdigest(),
            "seed":data["seed"],"policy":data["policy"],"band":data["band"],"arm":arm,
            "rent_cents":rent,"starting_score":starting_score,"stop":stop,"completed_cycles":trial.cycle,
            "releases_reached":len(releases),"reviews":[r["final_review"] for r in releases],
            "cash_cents":trial.cash,"rent_arrears_cents":trial.unpaid_rent(),"bank_arrears_cents":trial.bank_due(),
            "principal_remaining_cents":trial.remaining_principal(),"interest_remaining_cents":trial.remaining_interest(),
            "ending_score":trial.score,"decisions":decisions,"rows":rows,"credit_events":trial.credit_events,
            "loan_contracts":trial.loans,
            "trace":trial.trace,"cash_oracle_checks":len(cash_parity),"cash_oracle_passed":all(cash_parity) if cash_parity else None,
            "row_oracle_passed":row_parity,"disclaimer":"fixed recorded choices with candidate finances, not adaptive human or native loan gameplay"}
    return result


def conditional_portfolio_projection(result, projection_by_id):
    """A future financial forecast, never a legal free-Wait gameplay route."""
    route=Path(result["source_trace"]).stem
    family="Task30" if route.startswith("native_") else "Task29"
    profiles=[projection_by_id[f"{family}/{route}/game{i}"] for i in (1,2)]
    start=result["completed_cycles"]
    # Stop at the earliest captured title's age-Month30; every contributing
    # title still has a directly generated native forecast at every boundary.
    end=min(p["boundaries"][-1]["cycle"] for p in profiles)
    history=[{b["cycle"]:b for b in p["boundaries"]} for p in profiles]
    def settled_at(mapping, cycle):
        values=[b["settled_cents"] for c,b in mapping.items() if c<=cycle]
        return values[-1] if values else 0
    cash=result["cash_cents"]
    loans=copy.deepcopy(result["loan_contracts"])
    rows=[];first_shortfall=None
    for cycle in range(start+2-(start%2),end+1,2):
        income=sum(settled_at(h,cycle)-settled_at(h,cycle-2) for h in history)
        before=cash;cash+=income
        rent_paid=min(cash,50000);cash-=rent_paid
        paid_p=paid_i=due=0
        for loan in loans:
            for x in loan["installments"]:
                if x["due_cycle"]>cycle:continue
                due+=x["principal_cents"]+x["interest_cents"]-x["paid_principal_cents"]-x["paid_interest_cents"]
                for kind in ("interest","principal"):
                    paid=min(cash,x[kind+"_cents"]-x["paid_"+kind+"_cents"])
                    x["paid_"+kind+"_cents"]+=paid;cash-=paid
                    if kind=="interest":paid_i+=paid
                    else:paid_p+=paid
        shortage=(50000-rent_paid)+(due-paid_p-paid_i)
        rows.append({"cycle":cycle,"calendar_month_closed":cycle//2,"opening_cash_cents":before,
                     "projected_sales_settled_cents":income,"rent_paid_cents":rent_paid,
                     "bank_principal_paid_cents":paid_p,"bank_interest_paid_cents":paid_i,
                     "closing_cash_cents":cash,"shortfall_cents":shortage})
        if shortage:
            first_shortfall=rows[-1];break
    return {"source_trace":result["source_trace"],"arm":result["arm"],"start_cycle":start,
            "horizon_cycle":end,"rows":rows,"first_conditional_shortfall":first_shortfall,
            "label":"CONDITIONAL PROJECTION: exact native frozen-title sales, existing debt, $500 rent, no future development/Store/campaign costs or new titles; requires productive time the forecast does not supply. Stops at first financial shortfall. Not observed gameplay."}


def replay_native_candidate(path):
    """Combine the native phase actions with central-timing candidate bank math.

    The GDScript analysis adapter writes loan payments after the native monthly
    report. Replaying those payments inside this candidate boundary fixes their
    analytical month attribution without rewriting the actual native ledger.
    """
    data=json.loads(path.read_text(encoding="utf-8-sig"))
    journal=[a for a in data["final"]["finance"]["actions"] if a["source_id"]!="task30_candidate_startup"]
    principal=data["candidate_debt"]["principal_cents"]
    trial=Trial();checks=[]
    if principal: assert trial.accept(trial.quote(principal,principal))
    for i,a in enumerate(journal):
        error=trial.apply(a)
        assert not error,(path.name,i,error)
        expected=journal[i+1]["cash_before"] if i+1<len(journal) else data["final"]["cash_cents"]
        checks.append(trial.cash==expected)
        assert checks[-1],(path.name,i,trial.cash,expected)
    result={"source_trace":str(path.relative_to(ROOT)),"seed":data["seed"],"principal_cents":principal,
            "arm":"none" if not principal else "startup_"+str(principal//100),
            "completed_cycles":trial.cycle,"cash_cents":trial.cash,"reviews":[r["final_review"] for r in data["releases"]],
            "release_cycles":[r["cycle"] for r in data["releases"]],"ending_score":trial.score,
            "rows":trial.report(),"credit_events":trial.credit_events,"loan_contracts":trial.loans,
            "cash_oracle_checks":len(checks),"cash_oracle_passed":all(checks),
            "label":"Actual native draws/choices/Reviews with a separate candidate loan adapter; credit factors and central-month debt allocation remain modeled, not gameplay."}
    return result


def write_findings(summary, results, optional, native, projections):
    lines=["PATCH NOTES TASK30 — CREDIT/LOAN CANDIDATE FINDINGS v1",
           "Status: bounded READ-ONLY analysis. Every loan, score, tier, capacity and optional trait value below is UNAPPROVED.",
           "Implementation dispatch brief: DEFERRED until user review of this package. No bank lending, trait, or runtime balance was implemented.",
           "", "SOURCES / REPRODUCTION",
           "Live Task30 queue and cumulative authority §68; verified local Task29 studio finance and accepted lifespan baseline.",
           "Source HEAD: "+summary["source_head"]+". Current local Task29 source, not a claim about committed/pushed implementation.",
           "Command from patch-notes: python -B analysis/task30_credit_trial_v1.py",
           "Declared seeds:1104/4417; ordinary/synergy Task29 baselines; first releases at12/18 calendar cycles. Native long-attempts are a separate synergy-policy group.",
           "Model source SHA256: "+hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
           "Runtime source hashes and trace hashes are recorded in credit-summary.json and credit-route-overlays.json.",
           "", "MODEL DECLARATION",
           json.dumps(DECLARATION,indent=2),
           "", "VERIFICATION / COUNTS",
           f"{summary['unit_check_count']} deterministic candidate checks passed. Eight no-loan replays match all{summary['cash_oracle_checks']} native action cash checkpoints and every final monthly report row.",
           f"{len(results)} primary fixed-route overlays and{len(optional)} one-factor optional overlays. All56 primary overlays complete the available recorded two-release horizon; none claims adaptive/human play.",
           f"{len(native)} independent native candidate traces replay with{summary['native_candidate_cash_checks']} exact post-bank cash checks. Native raw gameplay verifications are documented by their separate harness.",
           f"{len(projections)} conditional portfolio forecasts contain{sum(len(p['rows']) for p in projections)} monthly rows and use direct Godot-generated frozen-title forecasts. These are future projections, not committed calendar actions.",
           "Checked: tier boundaries, all interest/principal remainders, origination alignments, monthly exactly-once payment, rent-before-interest-before-principal, partial recovery, full-clear blocking, no negative cash, frozen dues despite declining eligibility, quote conflict/replay, early payoff/startup lock, JSON candidate checkpoint continuation, bounded score changes, and quote/cash integer overflow.",
           "Python exact arithmetic is not proof of every future GDScript aggregate overflow guard. Candidate JSON roundtrip is not a durable-save implementation claim.",
           "", "FIXED-ROUTE RESULTS",
           "Startup500/1000/1500: each8/8 finishes the same recorded choices/releases. At the completed recorded horizon the loan has fully amortized, and every matched route has exactly$50/$100/$150 less cash than no loan. Reviews are unchanged in these overlays by construction.",
           "Post-first-sales500:8/8 eligible. Post1000 and1500:6/8 eligible; the two seed1104 early routes have installment capacity$76.04 ordinary/$66.72 synergy and reject both higher requests. Rejecting a quote leaves the no-loan route intact.",
           "At18-cycle first launch, nine startup installments are already due. Incremental runway after scheduled installments is only$87.62/$175.06/$262.50 for500/1000/1500, with principal still owed$125.06/$250.03/$375.00. Gross borrowed cash must not be mistaken for net runway.",
           "At22 cycles, eleven installments leave negative net borrowing contributions -$4.02/-$8.26/-$12.50 before the last installment. Immediate-month amortization is a weak tool for buying many pre-release cycles.",
           "", "NATIVE LONG-ATTEMPT RESULTS (FINAL RECOVERY-AWARE POLICY)",
           "Target24 first-release cycles was not forced. A rejected selected production action takes legal free phase/launch transitions; visible Rival income is used when sufficient to clear the obligation.",
           "Seed | loan | release cycles | actual Reviews | ending cash | modeled ending credit"]
    for r in native:
        lines.append(f"{r['seed']} | ${r['principal_cents']/100:.2f} | {r['release_cycles']} | {r['reviews']} | ${r['cash_cents']/100:.2f} | {r['ending_score']}")
    lines += ["The final seed1104 policy uses a real visible Rival receipt and reaches first Review9.7 atcycle22; seed4417 lacks the same recovery choice and releases atcycle18 with6.7. Both reach9.4 on Game2. Zero-loan controls already achieve those same outcomes. These are actual automated native profiles, not synthetic high Reviews and not a human playtest distribution.",
              "Within each matched native seed, startup debt buys no additional committed production or Review/lifetime-sales increase. Ending cash differs by exactly contracted interest. This sample does not support debt-funded first-game extension as a dominant strategy; two seeds are not exhaustive policy coverage.",
              "Analysis adapter limitation: native bank payments are explicit transfers after the native productive boundary; their native journal therefore records immediate boundary payments in the new partial month. credit-native-candidate-scores.json replays their modeled central-boundary timing; passive recovery stays in its true partial month. Neither dataset is silently rewritten into the other.",
              "", "SCORE / ELIGIBILITY FINDINGS",
              "The selected cash-flow score is distinct from earned recurring-surplus eligibility. One-off capital funding, Publisher/Beta/miscellaneous receipts and borrowing improve cash but are excluded from both score cash flow and recurring capacity. One-off Feature/Store/playtest/campaign costs reduce score flow but are excluded from recurring-capacity estimation; disclose this potentially optimistic capacity assumption.",
              "A no-sales month paying$500 rent yields cash-flow factor-2 plus on-time factor+3: score rises1 despite operating losses. An otherwise identical12-month borrower and rent-only control both reach612 from600. Borrowing/early payoff/repeated callbacks confer no extra history, but paid loss-making months can slowly raise credit. Keep this declared reliability-versus-profit tradeoff visible; consider revising before implementation, not after hiding the result.",
              "A late first month combines -2 flow/-20 payment:600→578. Clearing arrears is immediately score-neutral and late history remains. A later fully on-time month resumes bounded gain. Final native credit scores remain candidate calculations only.",
              "At most one active loan is an additional first-version candidate restriction. Existing-payment subtraction is implemented/tested, but simultaneous runtime loan portfolios are not claimed.",
              "", "FADING BACK CATALOG / EXISTING DEBT",
              "Conditional forecasts begin at the actual captured endpoint and stop no later than the first title's release-ageMonth30, so every contributing title has native projected data. No new game, campaign or future development/Store cost is assumed. Productive time is required but is not supplied by the forecast; this is not a legal Wait route."]
    no_loan_projections=[p for p in projections if p['arm']=='none']
    for p in no_loan_projections:
        row=p['rows'][-1]
        lines.append(f"{Path(p['source_trace']).stem}: {'first projected rent shortfall' if p['first_conditional_shortfall'] else 'projection horizon'} atcycle{row['cycle']}, closingcash${row['closing_cash_cents']/100:.2f}, shortfall${row['shortfall_cents']/100:.2f}.")
    lines += ["All four early Task29 portfolios eventually fail to cover rent in this two-title-only forecast. Existing accepted debt retains its exact dates and amounts even when new borrowing capacity falls to0; loan repayment cannot be made smaller by fading revenue. Loan arms generally bring less cash to this tail, and one early synergy portfolio reaches a rent shortfall one month sooner with borrowing.",
              "", "OPTIONAL SINGLE-FACTOR SCREENS",
              "$450 rent:16/16 fixed-route none/startup1000 variants reach the recorded horizon. $550 rent:8/16 finish; all eight slow variants stop at a counterfactual-invalid action (no-loan attemptcycle17; startup1000 attemptcycle19). These are fixed-choice stress failures, not proofs no adaptive legal recovery exists.",
              "Initial score550 or650:16/16 variants each finish. At550 the startup quote uses20% total interest, at65010%; the changed score is not income and does not alter reviews or sales. No trait point price, background combination or runtime bonus is selected. Preserve one chosen background and separate Genre-specialty rules.",
              "", "CONCRETE CANDIDATE RECOMMENDATION / REVIEW GATE",
              "Recommend a first reviewed lending package of one active loan, at most$500, available after first actual sales settlement and only if its maximum12-month installment fits the declared25% trailing recurring-surplus capacity. Keep startup borrowing unavailable in the first proposed implementation: under the immediate first-due convention none of the tested500–1500 limits bought additional native production, while every arm paid interest. A future grace-period/startup exception would require its own bounded comparison and ruling.",
              "Recommend retaining exact fixed quotes, full remaining contracted-interest early payoff for this comparison, rent-first/oldest-interest-first payments, no negative cash, no duplicate credit factors, and the explicit full-clear financial block with zero-cycle launch/navigation and real recovery receipts. Rates/term/score thresholds and this recommendation remain candidates for user review.",
              "Score formula is reproducible above; review whether mild-loss months should gain1 before locking it. Do not silently change the tested formula or call600/tiers approved.",
              "Employee, Publisher, Store and trait recommendations must now budget the actual$500 monthly obligation and payment timing. The$550 slow-route stalls show that historical low/no-rent recommendations cannot be carried forward unchanged. Publisher/Beta windfalls can bridge debt but cannot establish recurring affordability; expensive purchases can erode cash despite positive recurring capacity. No hypothetical employee/payroll/reward system was treated as playable.",
              "Implementation dispatch brief remains DEFERRED pending user review. The following are candidate acceptance/checkpoint requirements only.",
              "", "CANDIDATE ACCEPTANCE / CHECKPOINT CONTRACT",
              "Persist versioned run-level startup-used entitlement, unique loan/quote IDs, accepted quote revision, origination/due cycles, frozen principal/rate/term and original schedule, per-installment interest/principal paid plus arrears/late flags, total remaining balances, and the last processed payment boundary. Keep financing and principal out of income/profit.",
              "Persist bounded credit score, parameter-version ID, completed-month factor inputs/history and last processed credit month. Rebuild eligibility from the authoritative completed finance rows, not forecasts or borrowed cash. Preserve late facts after recovery; no score from opening/closing menus or early-payoff callbacks.",
              "Preflight accepted principal, cash receipt, sales settlement, rent, installment service and every aggregate before any direct phase mutation. Commit loan payments inside the central productive transaction BEFORE report publication; the analysis adapter is not that implementation. Reject stale/conflicting quotes and duplicate boundary callbacks atomically. Preserve frozen sales, release IDs, cards, RNG, and normal calendar/redraw rules.",
              "Require exact due alignment and final remainder tests, both recovery orders, cash/report reconciliation, saved-state replay, guarded UI/back navigation, exported inclusion and capture provenance. Task10 durable saves remain unimplemented; do not label this checkpoint contract as tested saves.",
              "", "FILES / LIMITATIONS",
              "Only analysis/task30_credit_trial_v1.py and task30-v1 findings/evidence were changed by this subtask. Native route/projection analysis files are separately owned and documented by their harness.",
              "No runtime balance, lifespan coefficients, campaigns, Review, prices, payout, trait or loan implementation was changed. No commit/push. No human graphical-input claim. Final source hash guard unchanged.",
              "Artifacts: credit-loan-predeclaration.json; credit-unit-results.json; credit-route-overlays.json; credit-summary.json; credit-native-candidate-scores.json; credit-conditional-portfolio-projections.json; native-projections-month30.json and the separately documented native traces."]
    (OUT/"credit-loan-findings-v1.txt").write_text("\n".join(lines)+"\n",encoding="utf-8")


def main():
    started=time.monotonic()
    OUT.mkdir(exist_ok=True);(OUT/".gdignore").touch()
    (OUT/"credit-loan-predeclaration.json").write_text(json.dumps(DECLARATION,indent=2))
    sources={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ("scripts","scenes","data") for p in (ROOT/folder).rglob("*") if p.is_file()}
    head=subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True).strip()
    checks=unit_tests()
    (OUT/"credit-unit-results.json").write_text(json.dumps({"checks":checks,"passed":all(c["passed"] for c in checks)},indent=2))
    paths=sorted((ROOT/"design-logs/task29-v1").glob("route_*.json"))
    assert len(paths)==8
    results=[replay_route(p,arm) for p in paths for arm in DECLARATION["arms"]]
    optional=[replay_route(p,arm,rent,score) for p in paths for rent,score in ((45000,600),(55000,600),(50000,550),(50000,650)) for arm in ("none","startup_1000")]
    (OUT/"credit-route-overlays.json").write_text(json.dumps({"main":results,"optional":optional},indent=2))
    native_paths=sorted(OUT.glob("native_*.json"))
    native=[replay_native_candidate(p) for p in native_paths]
    (OUT/"credit-native-candidate-scores.json").write_text(json.dumps(native,indent=2))
    projection_path=OUT/"native-projections-month30.json"
    projections=[]
    if projection_path.exists():
        projection_data=json.loads(projection_path.read_text(encoding="utf-8-sig"))
        assert not projection_data["errors"]
        by_id={p["id"]:p for p in projection_data["results"]}
        projections=[conditional_portfolio_projection(r,by_id) for r in results+native if r.get("stop") is None]
        (OUT/"credit-conditional-portfolio-projections.json").write_text(json.dumps(projections,indent=2))
    source_after={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ("scripts","scenes","data") for p in (ROOT/folder).rglob("*") if p.is_file()}
    summary={"source_head":head,"runtime_source_unchanged":sources==source_after,"source_sha256":sources,
             "unit_check_count":len(checks),"main_overlay_count":len(results),"optional_overlay_count":len(optional),
             "cash_oracle_checks":sum(x["cash_oracle_checks"] for x in results),
             "all_zero_loan_oracles_passed":all(x["cash_oracle_passed"] and x["row_oracle_passed"] for x in results if x["arm"]=="none"),
             "native_candidate_credit_count":len(native),"native_candidate_cash_checks":sum(r["cash_oracle_checks"] for r in native),
             "conditional_portfolio_projections":len(projections),
             "main":[{k:v for k,v in r.items() if k not in ("rows","trace","credit_events","source_sha256","loan_contracts")} for r in results],
             "optional":[{k:v for k,v in r.items() if k not in ("rows","trace","credit_events","source_sha256","loan_contracts")} for r in optional]}
    (OUT/"credit-summary.json").write_text(json.dumps(summary,indent=2))
    assert time.monotonic()-started<DECLARATION['wall_limit_seconds'],"Declared bounded analysis time exceeded"
    write_findings(summary,results,optional,native,projections)
    print(json.dumps({k:v for k,v in summary.items() if k not in ("main","optional","source_sha256")},indent=2))


if __name__=="__main__": main()
