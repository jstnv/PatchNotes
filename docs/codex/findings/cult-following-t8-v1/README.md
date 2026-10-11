# Cult Following T8 — local implementation and non-interactive acceptance

2026-10-10. Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, shared uncommitted worktree preserved. User requested feasible TODO implementation without computer control. No commit, push or export claim.

## Implemented ACTIVE/TRIAL

- New traits7: Cult costs one positive point and atomically seeds40 ordinary Fans at successful Studio creation. Cult-only starts$5,650; no-trait starts$5,700. Duplicate/invalid confirmations do not reseed or pay.
- Existing monthly gain/loss and frozen launch mapping apply unchanged. No protected Fans or extra Awareness/sales multiplier. Untouched40 Fans contribute10 Fan Awareness.
- Historical traits3–6 Cult previews remain inactive. Checkpoint replay derives the seed from validated traits, with no unverified seed field. Prior content revisions reject a newly active trait version.
- Selection copy and Overview show the trial terms and starting Fans. Headless layout/copy tests pass at1152×648 and1280×720.

## Compatibility defect found and repaired

The education regression suite initially failed six exact historical preview fixtures with `INCOMPATIBLE_CONTENT_OR_RNG`. The soundtrack's audio-credit JSON change had altered the broad data hash. The prior education snapshot and current source have identical gameplay JSON hashes: audio credits is the sole difference among six data files (`audit.json`).

New revisions omit `audio_credits.json`. Legacy revisions are recalculated with the two verified credit-manifest hashes, retaining every other data hash and full schema/provenance validation. Exact original education fixtures now pass. This does not accept arbitrary gameplay revisions or convert inactive previews. New revision: `668990bdd7aafab7ba7c4c064fe1ce04b13f8ba5422669d0bf3c2e580ccb61df`.

## Verification

- Clean Godot4.7.1 headless import passed (`import-v2`).
- **17 distinct focused suites passed**, listed with exact commands, isolated profiles, source hashes and error scans in `suite-summary.json`: Cult, Studio traits/folder, Fanbase/incremental/checkpoint, Awareness, education/debt/atomicity/edges, codec/store/runtime/Studio/Genre checkpoints, Predevelopment and Starwave.
- New Cult verifier: **136 checks, zero failures**. Includes invalid/duplicate creation, combinations, old versions/revisions, tampered Fans/seed/version, no-sales rent, neutral/weak/strong constructed ledger boundaries.
- **20 fresh processes** passed (`restart.py`, `restart-summary.json`): control/Cult creation and three legal launch checkpoints, exact Continue, tampered-save rejection preserving good bytes, constructed5.0-neutral boundary and a saved traits6 inactive Cult preview. Full finance/Fans/metadata/traits/RNG equality checked. Old-preview fixture is explicitly constructed; native launch inputs are real route outputs.
- **Two legal matched three-release routes**, seed1104, same cards/draws/actions/fees/Core/cycles, native Reviews5.4/0.4/4.1. Genuine startup point cash; no injected Review/Fans/funding. Productive actions and ordinary contracts used; no free calendar waits. `route-control/fit.json` and `route-cult/fit.json` retain all actions, finance, Fan history and Studio checkpoints.
- **776 independent Python assertions** pass (`audit.py`, `audit.json`): matched actions, transaction continuity, earned/settled sales, monthly Fans, rent, cycles, startup versions, frozen launch mapping and data-hash comparison.

| Result at cycle28 | No Cult | Cult |
|---|---:|---:|
| Startup cash | $5,700 | $5,650 |
| Cash low | $1,390 | $1,340 |
| Final cash | $3,124.12 | $3,318.88 |
| Earned and settled sales | $5,195.79 | $5,440.55 |
| Launch Fans, Games1/2/3 | 0 / 8 / 6 | 40 / 48 / 17 |
| Final Fans | 6 | 17 |
| Rent paid | $7,000 | $7,000 |
| Feature play costs | $3,130 | $3,130 |
| Final credit | 603 | 603 |

Cult spends one of two positive slots and$50 of unused-point cash. This route ends$194.76 ahead, but it is one starter-only policy and seed, not final balance evidence. Store/Research purchases, Bank and payroll were not activated in this route; their absence is explicit in the audited ledgers. Education/Lease/other-trait combinations have focused acceptance, not a new broad economy study.

## Reproduction / remaining acceptance

Use the Python and Godot executable paths recorded in each `command.json`. From repository root:

```text
python docs/codex/findings/cult-following-t8-v1/run.py <new-label> verify_cult_following.gd
python docs/codex/findings/cult-following-t8-v1/audit.py
```

`run.py` creates fresh APPDATA/LOCALAPPDATA and uses the established verifier-only port47733 wrapper; restart probes use dedicated48973. User saves, existing game and editor were untouched. Output directory labels must be fresh. `restart.py` consumes the recorded native payloads and creates fresh per-boundary profiles; use fresh output directories to rerun it.

The first education failure is preserved in `education_debt-final`; corrected results are `education_debt-v2`. Godot emits the pre-existing root-certificate warning and two WAV shutdown-object leak warnings in headless runs; they are disclosed, not counted as gameplay failures. No audible test, computer control, new export, physical text inspection or long-run balance claim. The old105-suite export predates soundtrack/Cult. Interactive exported acceptance remains open by current user scope. AI planning/cohort/entrant/news/performance inputs remain explicitly OPEN in TODO; no candidate default was implemented.
