"""Independent B6 provenance, cents, installment and payoff reconciliation."""
from pathlib import Path
import gzip
import hashlib
import json
import sys
import evidence as e

H = Path(__file__).resolve().parent
sys.path.insert(0, str(H.parent / "queue-completion-v1"))
import finance_audit as a


def money(s):
    f = s["finance"]
    return dict(cycle=s["cycle"], cash=s["cash_cents"],
                debt=sum(x["schedule"]["principal_cents"] - x["principal_paid_cents"] for x in f.get("bank_loans", [])),
                due_interest=sum(x.get("interest_cents", 0) - x.get("interest_paid_cents", 0) for x in f["obligations"]),
                arrears=s["finance_report"]["total_overdue_cents"], credit=f["credit"],
                settled=sum(r["sales_settled_cents"] for r in f["monthly_rows"]),
                earned=sum(x["entitlement_cents"] for x in s["sales"]))


def schedule_rows(schedule):
    p, n = schedule["principal_cents"], schedule["term_months"]
    base, extra = divmod(p, n)
    opening = p
    rows = []
    for i in range(n):
        principal, interest = base + int(i < extra), (opening + 50) // 100
        rows.append(dict(due_cycle=schedule["first_due_cycle"] + i * 2,
                         principal_cents=principal, interest_cents=interest,
                         due_cents=principal + interest))
        opening -= principal
    a.check(opening == 0, "independent principal schedule")
    a.check(sum(x["interest_cents"] for x in rows) == schedule["total_interest_cents"], "independent interest schedule")
    a.check(max(x["due_cents"] for x in rows) == schedule["maximum_installment_cents"], "independent maximum installment")
    a.check(sum(x["due_cents"] for x in rows) == schedule["total_payment_cents"], "independent payment schedule")
    return rows


def audit_bank(f):
    a.ledger(f)
    total_principal = total_interest = total_accrued = 0
    ids = [x["loan_id"] for x in f["bank_loans"]]
    a.check(len(ids) == len(set(ids)), "distinct loan identities")
    for loan in f["bank_loans"]:
        ident, schedule = loan["loan_id"], loan["schedule"]
        rows = schedule_rows(schedule)
        tx = [t for t in f["transactions"] if t["source_id"] == ident]
        receipts = [t for t in tx if t["kind"] == "financing_in"]
        a.check(len(receipts) == 1 and receipts[0]["cash_delta_cents"] == schedule["principal_cents"], "one financing receipt per loan")
        a.check(receipts[0]["cycle"] == schedule["accepted_cycle"], "financing receipt origination")
        bills = [b for b in f["obligations"] if b["expense_type"] == "bank_installment" and b["source_id"] == ident]
        a.check(len(bills) == loan["issued"], "issued installment count")
        cutoff = loan["closed_cycle"] if loan["closed"] else f["last_cycle"]
        a.check(loan["issued"] == sum(x["due_cycle"] <= cutoff for x in rows), "only actually due installments issued")
        principal_paid = interest_paid = accrued = 0
        for number, (bill, expected) in enumerate(zip(bills, rows), 1):
            a.check(bill["bill_id"] == f"{ident}:{number}", "stable installment identity")
            for key in ("due_cycle", "principal_cents", "interest_cents", "due_cents"):
                a.check(bill[key] == expected[key], "independent installment " + key)
            a.check(bill["month"] == bill["due_cycle"] // 2, "original due month")
            a.check(bill["paid_cents"] + bill["unpaid_cents"] == bill["due_cents"], "original installment balance")
            a.check(sum(p["cents"] for p in bill["payments"]) == bill["paid_cents"], "payment history total")
            a.check(bill["interest_paid_cents"] == min(bill["paid_cents"], bill["interest_cents"]), "interest paid before principal")
            a.check(bill["principal_paid_cents"] == bill["paid_cents"] - bill["interest_paid_cents"], "principal split")
            payments = [t for t in tx if t["kind"] == "bank_payment" and t["due_month"] == bill["month"]]
            a.check([(t["cycle"], t["amount_cents"]) for t in payments] == [(p["cycle"], p["cents"]) for p in bill["payments"]], "journal matches original bill payment history")
            a.check(all(t["cash_delta_cents"] == -t["amount_cents"] for t in payments), "installment cash outflow")
            due = [t for t in tx if t["kind"] == "bank_interest_due" and t["due_month"] == bill["month"]]
            a.check(len(due) == 1 and due[0]["amount_cents"] == bill["interest_cents"] and due[0]["cycle"] == bill["due_cycle"], "one interest accrual on original due")
            principal_paid += bill["principal_paid_cents"]
            interest_paid += bill["interest_paid_cents"]
            accrued += bill["interest_cents"]
        payoffs = [t for t in tx if t["kind"] == "bank_payoff"]
        a.check(len(payoffs) <= 1, "at most one explicit payoff receipt")
        a.check(all(t["cash_delta_cents"] == -t["amount_cents"] for t in payoffs), "payoff cash outflow")
        principal_paid += sum(t["amount_cents"] for t in payoffs)
        a.check(loan["principal_paid_cents"] == principal_paid, "loan principal reconciles bills and payoff")
        a.check(loan["interest_paid_cents"] == interest_paid, "loan interest reconciles original bills")
        a.check(0 <= principal_paid <= schedule["principal_cents"], "principal stays within contract")
        a.check(loan["closed"] == (principal_paid == schedule["principal_cents"]), "closure requires full principal")
        if payoffs:
            a.check(loan["closed"] and loan["closed_cycle"] == payoffs[0]["cycle"], "payoff closes at its actual cycle")
        total_principal += principal_paid
        total_interest += interest_paid
        total_accrued += accrued
    a.check(sum(r["principal_paid_cents"] for r in f["monthly_rows"]) == total_principal, "monthly principal cash reconciliation")
    a.check(sum(r["interest_paid_cents"] for r in f["monthly_rows"]) == total_interest, "monthly interest cash reconciliation")
    a.check(sum(r["interest_cents"] for r in f["monthly_rows"]) == total_accrued, "monthly original interest expense")


def audit_payoff(arm):
    before, final = arm["before_payoff"], arm["final"]
    if not arm["payoff_attempted"]:
        a.check(before == final and not arm["payoff"], "skipped payoff changes nothing")
        a.check(bool(arm["payoff_skip_reason"]), "payoff skip is explained")
        return
    a.check(arm["second_release_completed"] and len(arm["releases"]) == 1, "payoff is after successful Game 2 launch")
    q, after = arm["payoff_quote"], arm["after_payoff"]
    a.check(before["cycle"] == after["cycle"], "payoff zero cycles")
    a.check(arm["payoff_rng_before"] == arm["payoff_rng_after"], "payoff preserves RNG")
    if q:
        f = before["finance"]
        loan = next(x for x in f["bank_loans"] if x["loan_id"] == q["loan_id"])
        principal = loan["schedule"]["principal_cents"] - loan["principal_paid_cents"]
        interest = sum(b["interest_cents"] - b["interest_paid_cents"] for b in f["obligations"] if b["source_id"] == loan["loan_id"])
        reserve = sum(b["unpaid_cents"] for b in f["obligations"] if b["expense_type"] in ("rent", "payroll"))
        a.check((q["principal_cents"], q["interest_cents"], q["total_cents"]) == (principal, interest, principal + interest), "payoff quote independent principal and due interest")
        a.check(q["revision"] == len(f["actions"]), "payoff bound to current revision")
        a.check(arm["payoff"] == (before["cash_cents"] >= principal + interest + reserve), "payoff affordability includes due rent/payroll")
    if not arm["payoff"]:
        a.check(before == after == final, "rejected payoff preserves complete captured state")
        return
    a.check(before["cash_cents"] - after["cash_cents"] == q["total_cents"] + reserve, "exact payoff plus actual prior-bill service")
    a.check(before["finance"]["credit"] == after["finance"]["credit"], "payoff grants no immediate credit")
    a.check(len(after["finance"]["actions"]) == len(before["finance"]["actions"]) + 1, "single payoff operation")
    a.check(not arm["duplicate_payoff"] and arm["after_duplicate_payoff"] == after == final, "duplicate payoff rejected without mutation")
    a.check(arm["duplicate_payoff_rng"] == arm["payoff_rng_after"], "duplicate payoff preserves RNG")
    loan = after["finance"]["bank_loans"][-1]
    a.check(loan["closed"] and loan["principal_paid_cents"] == arm["principal"], "explicit payoff full closure")


def main():
    context = e.upstream_context(e.source_context())
    manifest = e.read(H / "route-manifest.json")
    a.check(manifest == [list(x) for x in e.ROUTES], "exact predeclared sixteen foundations")
    summary, comparisons = [], []
    for spec in manifest:
        name = "-".join(map(str, spec))
        receipt = e.validate_route(name, spec, context)
        payload = gzip.decompress((H / (name + ".json.gz")).read_bytes())
        a.check(hashlib.sha256(payload).hexdigest() == receipt["output_sha256"], "decompressed output provenance")
        d = json.loads(payload)
        a.check([d[k] for k in ("creation", "policy", "band", "seed")] == spec, "route declares matching inputs")
        a.check(d["valid"] and not d["errors"], "native validity")
        audit_bank(d["final"]["finance"])
        a.check(d["initial"]["cash_cents"] == (550000 if spec[0] == "legacy" else 570000), "genuine creation")
        first = d.get("first_release", d["final"])
        tx = first["finance"]["transactions"]
        # Exclude the zero opening balance before initial funding; include all
        # subsequent intermediate charges before same-action sales settlement.
        balances = [d["initial"]["cash_cents"]]
        initial_tx_count = len(d["initial"]["finance"]["transactions"])
        balances.extend(v for t in tx[initial_tx_count:] for v in (t["cash_before_cents"], t["cash_after_cents"]))
        summary.append(dict(name=name, release=d["releases"][:1], first=money(first), low_cents=min(balances),
                            feature_play_cents=-sum(t["cash_delta_cents"] for t in tx if t["kind"] == "feature_play"),
                            first_block=d["blockers"][:1], quote=d.get("quote", {}),
                            eligible=money(d.get("eligible_state", d["final"])), arms=len(d["loans"])))
        if d["loans"]:
            a.check([arm["principal"] for arm in d["loans"]] in ([0, 50000], [0, 50000, 100000]), "declared loan arms and no-loan first")
        for arm in d["loans"]:
            a.check(arm["restored_exact"], "identical full captured Studio")
            for field in ("cycle", "cash_cents", "redraws", "sales", "finance", "finance_report"):
                a.check(arm["initial"][field] == d["eligible_state"][field], "identical hydrated " + field)
            a.check(arm["valid"] and not arm["errors"], "arm native validity")
            audit_bank(arm["final"]["finance"])
            before, after, q, p = arm["initial"], arm["after_accept"], arm["quote"], arm["principal"]
            a.check(after["cycle"] == before["cycle"], "borrowing zero cycles")
            a.check(after["cash_cents"] - before["cash_cents"] == p, "cash financing distinct")
            if p:
                a.check(arm["accepted"] and q["accepted"], "quote accepted")
                completed = [r for r in before["finance"]["monthly_rows"] if r["month"] <= before["cycle"] // 2]
                older, latest = completed[-2]["sales_settled_cents"], completed[-1]["sales_settled_cents"]
                a.check(older > 0 and latest > 0 and q["older_sales_cents"] == older and q["latest_sales_cents"] == latest, "two actual positive completed sales months")
                basis = min(latest, (older + latest) // 2)
                a.check(q["basis_cents"] == basis, "conservative quote basis")
                a.check(q["rent_cents"] == 50000 and q["obligations_cents"] == 0, "actual no-employee rent and obligations")
                a.check(q["capacity_cents"] == max(0, basis - 50000) // 4, "capacity")
                sch = q["schedule"]
                a.check(sch["first_due_cycle"] == before["cycle"] + 2 + before["cycle"] % 2, "first full month")
                a.check(sch["maximum_installment_cents"] <= q["capacity_cents"], "largest installment fits capacity")
                schedule_rows(sch)
            else:
                a.check(before == after, "no-loan control changes nothing")
            a.check(money(after)["debt"] == p, "financing is debt")
            audit_payoff(arm)
        if d["loans"]:
            base = d["loans"][0]
            for arm in d["loans"][1:]:
                def calendar(x):
                    return {s["cycle"]: s for s in [x["after_accept"], *x["cycles"], x["before_payoff"]]}
                x, y = calendar(base), calendar(arm)
                common = sorted(set(x) & set(y))
                a.check(bool(common), "matched calendar exists")
                cycle = common[-1]
                left, right = money(x[cycle]), money(y[cycle])
                comparisons.append(dict(name=name, principal=arm["principal"], cycle=cycle, no_loan=left, loan=right,
                                        cash_delta=right["cash"] - left["cash"],
                                        cash_less_principal_delta=(right["cash"] - right["debt"]) - (left["cash"] - left["debt"]),
                                        second_reviews=arm["releases"], first_block=arm["blockers"][:1],
                                        payoff_attempted=arm["payoff_attempted"], payoff=arm["payoff"],
                                        payoff_skip_reason=arm["payoff_skip_reason"], final=money(arm["final"])))
    e.write(H / "audit-result.json", dict(pass_=True, checks=a.checks, provenance=context,
                                        foundations=summary, comparisons=comparisons))
    result = e.read(H / "audit-result.json")
    result["pass"] = result.pop("pass_")
    e.write(H / "audit-result.json", result)
    print("PASS", a.checks, "checks", len(summary), "foundations", len(comparisons), "loan comparisons")


if __name__ == "__main__":
    main()
