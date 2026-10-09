# Checkpoint and Crown/Neon implementation

2026-10-07, local `main` at starting HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`, with the working-tree changes recorded in `contracts-implementation-v1/source-state.json`. No commit, push or release-readiness claim.

## Delivered locally

- Full typed Studio checkpoint adapter/coordinator, run-owned RNG and stable project IDs, Continue, explicit backup recovery, New Run archives, save-failure controls and unsaved-exit warnings. All 42 RunState members are classified in the [field audit](checkpoint-runtime-v1/field-map.json).
- Crown and Neon first-unlock offers, chooser, immutable acceptance inputs, displayed/frozen Neon focus, two native Contract hands, exact approved cash and separately floored Promotion. SideStreet requires committed Ironclad completion; Starwave counts distinct completed offers without gaining an offer.
- Promotion is banked by offer ID, added before Buzz/Unknown Name in the one frozen launch Awareness result, and consumed only by its next successful release. Failed/duplicate launches preserve the bank. History, sales and unlocks share that result.
- Completed/pending offers, receipts, results, earned/consumed Promotion, finance/Bank/payroll, traits, ownership/familiarity, release histories and nine RNG streams restore without executing gameplay callbacks. Validation cross-checks Contract receipts/two productive hands, Primitive-only pools, approved terms/focus and Promotion's next-release identity.

The approved trial values are unchanged. Final balance, Starwave gameplay, courses and Fanbase rates remain open.

## Evidence and commands

Run these from the repository using the installed Python and Godot 4.7.1 recorded in each command JSON:

| Check | Evidence/result |
|---|---|
| Maintained regression gate | `python docs/codex/findings/contracts-implementation-v1/full_gate.py`: **83 suites passed** cumulatively. `gate.json` retains commands/results. After the final adapter validation change, relevant capture/runtime/Promotion and both process gates passed again. |
| Offer/cash/Promotion/liquidity boundaries | `verify_publisher_trial_offers`, `verify_publisher_trial_cash`, `verify_publisher_trial_promotion`, `verify_publisher_trial_liquidity`: zero failures. Zero/partial/full formula caps, exact cents, pending coexistence, stale/duplicate rejection, low-Scope native Pass hands, first-hand arrears rejection and hand-two income recovery. The liquidity/launch setup is a declared boundary fixture, not a legal balance playthrough. |
| Banking restart | `python docs/codex/findings/checkpoint-runtime-v1/process_gate.py`: seven independent processes pass initial → loan/hire → installment → payoff → unsaved acceptance → completion → reload. Every mapped field hashes identically before further native actions. |
| Crown/Neon restart | `python docs/codex/findings/contracts-implementation-v1/process_gate.py`: seven independent processes pass pending → unsaved acceptance → unsaved hand → completed-but-unpublished → paid completion → consumed launch → reload. Both awards survive and consume once; corruption rejects whole restore. |
| Native legal routes | `native_routes.py`: nine three-release routes across ordinary/current $5,700, synergy/legacy $5,500 and synergy/Lean+Buzz+Lease starts. Actual candidates, card selection, production, launch and finance callbacks; no money, scores, cards or Review injection. Seeded RNG/policy inputs are explicit. `native-crown-followup.command.json` adds a four-release route with Crown, payroll, accepted $500 Bank loan, eight dated installments and explicit payoff. Total: 31 releases in these ten recorded routes. Raw traces are losslessly retained in `native-traces.zip`, with original names/hashes in `native-traces-manifest.json`; rerunners regenerate raw JSON. |
| Rendering/navigation | `capture_ui.py`: chooser, Crown/Neon terms/focus, native hand results and bank notice at 1152×648 and 1280×720. Images inspected. Back/accept/dismiss and existing menu navigation pass. |
| Package | `export-checkpoint-contracts-v1/export.py` and `inspect.py`: fresh matching official templates, clean import/export, runtime allowlist, per-file hashes and PCK checks. Final manifest contains artifact paths/hashes. |

The application-wide writer lease correctly refused an additional writer while an editor-launched game held port 62741. That game was left untouched. Final restart/runtime reruns used `PN_CHECKPOINT_TEST_PORT=47412` in **test scripts only**, pre-acquiring an isolated TCP lease; production storage and port are unchanged. Process result JSON records this substitution. Earlier standard-port full-gate and restart checks passed. This tests isolated persistence without claiming two production writers can coexist.

Known environmental root-certificate messages are excluded explicitly. The two pre-existing deliberate invalid-scene/snapshot tests have named expected errors. Missing optional artwork produces existing warnings; no new placeholder art was introduced. Test-fixture errors were corrected and rerun, not treated as successful tests: Crown Pass Promotion expectation was corrected from 4 to 8; navigation now injects its replacement run before attaching the scene, avoiding an unrelated save-error modal; the matched continuation initializes its inherited policy context.

## Conditional comparisons, not balance approval

At cycle 35, after the identical first two releases and payroll hire in each cohort:

| Cohort | Neon route cash | No-offer next-project route cash | Arrears | Credit |
|---|---:|---:|---:|---:|
| Current, ordinary | $5,141.57 | $3,290.41 | $0 both | 606 both |
| Legacy, synergy | $5,370.18 | $3,459.02 | $0 both | 606 both |
| Lease, synergy | $5,542.10 | $3,676.94 | $0 both | 606 both |

These cash differences include the next project's actual costs as well as Contract cash. They are conditional on the declared policies, not equal completed development output. Ironclad was already completed. SideStreet was unavailable because the releases did not meet its printed-Scope gate; the requested SideStreet arms therefore correctly matched no-offer behavior, and are not independent available-offer observations.

From the same real post-Game-3 checkpoint, two native Crown hands versus development departure plus one native Design hand end at cycle 55: **$11,658.38 versus $9,495.38**, no arrears, credit 618. Crown pays $1,920 and banks 12 Promotion; the four-release continuation consumes it at Game 4 (Awareness 126 including Buzz and marketing). SideStreet is still unavailable at that checkpoint, recorded explicitly in `matched-sidestreet.json`. Existing SideStreet regression and restart suites separately pass.

The integrated Bank route accepts $500 at cycle 55, first due cycle 58, pays eight issued installments and explicitly closes at cycle 73. Principal paid is exactly $500; interest paid is $28.33. Native finance replay and the resulting checkpoint validate. This is source-scene automation, not exported interaction or evidence that the economy is finally balanced.

## Remaining acceptance

**C1–C4 are implemented and locally verified within the documented conditional routes. C5 disk/once-only checks pass; its exported interaction/Continue extension remains open with Task11.**

Task10 runtime is present, but the entire historical A01–A12 matrix is not claimed complete. Outstanding breadth includes every phase-specific quit/replay path, the full multi-title purchase/reserve/campaign restart matrix, all after-publication/cleanup and archive/disk-permission fault cases, and the complete interactive keyboard/mouse/settings isolation matrix. Existing codec, prepublication failures, backup recovery, native RNG replay and process evidence cover named subsets only.

The release EXE started with OpenGL and loaded 40 cards. Official release templates disable external `--script`/path overrides, explaining the previous diagnostic timeout. Computer Use was initialized for actual exported interaction, but its app-approval request timed out before a controllable exported window was returned. No exported Bank/Continue/two-game playthrough, human balance acceptance, audible-audio gate or release readiness is claimed. The separately launched isolated startup process was stopped; the user's editor game was preserved.

Fanbase remains at its authorized two-attempt stop (Reviews 3.6/3.5 missed [4.0,5.0)); no third attempt or 15% lock was introduced. Further employee redesign remains on hold.
