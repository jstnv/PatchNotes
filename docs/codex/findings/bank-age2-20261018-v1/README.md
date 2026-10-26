# Bank still-unpaid age2+ follow-up — 2026-10-18

**Investigation complete. The requested live age2+ state is NOT REACHABLE under the retained Bank-blocking rule; it is not a passing exported age2 test.** A different legal Ironclad route and an independent Bank-only partial-payment state confirm the source constraint. No gameplay change, edited cash/bills, forged dates, free Wait, hidden-income injection or player-save access. [Source and input hashes](source-pin.json), [independent audit](audit.json), [session log](../../logs/2026-10-18-bank-age2-feasibility-v1.md).

Main / HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, existing dirty checkout. Mechanic identity `1e7e9c1f1c5766d209a5d0826cf07982c528b6e4b132087e08130dcb0c30cb82`, unchanged from the preceding queue completion. Both historical prefixes retain their original recorded lineage; these are legal continuations on current source, not fresh recreation of the entire historical campaign.

## Why the target cannot be produced normally

The [retained economy rule](../../design/economy-banking.md) requires existing rent/payroll/Bank arrears to be cleared by the next productive action. Source independently establishes:

1. `run_state.gd:1322` is the ordinary calendar increment and advances exactly one cycle. `advance_calendar_cycle` delegates to the same productive transaction; there is no legal player Wait that bypasses it. Checkpoint hydration restores recorded time; it does not advance it.
2. `StudioFinanceLedger._blocking_unpaid_unchecked`, lines154–160, includes Bank installments and excludes only student debt.
3. `StudioFinanceLedger._apply`, line456, rejects a productive plan when blocking arrears exist before the action and any blocking arrears remain afterward. This validates the actual mixed payment plan, including rent and education order.
4. A first missed Bank installment can therefore remain unpaid at its original due cycle (age0). Any next committed cycle must clear it, allowing **paid recovery age1**. Rejected actions and free redraws cannot age it. Inductively, a normally issued unpaid Bank bill cannot reach age1 or age2+ through these commands.

This is a reachability restriction, not a change to the generic aged-bill representation or credit formulas. Existing age2/age4 policy fixtures remain useful **synthetic** coverage. Supported historical saves with already-aged bills are a distinct provenance question; none was substituted for a legal current route. Reopen live age2 acceptance only if the blocking rule changes explicitly or a genuine public-command counterexample is found.

## Alternate legal Ironclad route

Input: the actual Studio49 `education-distressed-committed/checkpoint.33.json`, cash$151.92, active $500 Bank loan and College Dropout debt. Unlike the preceding new-Development attempt, this route uses the available Ironclad advance, real Contract hands, deliberate priority changes and a free redraw. [Executable probe](legal_route.gd), [full action/finance evidence](route-v1.json), [exact tape](route-v1.json.tape.json).

| Action | Cycle | Cash | Observation |
|---|---:|---:|---|
| Accept Ironclad |49|$551.92|Real $400 advance; zero cycles |
| Deal, then change priorities |50|$118.06|Current dues paid normally |
| Play Split Screen / Scrolling / Sound Pass / Sound Pass |51|$118.06|First hand; no final payout |
| Change priorities again |52|$0|New due52 arrears: rent$353.96, Bank$44.59, education$70.68 |
| Try another valid priority change |52|$0|Rejected; complete state/RNG unchanged |
| Redraw one card |52|$0|Accepted zero-cycle action; exact bill/finance state unchanged |
| Play lowest-paying admissible finishing hand |53|$905.77|4-Color Palette / Controller / Technology Pass / Graphics Pass; genuine $1,375 receipt clears all $469.23 arrears |
| Dismiss result → Studio |53|$905.77|Durable Studio generation; independent cold restore passes |

All35 four-of-seven finishing combinations were assessed read-only through the actual Contract planner and ordinary productive preflight. Their payouts range$1,375–$1,916.66; every one can recover the balance. Only the minimum-payout hand was played. This is a bounded current-hand screen, not35 full gameplay paths or a global search.

The original due52 Bank bill retains its ID/date, principal$41.67, interest$2.92 and one $44.59 payment at53, with recovery age1. Rent retains its first $146.04 payment at52 and remaining $353.96 at53. Education retains principal$40.72/interest$29.96. Credit at52 is627→607 (rent−5, Bank−10, student−5); no extra monthly credit tick is created at53. No bill is reset or removed from history.

## Independent Bank-only guard

Input: actual exported Studio51 `bank-before-cold/checkpoint.34.json`, SHA256 `e8b27e5fb85d0c2389ecf921738e792d00db2185c2ecb1dd00b5a3e621b08dd0`. Ordinary Begin Development reaches52 with rent fully paid and the new Bank installment paid$44.17 of$44.59: **only42 cents of blocking Bank debt**, plus nonblocking education$70.68. Interest$2.92 is already paid; remaining Bank principal is42 cents.

Two different valid priority distributions both reject without changing cash, RNG, time, payments or credit. Free Design entry is accepted; an unaffordable real Bank payoff rejects atomically. The displayed runtime explanation names the42-cent unpaid balance. Thus the earlier failure is not solely caused by unpaid rent or an invalid priority distribution. [Probe](bank_only.gd), [result and text](bank-only-v1.json), [tape](bank-only-v1.json.tape.json).

Active Development does not export a checkpoint. The actual preceding Studio51 payload is separately published into an isolated normal `StudioCheckpointStore` and restored in another process, preserving every field. This verifies the retained committed state; it is not a new exported Quit/Continue interaction.

## Checks and evidence boundary

- Alternate route22/22; Bank-only guard12/12; both include exact in-process replay and rejected-action atomicity.
- Two fresh-process replays reproduce9 Ironclad actions and5 Bank-only actions, including rejections.
- Two ordinary isolated Studio-store saves and two cold restores pass: recovered Studio53 and last committed Studio51; exact cash/bills/history/loan/RNG are preserved.
- Existing expense-policy fixture functions pass86/86, including synthetic age tiers and recovery. [Wrapper](policy_ages.gd) redirects evidence output only, preserving canonical test code and its previous artifacts.
- Final nine processes pass132 assertions in total, plus the field-level independent audit. The audit count is not a count of independent scenarios. [First checks](checks.json), [successful save retry](save-recovered-v2-run.json), [remaining cold/replay checks](finish-checks.json).

The first storage probe failed because its temporary validator owner was not retained. The harness now owns the mapper throughout the save; the retry passes. That failed result remains preserved. Existing six-object shutdown warnings are retained. No gameplay or production verifier was edited.

No new export or rendered interaction was run: the requested live age2 state is blocked before a current-build graphical recipe exists. The earlier exported age1 acceptance retains its original scope. B7 overall remains PARTIAL for human quote comprehension and the inaccessible older-education/newer-Bank elective payoff. Every exported credit tier, final balance, clean-machine and release readiness remain unclaimed. No commit or push.

Reproduction: `python run.py <new-label> legal_route.gd`, then a new label for `bank_only.gd`; the retained helpers show exact cold/replay arguments. Use new labels and new store directories for new evidence. Profiles and outputs are isolated within this finding; `.codex-godot-temp` and original prefixes remain untouched.
