# Player Fanbase screenshots — bounded review v1

2026-10-10, America/Los_Angeles. **USER-PROVIDED VISIBLE CAPTURE / OBSERVED SCREEN CONTENT.** The two attached PNGs were copied from the chat's temporary paths into this thread's [captures folder](captures/). The user confirmed title “3” is the third game in the same run and **Cult Following was not selected**. The screenshots contain no build hash, checkpoint or Review/launch details, so they are not a source-matched export audit. Do not treat them as final numerical approval.

| Capture | SHA-256 | Visible content |
|---|---|---|
| [Studio Fans history](captures/2026-10-10-player-fans-history-v1.png) | `7DFC84BE26F6C8C1A93395AFEA1CC24BEC23E3EE2BE2DEF07AFBA07A42A027C2` | Current Fans867; monthly rows41–52. |
| [Title “3” Monthly Sales](captures/2026-10-10-player-title3-sales-v1.png) | `00FEE2A7B99FD07ABF21C86EF61785F4DB69E5CE9273C21DC64BE7D5C0F4345A` | Age months1–5, earnings, Paid/Unpaid and selected age-month5 detail. |

## Visible arithmetic

Every shown Fan history row reconciles `starting + gained − lost = ending`. Month41 starts548; gains in months41–52 sum319, losses shown are zero, and month52 ends867. Months48–52 contribute317 of those gains (32+135+64+49+37); the earlier seven shown months add2. These are **studio totals across concurrent titles**, not per-title recruitment.

Title “3”'s five visible age-month rows sum3,318 units, gross$33,146.82, net$23,202.77, Paid$22,265.71 and Unpaid$937.06, matching the displayed lifetime totals. `Paid + Unpaid = Net` exactly. Its units decline1632→606→462→351→267. In age month5, `Paid $930.07 + Unpaid $937.06 = Net $1,867.13`. The UI's “2 / 2 earning halves · Complete” label describes earning progress; [current report code](../../../patch-notes/scripts/ui/monthly_sales_report.gd) separately labels an unpaid amount as waiting for calendar-month settlement. The screenshot therefore does not itself show a payment discrepancy. A later boundary/Continue would establish when the remaining$937.06 was paid.

## What this adds and what remains open

The screenshots show the Fans history and Monthly Sales panels populated and legible in a player capture. They give a real high-audience observation for discussion:867 current Fans and a recent five-month rise from550 to867 with no displayed losses, **without a Cult Following seed**. This is **not** a measured gain-rate outcome for title “3”: the Fans panel aggregates concurrent releases, while Monthly Sales shows one selected title, and the screenshots lack a calendar-month/title identity join. The screenshots also do not show the title's Review, frozen launch Fans, Fan Awareness, a later launch's sales conversion, or a Quit/Continue comparison. Source/export identity remains unconfirmed.

**Player feel, 2026-10-10:** Asked how the no-Cult Studio growth from550 to867 over those five shown months felt while playing; the user answered **“About right.”** This supports retaining the current gain behavior for the ongoing trial. It is subjective feedback on this run, not approval of the final8% coefficient, a per-title attribution, or a conclusion about longer compounding.

The older desktop `ShellExecuteW returned 5` blocker was later superseded by [current-source exported interaction](../../findings/export-interaction-20261010-v2/README.md), which passed bounded Cult/Fanbase UI and Continue checks on pinned profiles. These user images add a distinct higher-Fan visual capture, not an independent reproduction of that audited route. Continue to hold the8% gain,15% loss and quarter-Fan Awareness values as **ACTIVE/TRIAL**. The smallest next evidence for this capture is the matching title “3” Review/launch details (Review, launch Fans, Fan Awareness) and, if available, the source/export identity. A screenshot after the next calendar settlement would resolve the displayed unpaid amount's timing. No gameplay correction or final tuning decision follows yet.

**Later screenshot update:** The user supplied a [release list and0.4 Review continuation](2026-10-10-weak-release-player-feel-v1.md) from this run. It identifies title “3” as a9.3 Review, resolves that one missing detail, and records severe weak-release loss feedback. Frozen launch Fans/Awareness for title “3” remain unshown.
