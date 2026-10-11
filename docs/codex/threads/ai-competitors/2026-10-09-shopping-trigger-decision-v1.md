# 2026-10-09 decision: rival Store admission timing

**Status: LOCKED first-slice AI policy; planner values remain OPEN.** The user directed this design thread to get to work after the [small admission-timing brief](2026-10-09-shopping-trigger-options-v1.md). Proceed with its recommended Studio-boundary choice. This is a documentation decision, not gameplay implementation or a change to player Store access.

## Selected rule

A rival considers **one new AI-planned Feature admission at Studio, before it creates its next project**. That comparison uses the same frozen, finite fresh-next-project planning envelope before and after hypothetical completed ownership. The project captures its owned Feature supply at creation; no subsequent purchase or Research completion is credited to its active Design or Alpha hands. A rival with an existing FIFO research head may take legal Research opportunities to finish that head. Completing the head does not itself authorize another new admission during an active project. A deferred shopping decision can be revisited at the next Studio boundary with then-current ownership, cash, unlocks and era.

This fixes **when** the new-admission planner runs. It does not settle how many planned hands it models, how much cash it allocates after dues, which candidate clears the relevance/search screens, whether the rival can actually pay the conditional completion quote, or how often it chooses Research instead of other legal work. Those remain **OPEN**. Ordinary Store legality and FIFO installment requoting still apply at each real transaction.

## Alternative logged

The [other choice](2026-10-09-shopping-trigger-options-v1.md) allowed a new admission during active development for a later project. It could spend idle cash earlier, but active-project supply is already frozen. That choice would require repeated future-project replanning and clearer separation of current versus later benefits. It is not selected for the first slice. A later design ruling may reopen it with source-matched pacing evidence.

## Source boundary

`ProjectState.configure_predevelopment()` stores the Feature IDs at project creation (`patch-notes/scripts/project_state.gd:64-71`), and `CardDatabase.get_project_features_for_phase()` reads that stored supply (`patch-notes/scripts/cards/card_database.gd:278-288`). The player Store is available at Studio, but that UI fact alone does not determine all future AI Store policy. The selected timing aligns the planner's hypothetical benefit with the next project whose supply has not yet frozen.
