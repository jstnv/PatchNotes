# Cross-title Fan recruitment overlap screen v1

2026-10-08, America/Los_Angeles. **READ-ONLY observed journals plus a labeled fixed-journal overlay; no unique-buyer observation or design approval.** Source is the isolated quarter-Awareness trial `codex/fanbase-quarter-trial` at `bd450a9e4e8d83ece1478cdf5a16526432e36cce` plus its two recorded uncommitted files. Four already captured legal routes were inspected; no new gameplay route or source edit was run. Main still lacks Fanbase runtime.

## What the current rule counts

`StudioFanbase.plan` keeps one studio Fan total but computes each title's recruitment separately. For each positive-Review title it reserves that title's frozen launch Fans from cumulative earned units, then applies its provisional Review-dependent conversion to the remaining estimated new buyers. The title's cumulative gain target is charged incrementally. Sales records contain copy counts, not buyer identities; the branch cannot determine whether a person counted by one title also buys another. The per-title reserve limits some repeat counting within a title, but does not establish cross-title uniqueness.

## Existing legal capture screen

From each route's final monthly Fan journal, count a boundary as **multi-earning** when at least two titles have positive earned units, and **multi-recruiting** when at least two titles have positive `new_fans`. The hypothetical overlay replaces a multi-recruiting boundary's sum of gains with its largest per-title gain while holding every captured sale, Review, loss and later journal entry fixed. It is an arithmetic sensitivity, **not** a playable revised rule: altered Fans could change later launch Awareness, sales and reserves.

| Existing capture | Boundaries | Multi-earning | Multi-recruiting | Recorded new Fans | Hypothetical same-boundary reduction | Recorded final Fans → fixed-journal overlay |
|---|---:|---:|---:|---:|---:|---:|
| [Quarter route](quarter-trial-v1/README.md) | 43 | 7 | 2 | 259 | 2 | 259→257 |
| [Restrained weak/recovery](quarter-trial-v1/README.md) | 35 | 3 | 1 | 206 | 1 | 165→164 |
| [Near-neutral primary](near-neutral-v1/README.md) | 30 | 8 | 0 | 97 | 0 | 79→79 |
| [Near-neutral alternate](near-neutral-v1/README.md) | 31 | 7 | 0 | 97 | 0 | 77→77 |

The quarter route's simultaneous positive gains are month28: 5+1, and month36: 21+1. The restrained route has month28: 18+1. Both near-neutral continuations have overlapping earned sales, but never two titles recruiting Fans on the same boundary. In the quarter route, Game2/3/4 contribute 97/50/112 new Fans over their whole lives; total259. This is a sum of estimates, not proof of 259 distinct people. The fixed-journal overlay's one-Fan reduction before Game4 and two-Fan reduction before Game5 do not cross the selected quarter-Awareness integer step at those captured launches; this does **not** verify a propagated policy or cash outcome.

Checks: for all139 monthly rows, starting Fans plus recorded gains minus losses equals ending Fans, and per-title gain/loss details sum to the row totals; final row equals final Fans. **560 arithmetic assertions pass.** The four compressed trace SHA-256 hashes, in table order, are `E21B716467CDF1295562749FC5E9AFDEE9716F8E526055976C7A62561B248410`, `1B7385773302AFC52BFB584AD13704D66370746D33C27A233F3518ED9F644EF6`, `4BD4988E8B8D76FA52A03041169FF41924E32C7F4396064C7171EA9595D558B4`, and `476DF918DF98880F18A2A9AA16E148275FE68049C93115CC1C9F7C48CC8AE4BA`. Source `studio_fanbase.gd` SHA-256 is `8EAFCE2C4AED02A10FE745AFEBA1FA773CBE5DE1C3D716123D4AD7A85D1F7425`. The branch and modified two-file status were checked read-only; Git ownership required per-command `safe.directory`, without changing Git config.

## Design reading

These routes make **same-boundary** double recruitment a small accounting sensitivity. They do not bound buyers shared by titles across different months, since no buyer identities exist. The large difference between multi-earning and multi-recruiting boundaries also shows that concurrent sales alone do not imply concurrent Fan gains. A global de-duplication rule would be a new modeling assumption, not a correction supported by these traces.

**Recommendation — ACTIVE/TRIAL only:** retain the branch's per-title eligible-unit proxy for the next playable comparison; do not add a same-boundary de-duplication change from this screen. Revisit cross-title overlap only if a longer legal portfolio route or player capture reveals material Fan compounding, and state the assumed audience-sharing rule before requesting runtime work. The 8% gain scale, 15% loss scale, reserve size, overlap rule and final Fan Awareness mapping remain OPEN or ACTIVE/TRIAL as documented; this screen locks none of them. The separately dispatched near-neutral v2 capture remains a distinct question.
