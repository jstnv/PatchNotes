# AI studios and competitors

Design draft started 2026-10-09 (America/Los_Angeles) from the user's competitor vision. This document records intended behavior and open decisions; it does not describe implemented gameplay. See [core and Studio](core-and-studio.md), [Genre specialties](genre-specialties.md), [Studio Traits](studio-traits.md), [Feature Store](feature-store-progression.md), [Fanbase](fanbase.md), and [sales and lifespan](game-lifespan.md) for the current shared systems.

## Purpose and boundary

Competitors are other studios operating in the same world and time as the player's studio. They make games, build audiences and resources, and continue developing while the player takes productive actions. Their releases create a living history of the games industry. The first design slice covers their background project simulation and high-Review news.

Every released game, including a competitor's, belongs in the world market record. The future market design will decide how releases change the market and influence later Reviews. This document does **not** set a market share model, Review modifier, competitive sales penalty, or change to the player's locked Month 1 units formula.

## User-set direction — LOCKED at the structural level

1. Multiple AI studios develop games concurrently with the player. Each studio persists across projects rather than being a fresh random rival attached to one player project.
2. Each studio has its own permanent Genre specialty, selected traits, bankroll, Fanbase, Feature Store ownership and progression, active project, and release history. These resources are separate from the player's and other studios' resources.
3. Their projects follow a development path similar to the player's: acquire usable Features, make a game, receive a Review, release it, earn money and gain or lose Fans through the relevant systems, then use their resources for later games. Their choices and outcomes should emerge from their studio state rather than a rating rolled only at launch.
4. January 1980 begins with a small incumbent cohort. Those studios already have games in the market and unlocked Feature pools, plus the resources and history needed to support that starting position. Their opening games are guaranteed to receive higher Reviews than the player's first game.
5. More studios found later. New entrants use the same starting framework of specialty, traits, bankroll and Feature access as a newly created player studio; the exact entrant policy and any AI-specific adjustments remain OPEN.
6. A high-reviewed competitor release produces a notification at the start of the **following calendar month**, rather than immediately when the rival releases.

The player's first game cannot reach a 10.0 Review under its starting Feature access, cash and rent constraints. The opening guarantee is literal: each designated incumbent opening game must strictly outscore any legal player first-game release. Determine the highest legally attainable first-game Review across starting builds and timing, then choose and verify an incumbent opening rating floor above it. Preserve the player's ordinary Review calculation; revisit the floor if future starting content or economics raises the player ceiling.

## Shared clock and studio state — proposed first simulation contract

Use the run calendar: January 1980, two successful productive cycles per month. On each committed run cycle, each active studio may advance one legal background action. Browsing, redraws, rejected player actions, loading a checkpoint and other zero-cycle navigation do not move the world. Rival progress and any due releases commit with the same cycle boundary, with deterministic run-owned randomness. This is a **PROPOSED** action granularity; exact AI policy and performance limits remain OPEN.

Each studio needs a stable identity and at least: name/founding date, Genre specialty, chosen traits, cash, Fans, owned and queued Features, familiarity/unlocks, current project/phase/progress, completed releases, and the state of its decision policy and random stream. A release needs a stable identity, studio, title, Genre/Theme, Review, launch date, frozen launch inputs and subsequent sales/Fan/finance history as applicable. An incumbent's pre-run titles begin as historical release records; their initial cash, Fans and Store inventory must reconcile with that history under a later starting-state rule.

The studio should choose projects and legal actions from what it owns and can afford. Its specialty grants a starting roster under the same structural rule as the player; a project may choose its own Genre independently. Traits should use existing definitions where their effects make sense for an AI studio. Exact trait choices, AI planning styles and handling of player-facing trait effects remain OPEN. Feature ownership, prerequisites, familiarity and research belong to the studio itself. Later entrants begin with the current studio-creation structure rather than inheriting incumbents' inventories.

**LOCKED direction, 2026-10-09:** AI studios draw and resolve actual legal card hands. Design, Alpha and Beta use the same candidate eligibility, finite/renewable supply, selection limits, redraw budget, priorities, synergies, costs, Bugs, QA, Marketing and phase/Review rules that apply to the player. An AI decision policy chooses among legal actions and cards; it does not invent Core totals or roll a final Review. Exact AI choices, use of optional publisher Contracts, Bank, employees and courses remain OPEN.

Released competitor games continue to exist while their studio starts another project. Income and Fan changes accrue on the ordinary monthly earning/settlement boundary, with a separate ledger per studio. No release creates immediate spendable launch cash. The player's current sales/Fanbase coefficients are trial or incomplete, so competitor economic rates and any independent market size remain OPEN.

## Performance design — PROPOSED guardrails, no numerical cap yet

Run rival decisions only when a successful productive action advances the shared calendar, never once per rendered frame and never as a catch-up simulation on load. Process active studios in stable ID order with deterministic, per-studio random state. A blocked studio can take a recorded idle turn. Resolve a finite number of zero-cycle redraw/choice steps within one turn so a rival cannot loop indefinitely.

Extract or reuse data-only candidate-deal and hand-resolution rules shared with the player. The current Design/Alpha/Beta phase scripts are `Control` scenes that also manage `CardView` nodes and animations; rival hands should use the same rules without creating those scenes, card art or motion for each studio. A bounded policy can rank the current seven candidates and legal selections using a small heuristic. It should choose one real path, without searching many future projects or running Monte Carlo rollouts for every rival action.

Keep active projects, inventories, RNG and pending news in the checkpoint. Resume from that state instead of replaying all historical hands. Retain compact immutable release records and only current accounting state needed for monthly income/Fans; long history should not be re-resolved each cycle. The maximum active-studio count, decision budget, release-history indexing and any work chunking remain OPEN until profiling.

Before selecting a population cap, benchmark representative opening and long-running worlds on the minimum target hardware. Measure worst and percentile time added to a productive action, memory, save size, deterministic replay, legal-result parity with player resolution, and exactly-once monthly news. If the measured pause is too long, simplify the AI's choice search or process the bounded world update across frames while holding the action transaction; keep the actual hand and outcome rules intact.

## Opening cohort and later entrants

The 1980 incumbents have distinct identities, specialties, traits, prior released games, cash, Fans and owned Features. Their head start should be visible in their existing catalog and ability to produce stronger early work. The exact number of incumbents, their histories, Reviews, start dates, assets and verified opening rating floor are OPEN. Their designated opening games must satisfy the first-game Review guarantee above through this starting setup and their actual production rules.

As calendar time advances, additional studios can be founded and start from the same studio-creation framework available to the player at that date. Entry cadence, maximum active population, initial genre distribution, later-era access, failure/retirement and whether a new entrant can later become an incumbent-like leader are OPEN. Entrants must not appear merely because the player opens a menu or reloads a save.

## High-Review news — LOCKED timing, OPEN threshold

When a competitor release qualifies as high reviewed, record a news event with its release ID, studio, title, Genre, frozen Review, release month and delivery month. Queue delivery for the first player-facing safe point at the start of the **next** calendar month, including while the player is in Design, Alpha or Beta. Deliver it once per saved timeline and preserve pending/delivered status through a Studio checkpoint. An unsaved mid-project exit follows the existing Studio rollback boundary, so replaying that month may show the event again. The notification reports an actual release result, not a forecast or a hidden project roll.

The Review threshold, whether multiple qualifying releases appear as separate alerts or a digest, presentation during an active player phase, and whether existing pre-1980 catalog titles receive an initial history summary are OPEN. The proposed safe-point and one-shot persistence rules implement the user's following-month timing without interrupting an unresolved hand.

## Current prototype and migration boundary

The current [primitive competitor ledger](../../../patch-notes/data/primitive_competitor_ledger.json) rolls one of four target project cycles for each player project. Beta can reveal that snapshot. [Launch market context](../../../patch-notes/scripts/market/launch_market_context_result.gd) explicitly assigns no competitor consequence, and the target comparison uses the player's project cycle rather than the run calendar. It is not a persistent AI studio.

The future design must decide how Study Competition and Playtest Rival Games reveal real studio projects, and whether the primitive snapshot is retired or retained for older saved results. Rival state and notifications will need durable checkpoint mapping. This document does not authorize a silent reinterpretation of historical frozen releases or older checkpoint bytes.

## Decisions to make next — OPEN

| Question | Why it matters |
|---|---|
| How many incumbents exist in January 1980, and what prior games/resources do they have? | Defines the visible starting market and opening difficulty. |
| What is the highest legal player first-game Review across starting builds, Features, cash and rent, and what incumbent opening floor exceeds it? | Makes the strict first-game guarantee testable as the starting economy changes. |
| How often do entrants appear, and can studios run out of money, pause, recover or close? | Controls long-run population and performance. |
| What bounded policy chooses among actual legal hands and redraws, and which optional Contracts, employee or Bank actions may it take? | Keeps real hand outcomes while bounding AI decision work. |
| What Review qualifies for next-month news, and how are simultaneous releases shown? | Sets alert frequency and clarity. |
| How do AI sales, Fans, operating costs and cash limits use the evolving player systems? | Prevents a background economy from inventing unapproved numbers. |
| What information do Beta intel cards expose about real projects? | Connects existing cards to useful decisions. |

Future market influence on Reviews is intentionally reserved for its own design ruling. No numerical market or sales effect is selected here.
