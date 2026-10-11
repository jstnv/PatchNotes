# Education E1–E4 independent review — 2026-10-09

## State and scope

Reviewed the shared dirty `main` worktree at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. This reviewer changed only the findings auditor and evidence here. The sole gameplay writer retained ownership of runtime and native test drivers. No native processes or Computer Use were launched by this reviewer; no commit or publication is claimed.

Authority: the approved education activation handoff, current local TODO/design, and current runtime. Candidate balance findings are not new gameplay approval.

## Result

`audit-education-v1.json`: **208,895 independent checks passed**. The frozen auditor is `auditors/audit-7065046a639b0d10.py` (full SHA-256 in the result). The copy preserves the exact audit source; the documented command runs `audit.py` in this findings directory.

- All **192** exact-cent approved and native amortization lines: 96 per trait, twelve-month non-accruing grace, first due cycle 26, final due cycle 216, scheduled rather than unpaid-balance interest, exact adjusted final payments.
- **23** focused/edge ledger captures and **4** explicitly isolated private payment vectors. The latter deliberately override cash without a financing journal and are rejected by public APIs; they establish ordering arithmetic, not reachable player states.
- **61** unique genuine route ledger snapshots. Three releases reached Reviews 5.8, 7.3 and 7.8 by cycle 54, accepted a real $500 Bank loan, and paid education from actual earned cash. Only real unused-point funding and Bank principal are financing receipts in that route. The separate creation/grace payoff cohort is not pooled into it.
- Ordinary service, original-due interest expense versus actual-payment-month interest/principal, credit history, education-first-date/Bank-same-date tie behavior, rent/payroll precedence, Bank installment overlap reserve, and the distinct elective education/Bank payoff rules reconcile independently.
- **13** separate active restart processes / **325** native assertions: nine constructed long-horizon acceptance processes and four genuine-route processes. Every captured before/after ledger is independently audited. Every cold restore matches the previous complete payload, including RNG. Eleven original generation byte hashes reconstruct exactly from their bound canonical envelopes; five still-retained originals also match their physical bytes. Earlier generations were normally pruned, not falsely claimed to remain on disk.
- The genuine route seed is exactly the immutable native checkpoint. An unsaved cycle-55 project/education payoff rolls back to the original cycle-54 Studio state and bytes; the subsequent actual saved payoff survives another Continue. Bank remains open, with its complete account unchanged. No instant credit bonus or unrelated persisted gameplay mutation occurs.
- **16** E4 processes cover seven authentic prior-schema fixtures, seven invalid/unsupported copies, explicit recovery and cold restoration, and 21 detached component boundaries. Legacy education previews stay inactive and retain their original point funding. Synthetic rent funding in those detached boundaries is not gameplay or player-balance evidence.
- The accepted atomicity suite's source/log is bound alongside the JSON-producing runs. It reports 36 native assertions for malformed/stale/repeated/insufficient quotes and save corruption; this audit does not pretend those log assertions are an additional captured transition dataset.

The separate rich legacy extension at `../education-e4-rich-legacy-v1/` reports **81,694** structural/provenance/cash checks and **29** native assertions in two processes. Additional read-only corroboration here verified all **102** current runtime hashes, complete migrate/cold payload equality, unchanged retained generations, and the result's source/auditor hashes. That fixture has 59 actions, 198 transactions, 38 bills, 11 payroll installments, 240 Fans, 18 pending Promotion, and a just-accepted Bank loan; it does not claim an already-paid Bank installment.

## Defects found and resolved

1. Prior-schema finance migration could call the replay helper after an unsupported old rent value made construction return an empty dictionary. The writer added the empty-result guard and a malformed-old-rent rejection case.
2. Education's literal APR copy contained `8%%/12`; the writer corrected it to `8%/12`.
3. Reusing the confirmation dialog after education payoff left its education title on Bank actions. Bank accept/payoff now explicitly restore the Bank title.
4. The edge harness stored the first private vector's `before` dictionary by reference and later replaced its cash for the Bank vector. Independent arithmetic rejected **edges-v2**, despite passing native assertions. The writer deep-copied that capture and produced **edges-v3**, whose inputs and outputs reconcile. The rejected earlier raw captures remain intact.

No unresolved runtime correctness defect remains from this review.

## Provenance and limits

Accepted data: `focused-v4`, `edges-v3`, `native-v1`, `atomic-v1`, all thirteen `restart-*-v2` records, and the separately bound E4 records. Earlier preparatory runs are retained and are not silently relabeled accepted.

Each accepted command pins source before/after, runner, log, captured output hash and output freshness. Historical source archives were preserved **after** execution against those exact manifests. Two independent test entry points changed afterward: the restart driver's redundant inherited variable was removed and the edge capture alias was repaired. The auditor verifies exact archived members and current gameplay identity, and accepts those explicit unrelated test-only differences only when the invoked accepted test is unchanged. This is not a claim that the archive existed before execution.

Rendered/exported education interaction and broader release acceptance remain separate gates. These headless and constructed checks do not establish subjective playability or balance. The prior genuine native and E4 audit files retain their own frozen auditor hashes and are not overwritten by this combined result.

## Reproduce the combined audit

From the repository root, using the bundled Python runtime:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/findings/education-implementation-v1/audit.py --focused docs/codex/findings/education-implementation-v1/runs/focused-v4/focused-cases.json --edges docs/codex/findings/education-implementation-v1/runs/edges-v3/edge-cases.json --native docs/codex/findings/education-implementation-v1/runs/native-v1/native-route.json --command docs/codex/findings/education-implementation-v1/focused-v4.command.json --command docs/codex/findings/education-implementation-v1/edges-v3.command.json --command docs/codex/findings/education-implementation-v1/native-v1.command.json --log-command docs/codex/findings/education-implementation-v1/atomic-v1.command.json --restarts --e4 docs/codex/findings/education-e4-compatibility-v1 --output docs/codex/findings/education-implementation-v1/audit-education-v1.json
```

The recorded run exited 0. Focused `git diff --check` passed (Git only emitted its existing LF-to-CRLF notice for the independently edited release helper). Shared task/status reconciliation remains with the parent implementation agent.
