# Staged entrant founding contract — source feasibility, 2026-10-25

**DESIGN / OPEN, no entrant implementation or population result.** This refines the [staged-entrant review](2026-10-25-staged-entrant-design-review-v1.md) under locked W6. A later rival must become a real Studio on one committed world boundary with no pre-founding income, expenses, Fans, Features or releases. The current source does not yet provide a legal saved representation for that state.

## Source-backed constraints

| Current path | Cycle-zero assumption | Required date-aware invariant |
| --- | --- | --- |
| `RunFactory.create_fresh_session` and `RunState._commit_studio_creation` | Creation requires completed cycle 0 and allocates the initial finance/Fanbase state there. | One explicit `founding_cycle`, equal to the committed world/player cycle; traits, permanent specialty and starting roster legal for that date. |
| `StudioFinanceLedger.create`, `_is_valid`, `_apply` | Initial funding is journaled at cycle 0/month 1; reconstruction always calls `create(initial_cash, rent)`; rent and payment rows use absolute month-minus-one indexing. | A funding transaction at the actual founding month, no earlier rows or bills, reconstruction from that start, and correct absolute-month lookup without zero-filled invented history. Preserve existing cycle-zero ledgers exactly. |
| `StudioFanbase.create`, `validate` | The ledger starts at cycle 0; validation expects `cycle / 2` monthly rows and replays every boundary from 0. | Start replay at founding cycle with zero prior months and validate only post-founding productive boundaries. Preserve old Fanbase bytes and replay. |
| `StudioCheckpoint._validate` | Startup trait cash receipts must occur at cycle 0. | Require each receipt exactly once on the saved founding cycle, and reject a mismatch between RunState, finance and Fanbase start. Education opening needs a separate date-aware schedule test if that trait is offered. |
| `RivalWorld` and `RivalWorldCheckpoint._read` | World registration is initial-only; ordinary rival save rows require a nonempty pre-1980 archive. | Atomic one-time boundary admission, stable ID and policy, explicit entrant kind/founding date, empty incumbent archive only for validated entrants, rollback on rejection and exact cold Continue. |

First private foundation version should test a single **untraited, base-funded** entrant on a predeclared even boundary, including its first rent, first real hand, duplicate/rejected admission and Studio checkpoint round trip. This is a *trial recipe*, not approval of entrant resources or cadence. A second version can cover trait funding, education, loans and Store access; a later world study can then compare publication, player market exposure, save growth and CPU. The existing max-eight codec check is a technical bound, not an approved cap.

The [Theme-only study](2026-10-25-public-theme-variety-finding-v1.md) shows why population and variety should be assessed together: six rival Themes and unchanged release cadence increased the Action/Fantasy player's earned units in both measured seeds. Do not compensate by changing market coefficients without an independent player challenge study. No shared TODO edit or canonical source change follows from this source feasibility note.
