from run import *
a=load(HERE/'analysis.json');v=load(HERE/'verification.json');audit=load(HERE/'hand-audit.json');source=load(HERE/'source-after.json')
assert v['status']=='PASS_WITH_RETAINED_SETUP_FAILURE' and a['statuses']=={'completed':12} and audit['status']=='PASS'
assert all(r['max_overdue_cents']==0 for r in a['rows'])
S='studies/early-brief-affordability-20261025-v1'
finding='EARLY-BRIEF-AFFORDABILITY-FINDINGS-2026-10-25-v1.md'
handoff='EARLY-BRIEF-AFFORDABILITY-HANDOFF-2026-10-25-v1.md'
session='SESSION-2026-10-25-EARLY-BRIEF-AFFORDABILITY-v1.md'
money=lambda n:f'${n/100:,.2f}'
names={'puzzle-4417-sound_sprites':'Puzzle4417','puzzle-4418-sound_sprites':'Puzzle4418','puzzle-4521-sound_sprites':'Puzzle4521','puzzle-4522-sound_sprites':'Puzzle4522','action-4417-exit':'Action4417','simulation-4417-exit':'Simulation4417'}
table='| Earned route | Start cycle / cash | Skip final cash | Three Briefs final cash | Difference | Brief awards (R) | Final R |\n|---|---:|---:|---:|---:|---|---:|\n'
for p in a['prefixes']:
    skip=next(r for r in a['rows'] if r['case']=='skip-'+p['route']);mean=next(r for r in a['rows'] if r['case']=='mean-'+p['route'])
    awards=', '.join(format(e['award']/100,'g') for e in mean['briefs'])
    table+=f"| {names[p['route']]} | {p['cycle']} / {money(p['cash_cents'])} | {money(skip['final_cash_cents'])} | {money(mean['final_cash_cents'])} | {money(mean['final_cash_cents']-skip['final_cash_cents'])} | {awards} | {mean['reputation_bp']/100:g} |\n"
cross_commands=sum(r['commands'] for k,r in v['receipts'].items() if k.startswith('cross-'))
replays={k:r['commands'] for k,r in v['receipts'].items() if k.startswith('replay-')}
cold=v['receipts']['cold']
briefs=[e for r in a['rows'] for e in r['briefs']]
assert len(briefs)==18 and sum(e['award']==0 for e in briefs)==8
drift='; '.join(f"`{x['path']}` ({x['change']})" for x in v['canonical_delta_during_study']) or 'none'
text=f'''# Earlier Crown Brief affordability — findings v1

2026-10-25. **Complete bounded private study; DESIGN review.** Rewards and redraw policy unchanged. [Predeclared plan]({S}/PLAN.md) · [analysis]({S}/analysis.json) · [verification]({S}/verification.json) · [review handoff]({handoff}). Results apply to the frozen private baseline; newer concurrent canonical finance/checkpoint/UI changes are not verified by these runs.

## Recommendation and design status

Retain the approved pilot terms for review. All six earned unlock states support three paid Crown Briefs and one further release without arrears under the fixed policies. This closes the specific earlier-start affordability investigation, not universal affordability or final balance. Each Brief arm finishes nine cycles later and with $1,790.21–$2,423.08 less cash than its skip comparator.

Progression is variable: totals range from0 to28.48R; eight of18 Briefs award zero. Puzzle4522 earns zero on all three. Prioritize the existing grade-preview and activation review with these negative fixtures before extending the Crown catalog. Do not add a cash floor, consolation award, guaranteed R20 schedule, Research mandate or reward change based on this study.

**APPROVED pilot terms:** [two hands, Scope9/Core4/spread2/fade6, up-to10R, zero cash/advance/Promotion/Investment](BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md). **PRIVATE candidate:** Crown paid-Search integration and planner. **OPEN:** canonical activation, presentation, accepted progression reliability, broader publisher products and final balance. Simulation success does not approve those items.

## Setup and valid comparisons

Four Puzzle Sound+Sprites first-unlock prefixes plus the first declared Action/Simulation seed were regenerated legally in the private Crown runtime. Exact recipes, owned Features, six earlier paid cash Searches, actual sales/rent/credit and existing Review7 eligibility were preserved. No cash/card/standing injections, loans, hires, extra Research or redraws. Puzzle uses two $450 purchases; Action/Simulation preserve their four-purchase access policies. These are conditional successful access routes, not a random player sample.

All six original-to-private cross-version checks pass over {cross_commands} commands: exact command/results, original replay state at every step, and final state/RNG equality after removing only the new empty `_crown_briefs` map. No checkpoint identity bypass. Each of six take/skip pairs starts from the same private Studio checkpoint, state and RNG.

The fixed take arm uses the existing public-information mean256 two-hand planner for three paid Briefs, then the original bounded production policy for one next release. The skip arm begins that same next game immediately. Each Brief is one Search cycle plus two hand cycles; acceptance/dismissal are free. Three Briefs cost nine productive cycles. Normal monthly sales and rent still occur; the final cash difference is not a direct Brief fee or payout. Comparison is at equal next-release count, **not equal calendar time**, and does not measure the skip arm's additional production opportunities during those nine cycles. All paired next-release Reviews match; no release-quality benefit was observed here.

## Outcomes

{table}
All12 branches complete, with {sum(r['commands'] for r in a['rows'])} accepted commands and zero arrears. The lowest observed branch cash is $1,640.41 in the Puzzle4418 skip arm; the lowest Brief-arm cash is $1,980.41, its actual starting cash. That observation is not a proposed minimum-cash gate. Every take arm completes all three paid Searches and all six hands, with zero redraws. Requested and credited Reputation match because all starts are R0 and no run reaches the R100 cap. Only Puzzle4521 reaches R20, on the third Brief; this grants no Crown commission/support entitlement in the candidate.

## Zero-award diagnosis

[Offline hand audit]({S}/hand-audit.json) independently matches36 selected projections and evaluates all35 final-hand quartets for each of18 Briefs (630 alternatives). Every selected final hand attains the highest grade available from that reached state. All eight zero-award cases have zero positive final-hand choices. This establishes a local dead end after the first hand; it does **not** establish that every other first-hand policy, draw sequence or legal redraw must fail.

Puzzle4522 final half-unit Cores are `[0,4,22,24]`, `[20,4,22,12]`, `[2,16,20,18]`; Scope9/9/10 and completion57.57%/81.81%/72.72% all end at balance0%. First-hand model estimates are hypothetical scenario summaries, not promised awards or calibrated win probabilities. An extra fresh replay of this three-zero route verifies the negative outcome without rerolling or changing seeds. [Verification extension]({S}/VERIFICATION-ADDENDUM.md).

## Checks, failures and bounds

- **PASS:** six original prefix/state/RNG cross-checks; six paired checkpoint checks;18 independent grade/award calculations;36 hand projections and630 final-hand alternatives.
- **PASS:** representative fresh-process replays: {', '.join(f'{k.removeprefix("replay-")} ({n} commands)' for k,n in replays.items())}; exact final states and per-step replay checks.
- **PASS:** existing32-check Crown structural probe at the lowest-cash earned start. This exercised a zero-award settlement; it is not new positive-cap saturation evidence. Parent maintained-suite evidence remains separate.
- **PASS:** cold Studio Continue from completed Action mean branch through one additional release: {cold['commands']} commands, exact starting state/RNG, total{cold['releases']} releases. Verification extension excluded from the measured comparison.
- **RETAINED setup failure:** initial `prefix-puzzle-a` exited1 before gameplay because canonical source changed during drift recording. Same immutable config/variant/seeds/limits passed in new `prefix-puzzle-a-retry1`; original output is retained. [Retry record]({S}/RETRY-NOTE.md). No rejected or timed-out gameplay cases. Failure reduction is not applicable to completed zero grades.
- Limits unchanged: prefixes420 commands, branches120; each run600sec import/run; cross probes/replays240sec, structural180sec, cold100commands/240sec. Local runner used serially, with unique projects/caches/profiles outside player saves. ObjectDB shutdown leak warnings remain verbatim in the verification record; no engine/script errors were detected in those logs.
- **NOT RUN / OPEN:** human or native/executable UI, canonical adoption, old-save migration, active-rival/world acceptance for Crown, other genres/starter pools, sustained long-run affordability, trial employee payroll and a calibrated player success model.

## Source, commands and retained evidence

Branch/main and HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared checkout preserved. Variant `early-brief-affordability-20261025-v1` forks immutable `crown-search-brief-20261025-v1`.

- Original canonical baseline: `434971b9525f09fab3fa0846ed094f53d6ee778f76ae8b97740a136c7b0fda3f`.
- Parent full identity: `df351261ff2a0de4293623b626bece331c6f5a569df8ae74817923ceaf0de5f7`.
- Candidate full identity: `{source['candidate_identity']}`; mechanics identity `9dd1e4551338d38894dace6eb98bc635c38b7e6ec47427b4078cf0ccfe8b0bd6`.
- Delta from parent: only three private debug policy/router scripts. External Brief planner changes only its base-policy preload. No gameplay or reward delta from the existing Crown candidate. [Before]({S}/source-before.json), [after]({S}/source-after.json), [policy pins]({S}/policy-pin.json).
- Concurrent canonical changes during this study: {drift}. Current full canonical identity `{source['canonical_identity']}`. Frozen candidate and parent remain exact; reconcile current canonical drift explicitly at adoption.

Exact invocations are retained in [run/orchestration]({S}/run.py), [cross checker]({S}/cross_check.py), [verification runner]({S}/verify.py), [negative replay]({S}/replay_zero.py), each `*-command.json` in this study, and raw `*.command.json` files. Primary configs: [Puzzle A]({S}/branches-puzzle-a.json), [Puzzle B]({S}/branches-puzzle-b.json), [Action/Simulation]({S}/branches-others.json). [Evidence hashes]({S}/evidence-manifest.json) cover reports, states, tapes, telemetry and command receipts.

Raw root: `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/early-brief-affordability-20261025-v1/`. Retain the failed prefix, successful prefixes, all branches, six cross checks, structural result, three replays and cold continuation. No canonical gameplay edits, commit, push, dispatch or release approval.
'''
handoff_text=f'''# Earlier Crown Brief affordability — review handoff v1

2026-10-25. **DESIGN review; no new canonical gameplay delta.** [Findings]({finding}) · [exact outcomes]({S}/analysis.json) · [verification]({S}/verification.json).

## Recommendation

Keep approved terms unchanged. Earlier-start short-horizon affordability is supported for all six earned states:12/12 branches complete, no arrears, nine extra cycles and $1,790.21–$2,423.08 less next-release cash in every Brief pair. Reliability remains a design-review question:0–28.48R across three Briefs, eight zero awards in18 attempts, including three consecutive zeros for Puzzle4522. Passing finance does not imply dependable reputation progression.

## Tasks, status and acceptance

| ID | Status | Action | Acceptance / dependency |
|---|---|---|---|
| EBA1 | **implemented and verified — private evidence only** | Close the bounded earlier-start affordability experiment | Preserve six legally regenerated prefixes, exact cross-version state/RNG,12 branches,18 Briefs, negative outcomes, setup failure/retry, three fresh replays,32 structural checks and cold Studio Continue. No canonical activation claim. |
| EBA2 | **proposed** | Extend existing preview acceptance with the recorded zero-award fixtures | Use [preview v2](CROWN-PREVIEW-HANDOFF-2026-10-25-v2.md) and [hand audit]({S}/hand-audit.json). Show one Search cycle plus two hand cycles, raw Core spread, separate completion/balance, provisional first-hand projection and exact final requested/credited award. Puzzle4522 must display zero correctly even at Scope target; hypothetical model estimates must not appear as banked Reputation or guaranteed success. Pure queries preserve state/RNG. Native/executable/human acceptance still required. |
| EBA3 | **proposed** | Review progression reliability before normal Crown exposure | Retain the entire0–28.48R range and three-zero fixture; do not promise R20 within three Briefs or mistake conditional final-hand impossibility for global inaccessibility. Decide whether the unchanged bounded challenge is acceptable after its outcome is clearly presented. No automatic consolation reward, new reserve gate, forced Research, redraw experiment or balance retune. |
| EBA4 | **approved — unchanged pilot terms only** | Preserve the accepted numerical pilot | [Approval](BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md): two hands,Scope9/Core4/spread2/fade6,up-to10R and zero other rewards; existing publisher rewards and Review7 access unchanged. This is not new canonical activation approval. |
| EBA5 | **proposed; gated** | Reconcile and review canonical adoption after activation approval | Reuse [sealed runtime packet](handoffs/crown-search-brief-20261025-v1/HANDOFF.md) and [CSB gates](CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md). Review current source drift, named migration, atomic once-only settlement, Studio-only Continue, UI/world/export and human acceptance. Add this study as evidence, not a replacement source archive. No new publisher cash/commission/support terms are authorized. |

## Exact delta and routing

Main HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f; source is pinned in the finding and manifests. Candidate full identity `{source['candidate_identity']}` adds only three private policy/router debug scripts to parent `df351261ff2a0de4293623b626bece331c6f5a569df8ae74817923ceaf0de5f7`. Runtime and rewards match the existing sealed Crown candidate; external planner merely routes to the original production policies. No new sealed gameplay patch is needed for this evidence-only delta. Canonical changes belong to PN Implementation after explicit activation authority and reconciliation.

The current canonical finance delta adds journal-validation caching; its behavior equivalence has not been tested here. Current canonical `scripts/persistence/studio_checkpoint.gd` also overlaps the existing Crown candidate, so PN Implementation must reconcile that path explicitly. Do not transplant the private project wholesale or treat these runs as acceptance of the newer checkout.

Refresh the existing Crown **DESIGN review needed** TODO entry with this handoff. Preserve other entries. No cross-chat dispatch, auto-adoption, commit, push or release claim.
'''
session_text=f'''# Contracts session — earlier Brief affordability

2026-10-25 (local). User delegated the next work after Puzzle Research; executed the proposed earlier earned-access take/skip study with rewards unchanged.

- Branch/main HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f; dirty worktree and `.codex-godot-temp` preserved. [Before snapshots]({S}/status.txt), [after]({S}/status-after.txt), [source identities/drift]({S}/source-after.json).
- Changed only this thread's new study/private simulator, dated finding/handoff/session and top summaries in README/HANDOFF, plus a minimal existing Crown TODO paragraph. No canonical gameplay/tests/assets/config edits.
- Exact checks/results: [finding]({finding}), [commands and preregistration]({S}/PLAN.md), [verification]({S}/verification.json), [hand audit]({S}/hand-audit.json). Six prefix comparisons,12 measured cases/18 Briefs; all complete, no arrears. Eight zero awards retained. Source snapshot setup failure retried with identical input in a new folder; no gameplay failures/timeouts or reduction.
- Recommendation: retain pilot terms; use actual negative fixtures for preview/progression review. Existing canonical activation and acceptance gates remain OPEN. No further balance adjustment or redraw study.
- TODO remains DESIGN review, not queued adoption. No commit, push, external message, Drive sync or release approval.
'''
for name,content in [(finding,text),(handoff,handoff_text),(session,session_text)]:
    p=THREAD/name;assert not p.exists();p.write_text(content,encoding='utf-8')
summary=f'**2026-10-25 Earlier Crown Brief affordability complete privately.** [Six earned starts /12 matched branches]({finding}) all complete without arrears; three paid Briefs add9 cycles and leave $1,790.21–$2,423.08 less next-release cash. Rewards unchanged. Progression ranges0–28.48R, with8 zero awards in18 Briefs and three consecutive zeros for Puzzle4522. Final-hand audit finds no positive quartet in those reached zero states; alternative first-hand policies remain unproven. [EBA1–EBA5 handoff]({handoff}) prioritizes preview/progression review; canonical activation, migration/UI/world/export/human gates remain open. Earlier pending-affordability labels below are historical.'
# Preserve current index bodies byte-for-byte, including concurrent updates.
index_changes={}
for name in ['README.md','HANDOFF.md']:
    p=THREAD/name;old=p.read_bytes();(HERE/(name+'.before')).write_bytes(old);nl=b'\r\n' if b'\r\n' in old else b'\n';end=old.index(nl+nl)+len(nl+nl);addition=summary.encode()+nl+nl
    assert p.read_bytes()==old;p.write_bytes(old[:end]+addition+old[end:]);assert p.read_bytes().replace(addition,b'',1)==old
    index_changes[name]=dict(offset=end,addition=addition.decode(),before_sha256=hashlib.sha256(old).hexdigest())
# Re-read TODO immediately before one minimal paragraph edit.
p=ROOT/'docs/codex/TODO.md';old=p.read_bytes();lines=old.splitlines(keepends=True);matches=[line for line in lines if line.startswith(b'**Crown paid-Search Brief')];assert len(matches)==1;original=matches[0];ending=b'\r\n' if original.endswith(b'\r\n') else b'\n'
new=f'**Crown paid-Search Brief — DESIGN review needed; approved pilot terms and private evidence,2026-10-25.** [Exact pilot approval](threads/contracts/BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md) retains2 hands,Scope9/Core4/spread2/fade6,up-to10R,zero other rewards. [Earlier18-case access](threads/contracts/CROWN-ACCESS-POLICY-FINDINGS-2026-10-25-v1.md) and [Puzzle Research12-case follow-up](threads/contracts/PUZZLE-RESEARCH-FINDINGS-2026-10-25-v1.md) preserve both Research fixtures and mixed pacing. [Earlier earned-start affordability](threads/contracts/{finding}): all12 take/skip branches from six legal starts complete without arrears; three paid Briefs add9 cycles and leave $1,790.21–$2,423.08 less next-release cash. Reputation ranges0–28.48R;8/18 Briefs award zero, including three consecutive Puzzle4522 zeros. [EBA1–EBA5 review handoff](threads/contracts/{handoff}) prioritizes truthful preview and progression-reliability review with negative fixtures; no new reward, cash floor, Research mandate or guaranteed R20 cadence. [Preview v2](threads/contracts/CROWN-PREVIEW-HANDOFF-2026-10-25-v2.md), [existing sealed runtime packet](threads/contracts/handoffs/crown-search-brief-20261025-v1/HANDOFF.md) and [CSB adoption gates](threads/contracts/CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md) retain explicit activation authority, current-source reconciliation, named migration and atomic/UI/world/export/human acceptance. Broader catalogs and final balance remain OPEN; no canonical Crown activation or cross-chat dispatch.'
replacement=new.encode()+ending;(HERE/'TODO.before.md').write_bytes(old);assert p.read_bytes()==old;p.write_bytes(old.replace(original,replacement,1));assert p.read_bytes().replace(replacement,original,1)==old
write(HERE/'publication.json',dict(files=[finding,handoff,session],indexes=index_changes,todo_original_line=original.decode(),todo_replacement_line=replacement.decode(),unrelated_todo_bytes_preserved=True,index_bodies_preserved=True))
print(json.dumps(dict(published=[finding,handoff,session],todo='Existing Crown DESIGN paragraph updated; unrelated bytes preserved.')))
