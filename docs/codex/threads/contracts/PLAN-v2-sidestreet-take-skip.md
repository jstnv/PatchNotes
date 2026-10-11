# SideStreet take versus skip — predeclared headless study

2026-10-11 (America/Los_Angeles). **Read-only existing-rule study; no gameplay candidate or numerical approval.** The question is whether accepting one recurring SideStreet cash offer before a pending Crown/Neon first offer improves cash and advances Starwave's three-completion gate enough to justify two productive Contract cycles. The approved Crown/Neon/Starwave ACTIVE/TRIAL numbers and locked Ironclad/SideStreet rules remain fixed.

## Hypothesis and cases

From one lossless Studio checkpoint after two distinct releases, one committed Ironclad completion, a pending release-linked SideStreet offer and a pending Crown or Neon first offer, compare:

1. **Take:** accept and complete the eligible SideStreet offer, then accept and complete the same available first-unlock publisher, then develop the third release.
2. **Skip:** leave SideStreet pending, accept and complete that first-unlock publisher, then develop the third release.

Both arms receive the **same checkpoint bytes and RNG state**, identical visible-order/Feature-first choices and no injected cash/cards/offers. The only policy difference is the SideStreet acceptance and its legal two hands. SideStreet remains pending in Skip; neither arm takes Starwave, so the comparison isolates eligibility/access rather than its payout. Target three total releases, at most 140 commands per continuation. Stop and preserve any rejection, incomplete route, command bound, timeout or source mismatch; no replacement seed or budget increase. A pair is eligible only if the declared checkpoint contains both a SideStreet offer and a Crown/Neon offer. Ineligible prefixes remain findings, not economic comparisons.

## Prefix, seeds and policy

Use current canonical rules through the isolated `tools/simulate.py run` runner, **without creating a gameplay variant**. The thread-owned external [policy](sim-v20/sidestreet_policy.gd) delegates legal project choices to the existing finite development fixture and legal Contract commands to CampaignSession. Two predeclared Sports-specialty, Sports/Fantasy recipes use seeds `4417` and `1104`, no traits, genuine current creation cash. For each seed: play two releases with 5 Design/6 Alpha/6 Beta hands, accept and complete Ironclad once after release 1, then stop at Studio immediately after release 2. The previous pre-Education Sports/4417 route reached Crown under a different legal policy; it is historical motivation only and no current-source guarantee. Treat any unearned Crown/Neon, unearned SideStreet, first release failure or finance block as a preserved eligibility miss.

Policy selection is `features_first` for development and four available Feature-first Contract cards; no redraw, Store purchase, hire, loan, campaign or artificial wait. If this policy cannot produce a legal four-card hand, keep its rejection. Prefix limit: 180 commands, two releases, 240-second import and 240-second experiment timeout. Each matched continuation uses the same source identity and checkpoint from its own prefix. A source/rules change between prefix and continuation is a stop, not a reason to edit a checkpoint. The full config, runner command and frozen manifests remain in versioned `sim-v20/` output folders.

## Measurements and checks

- Verify exact prefix checkpoint and RNG equality, policy/source hashes, offer IDs and qualifications before accepting a pair. Retain every prefix including ineligible cases.
- Compare SideStreet completion amount, Crown/Neon receipt and Promotion, Starwave offer availability after each distinct completion, release 3 Review/Awareness and date, cash/overdue/credit, settled portfolio sales, finance events and first blocked command.
- Use optional command telemetry to compare only actual shared calendar cycles, plus the same release ordinal. Record productive-cycle and calendar opportunity cost separately from direct Contract receipts. Keep both ending and intermediate cash lows and original bill identities; an absent obligation is untested, not zero cost.
- Run the same-source paired reporter only for eligible successful pairs, then replay each representative take/skip arm in a fresh process from its frozen bundle. Check exact results/tape/state and retained errors. Do not call a successful replay independent strategy evidence.

## Decision boundary

This can support a recommendation to retain the current SideStreet choice, improve player guidance, or investigate a specific tradeoff. It cannot approve a payout/gate change, final publisher balance or a canonical implementation. If no eligible prefix appears in the two declared seeds, report that as a route-access limitation and prepare a new predeclared strategy only after reviewing the failure evidence. Do not add a TODO adoption item unless the findings identify a concrete implementation delta and a design ruling supports it; a bounded read-only result may instead be logged as completed evidence with no new queue work.

## Protocol repair, before usable route results

The first attempt `sim-v20/prefix-v1-run-01` imported successfully but executed **zero commands** in both cases: the external policy tried to instantiate itself from `res://scripts/debug/sidestreet_policy.gd`, while the runner copies it to `res://scripts/debug/experiment_policy/supplied_policy.gd`. The full failed bundle is retained. `sidestreet_policy_v2.gd` and `prefix-v2.json` correct only that self-load path and policy identity; the declared seeds, legal choices, budgets and stopping conditions are unchanged. This is a runner policy repair, not a gameplay-rule revision or a favorable-case search.
