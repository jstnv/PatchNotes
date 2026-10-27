# QA Specialist challenge and benefit — 2026-10-25

**Historical benefit proposal:** The QA card-switch pairing below was replaced by [Feature synergy replay Bug search](2026-10-25-qa-synergy-search-design-v2.md) for the same-hand challenge. The user later revived the swap as a [separate pure-hand QA challenge](2026-10-25-qa-two-challenges-decision-v4.md). The same-hand training challenge below remains selected.

**Research trigger supersession, 2026-10-26:** The shared employee duty still applies regardless of specialty training, but the passive-after-any-productive-cycle wording below was superseded by [active Store Research only](2026-10-26-active-research-falloff-direction-v1.md).

## Scope and status

This is an Employees/Challenges **design** record. Affordability, wages and the player-facing hiring rule are outside this pass. Employee implementation and reopening the Employees button remain on hold. No gameplay or shared To Do List change is authorized here.

**LOCKED user direction, not implemented:** Every employee may take shared Feature Store research duty. An assigned employee contributes one guaranteed half research-cycle after a committed normal productive cycle; contributions stack and the Store charges each actual half-step. Specialty challenges unlock separate employee-owned benefits. The details and accounting questions remain in [the research design](2026-10-25-employee-research-half-steps-v1.md).

**LOCKED QA challenge criterion, not implemented:** Train a QA Specialist on a **single successfully committed Beta hand** that actually discovers at least one Hidden Bug through Search **and** fixes at least one Known Bug through Debug. Selecting both QA cards without both positive results does not qualify. Beta already resolves Search before Debug, so the newly discovered Bug can be fixed in the same hand. The selected criterion is the same-hand combination; employee ownership and immediate permanent training follow the locked employee challenge architecture. Applying the Production challenge's once-per-employee/project trigger convention to QA is a candidate detail, not a separate user ruling. The exact record and UI remain design details.

**CANDIDATE QA benefit, not approved:** A trained QA Specialist may, once per employee per project, let the player choose **one selected QA card** to perform the other QA operation for one later committed Beta hand: Search card as Debug or Debug card as Search. The card keeps its ordinary `beta_value`, card slot, productive cycle, refill and existing specialization/balanced treatment. Resolve all Search operations before Debug as usual. The benefit changes the player's available operation, not the number of cards, Bug pool, score, or chance to draw a card. The training hand cannot use its newly earned benefit; an employee trained in a prior project may use it on the first qualifying hand of a new project. Show the chosen operation before commitment. Cancelled, invalid, rejected or duplicate actions consume nothing. This is a proposal for user selection, not an approved buff.

## Why this challenge and candidate benefit

The current four-card Beta hand draws from seven candidate instances. QA has Search and Debug; Search reveals Hidden Bugs and Debug fixes Known Bugs. In the native command, Search requests commit before Debug requests, and the result reports actual `discovered` and `fixed` totals. The same-hand challenge therefore asks the player to assemble a useful chain instead of merely playing QA cards or receiving free Core. A trained QA card switch would help when the hand contains the wrong QA operation for the project's current Bug state, while preserving the normal opportunity cost of a selected card and productive cycle.

The earlier **across-two-hands** QA challenge is SUPERSEDED by the user's same-hand choice. The older generic Search-then-later-Debug proposal in the system design is historical. No QA card-switch result has been simulated or observed in play. The Production Specialist's curated-redraw study was weak and is not reused here.

## Candidate resolution and acceptance questions

1. Require an actual positive Search and Debug result on the same committed hand. A hand with zero Hidden Bugs cannot train through an ineffective Search; a hand with no Bug fixed cannot train through Debug. The fixed Bug need not be identified as the same individual Bug just discovered, since current project state tracks counts rather than Bug identities.
2. If the card-switch benefit is selected, make the choice before committing the hand. Recompute ordinary Search/Debug outcomes from the chosen operation using the card's existing value; count the QA card as QA for current specialization and balanced qualification. No extra action, card, redraw, free Bug removal or Core score.
3. Only successful commits may spend a project use. Whether to reject a switch that produces **zero extra useful work**, or permit a deliberate zero-effect use, is OPEN. Avoid silently consuming an employee benefit from a preview or rejected command.
4. Record the trained employee ID, project ID, challenge hand and any later project use so a phase exit, repeat callback or lossless reconstruction cannot award/spend twice. UI needs to identify a pending switch and the resulting Search/Debug operation before Play.
5. Compare the candidate against untrained matched Beta hands with Hidden, Known and no Bugs, QA-only and mixed hands, and short Beta windows. Measure actual Bugs fixed by launch, Review, productive cycles, redraw use and the fraction of projects where the benefit had a useful opportunity. This is a future design/evidence plan, not a request to run a simulation now.

## Open decisions

- Select or reject the **QA card switch**; a simpler alternative is carrying unused Search capacity into a later Debug, but that risks a passive Bug bank and needs its own cap and persistence rule.
- Decide whether the benefit may be spent on the same Beta hand by an employee trained on an earlier project and, if multiple trained QA employees exist, whether their uses may stack on one hand. The candidate allows the former and leaves the latter open.
- Decide the no-effect consumption rule, presentation, and exact identity/persistence shape. Keep QA distinct from current publisher Contract challenges and from shared research duty.

## Local session record

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at inspection, with extensive pre-existing shared worktree changes. Read CURRENT_STATE and TODO first; then Employees/Store design, thread notes, Beta source and repository provenance. Inspected status and targeted diffs before edits. This turn changed the two 2026-10-25 Employees thread notes, thread README/working notes, Employees and Store design, DECISIONS and CURRENT_STATE only. Targeted tracked-document `git diff --check` passed, the new QA note has no trailing-whitespace lines, and links in both dated notes resolve. The already modified shared TODO was not edited by this turn. No Drive, simulator run, gameplay/test edit, commit or push.
