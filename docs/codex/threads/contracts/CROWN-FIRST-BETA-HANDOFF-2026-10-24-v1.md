# Crown CA1f — first-hand Beta redraw handoff v1

2026-10-24. **DESIGN review; no canonical implementation queued.** User approved the bounded test with unchanged rewards; policy remains OPEN. [Plan](CROWN-FIRST-BETA-PLAN-2026-10-24-v1.md), [findings](CROWN-FIRST-BETA-FINDINGS-2026-10-24-v1.md), [source pins](studies/crown-first-beta-20261024-v1/source-pins.json), [exact policy delta](studies/crown-first-beta-20261024-v1/policy.diff), [audit](studies/crown-first-beta-20261024-v1/policy-audit.json), [verification](studies/crown-first-beta-20261024-v1/verification.json), [manifest](studies/crown-first-beta-20261024-v1/evidence-manifest.json).

## Matching source and exact change

Fresh `crown-first-beta-v1`, baseline `3a657520108df3a42efca0abf7347c43a3068bf6e47074016772072b1c1483d3`, helper-added project `da3efbe3c902ceb1778e7fe12304fb002ba5b013819a2b7001b03713cbfebb02`, policy `86f8088b00f48de903ef3f0b93927cba94ac9745889ea48f1a30ec08466cc10d`. HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty `main`; reconcile future canonical drift before any adoption. Only private project addition is existing legacy helper; do not transplant it into production as gameplay.

Candidate adds `first_search_redraw` ahead of ordinary Beta play: first productive hand pending, no visible Search, unused one-card allowance/runtime availability and four-rent reserve. Keep unchanged scored four with a Debug if visible, discard last unkept index; otherwise preserve the CA1e late guard. Shared allowance, two QA extension hands, purchases, scoring, gates and rewards remain unchanged. Both original policies are rerun unchanged through flags in the same external policy.

## Tasks and disposition

| Item | Status | Action / acceptance | Dependencies |
|---|---|---|---|
| CA1f experiment | **implemented and verified — private policy/evidence only** | Retain all six cases/36 releases/1180 accepted commands, both controls, every redraw miss, source/guard audits, exact replay/Studio Continue and shutdown warnings. | Source/plan/policy/evidence hashes match; no canonical implementation claim. |
| Policy disposition | **proposed** | Do not adopt this first-hand policy or blanket late reservation. Park redraw-timing experiments at this bounded result; leave canonical rewards, Review7, player rules and default AI unchanged. A future QA-policy study would need a new substantive hypothesis, rather than more seeds or extra redraw/hand budget to rescue this candidate. | Complete findings; future gameplay/default-AI adoption requires a separate design ruling. |
| Next Contracts design work | **proposed** | Prepare a Crown reputation-brief/progression design matrix against current framework and prior successful legal access witnesses. Identify challenge promise, partial/missed outcomes, per-Studio standing, release pacing and current/predecessor persistence acceptance. Label every unapproved term OPEN and list specific user rulings or implementation dependencies. No reward, gate or relationship activation is authorized by this test. | Preserve existing Crown access witnesses and CA1c/CA1e tradeoffs. Distinguish proposed terms from approved rules; fresh source and explicit migration authority before implementation. |

Return to Crown reputation-brief and progression design using the existing successful access witnesses, rather than requiring this failed QA branch to unlock Crown first. Reconcile current approved framework/authority, then prepare a concrete brief acceptance matrix: challenge promise, successful/partial/missed outcomes, owner-scoped standing, release-paced availability and persistence requirements. Keep proposed terms distinct from approved rules; this experiment supplies no authority to change rewards, unlocks or activate Crown relationships.

Shared TODO receives one minimal Crown DESIGN update preserving prior evidence links. SideStreet ACTIVE/TRIAL authority unchanged; Crown activation/terms/migration remain OPEN, CP2 rewards held. No auto-merge, chat dispatch, commit/push or release-readiness inference.
