# Crown CA1e: reserve the Beta redraw — pre-run plan v1

2026-10-24. **Approved experiment; candidate policy remains OPEN.** User: “Go ahead and cook for reserving the Beta redraw when Search for Bugs is missing. Keep rewards unchanged.”

## Question and source

Does reserving the existing one-card Beta redraw for a visible Search-starved QA extension entry improve discovery, fixing and Crown accessibility without changing rewards or budgets? The [preceding finding](CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md) found lower Bugs but worse Crown access under automatic QA extension; this study does not approve that extension.

Create fresh Contracts-owned `simulators/crown-beta-redraw-v2` from current canonical dirty source (`main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`). Preserve its baseline/ancestry. Only add the unchanged legacy policy helper to the private project. Pin full manifests, baseline drift, helper, policy, runner, plan and runtime hashes in `studies/crown-beta-redraw-20261024-v1/source-pins.json` and retained bundles. Old checkpoints/results are historical; regenerate legal recipes on this revision.

Pre-run capture failure retained: `crown-beta-redraw-v1` creation rejected with exit1 because `scripts/market/rival_world_checkpoint.gd` changed while copying. No case ran. Retry once into a fresh v2 folder; leave v1 intact. Experimental policy, cases and limits are unchanged. This records concurrent source work rather than bypassing the snapshot consistency guard.

## Frozen comparison

Four fresh cases: Simulation specialty, seeds **4522 then 4521**, each control and candidate. Each pair shares the complete legal Studio recipe, identity, seed, no Traits and initial state/RNG; verify actual equality with the maintained paired reporter. No granted money, cards, scores, standing or arbitrary checkpoints. Maximum **six releases, 320 commands per case**. Both use CA1d QA policy: ordinary Scope acquisition, optional extra Design/Alpha hand, at most two QA extension hands, no targeted Core purchase. Policy settings differ only in reserved Beta redraw timing; labels differ for evidence.

- **Control:** existing early generic one-card Beta redraw, then current Search/Debug QA extension behavior.
- **Candidate:** skip the early generic Beta redraw. At ordinary Beta exit/extension entry, after checking fewer than two extension hands and cash at least four monthly rents, if Search for Bugs is absent, the per-phase policy redraw is unused and runtime redraws are positive, redraw exactly one visible card. Keep the best existing-scored four-card set, requiring a Debug in that set when any Debug is visible; discard the **last candidate-array index outside that set** (same ordinary discard ordering). Lexicographic combination enumeration preserves existing ties. If no legal four-card set exists, do not redraw. This preserves a Debug where available. Mark the allowance spent on issuance; no retry on rejection.
- After redraw, use the unchanged QA rules: select Search and Debug when both visible, Search alone if present, or Debug only with positive known Bugs; otherwise exit. The candidate can reserve the allowance and never use it. It cannot redraw after the two extension hands are spent. Never read hidden Bugs/future draws or infer hidden state from diagnostics.
- Exactly the old ceiling of one redrawn card per phase; Design/Alpha redraws, play scoring, purchases, reserves, contract policy, Review7 gate, rewards, base card scores, rent/credit, player hand limits and runtime rules stay unchanged. Budget ceilings match; realized redraws/hands/purchases and future RNG can differ. Compare complete routes, not a false claim of identical downstream draws.

## Measurements and checks

Record commands/rejections, actual reserved opportunities/attempts, replacement identity, immediate Search hit/miss, subsequent Search/Debug plays, discoveries/fixes, no-effect QA hands, per-phase hands/redraws, release Review/components/zero-variance diagnostic, remaining Bugs, actual Crown unlock/release/cycle, scope completion, rent, cash lows/arrears, purchases, matched calendar and release results. Keep neutral-market versus actual rival exposure explicit. Review diagnostics are post-run only.

Run control before candidate in the first pair; inspect its status and independent policy audit before the second pair. At most two isolated runner processes. Each invocation uses a new external output directory under `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-beta-redraw-20261024-v1/`; runner `--timeout 600` separately bounds import and execution. Retain source, command, outcome and warnings; never change seeds/budgets to improve results.

Fresh-process exact replay: candidate Simulation4522, including telemetry. If incomplete, replay its retained prefix and the first complete candidate in declared order when available. Cold Studio-only Continue: first complete candidate (4522 preferred) through release7, maximum80 commands, same policy and mechanics. Verify exact initial state/RNG against original final values. These are verification cases, excluded from four-case numerical comparison. Use failure reduction on a recorded gameplay rejection/divergence when applicable; malformed policy tooling failures get a separately recorded corrected revision, not overwritten evidence.

Stop after four bounded cases, audits, representative replay and Continue, or a concrete blocker preventing valid execution. No broader seed sweep, reward tuning, default AI/gameplay adoption, graphical acceptance, commit or push. Recommendation is evidence with uncertainties; passing simulations do not approve balance. Finish a versioned finding/handoff/session log and minimally refresh the existing Crown DESIGN TODO paragraph, preserving concurrent entries.
