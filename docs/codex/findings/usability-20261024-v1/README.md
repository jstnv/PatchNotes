# Studio, priorities, Store and Bank usability — 2026-10-24

**IMPLEMENTED locally** for the direct user request. Bank recovery/defaults and the new 10% floor are bounded ACTIVE/TRIAL choices; final balance and human comprehension remain OPEN. No commit, push, refreshed release EXE or release-readiness claim.

## Source and actual scope

- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. The inherited dirty worktree and `.codex-godot-temp` were preserved.
- Final runtime identity `6b39be120a228132e8cd78b6c00194fc95f734430ee485901d3479d20b61d315`. [Complete source manifest](source.json), [63-path delta against the frozen starting checkout](adoption-delta.json), [frozen predecessor reader ancestry](frozen-reader.json).
- Ordinary card rules, score calculations, sales and publisher terms were not changed. New priority choices intentionally use the new floor. Continue remains Studio-only.

## What changed

- New Trait selections use version9: no count cap, real negative draft balances, invalid-point Play guard, unchanged point/effect amounts, and one education history. Versions3–8 retain their original accounting/effects/count rules.
- Selected/Available lists show names only, positives before negatives; descriptions and point prices are on hover. Balance and startup cash bonus remain outside scrolling. Overview has independently scrolling positive/negative columns and a negative-balance direction back to Traits.
- Contextual tips have no expiry. Close and Tip work; transient hand motion and automatic phase-context changes preserve an open tip. Explicit full-menu replacement/navigation still uses the existing context controls.
- Contract and Specialist planning use sliders with the existing priority pie. New Core/Beta/employee/Contract commands require10–50 in five-point steps, total100; historical5% allocations remain readable without reweighting state/RNG. Draft totals display `X/100`; one cosine pulse tints every slider white→red→white over1.4s, starting at0 on each over-budget crossing and clearing when corrected.
- Store details show Core/Scope and play cost. Acquisition amounts are on action buttons; familiarity/parent-project credits are on purchase hover. Missing named parents replace purchasing with an untruncated, wrapping navigation action. One parent navigates directly; an AND gate offers both targets. Category cone backgrounds/borders are removed; nodes, headers and paths remain. Research confirmations retain irreversible-payment information; detailed forecast cautions remain in Debug.
- Bank2 quotes clamp positive exact-cent requests to qualified bounds. The new minimum is three actual rents ($1,500 base/$1,545 Expensive Lease). Ordinary lending retains the conservative two-positive-settlement basis and reserves all existing Bank installments against the shared capacity. Arrears no longer hard-block quoting; existing ordered recovery deducts them from proceeds. A cash-poor Studio can use one three-rent recovery facility in its lifetime, including with active debt. Full principal and ordinary positive interest remain owed. Rich/no-sales Studios get no facility; borrowing never becomes sales/profit/credit. Multiple active loans have explicit schedule/payoff selection.
- Versioned quote replay plus a frozen exact P4 reader preserve accepted old debt and saves. New public acceptance cannot use an old quote to bypass current rules. Only the exact accepted editor/PCK predecessor world identities are added.

## Verification

| Gate | Result | Boundary |
| --- | --- | --- |
| Maintained verifier coverage | **182/182 have a passing receipt** | Source-fenced union of one broad182-suite run and focused continuations; **not** one all-green run on a single final source. [Per-suite provenance and failures](coverage.json). |
| Final affected matrix | **17/17 PASS**, canonical unchanged | Bank, Traits, HUD/tips/pause, priority influence, Store/parents/research/advice, publisher support and checkpoints; includes106 matched native/headless campaign boundaries across two legal routes. |
| Bank2 adversarial checks | **38/38 PASS** | Arrears deduction, active-debt rescue, automatic maximum, actual rent, no facility stacking/wealth subsidy, duplicate/tampered/versioned quotes, historical journal replay, immediate borrow/payoff neutrality. |
| Current/prior persistence | **23/23 PASS** | Trait9/Bank2 checkpoint; actual P4 compiled player and populated active/Founder worlds; actual prior EXE earned generation; every saved field/RNG equal, unknown/mixed source pairs rejected. |
| Independent OS-process reader | **18/18 PASS** | Fresh isolated profile restores current checkpoint exactly and repeats predecessor gates. |
| Review regressions | **12/12 PASS** | Historical Beta reset, both active-loan schedules/payoffs/confirmations, open tip during empty transient guidance. Independent read-only reviewer confirmed fixes with no remaining important finding. |
| Native rendering | **52/52 PASS**,14 captures | Actual Godot/OpenGL,1152×648 and1280×720. Trait controls, Overview, map/AND action, Contract slider/pie/red pulse and confirmed native Bank recovery. Component/render/input-signal evidence, not direct release EXE or human usability approval. |

[Final audit receipt](final-audit-result.json), [native receipt](final-audit-native-native-result.json), [raw evidence locations/hashes](external-artifacts.json). Five representative captures are retained under [captures](captures/). The final audit and final affected matrix use the same immutable final source; both report canonical unchanged.

### Retained failures and repairs

Initial RED checks reproduced capped/missing Traits UI, hidden negative accounting, eight-second tip expiry, numeric Contract controls, verbose Store details and Bank rejection. Early verifier compilation errors were repaired and retained, followed by actual baseline behavior failures. Review found and fixed transient tip dismissal, Beta's legacy-draft overwrite and inaccessible older loan payoff.

The broad run retained23 failing suites: old cap/version/5%-bound/timer/Store-copy assumptions and early Bank route qualification. Historical digests were not rewritten. Metadata normalization is restricted to old-cap-valid, non-Cult selections; Bank1 journal checks run the frozen Bank1 implementation. Current financial tests derive signed Bank2 installments and preserve payment-order assertions. A bounded2/3/4-hand route probe found a legal four-hand first-release route that qualifies for the new loan minimum; both live/headless paths use those same actions. Two simultaneous test runners also exposed the shared47733 test lease; generated wrappers now retain a strict dedicated-port guard with a separately recorded47700–47799 test port. The production62741 lease is unchanged. [Coverage](coverage.json) retains failing and passing run references; no failed receipt is presented as a pass.

## Reproduction and remaining limits

Use the bundled Python and Godot paths recorded in [work.py](work.py). `all_checks.py --output <fresh-temp-path> --port 47735 --tests <suite names>` repeats the affected matrix. [final_audit.py](final_audit.py) creates an immutable copy and independent profiles, then runs persistence, cold, review and native jobs. External predecessor fixtures are explicitly optional for the maintained persistence verifier and supplied by the local audit driver; raw paths are in the manifest. Use a new output/version for another run.

Human preference, long-term Bank balance and the 10% floor remain OPEN. No computer-control interaction or release EXE export was necessary for this request; native screenshots do not establish clean-machine, device, audible or final release acceptance. Existing missing-art fallback/leak warnings remain recorded in raw verifier logs.
