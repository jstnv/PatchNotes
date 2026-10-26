# Contracts publisher formulas — session log v2

2026-10-18 (America/Los_Angeles). Working branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; the checkout and central TODO were already dirty and were preserved. This log follows [session v1](SESSION-LOG-2026-10-18-publisher-formulas-v1.md). No canonical gameplay, tests, assets, configuration, shared TODO, design authority, commit or push changed in this pass.

## Changed thread-owned files

- Created [publisher design v3](PUBLISHER-SYSTEM-DESIGN-2026-10-18-v3.md), correcting the v2 full-delivery trust contradiction, defining positive frozen project Scope, SideStreet support issuance, release atomicity, title-rights/finance accounting, campaign rights and checkpoint migration. The original [v2 design](PUBLISHER-SYSTEM-DESIGN-2026-10-18-v2.md) is marked SUPERSEDED and retained.
- Created [relationship plan v2](PUBLISHER-RELATIONSHIP-ARITHMETIC-PLAN-2026-10-18-v2.md), [checker v2](publisher_relationship_arithmetic_v2.py), [finding v2](PUBLISHER-RELATIONSHIP-ARITHMETIC-FINDINGS-2026-10-18-v2.md) and its two [JSON outputs](sims/publisher-relationship-arithmetic-20261018-v2.json). The v1 plan/finding remain historical and are marked SUPERSEDED for the current formula.
- Annotated [economic finding v1](PUBLISHER-SYSTEM-ARITHMETIC-FINDINGS-2026-10-18-v1.md) with the rejection of its cash-only Ironclad support row; its numbers were not changed. Updated the current pointer in [README](README.md) and proposed P1–P5 acceptance in [HANDOFF](HANDOFF.md).

## Checks and evidence

- Two fresh bundled-Python processes ran `publisher_relationship_arithmetic_v2.py` into distinct `sims/publisher-relationship-arithmetic-20261018-v2.json` and `...-v2-replay.json`: **PASS**, 9 Brief cells, 45 commission cells, four invalid Scope rejections, eight progression events, publisher isolation; identical SHA-256 `5C85A0FE51F84D4B9B0512F54FE94F10CC1EC28D53DDDD39E762570DEB8EEA28`.
- Recomputed the five source SHA-256 values pinned in [economic plan v1](PUBLISHER-SYSTEM-ARITHMETIC-PLAN-2026-10-18-v1.md): **PASS**, all match the current worktree. That check does not validate the proposed new runtime.
- Markdown local-link check across the v3 design, v2 plan/finding, this session log, README and HANDOFF: **PASS**, 335 checked links and zero missing targets. `git -c core.whitespace=cr-at-eol diff --check -- docs/codex/threads/contracts/README.md docs/codex/threads/contracts/HANDOFF.md`: **PASS**.

## Outcome and follow-up

The corrected rules are **PROPOSED**, not user-approved, ACTIVE/TRIAL gameplay or integrated code. The economic screen's cash-only Ironclad support is mathematically weakly dominant and is **rejected** as a playable profile; SideStreet is the first proposed support pilot. Formula-only checks do not establish legal offer access, production cashflow, Review/Scope attainability, audience comprehension, finance/rights migration, or both-size/exported Continue. Next evidence should use a Contracts-owned simulator variant or source-matched legal current-game routes for the actual deal runtime, then a source-pinned adoption review. All P1–P5 handoff items remain **PROPOSED**. The central To Do List was not edited in this pass.
