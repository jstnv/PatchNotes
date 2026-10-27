# Twelve-Scope starting pools — 2026-10-27

User request: "nerf the starting pools for each genre ... starting pool only add up to12 scope." Read CURRENT_STATE/TODO/README, relevant Genre/root-first design and findings, source/status/diff before edits. Shared dirty `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`. Existing edits and `.codex-godot-temp` preserved.

## Implemented

- `scripts/studio_specialties.gd`: new founding version4, six common root Features plus fixed genre-specific subsets of v3. Every pool totals exactly12 Scope, counts9–11. Explicit membership prevents random/future auto-grants; fail closed if definitions no longer total12. Historical1/2/3 behavior retained. [Full pools](../design/genre-specialties.md#new-founding-rosters-v4--twelve-scope2026-10-27).
- `scripts/persistence/studio_checkpoint.gd`: current metadata admits4. Hydration keeps saved membership and RNG; historical validators were not broadened.
- `scripts/market/rival_world_checkpoint.gd`: exact preceding runtime `3eb0f864ee07afc000f7ac087b5b1b7c2396d93e89056b53a84900b9e4954560` admitted under ordinary full validation. Saved fields and unknown-source rejection unchanged.
- Maintained verifiers updated to current v4 fixture; old1/2/3 fixtures retained. Version tests explicitly preserve historical Maps routes. Creation UI checks the actual current promised membership rather than its old hardcoded18 cards. New fixed fixture `scripts/debug/fixtures/studio_specialties_v4.json` is independently authored from raw printed values.
- Broad campaign parity adds optional explicit founding-fixture version and exact initial-checkpoint artifact. Long Bank/payroll matrix uses recorded v3 supply; dedicated current v4 scene/headless cases exercise every specialty with its matching project Genre and Continue. No Bank rule was altered to make a loan test pass.
- Shared creator/factory gets the same default. Incumbent trial extras/archive/funding/policy unchanged; Action keeps their parent paths. No card-ledger, price, starting-cash, scoring, project Scope30, Research, tutorial or audio change. Existing EXE/ZIP unchanged.

## Verification

Evidence: `docs/codex/findings/starter-scope-20261027-v1/`, including exact before files, genuine pre-edit saves, plan/rulings, every command/exit/error receipt, typed tapes/checkpoints, source manifests, scoped diff and audit. Bundled Python runner: `-X utf8 .../run.py LABEL SCRIPT [--native]`. Godot4.7.1, Dummy audio, private profiles/writer ports; player saves untouched.

| Label / coverage | Result |
|---|---|
| baseline-rosters | PASS16: all8 actual preceding Studios, fresh and one legal optional purchase each |
| baseline-world | PASS2: actual preceding Studio plus rival world |
| red / root-first verifier | Expected24 failures on old default version/membership/persistence |
| roots-v2 | PASS229: exact8 fixtures, actual printed Core/12 Scope, all named parents, no familiarity/regrant, current saves, unchanged incumbent bonus parents |
| versions | PASS220: historical1/2/3 previews and saves; current old-version research quotes/transactions and invalid-version rejection |
| specialties-v2 / native-menu | PASS188 each headless/rendered creation, all8 previews, commits, discard, repeat prevention and initial/next supply |
| old-rosters | PASS65:16 real old fresh/purchased saves preserve ownership/cash/RNG and future supply, no regrant |
| cold-world | PASS10: exact previous player/world/RNG, unchanged save bytes, no replacement generation, unknown source rejected |
| checkpoint | PASS46 typed codec checks |
| first-games-v2 | PASS184:8 ordinary-funded matching-Genre first releases,144 legal commands and exact result/state/RNG replays; no Store buying or extra funding |
| v4-live-genres | PASS120 matched scene/headless boundaries across8 specialties/matching project Genres, including real Studio flush/Continue |
| historical-live | PASS106 matched broader Bank/payroll/research/contract boundaries with explicit historical v3 foundation |
| rivals | PASS120,20 cycles/four live releases, exact current Continue/market/RNG; trial policy unchanged |
| identity-final / audit.py | PASS: current non-debug resource bytes match manifest; exact predecessor reconstructs from retained originals; all8 fixtures strict v3 subsets with12 Scope |

Final runtime identity `6e31125897228a4a80f175f449f0fdd52400079450a310b4ee6f40a71d063d4a`. Independent scoped production and additional test review: no actionable findings. Reviewer caught a coverage wording caveat in the first native case set (all specialties used Action projects); the final `v4-live-genres` explicitly passes each matching Genre. Earlier passing Action-project case set retained.

## Retained diagnostics and limits

- First enhanced root check compared typed integer Core totals directly with JSON float arrays; normalized independent expected numbers to integers. The failing8-assertion receipt is retained. The UI fixture's old18-card literal was replaced with its actual promised current membership; retained one-failure receipt.
- Initial new route harness accessed absent `payload` on the launch policy choice and timed out at130s; fixed the test adapter to default an empty payload and add its own bounded timeout. No runtime fix claimed. Final8 routes complete normally.
- Original fresh-v4 broad matrix reached32 matched boundaries before its fixed Bank loan was legally denied. Retained as a supply/balance consequence, not a live/headless divergence. No underwriting relaxation/funding injection. Broader historical transaction coverage is explicit v3, with an exact exported initial checkpoint for CLI reproduction; current v4 first-release/Continue coverage stays separate.
- Finite fixture uses seed4417, Features-first2/2/2 hands; first releases play10–12 Scope against required30, with ending cash$3,610–$3,750 at cycle7. These are legal under-Scope releases, not optimal strategies or final economy/AI balance proof. Twelve starting Scope is approved by the direct user request; wider balance and human experience remain separate.
- Existing missing-artwork, incomplete-selection and ObjectDB cleanup warnings remain; successful receipts contain no SCRIPT ERROR/ERROR/FAIL. No allocation/performance/visual-art fix or whole-release readiness claimed.

Updated Genre design, cross-system decision, CURRENT_STATE and TODO minimally after re-reading queue, plus this log. No commit, push or export. Evidence uses compact tapes/checkpoints and saved changed files, without cloning whole projects into each experiment.
