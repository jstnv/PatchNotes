from pathlib import Path

root=Path(__file__).resolve().parents[4]
todo=root/'docs/codex/TODO.md'
text=todo.read_text(encoding='utf-8') # Fresh shared-list read, immediately before minimal edits.
old='Still-unpaid age2+ and every exported credit tier are not claimed. The [2026-10-18 bounded age2 attempt](findings/queue-20261018-v2/BANK-AGE-ATTEMPT.md) stopped at the ordinary productive-cycle preflight rejection at cycle50/cash0; target-dependent checks failed and the legal rejection is retained. This does not close age2+ acceptance.'
assert text.count(old)==1
new='**Still-unpaid age2+ — NOT REACHABLE under the retained blocking rule; investigation COMPLETE, not exported PASS,2026-10-18.** A [different legal Ironclad route and independent42-cent Bank-only guard](findings/bank-age2-20261018-v1/README.md) confirm that a productive advance must clear every existing blocking bill; normally issued unpaid Bank debt stays at age0 or recovers at age1.132 assertions across nine passing processes, two cold Studio restores and two exact fresh replays pass;437 independent field checks reconcile the evidence. Reopen this route only after an explicitly changed rule or a genuine public-command counterexample. The [earlier failed attempt](findings/queue-20261018-v2/BANK-AGE-ATTEMPT.md) stays retained. Every exported credit tier remains unclaimed.'
text=text.replace(old,new,1)
entry='**2026-10-18 Bank age2+ follow-up — reachability investigation COMPLETE; live/exported target NOT REACHABLE under current rules.** [Alternate legal routes, source proof and results](findings/bank-age2-20261018-v1/README.md) · [session log](logs/2026-10-18-bank-age2-feasibility-v1.md). Ironclad reaches a new unpaid due52 and recovers at53; valid attempts to advance with debt reject atomically. An independent partial Bank-only balance of42 cents confirms the same guard without rent arrears. Legal redraws cost zero cycles. Current progression therefore cannot leave a Bank bill unpaid through age2. No rule was changed or synthetic fixture labeled as gameplay. B7 remains PARTIAL for human quote comprehension and the inaccessible elective-payoff combination; no runnable age2 route remains queued absent a changed rule or counterexample.\n\n'
marker='## Dispatch and shared constraints\n\n'
assert marker in text
todo.write_text(text.replace(marker,marker+entry,1),encoding='utf-8')

state=root/'docs/codex/CURRENT_STATE.md'
text=state.read_text(encoding='utf-8');title,rest=text.split('\n',1)
entry='**2026-10-18 Bank age2+ investigation:** an alternate legal Ironclad route and an actual42-cent Bank-only partial state confirm the existing production-blocking rule. Normally issued unpaid Bank bills cannot age beyond their due cycle; a successful next cycle must clear them, yielding recovery age1.132 assertions/nine passing processes, exact cold restores and two fresh replays pass. The live/exported age2 target is **NOT REACHABLE under current rules**, not a passing playtest; B7 human/payoff limits remain. [Evidence and source proof](findings/bank-age2-20261018-v1/README.md). No gameplay changes, commit or push.\n\n'
state.write_text(title+'\n\n'+entry+rest.lstrip('\n'),encoding='utf-8')

economy=root/'docs/codex/design/economy-banking.md'
text=economy.read_text(encoding='utf-8')
text+='\n## Bank aged-bill reachability evidence — 2026-10-18\n\nThe existing blocking rule is unchanged. [Two legal continued routes and source analysis](../findings/bank-age2-20261018-v1/README.md) establish that, for normally issued current-game Bank bills, an unpaid balance cannot advance beyond the original due cycle: the next productive action must clear all blocking rent/payroll/Bank balances. Even42 cents of Bank principal blocks with rent already paid. A successful recovery may record age1; free actions do not age bills. Thus still-unpaid age2+ is not a runnable ordinary acceptance route under the retained rules. Generic age2/age4 credit calculations remain covered by synthetic fixtures, not live/exported Bank evidence. This is evidence of a rule consequence, not a proposal or permission to relax the blocker. Human quote comprehension and the inaccessible elective-payoff combination remain separate B7 limits.\n'
economy.write_text(text,encoding='utf-8')
print('Updated TODO, CURRENT_STATE and economy evidence without changing gameplay rules')
