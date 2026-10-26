# Publisher overnight findings v1

2026-10-22. **Completed bounded read-only evidence; new design remains PROPOSED.** This pass tests the frozen support candidate and recommends renewal/failure rules. It does not modify canonical gameplay or implement v4. [Predeclaration and bounded follow-up](studies/publisher-overnight-20261022-v1/PLAN.md), [exact commands](studies/publisher-overnight-20261022-v1/COMMANDS.md), [artifact/accounting audit](studies/publisher-overnight-20261022-v1/audit-v1.json).

## Source and comparison boundary

Dirty shared `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; [entry status/diff summary](studies/publisher-overnight-20261022-v1/provenance.json). The current TODO still records publisher progression as DESIGN review needed; no approved adoption or active implementation of these new rules was verified. Canonical changes by other threads were preserved.

All six new simulation runs use the read-only Contracts-owned [support candidate](simulators/publisher-progression-support-market-v1/variant.json). Exact gameplay identity: `b53d9a31b1f54155324e3ec942d86baedd7facae9adf519fd644690326fc8b07`. Candidate manifest identity: `4e7a533335d8d0f1b17f3508414c2e49088a4ca88de9376a1b76f4d0aa46e469`; original canonical base `5edfa7878cd17904281d7cf7f2cf907e67b5f40edb4d9db83b3f99580f2aa415`; commission parent `f64b1f8e46df066fe7587bc9ab2d22aec7a36e56874345a2c15022ab484da568`. `baseline_drift=true`; current captured canonical identity is recorded per run, including `4fbcd029fa6382e673e8e0e3db17e7e25e8926998b9c6090eef3a21afcdd356d`. These experiments do not establish byte-current canonical behavior. Godot4.7.1, Python, executable/runner/policy hashes, imports, isolated profiles and manifests are retained in each bundle.

The weak-game pairs copy the entire legal Sports/Fantasy seed1112 post-commission Studio envelope at cycle53, four releases, R35/I15 and$9,922.15. Each support/self pair has identical input, initial state, RNG, source and bound; the only deliberate pair choice difference is accepting support. The policy uses detached visible cards with Feature-first ordering, no hidden future search. Game5 uses2/2/2 or3/3/3 Design/Alpha/Beta hands; Game6 uses5/7/6 and Game7 uses2/2/2. Both pairs reach common calendars, and the audit retains per-cycle deltas rather than comparing different end dates.

Canonical files changed concurrently during this pass: the audit retains four captured canonical identities. All six new runs retain the same candidate manifest and mechanics identities. No comparison mixes canonical revisions or treats a changing canonical snapshot as a matched control. All nine new cases observed zero arrears; these results do not establish distressed-start rescue.

## Legal outcomes

| Case | Commands | Final cycle / total releases | Result and boundary |
| --- | ---: | --- | --- |
| Weak2 support | 64 | 86 / 7 | Game5 Review2.8, age6 actual512 units, missed both targets; I stays15; valid Studio checkpoint |
| Weak2 self | 64 | 86 / 7 | Same starting state/schedule; valid control checkpoint |
| Weak3 support | 67 | 89 / 7 | Game5 Review4.5, age6 actual855 units, missed both targets; I stays15; valid Studio checkpoint |
| Weak3 self | 67 | 89 / 7 | Same starting state/schedule; valid control checkpoint |
| Second support at I25 | 18 | 86 / 7 | Quote and$915 funding accepted; project completes; **no valid ending Studio checkpoint** |
| Reduced second support | 15 | 83 / 7 |1/1/1 minimum phase schedule reproduces the missing checkpoint; exact fresh replay |
| Full commission after weak2 miss | 28 | 105 / 8 | Review8.7/Scope30, full$6,000 fee; R35→50 and I15→30; valid Studio checkpoint |
| Campaign revival after cutoff | 19 | 94 / 8 | Legal$100 campaign after age26; renewed title sales all belong to Studio; valid checkpoint |
| Support after recovered I30 | 18 | 112 / 9 | New support quote accepted after full commission recovery; **no valid ending Studio checkpoint** |

Runs: [weak pairs](sims/publisher-overnight-weak-pairs-20261022-v1/run-report.json), [second support](sims/publisher-overnight-renewal-20261022-v1/run-report.json), [reduced reproduction](sims/publisher-overnight-renewal-reduced-20261022-v1/run-report.json), [recovery commission](sims/publisher-overnight-recovery-20261022-v1/run-report.json), [revival](sims/publisher-overnight-revival-20261022-v1/run-report.json), [support after recovery](sims/publisher-overnight-recovery-renewal-20261022-v1/run-report.json). All360 recorded commands were accepted under the private source. Command execution success does **not** make the three missing-checkpoint cases acceptable for adoption.

At cycle86, Weak2 support has$17,812.90 versus$17,810.80 control, a+$2.10 difference; both have425 Fans. Its supported Game5 has539 units/$3,769.22 raw net, $753.84 recoup and$3,015.38 Studio earnings. At cycle89, Weak3 support has$20,953.21 versus$21,009.32 control, a−$56.11 difference; both have466 Fans. That supported title has940 units/$6,573.42 raw net, $875 recoup and$5,698.42 Studio earnings. Later games and real portfolio settlement are included. These are policy-conditioned results from one legally earned starting state, not estimates of success probability or broad balance.

## Miss, recovery and expiration

Both supported misses generated one final failed assessment and zero new Investment, preserving R35/I15. Their legal later Studio quotes did not offer same-capacity support; ordinary later releases did not manufacture a reward. The fresh-process recovery continuation fully delivered a later commission and reached I30. A subsequent fresh run offered and accepted support using that earned capacity. This establishes a legal recovery path under the existing numeric rule; saved repeated-deal completion remains blocked below.

The weak2 title's 20% recoup stopped below the$875 cap. By age26 it was dormant with raw net376,922 cents, recoup75,384 and Studio earned301,538. That quiet boundary alone could not prove that newly earned post-cutoff sales avoid recoup. The declared paid revival generated10 more actual units and6,993 cents raw net at ages27–28. Recoup remained75,384, while Studio earned rose by the full6,993 cents and settled on the normal boundary. At age34, raw383,915 = publisher75,384 + Studio308,531. The original age6 failed assessment and I15 remained unchanged. The campaign cost10,000 cents; this is a cutoff test, not a profitable-campaign recommendation.

This closes a legal **post-expiration positive-sales** witness and both-target miss witness. It does not cover positive earnings on the exact23→24→25 transition, a Review-only miss, a units-only miss, or every global settlement alignment. No invented score/unit/cash values or free time advances were used.

## Reproducible save blocker

The existing candidate offers a second support deal after the first success. The source checkpoint validator contains `if r.support_deals.size() > 1: return "Support pilot allows one deal"` in [StudioCheckpoint](simulators/publisher-progression-support-market-v1/project/scripts/persistence/studio_checkpoint.gd). The legal18-command route and reduced15-command route both finish in Studio with `artifacts.studio_checkpoint` empty. The recovered I30 route reproduces the same observable failure. The reduced tape reproduces all15 accepted commands and final state exactly in a fresh process.

The runner reports these campaigns as completed because it checks the command/release goal and treats checkpoint export as an optional artifact. Adoption acceptance must explicitly require a nonempty, restorable Studio envelope. Do not “fix” the result by relaxing the validator to ignore history or dropping older deals. Implement chronological validation of multiple deals, accepted capacities, qualifying events and aggregate rights-to-finance reconciliation. The exact guard is source evidence; the runner does not print its internal capture-error string.

## Verification and retained limits

- Existing successful support baseline: fresh46-command exact replay before new experiments.
- Weak2 support: fresh64-command replay,65 telemetry samples verified.
- Reduced save blocker: fresh15-command replay,16 samples; replay success preserves the invalid-save ending rather than curing it.
- Revival: fresh19-command replay,20 samples.
- Recovery commission: fresh28-command replay,29 samples.
- The [independent audit](studies/publisher-overnight-20261022-v1/audit.py) passes409 checks of source/input/state/telemetry identities, same-state pairs, accepted bounds, exact funding, rights, journal/monthly earned/settled/unsettled sums and nonoperating funding classification. It explicitly retains all three checkpoint acceptance failures. These checks do not establish corruption resistance or all Bank behavior.
- Six run invocations plus five replay invocations stayed within the declared12-invocation ceiling; no timeout or rejected gameplay command occurred. Existing variants and player saves were not edited. Godot logs retain a six-ObjectDB-instance exit warning; no claim is made that this warning was fixed.
- The existing shared comparator's executed-query hashing defect was already documented and was not modified or retried. Direct audited pairs use the whole initial envelope, initial state/RNG and exact source, with matched-cycle deltas. No official comparator report is claimed.

Fresh runs successfully restored real post-support Studio envelopes to continue play, including recovery and revival. This is simulation-envelope continuation; native disk-coordinator migration, corrupt-save rejection, exact whole-state roundtrip, exported Continue, UI, audible and human comprehension tests remain separate.

## Design recommendation

Use [proposal v4](PUBLISHER-RENEWAL-AND-FAILURE-PROPOSAL-2026-10-22-v4.md) for review: retain the separate trust/capacity model, no debt or rating loss on support misses, and require a new qualifying result for repeat support. A full commission supplies a recovery route; success remains qualifying when Investment is already100. Wait for the latest support assessment before renewing, and do not accumulate a backlog of success tokens.

The [renewal model](studies/publisher-overnight-20261022-v1/renewal-model.json) compares2,328 synthetic boundary states and an illustrative12-success path. The old rule permits nine successful support acceptances from I15 through I95, then disables support at100. A naive clamped threshold permits another package after a cap-level miss without new success. The event-based proposal avoids both examples. A second process produced byte-identical model output. This arithmetic is not legal cap-reaching gameplay or implementation of the new policy.

The [offer and finance specification](PUBLISHER-OFFER-AND-FINANCE-SPEC-2026-10-22-v1.md) supplies exact candidate quote/result copy, funded-start flow, title ownership, cash-versus-marketing recoup disclosure and finance fields. The [review handoff](HANDOFF-PUBLISHER-OVERNIGHT-2026-10-22-v1.md) lists the concrete source gaps and acceptance gates. All numeric terms and v4 renewal remain **PROPOSED**; final balance and broader publishers stay deferred. The genuine adoption blockers are the missing saved-repeat path, transaction/quote/display gaps from the prior reviews, and a design ruling on the proposed pilot.
