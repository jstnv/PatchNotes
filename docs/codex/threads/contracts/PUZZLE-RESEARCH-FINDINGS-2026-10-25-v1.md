# Puzzle Research and Crown access — findings v1

2026-10-25. **Bounded research; rewards, Review7 gate and canonical gameplay unchanged.** User requested Puzzle Research investigation. [Preregistered plan](studies/puzzle-research-20261025-v1/PLAN.md) · [review handoff](PUZZLE-RESEARCH-HANDOFF-2026-10-25-v1.md).

## Result and recommendation

**Retain 8-bit Sound + Sprites as a useful accessibility test route; do not replace the original purchase strategy universally. Keep rewards unchanged.** It reaches Crown in all four tested seeds, while8-bit Sound + General Combat reaches three. On the original stuck seed4417, Sprites earns Review8.4 at Game4/cycle80; the baseline peaks at6.9 within four releases. All12 declared campaigns complete four releases without arrears.

Confirmation is mixed for pacing: on4418, Sprites unlocks one cycle sooner (62 versus63); on4522 it unlocks20 cycles later (83 versus63), after Game3 misses at6.9. It finishes with less cash than baseline on all four seeds. It is an additional legal route, not a reliable universal speed or income improvement. Do not turn a successful seed into compulsory shopping advice or a hidden seed-specific rule.

Discovery alternatives also matter: Music + Sprites reaches both discovery seeds but ranks two total unlock cycles behind8-bit Sound + Sprites; Music + General Combat still misses4417. These unselected pairs did not receive confirmation runs and cannot be called globally inferior.

Next useful Contracts question: can the approved private Crown Brief be afforded and understood from these earlier, legitimately earned access states? Reuse the retained legal routes to regenerate source-compatible prefixes in the private Crown Search candidate, then compare paid Search/Brief work against skip with unchanged rewards. No canonical exposure or extra balance change follows from this research. Keep the existing grade-preview/migration/world/UI/export gates.

## Exact source and comparison

Branch main, HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f, shared dirty checkout retained. Named private variant `puzzle-research-20261025-v1` is an immutable-source child of `crown-access-policy-20261025-v1`; full parent/canonical/candidate identity `434971b9525f09fab3fa0846ed094f53d6ee778f76ae8b97740a136c7b0fda3f`. **Zero runtime delta.** Only external research policy/configs and public-score logging differ. [Before pin](studies/puzzle-research-20261025-v1/source-before.json), [after pin](studies/puzzle-research-20261025-v1/source-after.json), [policy/plan hashes](studies/puzzle-research-20261025-v1/pin.json).

Four ordered two-Feature pairs: baseline8-bit Sound + General Combat; Music + General Combat;8-bit Sound + Sprites; Music + Sprites. Each selected card has Scope2 and actual quote$450; each completed pair costs$900, two Research actions and the same normal calendar costs at acquisition. No extra funding, synthetic ownership or prerequisite bypass. The research policy requires the existing$6,000 quoted post-acquisition reserve, but this is not an exact future-bills guarantee or a gameplay constraint.

Discovery uses the retained Puzzle4417/4521 recipes with current v3 roster and no traits, four arms each. Baselines exactly reproduce previous initial/final state/RNG, counters and outcomes. Four-arm starts match, and every arm shares the same full state prefix until its first changed purchase. Same real Ironclad/six paid cash searches, first game2/2/2, priorities15/10/30/45 and Beta50/25/25, visible selection and bounded exit policy. No redraw, Bank, employee, extra Research, reward, price, target, gate or phase-policy changes. Additional exit logs include only observable Cores.

Discovery ranking was fixed before runs: completed/arrears-free access count, then completed/arrears-free count, then earliest summed unlock cycles (non-access421), minimum cash, lexical name. Chosen alternative **sound_sprites**. Fresh confirmation compares it against baseline on predeclared seeds4418 and4522; those seeds were not replaced after seeing results. This selection is adaptive, and the confirmation is reported separately.

| Alternative | Discovery access | Completed/no arrears | Cycle score | Minimum cash across discovery |
|---|---:|---:|---:|---:|
| sound_sprites | 2/2 | 2/2 | 145 | $1,539.64 |
| music_sprites | 2/2 | 2/2 | 147 | $1,875.87 |
| music_combat | 1/2 | 2/2 | 486 | $1,895.87 |

Each case: four total releases,420 commands, first rejection/bound/timeout stops; three serial bundles,600sec import/run each. Fresh-process replays240sec each; cold Studio Continue100commands/240sec. The extra cold release is verification only, excluded from four-release access counts. Exact argv/exit files are alongside [run.py](studies/puzzle-research-20261025-v1/run.py); frozen bundles retain runner/Godot/import/experiment command manifests. No seed, budget or horizon was silently changed.

## All declared results

| Case | Reviews in order | First Crown cycle | Final cycle | Final cash | Minimum transaction cash |
|---|---|---:|---:|---:|---:|
| puzzle-4417-baseline | 1.1, 5.6, 6.5, 6.9 | Not reached | 82 | $5,298.51 | $1,915.87 |
| puzzle-4417-music_combat | 1.1, 5.8, 6.3, 6.8 | Not reached | 82 | $5,399.34 | $1,895.87 |
| puzzle-4417-sound_sprites | 1.1, 4.3, 6.1, 8.4 | 80 | 80 | $2,408.93 | $1,539.64 |
| puzzle-4417-music_sprites | 1.1, 5.0, 6.1, 7.2 | 82 | 82 | $3,192.49 | $1,875.87 |
| puzzle-4521-baseline | 1.7, 6.8, 7.7, 8.7 | 67 | 87 | $10,212.15 | $1,514.84 |
| puzzle-4521-music_combat | 1.7, 6.5, 7.3, 8.6 | 65 | 85 | $8,896.90 | $1,994.84 |
| puzzle-4521-sound_sprites | 1.7, 6.1, 7.1, 8.0 | 65 | 85 | $7,484.32 | $1,994.84 |
| puzzle-4521-music_sprites | 1.7, 6.6, 7.0, 8.2 | 65 | 85 | $8,494.25 | $1,974.84 |
| puzzle-4418-baseline | 1.7, 5.5, 7.6, 7.5 | 63 | 85 | $6,933.74 | $1,977.69 |
| puzzle-4418-sound_sprites | 1.7, 4.9, 7.7, 7.4 | 62 | 83 | $6,052.07 | $1,640.41 |
| puzzle-4522-baseline | 1.6, 6.1, 8.4, 8.0 | 63 | 83 | $14,662.38 | $1,716.82 |
| puzzle-4522-sound_sprites | 1.6, 5.7, 6.9, 7.6 | 83 | 83 | $9,630.36 | $1,696.82 |

12 measured cases, 1854 accepted commands. [Full analysis](studies/puzzle-research-20261025-v1/analysis.json) includes completed/rejected status, arrears, exact purchased IDs/costs/actions, paired-prefix checks and observable exit scores. [Selection/ranking](studies/puzzle-research-20261025-v1/selection.json). Raw complete bundles retained at `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/puzzle-research-20261025-v1/`; [evidence hashes](studies/puzzle-research-20261025-v1/evidence-manifest.json).

## Verification and limits

**Publication source check:** the initial strict canonical-identity guard detected one concurrently added standalone latency diagnostic after the study source check. All existing canonical files and the frozen simulator still match. [Exact hashes, failed guard and read-only inspection](studies/puzzle-research-20261025-v1/PUBLICATION-SOURCE-NOTE.md). Current full canonical identity therefore differs from the executed baseline; no gameplay rerun or adoption claim is made for that later checkout.

- PASS: two exact historical baselines, four matched initial-state/RNG groups, eight exact shared-prefix checks,12 current-roster fixtures. Completed cases must actually purchase their exact two IDs, spend90000c and perform two Research actions/six Searches.
- PASS: fresh-process selected-alternative replay on4417 and4418, including exact telemetry. Fresh Studio Continue reaches a fifth release with exact initial state/RNG. [Receipts and retained diagnostics](studies/puzzle-research-20261025-v1/verification.json). Reduction is applicable only if a case rejects, not for a completed four-release campaign below Review7.
- Retained engine diagnostics include exit ObjectDB leak warnings; no ERROR/SCRIPT ERROR in the three import/experiment logs. These warnings were not repaired by this policy study.
- NOT RUN: native/UI/export/human acceptance, additional specialties, other card-selection/phase strategies, actual Crown Brief play from the earlier unlocks, later eras or mandatory shopping advice. Existing preview/migration/world/exposure gates remain separate.

Owned card totals are an explanation hypothesis, not realized hand totals. Changing a Feature changes the draw pool, exhaustion and subsequent RNG consumption; exact starting RNG does not mean identical later draws. The pair comparison includes phase placement and printed value together (Music7 Alpha versus8-bit Sound5 Design; Sprites7 Design versus General Combat5 Alpha), so it cannot isolate either stat strength or phase alone. It does not establish that the winning pair is globally optimal. Two discovery and two confirmation seeds are a bounded check; passing runs never approve balance or a mandatory purchase path. Retain the original four-purchase exit-only comparison as separately pinned historical context, not a newly run arm.
