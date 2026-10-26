# Crown visible planning and bounded redraw — findings v1

2026-10-24. **Private experiment completed; Crown relationship rules remain OPEN.** [Pre-run plan](CROWN-PLANNING-PLAN-2026-10-24-v1.md) · [review handoff](CROWN-PLANNING-HANDOFF-2026-10-24-v1.md) · [exact commands](studies/crown-planning-20261024-v1/COMMANDS.md).

## Decision supported by this evidence

The tested retained-card forecast does not improve earned Reputation. The tested redraw heuristic helps one seed and hurts another; it can sacrifice an already positive final hand. **Do not recommend this redraw policy or activate Crown progression from this screen.** First test a conservative redraw that retains the best four visible cards. If access still misses the desired pace, compare completion-plus-balance standing against the current minimum rule in a separate declared experiment. Three-opportunity R20 is an investigation target, not an approved pacing promise.

This is not proof that Crown's formula is impossible, nor that balance-aware human play cannot do better. Only two seeds reached Crown. The first-hand forecast is approximate and the tested redraw strategy is aggressive.

## Authority and exact source

Branch `main`; HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared worktree dirty. Current local authority records SideStreet P2/P3 and P4 complete at their approved bounded ACTIVE/TRIAL scopes. Crown Briefs, commissions, support and numerical terms remain proposed.

The pre-run plan described the inherited source as intermediate P4 because it was captured before acceptance. **The actual runner finds zero canonical delta:** its original baseline equals the current canonical snapshot. P4 acceptance status advanced without changing these captured gameplay bytes. No blind rebase is needed to explain this comparison; refresh/reconcile current source again before eventual adoption.

| Identity | SHA-256 |
| --- | --- |
| Original baseline and current canonical at capture | `3f7df6cf437978aa9a119df09c175c8a720ce560d1a03abdaff46e26fd40fa10` |
| Parent Crown Brief candidate / creation | `5b56c077fa895c4e3b5a24667f4e341a5c1747060fac961e3f8947929ab23950` |
| `crown-planning-brief-v1` candidate | `30435aa3146a1e1c8f7835138173d92b2bb1d2170a5409bb2ae9cc0a09579a4c` |
| Frozen run source including supplied policy | `c9ffa36359c4eab8620895ccdf4edde603213187d458087f09f6cdc4e9444d0c` |
| Runtime mechanics | `812a6045d18b8e5ad2d157f41aec7598b81c16264531a8fd401a43efc4425b0d` |
| Policy | `7025907eed4189398c7c1229b5c084aab3bcac60032d2a5db540fe6590bb9df2` |
| Runner | `65bdf6c5eb4a47af829283a0b07d4b78ad45e8a95139607b96a613d6ffbf9193` |
| Godot4.7.1 console | `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef` |

The only project change from the parent is `scripts/simulation/contract_session.gd`: expose the detached integer `available_redraws` using `RunState.get_available_redraws()`. All ten inherited private Crown paths remain unchanged. The full eleven-path delta, original archives, manifests and parent lineage are preserved. This private schema remains fresh-save-only; no canonical migration was implemented.

## Setup and measurements

Three fixed seeds4417–4419, five policies, identical legal Action/Cult Following starting recipes and Studio identities per seed. Existing development route, Crown cash Contract and unlock precede separate zero-currency Crown Briefs. Two successful four-card hands per Brief, at most three Briefs, stop accepting at R20. Six-release/200-command cap per case;240-second process limit. Controls run before candidate policies. No seed substitution, increased horizon, runtime repair or second gameplay batch.

The unchanged candidate awards up to10R from `min(completion,balance)`, using Scope9/Core4.0 each, denominator66, full balance at spread≤2.0 Core points and zero balance at spread≥6.0. No cash, Promotion or Investment from a Brief. Policies inspect current detached observations only. The retained forecast uses the three unplayed visible cards plus average contributions from the observed seven; its hypothetical means are not legal draws and do not claim future pool/RNG knowledge. Final play enumerates all35 real quartets. Redraw replaces one excess-contributing card from the selected quartet, at most two tokens on hand2, using the actual available budget.

### Earned standing after three Briefs

| Policy | Seed4417 | Seed4418 | Tokens per completed route |
| --- | ---: | ---: | ---: |
| Prior balanced control |7.50R|12.50R|0|
| Retained-card forecast |7.50R|12.50R|0|
| Control + limited redraw |9.69R|10.00R|6|
| Retained forecast + limited redraw |9.69R|10.00R|6|
| Skip Briefs |0|0|0|

No route reachesR20; no full-grade Brief. Across eight take routes:24 Briefs,14 positive partial results,10 zeroes. These are policy comparisons on two common reachable seeds, not24 independent campaign samples. All12 redraw-using Briefs consume two tokens. Each route ends with4 tokens after ordinary regeneration; final stock does not mean redraw was free of intermediate resource use.

The forecast changes some visible choices on4417 without changing its outcome; other paired traces match. Redraw can help immediately:4417 Brief1 improves from zero to96.96% grade. It can also destroy available progress:4417 Brief3 drops from50% to zero after redraw;4418 Brief2 drops from75% to25%. Later Brief draws differ because redraw advances Contract RNG, so whole-route differences cannot be attributed solely to the immediate replacement. [Per-Brief diagnosis](studies/crown-planning-20261024-v1/diagnosis-v1.json).

### Cash, time and failed access

All take policies finish six releases at cycle48 versus skip at42. Final cash is identical across take policies within each seed:4417 `$7,428.60` versus skip `$8,837.69`;4418 `$12,200.26` versus `$13,434.53`. Same-release cash deltas are `-$1,409.09` and `-$1,234.27`, with six extra productive cycles. At the last shared calendar cycle42, deltas are `-$20.21` and `-$1,995.17`, but release progress differs. These include cadence/sales/rent effects; they are not a cash fee imposed by Briefs. Later tiny development projects remain a study-policy limitation.

All five4419 cases fail on the same game3 Design affordability action before Crown unlock/any Brief:53 recorded/52 accepted commands, two releases, cycle25, `$116.68`, zero overdue. Prior Reviews2.4/6.0 fail Crown discovery. Full failed-prefix state/RNG match across arms. Retain this intake failure; it is neither a Crown redraw failure nor permission to inject an unlock. No additional failure reduction was needed for this unchanged, pre-intervention rejection.

## Verification and retained limits

- **PASS:**576 analysis checks of matched initial complete state/RNG and first-Brief boundaries, independent scoring/projection/policy ranking, legal finite Feature use, actual zero currency/Investment, one P1 source per result, two hands, actual bounded token debit, saved counters and release pacing.
- **PASS:** controls match all prior outcome/RNG fields; all four successful balanced/skip controls also match the prior entire durable Studio payload. Different mechanics identities were not rewritten or bypassed.
- **PASS:**130-command control replay and136-command redraw replay in fresh processes, exact state at every step/final boundary.
- **PASS:**15-command cold Studio Continue to release7/cycle52; initial complete state/RNG match exactly, completed Brief scores/redraw counts, pending offer and complete P1 event history remain unchanged.
- **PASS:**865 integrity/closeout checks, mostly file hashes plus replay/save assertions; original archives/ancestry, parent candidate, plan, policy and cases remain unchanged. No Starwave legacy-count leak or unintended commission/support deal.
- **RETAINED FAILURE:** batch exits1 because five of15 cases reject the known pre-Crown action; ten complete. Total1,559 recorded/1,554 accepted commands. Replays, continuation and analyses exit0. No timeout/import/script error. Four processes each log the existing six-ObjectDB-instance exit warning; warnings are retained, not fixed here.
- **NOT RUN / OPEN:** conservative redraw, exhaustive optimal first-hand planning, other specialties/traits, broader seeds, longer access horizons, actual Crown commissions/support, adversarial migration/ownership/disk acceptance, maintained full suite, GUI/native/exported/human acceptance and final balance.

All simulated gameplay ran through isolated headless runner copies and profiles. No computer control, canonical gameplay, player saves, shared design authority, commits or pushes were modified. TODO receives a separate review entry only after this completed evidence.

## Evidence

[Analysis](studies/crown-planning-20261024-v1/analysis-v1.json), [integrity/source/command-result closeout](studies/crown-planning-20261024-v1/closeout.json), [policy](studies/crown-planning-20261024-v1/policy.gd), [cases](studies/crown-planning-20261024-v1/cases.json), [observation patch receipt](studies/crown-planning-20261024-v1/prepare-receipt.json). Raw frozen projects, all cases/failures, command JSON, replay tapes, saves and logs remain at `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-planning-20261024-v1/`; selected exact hashes are in closeout. This new evidence supplements the [prior balance study](CROWN-BALANCE-FINDINGS-2026-10-24-v1.md) without overwriting it.
