# QA pure-hand challenge and Search/Debug swap — 2026-10-25, version 3

**Historical proposal:** The user subsequently selected **two QA challenges**, required **three** committed pure Search and **three** committed pure Debug hands across projects, and ruled that commits count even without Bug output. After training, a new pure hand arms one swap for one later hand in that project. The earlier either-hand/positive-result recommendation below is **SUPERSEDED** by [version 4](2026-10-25-qa-two-challenges-decision-v4.md).

## User direction and status

**SELECTED qualitative direction; NOT IMPLEMENTED:** The user wants the ability to swap a selected QA card's **Search** and **Debug** operation as an earned employee benefit. The challenge for this benefit is to play **pure Search or pure Debug hands**. This revives the earlier card-switch idea with a distinct training condition; the earlier once-per-project use limit was only a candidate and has not been reapproved. This note does not change the established same-hand Search-plus-Debug challenge or its Design/Alpha synergy Bug-discovery benefit while the relationship between the two QA challenge tracks is being clarified.

**OPEN exact challenge threshold:** “Pure” means a committed four-card Beta hand whose selected cards are all Search, or all Debug. It is not the same as the existing QA specialization, which accepts any mix of QA Search and Debug cards. The user is choosing whether **either** pure hand trains the swap or **both** a pure Search hand and a pure Debug hand are needed, and whether a hand must actually discover/fix at least one Bug. Until that answer, no exact trigger is LOCKED.

**CANDIDATE benefit operation:** Before committing a later Beta hand, a trained employee lets the player switch one selected QA card from Search to Debug or Debug to Search. That card retains its printed `beta_value`, QA category, card slot and normal productive-cycle/refill cost. Resolve all Search before Debug as the current Beta action does. No extra card, free Bug removal, Core score, redraw or cycle. A canceled, rejected or duplicate action consumes no use. The count and refresh of uses, same-hand use after training, and multiple-employee stacking are OPEN.

## Current-source feasibility

Beta presents seven candidates and requires four selected instances. The source has one renewable Search definition and one renewable Debug definition, so several separately drawn instances of either can coexist; an all-Search or all-Debug four-card hand is legal. QA specialization currently checks category, not operation, and applies to either pure hand. Debug carries twice Search's definition weight inside QA. At the highest current QA priority (50%), an ordinary fresh seven-card pool with all categories available draws Search with probability 1/6 per slot and Debug with probability 1/3. Thus the chance that this fresh pool contains at least four Searches is about **1.76%**; for four Debug cards it is about **17.33%**. These are source-derived initial-pool arithmetic, not observed play rates: retained cards, redraws, depleted finite categories and later hands change reachability. Requiring one of each pure hand in one project may be much harder than the previous mixed-hand challenge and needs a bounded reachability review before any implementation handoff.

**Design recommendation, not a ruling:** Let either pure operation hand with an actual Bug discovery/fix train the swap, as a separate QA track. The rare four-Search hand would then be an alternative route rather than a mandatory second gate. If the user wants each swap direction trained separately or wants both pure hands, record that explicit choice and check reachability before implementation.

## Dependencies and open decisions

1. Clarify whether this is a **second QA challenge and reward** alongside the mixed Search/Debug challenge and synergy Bug discovery, or a replacement for that earlier QA track.
2. Clarify whether one pure hand qualifies or both pure operations are required, and whether the hand needs positive Bug discovery/fixing rather than only a successful commit. A further unselected possibility is directional training: pure Search unlocks Search-to-Debug, while pure Debug unlocks Debug-to-Search. Do not assume both swap directions unlock from one hand until this is settled.
3. Choose the swap's use limit and reset, whether a newly trained employee can use it in the same project on a later hand, and how multiple trained QA employees combine. Any chosen operation must be visible before Play.
4. Preserve existing Beta Search-before-Debug order, QA specialization and Balanced Operations qualifications, actual Hidden/Known/Fix accounting, hand/refill costs and deterministic rejection/replay. This proposal is separate from every employee's shared Store research duty.

If the user selects two QA tracks, an earned swap could help assemble the separate mixed-hand Search-plus-Debug challenge on a later hand. That hand would still need to **actually** discover and fix Bugs; swapping alone would not train the synergy-search benefit. This interaction is a design reason to keep the rewards distinct, not an approved unlock sequence.

## Local session record

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at inspection; existing shared worktree edits preserved. Read CURRENT_STATE and TODO first, then QA notes, Beta card definitions/command, priority rules and targeted diff. Changed this version-3 thread note, historical banners in versions 1/2, thread README/working notes, Employees design, DECISIONS and CURRENT_STATE. Targeted tracked-document `git diff --check` passed; all three QA dated notes have zero trailing-whitespace lines and their local links resolve. The already modified shared TODO was not edited by this turn. No gameplay/test change, simulator run, Drive, commit or push.
