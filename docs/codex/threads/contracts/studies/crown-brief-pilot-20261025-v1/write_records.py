from run import *
a=load(HERE/'analysis.json');w=load(HERE/'witness-analysis.json');s=load(HERE/'summary.json');v=load(HERE/'closeout.json')
assert v['status']=='PASS'
study='studies/crown-brief-pilot-20261025-v1'
finding='CROWN-BRIEF-PILOT-FINDINGS-2026-10-25-v1.md'
handoff='CROWN-BRIEF-PILOT-HANDOFF-2026-10-25-v1.md'
table='\n'.join('| '+r['arm']+' | '+str(r['seed'])+' | '+', '.join(f"{x['award']/100:.2f}" for x in r['results'])+' | '+f"{r['reputation_bp']/100:.2f}"+' | '+str(r['final_cycle'])+' | '+f"${r['cash']/100:,.2f}"+' |' for r in a['rows'])
full=v['full_witnesses'][0]['result']
text=f'''# Crown Brief pilot CB2 — accessibility and pacing

2026-10-25. **COMPLETE bounded private experiment; Crown rules/activation remain OPEN.** User authorized this simulator pilot with unchanged rewards; Beta redraw work stays parked. [Design](CROWN-BRIEFS-DESIGN-2026-10-25-v1.md), [pre-execution plan]({study}/PLAN.md), [targeted follow-up declaration]({study}/FULL-WITNESS-ADDENDUM.md).

## Recommendation

Keep existing rewards and the candidate Brief formula unchanged for now. Legal partial progress and a full10R result are demonstrated. The tested policies do **not** establish reliable R20 within three opportunities. Next investigate two-hand planning on these matched legal starts, with redraws still parked; hold commission/support activation and numerical approval. Do not introduce a hidden perfect-Brief prerequisite or claim a required number of opportunities from this small study.

## Source and legal starting conditions

- Branch `{v['branch']}`, HEAD `{v['head']}`, shared dirty checkout. Intake [status]({study}/status.txt), [diff summary]({study}/diff.txt). Canonical snapshot identity `{v['variant']['base_identity']}`.
- Baseline `crown-brief-access-20261025-v1` contains only the retained access-policy helper beyond canonical. New Contracts-owned `crown-brief-pilot-20261025-v1` descends from it with protected original archive/ancestry; [candidate pins]({study}/candidate-pins.json), [exact historical-delta reconciliation]({study}/merge-receipt.json).
- Candidate identity `{v['candidate_identity']}`; executed mechanics identity `{v['source_identity']}`. Thirteen changed/added project paths include ten runtime/schema paths and three debug policy helpers. Only private `project/` copies changed. No commission/support activation, existing reward change or canonical gameplay edit.
- Private save tag `-crown-brief-cb2-private1` distinguishes these rules. No historical/canonical checkpoint was imported or relabeled. Legacy migration and active-rival Crown Brief acceptance are unverified and block adoption.
- Fresh legal Action/no-Trait seeds4521/4522 reproduce Crown unlock at Game4/cycle60 and Game3/cycle43, with cash$8,515.44/$7,972.51. Each canonical-behavior prefix ran before the private comparison. Regenerated candidate prefixes have exact outcomes/RNG and all existing saved-run fields equal; only pending `crown_briefs` is added. [Prefix audit]({study}/prefix-audit.json).
- All five arms per seed begin from one identical unedited candidate Studio envelope and RNG. Same legal CA1b development/acquisition policy; no new Beta changes. Briefs use default equal priorities, four visible cards per hand, no Brief redraws, two productive hands, maximumthree consumed opportunities before the final release. One pending offer persists, cash Contract separate and not a prerequisite. No synthetic funds/cards/scores/standing or hidden draw reads.

## Main comparison — declared before execution

Ten of ten cases complete; **1,060 commands, all accepted**.24Briefs across two starting worlds:9partial,15zero,0full,0R20. These results are correlated, not24independent population trials.

| Policy | Seed | Reputation per Brief | Total R | End cycle | End cash |
|---|---:|---|---:|---:|---:|
{table}

Balanced maximizes immediate projected grade, completion and narrow spread; it is greedy per visible hand, not a two-hand planner. Completion-first ignores the balance penalty until its tie-break; naive takes the first four. Pass-heavy maximizes available Pass count before grade. No policy changes draw weights or reads hidden state.

All Brief-taking arms in each seed finish six cycles later than skip and have exactly the same end cash as each other. Three Briefs cost six productive cycles and no direct cash fee. At equal release counts, take-minus-skip cash is **-$1,560.70** for4521 and **-$1,535.03** for4522. This includes shifted rent/sales exposure, not an isolated Brief charge. All runs have zero ending arrears, and observed minimum cash stays at the starting$8,515.44/$7,972.51. This does not establish affordability for a cash-poor Studio. [Matched-calendar/release comparisons and finance details]({study}/summary.json).

Pass-heavy earns10.00/9.69R, while still using10/14Features across three Briefs. Seed4521 earns7.50R at Scope3 and2.50R at Scope2; low-Scope partial progress is legally demonstrated, but no no-Scope or Pass-only R20 route is established. Skip keeps the original pending offer unchanged through all three new releases, with no backlog. [Independent556-check audit]({study}/analysis.json).

## Targeted full-award feasibility follow-up

The primary audit found full-grade final quartets visible in the second Brief for naive/pass-heavy4522. Neither policy chose them. Before any extra execution, the separate addendum fixed two new policies: retain naive or Pass-heavy first-hand selection, then maximize actual visible final-hand grade. Both restart the same untouched4522 unlock envelope with the same180-command/six-release bounds and unchanged rewards. This is post-outcome-selected feasibility evidence, not an expanded unbiased cohort.

Both two-case runs complete109commands and earn **2.50 +10.00 +0 =12.50R**. The full result commits at cycle{full['cycle']}, Scope{full['scope']}, Core half-units{full['cores']}, grade100%, exactly10R and zero cash/Promotion/Investment. These two related policies on one seed establish one legal full-award route, not general reliability. Neither reachesR20. [140-check independent witness audit]({study}/witness-analysis.json) · [full-witness selection]({study}/full-witness-selection.json).

## Verification and retained limits

- PASS: prefix existing-state/RNG parity; ten matched starts; independently recomputed scoring, policy ranks/ties, finite Feature use, four visible cards, two productive actions, zero direct reward, once-only P1 events, owner/source ordinals and publisher isolation. Full/partial/zero in actual Brief play are covered.
- PASS: four fresh-process exact replays: partial balanced, zero completion-first, skip, and full-award witness. Each verifies every taped state/RNG and telemetry sample. [Closeout]({study}/closeout.json).
- PASS: cold Studio-only Continue restores the selected balanced run's exact ending state/RNG, then executes{v['cold']['commands']}commands to Game{v['cold']['releases']}/cycle{v['cold']['cycle']} on identical mechanics. This tests the candidate's own checkpoint, not migration from player/canonical saves.
- PASS: unchanged maintained `verify_contract_challenge_runtime`, `verify_contract_challenge_matrix`, and `verify_publisher_relationships` on frozen candidate source, isolated profiles. P1 suite43checks/0failures. These protect existing publisher rewards/ledger behavior; they are not complete Crown adoption acceptance. [Receipts]({study}/focused-checks.json).
- PASS: independent read-only review; corrected analyzer completeness reporting, with original report retained. [Review]({study}/REVIEW.md). No measured case was discarded or rerolled.
- None observed: rejected campaign commands, incomplete campaigns or timeouts. Reduction is not applicable. Retained tooling issues: missing-path/wildcard inspection errors and one failed patch-context match before execution; no runtime source or seed/budget change followed them. The [cold-audit API correction]({study}/CLOSEOUT-AUDIT-CORRECTION.md) replaces an inapplicable paired-case helper with direct source/input/result/telemetry validation, preserving every artifact. ObjectDB exit leak warnings remain recorded and are not claimed fixed.
- NOT RUN: broad specialties/Traits/cash-poor access, long-horizonR20, stronger two-hand planning, current-rival worlds, Crown cap-clipped live campaign, complete forged-history/transaction rejection matrix, named predecessor migration, UI/export/human/device acceptance. The same-source prototype is not adoption-ready.

## Commands and evidence

Python `{PY}`; Godot `{GODOT}`. All run/replay commands use `tools/simulate.py` with new output folders and480-second import/run limits. Study scripts: `setup.py baseline`; `run.py baseline`; `setup.py candidate`; `prepare_policy.py`; `run.py prefix`; `prepare_branches.py`; `run.py branches-4521`; `run.py branches-4522`; `analyze.py`; `summarize.py`; `check_suites.py`; `verification.py`; `prepare_witness.py`; `run.py witness`; `analyze.py witness`; `replay_witness.py`; `closeout.py`. [Exact argv and configs]({study}/), including stage-specific command/exit/driver records. Maintained suites use the documented runner's isolated environment/process helpers against the completed frozen prefix source; pre/post source hashes match.

Raw frozen projects/profiles/tapes/reports are retained at `{RAW.as_posix()}`; [hashed evidence manifest]({study}/evidence-manifest.json). Concurrent canonical font/UI work produced{len(v['canonical_drift'])}changed/added paths at closeout; exact hashes are in closeout.json, and those edits are preserved. No Contracts mechanics overlap was present at that boundary. No player-save write, computer control, commit, push or release-readiness claim. [Next work]({handoff}).
'''
(THREAD/finding).write_text(text,encoding='utf-8')
(THREAD/handoff).write_text(f'''# Crown Brief CB2 — review handoff

2026-10-25. **DESIGN review; no canonical implementation approval.** [Findings]({finding}) and [design authority](CROWN-BRIEFS-DESIGN-2026-10-25-v1.md). User authorized the private pilot while keeping rewards unchanged; Crown values/activation remain OPEN. SideStreet ACTIVE/TRIAL authority is unchanged.

| Item | Status | Acceptance / dependency |
|---|---|---|
| CB1 private prototype | **implemented and verified — private bounded scope only** | Source-pinned two-hand Brief; release-paced storage; denominator66/balance evaluator; trusted P1 zero-currency result; candidate-only rules identity. Existing rewards unchanged.13-path exact delta in sealed review packet below; not a drop-in adoption. |
| CB2 accessibility/pacing | **implemented and verified — experiment only** | Legal Action4521/4522 unlocks, ten same-state branches,24Briefs, targeted full10R witness, four exact replays and cold Continue. NoR20 in three opportunities; do not promise it. |
| CB2b two-hand planning | **proposed** | New versioned observation-only policy on these current-source legal prefixes, no redraw or reward changes. Compare first-hand choices that preserve weak-Core coverage/second-hand options against fixed greedy baseline. Predeclare bounds, do not peek at future cards, report full/partial/zero/R20 plus cash/cycles and retain failures. Earlier historical lookahead did not improve its bridge cohort; do not blindly repeat it or claim new strategy superiority. |
| CB3 adoption acceptance | **proposed; gated** | Explicit lifecycle/source/terms snapshots, requested-versus-credited cap, atomic rejection/duplicate restoration, separate cash-count, owner/publisher isolation, named prospective predecessor migration and populated active-rival handling. Test actual UI/projections and Studio-only Continue. Current packet only covers the listed bounded cases. |
| CB4 canonical activation | **proposed; gated** | Requires explicit pilot numerical/activation approval plus CB3. PN Implementation reconciles current canonical delta and runs native/export acceptance. Do not adopt the experimental schema tag or legacy-incomplete codec as production migration. |
| Commission/support | **proposed; held** | Separate approval and evidence; R20 and later terms remain OPEN. No implementation or reward adjustment in this handoff. |

## Exact review material

Candidate `simulators/crown-brief-pilot-20261025-v1`; ancestry starts from current canonical snapshot `{v['variant']['base_identity']}`, executed mechanics `{v['source_identity']}`. [Thirteen-path delta and checks]({study}/closeout.json), [source pins]({study}/candidate-pins.json), [experimental policies/plan]({study}/PLAN.md), [targeted follow-up]({study}/FULL-WITNESS-ADDENDUM.md). [Sealed source packet](handoffs/crown-brief-pilot-20261025-v3/HANDOFF.md) is for DESIGN review only. The tool's generic READY FOR IMPLEMENTATION REVIEW heading means source review, not numerical approval or adoption readiness. Failed v1/v2 packaging attempts remain recorded; partial v2 must not be adopted.

Recommendation: keep rewards; useful/full results are attainable, but reliable pacing and player comprehension are not established. No shared TODO implementation queue, canonical adoption, chat dispatch, commit or push is implied by the review packet.
''',encoding='utf-8')
(THREAD/'SESSION-LOG-2026-10-25-crown-brief-pilot-v1.md').write_text(f'''# Contracts session — Crown Brief pilot

2026-10-25; `{v['branch']}` / `{v['head']}`, dirty shared checkout preserved. User request: private Crown Brief accessibility/pacing, unchanged rewards; redraw work parked.

Created two thread-owned simulator versions and `{study}/` plan/scripts/configs/audits; reconciled historical Brief source only inside candidate. Created [{finding}]({finding}) and [{handoff}]({handoff}). README/HANDOFF receive one dated status paragraph; TODO's existing Crown paragraph receives a minimal DESIGN update after reread. No shared design authority, CURRENT_STATE, canonical gameplay/tests/assets/configs or .codex-godot-temp edits.

Exact commands/results: study command/exit JSONs; source and raw manifest in finding. Two baseline+two candidate prefixes pass; ten main cases1060commands and two targeted cases218commands accepted;556+140independent checks; three maintained suites pass; four exact replays and Studio cold Continue pass. All original outcomes retained. No runtime rejects/timeouts. Initial inspection and patch-context errors were tooling only. Analysis reporting bug and cold-audit API mismatch corrected without changing case data; initial reports retained. First packet attempt rejected replay-mode references; second failed concurrency guard during canonical UI work; only successful v3 is linked. ObjectDB leak warnings retained.

Recommendation: unchanged rewards. Legal full/partial/zero demonstrated; noR20 in three opportunities under tested policies. Proposed next work is targeted two-hand planning; migration/native/export/adoption approval remain gates. No user ruling is needed to complete this bounded experiment. No commit/push/release-readiness claim.
''',encoding='utf-8')
print('Wrote finding, design-review handoff and session log')
