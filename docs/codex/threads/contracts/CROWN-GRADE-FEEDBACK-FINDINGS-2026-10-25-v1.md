# Crown grade feedback — findings v1

2026-10-25. **PASS: bounded offline evidence; presentation PROPOSED.** [Preregistered plan](studies/crown-grade-feedback-20261025-v1/PLAN.md) · [design](CROWN-GRADE-FEEDBACK-DESIGN-2026-10-25-v1.md) · [handoff v3](CROWN-PREVIEW-HANDOFF-2026-10-25-v3.md).

## Question and outcome

Visible current scores and cards can explain all eight retained final zero results without predicting a future draw. Keep rewards unchanged and add the proposed selected-hand feedback, final-hand current-card warning and derived consecutive-zero reminder. This study tests the arithmetic and state distinctions behind that presentation; it does not measure player improvement or change any prior outcome.

| Check | Outcome |
|---|---|
| Selected projections compared with recorded engine projections | 36/36 match |
| Final grade, requested/credited award and resulting standing | 18/18 match |
| Current-card quartet evaluations | 1,260: 35 at each of 36 hands |
| Final-hand current-card zero warnings | Exactly the eight recorded zero-result hands; none on the ten positive-result hands |
| First-hand warning suppression | All 18 first hands; one had all 35 provisional options at zero |
| Positive first-hand score value later finishing at zero | Seven Briefs; provisional values ranged from +2.50 to +3.33 Reputation |
| Consecutive-two reminder on recorded result sequences | Only Puzzle4522, after its second and third zero results |
| Constructed scoring / selection / history protocol cases | 21 / 6 / 16 pass, separately labeled |
| Finite completion/balance arithmetic domain | 603 combinations: requested zero iff grade zero for these pilot terms |
| Input files and frozen private source | Unchanged |

The reminder's threshold of two is a proposed informational design choice. Passing these checks does not approve it, canonical activation or final balance. A final-hand warning establishes the available grade from the reached state and current cards. It says nothing about the optimality of the preceding hand or what a legal redraw might produce.

## Material findings

1. **First-hand optimism needs an explicit label.** Seven actual first-hand selections had positive score value and later earned zero. Puzzle4522's second Brief went from +2.50 provisional to +0.00 final while Scope rose from 2 to 9. Displaying the early number as banked or guaranteed standing would be wrong.
2. **Scope is insufficient.** All eight zero-result hands meet or exceed Scope9. Core imbalance drives balance to zero. Puzzle4522 finishes with Work completion57.57%,81.81%,72.72%, so “Brief complete” is clearer than the prior “Work complete” copy. Completion of the two hands and the Work completion percentage are different facts.
3. **The current-card warning is bounded.** All 35 final selections score zero in each of those eight reached states. A first-hand snapshot also had all current provisional choices at zero, but no future draw is visible there; its warning remains suppressed.
4. **Consecutive matters.** Puzzle4522's awards0,0,0 yield reminder counts2 and3. Action4417's0,7.5,0 and Simulation4417's0,10,0 do not trigger it. A positive earned award resets the count even when the cap clips actual credit to zero, as constructed cases verify.
5. **No new durable streak state is necessary in the proposal.** The inspected relationship ledger already has ordered identities, source/kind, requested/credited amounts and trusted reconstruction. Production can derive the summary after validation. This offline study reconstructed result sequences from verified logs; it did not implement or test a native persisted-ledger consumer.

## Methods, assumptions and limits

Read only the six earned-start branches containing18 Crown Briefs from [earlier affordability](EARLY-BRIEF-AFFORDABILITY-FINDINGS-2026-10-25-v1.md). The original fixed seeds remain4417,4418,4521,4522 for Puzzle and4417 for Action/Simulation. Their legal starts, ownership, current cards, selected tokens, sequence/view identity, standing and rewards are unchanged. No new campaign, hand, RNG draw, seed, policy, checkpoint conversion, gameplay variant or engine process was run.

The [offline reference](studies/crown-grade-feedback-20261025-v1/reference.py) projects the current four cards, recomputes approved integer scoring and enumerates current visible choices. The [analysis](studies/crown-grade-feedback-20261025-v1/analyze.py) compares selected outcomes against the recorded engine projections/results. Hypothetical first-hand model plans and later draws are not consumed by the feedback logic. Final-hand alternatives are scoring counterfactuals over recorded candidates, not newly executed engine commands or proof of native finite-card validation.

The history fixture uses actual verified completed awards to reconstruct a filtered sequence; it does not represent a fresh reading of a serialized Godot ledger. Six selection mutations cover incomplete, duplicate, unknown, stale, unrelated-product and incoherent-animation requests. Sixteen history cases cover empty/one/two/three zeros, cap-clipped positive awards, interleaving, unavailable/unvalidated history, missing source, duplicate identities, ordering and invalid credit. Repeated queries preserve the reference inputs. Runtime world/RNG purity and native performance remain untested.

The named constructed matrix has43 cases. An additional603 finite integer evaluations establish the exact pilot rounding property; they are arithmetic coverage, not extra player trials. One invocation completed in0.159 seconds with a60-second limit, exit0, no timeout or rejected study. No correction, rerun, reducer or new campaign was needed. The earlier study's retained setup failure and engine warnings remain in its evidence; this consumer neither reruns nor removes them.

An explicit [post-matrix cap display review](studies/crown-grade-feedback-20261025-v1/CAP-REVIEW-ADDENDUM.md) identified a remaining copy risk: proactive improvement advice at R100 could imply room for extra credit. Five separate constructed [display cases](studies/crown-grade-feedback-20261025-v1/cap-reminder-v1.json) verify suppression at cap while retaining the true history count. This extension leaves the sealed main matrix unchanged and adds no player trials.

## Source and reproduction

- Shared branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty edits and `.codex-godot-temp` preserved. [Branch/status/diff snapshots](studies/crown-grade-feedback-20261025-v1/).
- Observed private full source identity `f7de61169758dcd874972c59e584c7b6a9a36f1fedc4f24b2398f6a2edfdf60f`; mechanics `9dd1e4551338d38894dace6eb98bc635c38b7e6ec47427b4078cf0ccfe8b0bd6`. Same immutable ancestry and approved numerical terms as the prior study.
- [Exact frozen/current source snapshot](studies/crown-grade-feedback-20261025-v1/source-before.json), [input hashes](studies/crown-grade-feedback-20261025-v1/run-v1/input-pins.json), [code hashes and exact command](studies/crown-grade-feedback-20261025-v1/command-v1.json), [execution receipt](studies/crown-grade-feedback-20261025-v1/execution-v1.json).
- Command: bundled Python executes `docs/codex/threads/contracts/studies/crown-grade-feedback-20261025-v1/run.py`; its retained command launches `analyze.py run-v1` once with60-second timeout. Do not reuse the output name for another attempt.
- [Summary](studies/crown-grade-feedback-20261025-v1/run-v1/summary.json), [36 feedback fixtures](studies/crown-grade-feedback-20261025-v1/run-v1/feedback-fixtures.json), [history fixtures](studies/crown-grade-feedback-20261025-v1/run-v1/history-fixtures.json), [constructed checks](studies/crown-grade-feedback-20261025-v1/run-v1/constructed-checks.json).

Current canonical finance/checkpoint/UI work has drifted from the frozen experiment. These results do not establish equivalence with that newer checkout. No canonical gameplay/UI/test/config/asset edits, commit, push or external dispatch occurred in this pass.

## Remaining gates

**NOT RUN:** native/UI/export acceptance, actual runtime query purity, current-source integration, live ledger/Studio restoration, human comprehension and effect on player decision-making. **OPEN:** exact presentation approval, reminder threshold approval, normal Crown exposure and whether observed progression variability is acceptable. Rewards remain unchanged; no balance, pity, redraw, cash-floor or guaranteed-R20 change is recommended here.
