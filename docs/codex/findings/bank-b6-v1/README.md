# Banking B6 v1 — first-release pressure and preparation shortfall

Executed 2026-10-09 after the parent's source-bound repaired-export acceptance. **Sixteen foundations complete; no loan comparison was reached under this preparation policy.** This is bounded read-only evidence on the original pre-Fanbase integrated source, not balance approval. The separately predeclared [v2 continuation](../bank-b6-v2/PLAN.md) addresses the missing fourth earning cycle.

## Observed first releases

Both genuine startup ledgers use the same cards/policy within each seed. No Trait, employee, loan or invented charge changes first-game cash. Feature fees below are actual paid hand charges; rent is $500 per completed month.

| Policy / seed | Early cycle / Review | Early cash, legacy / current | Late cycle / Review | Late rent arrears, legacy / current | Actual Feature fees, early / late |
|---|---|---|---|---|---|
| Ordinary / 1104 | 12 / 5.4 | $1,190 / $1,390 | 18 / 7.4 | $360 / $160 | $1,310 / $1,360 |
| Ordinary / 4417 | 12 / 4.4 | $1,140 / $1,340 | 18 / 6.9 | $360 / $160 | $1,360 / $1,360 |
| Synergy / 1104 | 12 / 5.8 | $1,180 / $1,380 | 18 / 7.7 | $280 / $80 | $1,320 / $1,280 |
| Synergy / 4417 | 12 / 6.2 | $1,180 / $1,380 | 18 / 8.5 | $360 / $160 | $1,320 / $1,360 |

Every early route completed at positive cash with no overdue rent and credit600. Every late route completed its declared18 cycles at cash0 with original rent arrears and credit595. The transaction-level cash trough equals these release cash balances. The bounded attempt did **not** reproduce a late6.2 Review: the nearest late result is6.9, a +0.7 gap. The observed6.2 is an early cycle12 route and must not be relabeled as the reported late case.

## Why lending was not reached

Early routes completed Colored Text Research (+1 cycle) and two Ironclad hands (+2); a campaign at release age3 was ineligible. Late routes first rejected Colored Text admission while rent was overdue, then Ironclad supplied two earning cycles and cleared arrears; their eligible campaign supplied the third. All routes therefore stopped at release age3 (cycle15 or21), with only one positive completed sales month. Bank quotes correctly rejected them. No loan was inserted and no free wait was used. V1 has zero loan arms, so it establishes no matched lending outcome.

## Reproduction and audit

- `run.py install`: analysis-only installation and clean import, exit0/errors0.
- `--check-only --script res://scripts/debug/b6.gd`: exit0/errors0.
- `run.py check`: source-bound automated/exported acceptance passed.
- `run.py run`: all16 declared foundation processes exit0/errors0; raw compressed outputs, exact commands, logs and per-route provenance receipts are retained.
- `audit.py`: original independent audit stopped on its per-month `due = paid + unpaid` assumption. That assumption is invalid when a prior-month bill is paid in a later month; this failure is preserved in the original script.
- `audit_v2.py`: **3,209 independent checks pass**. The separate audit version reconciles original-month due/remaining arrears, actual payment-month cash, individual bill payment histories, total journal/monthly cash and source provenance. It reads the original route archives without changing their original execution hashes.
- Before execution, the expanded Bank audit passed860 checks against three existing exported installment/payoff captures and rejected a deliberately corrupted interest-paid field. This is auditor verification, not a new B6 gameplay route.
- Expected placeholder-art warnings remain visible in logs. Native error scans found no non-certificate `ERROR`, `SCRIPT ERROR` or `FAIL` lines. No audio, clean-machine or release-readiness claim.

Run the corrected audit with:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/findings/bank-b6-v1/audit_v2.py
```

The immutable source manifest retains original main HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`; this implementation session began on main `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. The payload hashes matched at intake. Subsequent Fanbase work is outside this experiment. No gameplay, finance rule, rate, balance value, commit or push was changed by B6.
