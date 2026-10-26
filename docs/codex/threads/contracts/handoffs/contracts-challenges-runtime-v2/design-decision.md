# Contract-run challenge pilot — ACTIVE/TRIAL terms

2026-10-18 (America/Los_Angeles). The user explicitly authorized implementing the five named challenge types and approved the candidate publisher map, thresholds, $100 cash cap and 4 Promotion cap for a bounded trial. This supersedes the OPEN numerical status in [the prior direction](CHALLENGES-DECISION-2026-10-17-v1.md) for this pilot only. Final balance and wider rollout remain OPEN.

| Publisher | ACTIVE/TRIAL challenge |
|---|---|
| Ironclad | None; introductory Contract with current payout only. |
| SideStreet | No successful redraws; final Scope at most 12, with grade fading to zero over the next 4 Scope. Combine the two grades by the lower value. |
| Crown | Four final Core half-unit totals: max minus min at most 4 for full credit; grade fades to zero over the next 8 half-units. |
| Neon | Total final Core half-units at least 3 × final Scope for full credit; otherwise proportional grade. Zero Scope/zero Core earns zero. |
| Starwave | Each final Core target 14 half-units; sum of absolute deviations from the four targets fades grade to zero over 16 half-units. Over and under count equally. |

For each challenged Contract, grade is an integer from 0 to 10,000 basis points. Bonus cash is `floor(10000 cents × grade / 10000)` and bonus Promotion is `floor(4 × grade / 10000)`; each is capped at $100 and 4 points. Grade is fixed after the final required hand. No challenge can reduce the already-approved acceptance guarantee, base completion payout, or base Promotion. Bonus Promotion uses the same next successful launch boundary; failed launch preserves it. Freeze terms when a new Contract is accepted. Existing completed saves keep their original earned result with no retroactive bonus. This is a trial implementation decision, not a final balancing approval.

Runtime adoption requires source-pinned finance/checkpoint/rollback and UI verification. [Initial scorer evidence](CHALLENGES-FINDINGS-2026-10-17-v1.md) proves only grading and no-change parity. The new full-path candidate must demonstrate actual legal full/partial/miss outcomes before canonical reconciliation.
