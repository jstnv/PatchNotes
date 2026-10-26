# New queue design disposition — 2026-10-17

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty worktree. This is the implementation thread's review under the user's unattended execution request. It completes the review/deferral deliverables; it does not activate unspecified effects or candidate prices. Source inventory: [intake](intake.json), [baseline hashes](baseline-source.json). Implementation evidence is separate in [README](README.md).

## Handoff 013: Genre/Theme Store entitlements

**Review COMPLETE; first playable pack explicitly DEFERRED. All new mechanics below remain OPEN recommendations.** [Brief](../../../../patch-notes/design-logs/feature-pools/handoff-013-genre-theme-store-design-review.md).

Recommended representation: a versioned entitlement keyed by `(kind, stable_id)`, with `kind` exactly `genre` or `theme`. Feature prerequisites are typed references to canonical Feature IDs. All listed parents must be permanently owned; queued Research never satisfies a parent. Validate IDs, duplicate references, self/cyclic entitlement edges and missing definitions before offering an acquisition. Report every missing parent; an absent definition makes that offer unavailable with a specific reason, rather than silently dropping the condition.

Retain all eight current Genres and ten Themes as baseline options in new and existing campaigns. Do not retroactively charge or lock them. Store new permanent entitlements separately from owned Feature cards. Only future `begin_development` commands use the union of baseline options and completed entitlements. Keep founding specialty, frozen project Genre/Theme/ratios, historical Review and sales metadata unchanged. Persist the entitlement rule version and exact acquisition evidence; a rejected command changes no cash, time, RNG or supply.

Reuse the **ownership gate only** initially. Do not inherit Feature down payments, FIFO timing, familiarity discounts or Resourceful discounts by accidental generic dispatch. A later approved acquisition specification must explicitly select each of these. UI should distinguish “requirements met” from “owned” and “available for the next project.” AI choice must consume the same legal option set.

Interactive Movie/Motion Capture cannot be the first implementation pack yet: neither live ID/definition, exact four-Core ratio/target profile, access/era/platform terms, transaction price/duration nor approved copy exists. Required acceptance is: both-owned gating; malformed references; old-save baseline options; queued/completed cold Continue; rejected action atomicity; unchanged active/released identity; actual new-project selection and Review; both-size keyboard/UI explanation. No new rollout task is created.

Source reviewed: `primitive_predevelopment.gd`, `project_state.gd`, `primitive_predevelopment.json`, `review/primitive_review_calculator.gd`, `studio_specialties.gd`, `cards/feature_store_catalog.gd`, `persistence/studio_checkpoint.gd`. The four-card Alpha pack remains independent.

## Handoff 014: Pass upgrades

**Review COMPLETE; first effect/terms package explicitly DEFERRED. OPEN recommended model:** one effective Pass per Core category in each project's frozen catalog, replacing that category's base effect for future projects after a permanent typed `pass_upgrade` entitlement. Keep the logical Pass identity stable and version its effect; do not place base and upgraded copies in the same pool. Specify all four categories together in the eventual design review to avoid accidentally privileging one Genre; no numerical increase is selected here.

Keep the current +2, Scope 0, renewable, uncharged Passes until exact effects are approved. No new +3/+4 amount, price, parent Feature ID, discount, research duration or live pilot is inferred. Reuse Handoff 013's owned-Feature AND semantics and separate entitlement namespace, subject to its eventual approval.

Required integration map:

| Consumer | Required invariant |
|---|---|
| Seven-candidate/four-card deal | One effective Pass per category; no duplicate definition caused by an upgrade |
| Class selection | Existing 50/50 Feature/Pass choice and single-class fallback remain intact |
| Weighting/scoring/specialization | Resolve the project's frozen Pass definition, including both weighted deal inputs and specialization classification |
| Lifecycle/cost | Renewable, Scope 0 and zero direct play charge unless separately approved |
| Employee Pass-plus-Feature training | Stable logical IDs; audit any effect lookup against frozen definitions |
| Corrective Playtest cards | Resolve the same frozen category Pass; no alternate upgraded supply path |
| Launch guard | Upgraded Passes still do not count as implemented finite Features |
| Persistence | Older projects retain +2 definitions, active hands remain byte-stable, released outcomes never recalculate |
| Transactions | Admission/Research rejection leaves cash, cycle, pool and RNG unchanged |

Before implementation: approve exact effects and all transaction terms, then build a private variant covering current and old project snapshots, repeated renewable draws, depletion fallback, Employee interactions, cold Continue, exact replay and both-size card/Store text. Current development sessions obtain Passes from the catalog independently of finite Feature supply; simply changing `card_ledger.json` would rewrite existing projects and is therefore unsuitable.

Source reviewed: `card_ledger.json`, `simulation/development_session.gd`, `simulation/development_actions.gd`, `simulation/alpha_hand_command.gd`, `simulation/production_hand.gd`, `run_state.gd`, `studio_specialties.gd`. [Brief](../../../../patch-notes/design-logs/feature-pools/handoff-014-pass-upgrade-store-design-review.md).

## Contracts challenge review

**Review COMPLETE; runtime pilot remains OPEN pending approved terms and legal attainment evidence.** [Direction](../../threads/contracts/CHALLENGES-DECISION-2026-10-17-v1.md), [proposed handoff](../../threads/contracts/CHALLENGES-HANDOFF-2026-10-17-v1.md).

Preserve Ironclad without challenges and keep each existing publisher's base cash/Promotion unchanged. Recommend a versioned challenge bundle frozen with accepted terms; successful committed redraws alone increment its counter. Grade only after the final required hand. Use separate result and finance entries for base cash, bonus cash, base Promotion and bonus Promotion. An acceptance preview, canceled redraw, rejected hand, repeated completion or Continue must never grant or consume a bonus.

The v3 publisher map and minimum-condition grading are useful candidate inputs, but scorer-only tests do not show that targets/fades are attainable in a real Contract. The proposed $100/+4 caps and floor rounding have no approval. Explicitly defer numerical activation rather than silently converting these values to ACTIVE/TRIAL. A private next version should predeclare full/partial/miss routes for every publisher, include SideStreet/Starwave's currently zero base Promotion, and show separate exact-cent and integer-Promotion rounding before an adoption decision.

Recommended migration: existing accepted/in-progress Contracts remain on their frozen pre-challenge version; old completed results retain their settled base amounts and receive no retroactive challenge bonus. Newly accepted eligible offers use the later approved challenge definition. Promotion records need separate keyed bonus provenance and the same once-only next-successful-launch consumption boundary. Reject malformed versions atomically; retain Studio-only Continue. Both-size offer/progress/result and exported acceptance remain required after a full-path variant exists.

## Other design dependencies

Founder progress UI, larger saved populations, annual awards, full-industry market share, Innovation Path content and comeback rules lack implementation handoffs. The new ledger does not enable ten subsidiaries under the existing eight-rival checkpoint cap. Keep these as scoped dependencies, not completed gameplay. Market pressure likewise requires its private transaction/age-month/migration experiment and explicit numeric selection; neutral release rows alone cannot approve it. Human comprehension, audible timing and final balance remain human/design acceptance rather than automated completion claims.
