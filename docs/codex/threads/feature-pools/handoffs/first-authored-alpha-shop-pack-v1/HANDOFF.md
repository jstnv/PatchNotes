# Handoff 012 — first authored Alpha shop pack

2026-10-17, America/Los_Angeles. **QUEUED implementation review for PN Implementation; design-thread documentation only.** [Decision 012](../../../../../../patch-notes/design-logs/feature-pools/decision-012-first-authored-alpha-shop-pack-2026-10-17.md) records the user's **“Yes, use temporary terms”** approval after [Proposal 012](../../../../../../patch-notes/design-logs/feature-pools/proposal-012-first-authored-alpha-shop-pack-2026-10-17.md). Four named authored cards and $1,700/$0 shop terms are approved for a bounded **ACTIVE/TRIAL** pilot, with final balance still OPEN. This handoff does not itself change gameplay, dispatch another chat, commit or push.

## Source boundary and question

Base observed 2026-10-17: dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Existing edits belong to concurrent work; recheck source, diff and the single overlapping gameplay slot before adopting. The live `patch-notes/data/feature_store_ledger.json` has eleven early later-nodes and none of these four. The 2026-10-17 [three-Core finding](../../../../findings/queue-execution-20261017-v2/README.md) and [two-parent finding](../../../../findings/two-parent-store-20261011-v1/README.md) establish the required structural foundations, not this content rollout. Printed identities come from the local [authored table](../../../../../../patch-notes/design-logs/feature-store-staged-v1/sources/Patch_Notes_Multi_Era_Feature_Store_Design_v1.md) and [Stage 1 catalog](../../../../../../patch-notes/design-logs/feature-store-staged-v1/stage1_catalog_v1.json).

Selected SHA256 source pins at handoff preparation: `card_ledger.json` `0f093b0ba907043120c3e6e529511322e6e0b99358adf6d69c80d5c174cfc83c`; `feature_store_ledger.json` `547a1cbc408ac263f3cf3a9e96e8667f33993e211bbb492937716c7df414cf`; `card_data.gd` `a77cf773d3591fe9ba07aca3a258aee5d1027da45f6ecd70c46187f4b9ba1d1a`; `card_database.gd` `2b08963e39e206085658c03c1f003ef048ba63d78cc71da11ff581d4d5521540`; `feature_store_catalog.gd` `01f10357af592115db8ba39af812eb8790758b465d8c0a07127ae998d386e22d`; `run_state.gd` `8352dee38ef666e7133cdb6bac94536f6b97b775146fbd200c89de278490bc30`; `feature_store_map.gd` `3c085ba8eec2aece9546a193dc0f5c05f6cda2f9f9a45b260d60566d42579135`. The source table is `457a3abd9318602f900740640da76c8330b8a2fa774a279941999d015f4398ee`; Stage 1 catalog `7abb61ce205ab9471342bc092059c408f66a49b547011ddb19b61142fd3f9ab4`. These are working-tree bytes, not a claim that dirty HEAD alone reproduces them.

**Question:** Can the four authored Alpha cards become normally purchasable in the current early Store, preserving all printed facts and existing research/prerequisite behavior, without admitting other catalog candidates or changing unrelated rules?

## Exact content to add

Add four distinct finite `type=feature`, `phase=alpha`, `renewable=false` entries to the later Store's card definitions/offers. Use the established ledger schema and `base_price_cents=170000` for each. No new per-node research-duration field: each uses the current one successful Research action. Do not insert them into `card_ledger.json`'s Primitive/starter supply. Preserve authored order, not aggregate-only scores.

| ID / name | Map lane; department | Printed ordered scores; Scope | Named parent IDs in anchor-first order |
| --- | --- | --- | --- |
| `turn_based_combat` / Turn-Based Combat | Gameplay; `gameplay` | Design 5; 2 | `general_combat` |
| `character_classes` / Character Classes | Gameplay; `gameplay` | Technology 2 → Design 3; 2 | `general_combat`, `save_files` |
| `character_development` / Character Development | Story & World; `story` | Design 5; 2 | `character_backstories`, `save_files` |
| `branching_dialogue` / Branching Dialogue | Story & World; `story` | Technology 2 → Design 3; 2 | `dialogue`, `branching_nodes` |

Use the first named parent as the map anchor; show the second as an explicit AND/cross-lane requirement. Keep the current first-game/early-node Store access policy for all four. Add no new calendar/release/platform gate; the source's “1981–83” label is not an individual unlock year. `gameplay_features_required=0` for all four. Artwork may use the current fallback until a separate asset decision, but no missing texture or invisible node is acceptable. Keep exact names/IDs and ordered scores in card, Store and tooltip text.

## Transaction, pool and scope limits

- For each child, queue admission costs 85000 cents and zero cycles. The one successful Store Research action costs one normal productive cycle and the nominal other 85000 cents, recomputed with then-earned parent familiarity. Under the current 50% cap, the familiarity component alone can reduce that installment to 42500 cents. Existing Resourceful final-installment behavior may apply; do not reinterpret the stated minimum as accounting for that separate trait. Rejected admission/action must not change cash, cycle, queue, RNG or ownership.
- Both named parents must be owned before admission to any two-parent child; queued parents are not owned. Each eligible parent's distinct-project committed-play credit contributes under the one shared cap. Display every missing parent and exact current down-payment/next-installment quote. No automatic ancestor purchases or new reserve gate.
- The committed-play fee for **these four Alpha cards** is temporarily **0 cents**. Preserve Primitive play fees and current later-card no-charge path. This is an explicit pilot value, not a permanent general rule. No new purchase price or fee for any other card.
- Research completion grants permanent ownership and future-project supply, with no guaranteed immediate draw or play. Preserve finite Alpha lifecycle and department handling. Keep specialty starter rosters frozen, and do not add the cards to any Primitive or publisher Contract pool. No direct platform tags, AI planner redesign, later-era content, Boss Battles, Sub-Areas or Background Music in this handoff.

## Acceptance for the implementing thread

1. Reconcile current dirty source with the handoff pins and report any conflicting change before adoption. Verify all four entries validate with unique IDs, exact score order/Scope/department/parents/price and no unintended fifth card. Confirm the Store graph has no dangling/duplicate/cyclic links.
2. Exercise one-parent and two-parent admission, including each parent absent, queued and owned. Verify cross-lane requirements, combined familiarity from separate parents, same-project eligible credit, cap and exact cents. Verify $850 deposit, discounted installment, unaffordable rejection, one-cycle completion, ownership and child unlock. Preserve existing eleven-node quotes and research behavior.
3. Verify completed ownership enters only a newly started project's owned supply; record at least one legal Alpha draw/commit for each new card or explicitly mark any unobserved card NOT RUN. Reconcile Core contributions, Scope, department, specialization, weighting, Bug Pressure and finite exhaustion against the printed row. Primitive specialty grants and Contract pools must remain unchanged.
4. Inspect Store map/detail/keyboard and card faces at both supported sizes, including all four nodes, AND badges, exact quotes and artwork fallback. Check checkpoint/Studio-only Continue and representative fresh-process replay for queued and completed research; verify rejected actions preserve state/RNG. Run focused current Store/card/finance suites and a suitable integrated regression set; log exact commands, source identities, failures and unrun acceptance.
5. Report actual implementation status in PN Implementation's own logs and update TODO only after verification. Human Store comprehension, asset approval and final balance remain deferred/OPEN; passing checks do not convert ACTIVE/TRIAL values to LOCKED.

The four-card pilot is selected under the user's new content direction and explicit temporary-term approval. Availability follows existing early Store policy as a bounded integration choice; future era-entitlement or platform policy may supersede it only through a later design ruling.
