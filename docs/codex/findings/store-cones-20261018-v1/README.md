# Cardinal Store trees — 2026-10-18

Direct user request; implemented locally on dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Existing edits and `.codex-godot-temp` preserved. No commit, push or export.

## Scope and evidence

- Gameplay lower left; Story & World lower right; Visuals upper left; Audio upper right; Technology & Tools above. Inner roots share a vertical grid axis, except the horizontal Tools row. No independent root is packed ahead of a branch. All positions use a 212-unit grid; side generations have wider spacing. Side cones open up/outward or down/outward as requested, with a separate upward crown.
- Every current fork has one aligned child and an adjacent sibling. General Combat → Turn-Based Combat stays level; Character Classes is directly below Turn-Based. Text → Scrolling and 4-Color Palette → Sprites are the Visual spines. Cones reserve expansion space; empty space creates no new prerequisites or Features. Tools has only one existing upward branch, Save Files → Branching Nodes; lateral space is reserved for future authored branches.
- Six real acquisition parents: Multiple Endings ← Branching Dialogue; Secrets ← Exploration; 8-Bit Music ← Music; 8-Bit Sound ← Sound Effects; Scrolling ← Text; Sprites ←4-Color Palette. Existing additional AND parents remain in details/badges. Later Branching Dialogue is required for a new Multiple Endings acquisition; it cannot be purchased in initial Primitive shopping.
- `branches2` admits exact named prior content revisions. Existing grants/owned children and paid research queues retain their state without retroactive parent grants, charges or cancellation. Narrow exact prior-world source compatibility retains player, rival, Founder, financial and RNG data. Unknown identities still reject.
- All data files and scoring scripts are unchanged. Handoff017 specialty changes remain queued, outside this request.

## Verification

Godot 4.7.1; [runner](run.py) creates immutable source copies and private profiles. Every row below exited0 with no script/errors. Exact commands are recorded in each stage's `results.json`; run a fresh stage as `python -X utf8 run.py <new-stage> <verifier> ...`.

| Stage | Check | Result |
|---|---|---|
| before | Native old-rule six paid queues + eight specialty saves; Founder/world capture |12/12 +30/30 |
| final-v1 | New parent legality, ordered full chains, atomic rejections, queued-vs-owned, exact current hydration, actual old queues/rosters |225/225 |
| final-v1 | Earlier four Primitive branches / retained grants |177/177 |
| final-v1 | Two-parent structure / FIFO research |65/65;26/26 |
| final-v2 | Existing Store behavior |66/66 |
| final-v3 | Mouse/keyboard/drag/tooltip/Pause navigation |78/78 |
| final-v3 | Studio checkpoint / eight specialties / Alpha pack |93/93;245/245;174/174 |
| final-v4 | Conditional acquisition/spending guidance |38/38 |
| final-v4 | Native UI geometry and interaction |288/288;24 PNGs at900×600,1152×648,1280×720 |
| final-v4 | Founder/world / actual pre-change world migration |30/30;8/8 |

The native checks cover all 42 nodes, 24 real edges (including the synthetic Gameplay-count gate), exact roots/grid/forks, outward direction, disjoint footprints, connector clearance, visible names, overview, category shortcuts, popup focus and passive-state preservation. Screenshots inspected: overview, Visuals, Audio, Gameplay, Story, Tools and Combat fork. [Combat fork](final-v4/store-combat-fork-1152.png), [overview](final-v4/store-overview-1280.png), [Tools crown](final-v4/store-technology-tools-1280.png). Overview is a navigation thumbnail; zoom/focus exposes readable labels.

[Final audit](final-source-audit.json): all 727 canonical source/asset inputs exactly match the imported/rendered final-v4 project. Runtime identity `f4303f0101e1971026080ec0b0acf3c817e96675fa190758d7c8651b8969a412`. Earlier final-v1/v2/v3 passing mechanics differ only in the later explicit music-player process mode and its exact compatible-world identity; those audio/restore changes have separate [six-suite evidence](../pause-track-20261018-v1/README.md). [Task diff](task-diff.patch) compares this task against the actual dirty pre-edit source, not HEAD.

## Retained failures and limits

Initial constant-expression parse error corrected before behavior checks. First native layout needed more horizontal spread and revealed deferred scroll-range centering; explicit target centering now waits for layout, and subsequent native checks pass. Older tests assumed18 edges, Colored Text as the first outward Text node, Sprites as an independent root, every unowned Primitive being immediately purchasable, or8-Bit Music as a parentless acquisition ancestor. Those fixtures/expectations now use the requested topology and actual legal admission. Early failed stages remain recorded, including a missed duplicate edge-count assertion corrected in final-v2. Existing six-ObjectDB exit warning also occurs on the pre-change source.

No full release gate, refreshed export, balance study, long campaign or human map-comprehension claim. A separately queued specialty change was preserved. The accompanying pause follow-up changes no Store rules.
