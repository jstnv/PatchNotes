# Acceptance and foundation integration — 2026-10-17

**Local implementation and bounded acceptance complete; remaining limits below.** Main at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, with the pre-existing dirty workspace preserved. No commit or push was made. The user requested the AI campaign and failed-launch Promotion first, then remaining feasible TODO work. [Declared plan](PLAN.md), [independent audit](audit-result.json), [session log](../../logs/2026-10-17-acceptance-and-foundations-v2.md).

## Exported acceptance

| Check | Result and actual boundary |
|---|---|
| Ordinary AI campaign | **PASS:** start from the retained real new Studio; play Design, Alpha, Beta and launch, reaching cycle7 and both rivals' first live releases. Cold Continue, complete Ironclad through cycle9, then cold Continue again. Both rivals have begun their next projects. The two checkpoint generations remain byte-identical after restart. This is a nine-cycle campaign, not a 40-cycle stress result. |
| Promotion rejected/cancelled launch | **PASS:** from a legally earned Neon bank of20, skip Design and observe Alpha's zero-Feature Beta guard. Play a legal Alpha hand, enter Beta, open the launch warning and cancel. Quit with rollback warning; fresh Continue returns to Studio17 with20 Promotion,53 Fans and540244 cents. The retained checkpoint matches its legal origin byte-for-byte. The native invalid-commit test remains separate; no debug corruption was injected into the export. |
| AI cross-revision Continue | **PASS for the named prior source only:** unmodified cycle7/9 exported checkpoint envelopes restore on the integrated source, then are saved and restored in a second fresh process. Rival project, hand, RNG, finance, archive and release fields are preserved. Unknown source IDs still reject. The explicit compatibility entry is `3e0d3958740f71149b3bb5b3e9f0b15b70cc6d71c96c6c03dd1f594d56a71c8f`; it accepts only the earlier world shape without Founder metadata. This does not establish arbitrary old-world migration. |
| Integrated export | **PASS:** corrected clean import/export,297-entry package audit including nonempty `project.binary`, ordinary cold Continue at1152×648 and1280×720 on v3, followed by1280 Continue on final v4 after a UTF-8 text repair. The final build matches current canonical runtime files. |
| Bank aged-payment route | **BLOCKED at the recorded legal routes:** twelve declared reserve routes, then three bounded adaptations, produced genuine arrears or an unaffordable next hand before an aged education checkpoint. No exported elapsed-age pass is claimed. All inputs, actions and rejections are in `age-probe-v1` through `age-probe-v5`. |
| Older education arrear + newer Bank elective payoff | **INACCESSIBLE at the ordinary public-action boundary examined.** Automatic service consumes available incoming cash against due bills; public finance cannot retain an unjournaled positive-cash/arrears state. The290-check education edge suite verifies ordering, atomic rejection and explicit private payment-plan vectors. Those vectors are labelled as such and do not count as an exported payoff. |

The original AI/Promotion routes used [the retained B export](acceptance-build-manifest.json). Its source pin is [retained here](acceptance-source-pin.json). Final export: [v4 build manifest](final-delivery-v4/build-manifest.json), [297-entry audit](final-delivery-v4/pack-manifest-verified.json). EXE SHA256 `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`; final PCK `a6889d1ff05828e6881c9bc87781093a851f752a916d3dac85f1df475a8d8103`. These are distinct source/build boundaries; the whole publisher matrix was not replayed on one final binary.

[Capture index](captures/index.jsonl), [original five process exits](ui-processes.jsonl), [later build launches](final-ui-processes.jsonl), [cycle7](milestones/long-ai-studio7.json), [cycle9](milestones/long-ai-studio9.json). All seven successful pre-v4 UI processes exited0; final-v4 exit is recorded separately in the same log. Dummy audio was used, so no audible claim follows.

## Approved foundations adopted

### Contracts definitions

Reconciled the sealed Contracts candidate, adopting only its delta. `ContractDefinitions` centralizes the five existing IDs, titles, targets, hand counts, score profiles and frozen terms. Existing `ContractState`/`PublisherTrialTerms` callers and checkpoint shape remain compatible. Cash, gates, eligibility and Promotion values are unchanged. [Adoption hashes/backups](foundations/adoption.json).

The four-release Crown route completed85 commands, then replayed exactly in a fresh process. Its pre-foundation baseline matches at all85 command boundaries after removing only the new **empty** ordered-contribution member from the legacy card-definition projection. Every result, run/project state, finance and RNG field remains compared. [Comparison](comparison-crown-v2.json), [current run](integrated-crown-v2/run-report.json), [exact replay](integrated-crown-v2-replay/replay-report.json). The source identity fence was not weakened or bypassed in the maintained replay engine; the explicitly labelled compatibility projection is an analysis-only comparison.

### Studio Traits registry

Adopted only `studio_traits.gd`: point amounts, first active saved versions and historical active order derive from the existing catalog. The665 version3–8 snapshots reproduce the baseline bytes: SHA256 `1d37d99c818e4502064f4ea329a602b8631ecfe4b917c2d92642bf8a97cb3aea`. Two fresh two-release routes complete36 commands each and match the prior outcomes at all72 boundaries with the same empty-field normalization; the selected-Traits route also replays exactly. No trait value, effect or save migration changed. [Snapshot/process checks](fresh-world-v3/results.json), [control comparison](comparison-traits-control-v2.json), [selected comparison](comparison-traits-selected-v2.json), [run](integrated-traits-v1/run-report.json), [replay](integrated-traits-v1-replay/replay-report.json).

### Ordered three-Core support

Card data accepts one to three ordered, distinct positive integer Core entries for Design/Alpha. Validation rejects malformed, duplicate, mixed legacy/new and excluded-phase definitions. Legacy primary/secondary fields still adapt unchanged. Production, weighting, Bug Pressure, observations, hand preview and Store text read every entry; primary-only specialization retains authored order. A third Godot text field appears below the top band only when present. No live card ledger, price, fee, Contract eligibility or Employee third-category matching was added.

The99-check verifier covers strict validation, weighting, raw pressure, finite lifecycle, specialization, legacy catalog arithmetic and view reuse. Native/headless Design and Alpha each match complete project, event order, refill and RNG state on the same synthetic three-score hand. Both-size rendered fixtures show third, second and single score cases; the deliberately long synthetic department abbreviates with full tooltip text. [1280 render](rendered/three-core-1280.png), [1152 render](rendered/three-core-1152.png). Existing51-card frame fit passes1705 checks with no abbreviated catalog fields. Missing `split_screen.png` uses the existing artwork fallback and remains an asset warning.

### Founder/ownership integration

Adopted and hardened the pure candidate records/planners/codec, then connected an **explicitly initialized** optional world extension. No default formation split, valuation, outside funding or takeover policy is enabled. New-game behavior remains unchanged until an approved caller initializes ownership.

- Consented primary/secondary transactions validate funds, already-due liabilities, revisions and ownership cycles. Every corporate cash leg and cap-table change publishes together; reentry and duplicate settlement reject. Capital has separate in/out finance fields and is excluded from operating profit/credit inputs. Pending offers and consents persist with the world.
- Saves cross-check each ownership cash event against the exact finance action and use the Studio envelope's exact-integer encoding. Old saves without this extension retain their shape. The additive finance row fields remain under schema6; an older reader cannot be assumed to load ownership-bearing saves.
- The Gameplay API switches the sole manual operator only at a safe Studio boundary with direct Founder majority and an idle target Studio. The former Studio retains its full state and advances through ordinary AI commands. Corporate control chains, CEO mandates and a player-facing formation/ownership flow remain future design/integration work.
- Focused foundation27, world30 and Gameplay10 checks pass. Reentrant observers see the fully settled state; malformed event integers and mismatched cash histories reject. A fresh-process whole-world save/restore pair preserves ownership, pending consent, finance, former-Studio activity and operator identity. Normal Gameplay tests exercise automatic Studio save and rollback of an unsaved next project. This is a tested foundation API, **not a completed playable Founder career loop**.

[Adoption record](foundations/founder-adoption.json), [final world/API checks](final-ui-wire-v7/results.json), [six fresh world processes](fresh-world-v3/results.json).

## Repairs and verification

Fixed Studio dashboard bounds when it becomes visible after Review, and shortened/wrapped Alpha's zero-work guard text. Repaired text encoding in `phase_workspace.gd`; multiplication symbols and arrows retain their original text. The checks wait for the existing menu transition before asserting final positions. Gameplay scoring and timing rules are unchanged by these repairs.

- [Final focused regression](final-focused/results.json):20/20 suites pass, including Contracts, Traits/Cult, checkpoint, cards, Store, Bank, finance and native/headless command oracles.
- [Integrated checks](integrated-v6/results.json):7/7 suites pass, including new ownership/API, three-Core parity, AI activation, Promotion failure and education edges.
- [After final text repair](final-ui-wire-v7/results.json):5/5 affected suites pass; six fresh world restore processes and the665-case snapshot pass again.
- [Independent audit](audit-result.json): exact checkpoint bytes/checksums, transaction continuity/cents, bill payments, live-release uniqueness, process exits, campaign comparisons, package contents and current runtime hashes. The count and timestamp are authoritative in the JSON.

This is focused evidence with explicit source snapshots, not a fresh uninterrupted run of every maintained project verifier. Earlier failed attempts are retained: missing verifier names, missing fixture/output environment, a fixture supply mismatch, random test release IDs, dictionary-key order in a comparison, numeric save-version encoding, and two failed package launches caused by inaccessible export temporary storage. Corrected export helpers now reject `ERROR:` lines and require `project.binary`. Native ObjectDB exit warnings remain visible; no clean-shutdown claim is made.

## Remaining work

1. Exported elapsed Bank/education overdue-age interaction remains unverified; retain the bounded failures and devise a new legal route before another attempt. The older-education/newer-Bank payoff is not a passed exported case.
2. Human Bank quote comprehension, audible music/SFX/mute/loop feel, clean-machine acceptance and deferred human Store testing remain separate. Agent screenshots and Dummy-audio runs cannot close them.
3. AI Store/Core planner constants, detailed policy/entrants/news and representative population performance; Founder valuation/credit/formation/mandates/UI; Feature era/platform gates and authored content remain OPEN. Deferred balance studies were not restarted.
4. Broad final release acceptance retains the source/build matrix above. No final balance, release-readiness, commit or push claim.
