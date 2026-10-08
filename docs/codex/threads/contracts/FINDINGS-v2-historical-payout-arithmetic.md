# Contracts findings v2 — historical advance payout arithmetic

2026-10-07 (America/Los_Angeles). **Read-only exact-cent re-scoring of historical candidate hands, not a current-source native Task 34 run.** Current repository at calculation: `main` `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`, with no tracked gameplay changes in status. Input: local `patch-notes/design-logs/task32-v1/evaluations.json` and `contract_traces.json`; their [Task 32 source manifest](../../../../patch-notes/design-logs/task32-v1/source-before.json) records base HEAD `e054791d0348d90faf70e9d827892c351fa018bc` plus exact then-local file hashes. Input hashes, the [recalculation script](historical-payout-v1/analyze.ps1), and its [summary](historical-payout-v1/summary.csv) are saved in this thread folder. The historical route/hand sample is not a current-source replay.

## Setup and checks

The 640 historical candidate hand traces have two shortlisted targets each, yielding 1,280 evaluation rows. For each row, retain its recorded fixed-share numerator/denominator and candidate cap `C` (Crown 192,000 cents; Neon 156,000 cents). For `A ∈ {0, 15000, 20000, 30000}` cents, calculate total direct cash exactly as `A + floor((C − A) × numerator / denominator)` with integer remainder before division. This does not change hands, eligibility, rent, settlement, Promotion or cash timing. The `A=0` calculation matched the recorded Task 32 payout in **1,280/1,280** rows.

| Publisher / target Scope | Historical rows | Mean total at A=$0 | Mean added total at A=$150 | At A=$200 | At A=$300 |
|---|---:|---:|---:|---:|---:|
| Crown / 9 | 320 | $1,665.45 | +$19.89 | +$26.51 | +$39.77 |
| Crown / 10 | 320 | $1,662.03 | +$20.15 | +$26.87 | +$40.31 |
| Neon / 10 | 320 | $1,224.87 | +$32.22 | +$42.96 | +$64.45 |
| Neon / 11 | 320 | $1,220.83 | +$32.61 | +$43.48 | +$65.22 |

At full completion, every arm totals the same cap; at zero completion, total equals the advance. These are formula endpoints, not observed access or gameplay outcomes. The historical sample contains no zero-completion hand and repeats each trace under two targets, so the means are descriptive of this selected hand set, not publisher-wide expected value.

## Interpretation and limits

In these historical hands, the advance changes eventual total cash much less than its face amount because most completion fractions are high. Its possible **timing** benefit—clearing arrears before the first hand—is the important untested question. The old $147.65 arrears state would arithmetically leave $2.35 after a $150 receipt if it reproduced exactly and the central ledger serviced that arrear; this is a conditional identity, not proof of first- or second-hand access. Current Studio creation, RunState, finance and Contract flow differ from the Task 32 snapshot. A genuine current $5,700 startup receipt, current-source route, paid rent/credit and next settlement are still required.

Recommendation: do not choose $150, $200 or $300 from this arithmetic. First reproduce a legal current-source blocked state, then run the predeclared paired native/finance Task 34 comparison. No candidate number, target, cap or Promotion amount is approved by this finding.
