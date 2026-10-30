from run import *
def main():
    a=load(HERE/'analysis.json');rows=a['rows'];v=load(HERE/'verification.json');assert v['status']=='PASS'
    winner=load(HERE/'selection.json')['selected'];assert winner=='sound_sprites'
    baseline=[r for r in rows if r['arm']=='baseline'];candidate=[r for r in rows if r['arm']==winner]
    assert len(baseline)==len(candidate)==4 and sum(bool(r['access']) for r in candidate)==4 and sum(bool(r['access']) for r in baseline)==3
    assert all(r['status']=='completed' and r['max_overdue_cents']==0 for r in rows)
    differences=[]
    for b in baseline:
        c=next(r for r in candidate if r['pair']==b['pair'])
        differences.append(dict(seed=b['pair'].split('-')[-1],baseline_access_cycle=b['access']['cycle'] if b['access'] else None,candidate_access_cycle=c['access']['cycle'],cycle_delta=c['access']['cycle']-b['access']['cycle'] if b['access'] else None,final_cash_delta_cents=c['cash_cents']-b['cash_cents'],baseline_final_cycle=b['cycles'],candidate_final_cycle=c['cycles']))
    write(HERE/'paired-summary.json',differences)
    assert all(d['final_cash_delta_cents']<0 for d in differences)
    finding='PUZZLE-RESEARCH-FINDINGS-2026-10-25-v1.md';handoff='PUZZLE-RESEARCH-HANDOFF-2026-10-25-v1.md'
    interpretation='''## Result and recommendation

**Retain 8-bit Sound + Sprites as a useful accessibility test route; do not replace the original purchase strategy universally. Keep rewards unchanged.** It reaches Crown in all four tested seeds, while8-bit Sound + General Combat reaches three. On the original stuck seed4417, Sprites earns Review8.4 at Game4/cycle80; the baseline peaks at6.9 within four releases. All12 declared campaigns complete four releases without arrears.

Confirmation is mixed for pacing: on4418, Sprites unlocks one cycle sooner (62 versus63); on4522 it unlocks20 cycles later (83 versus63), after Game3 misses at6.9. It finishes with less cash than baseline on all four seeds. It is an additional legal route, not a reliable universal speed or income improvement. Do not turn a successful seed into compulsory shopping advice or a hidden seed-specific rule.

Discovery alternatives also matter: Music + Sprites reaches both discovery seeds but ranks two total unlock cycles behind8-bit Sound + Sprites; Music + General Combat still misses4417. These unselected pairs did not receive confirmation runs and cannot be called globally inferior.

Next useful Contracts question: can the approved private Crown Brief be afforded and understood from these earlier, legitimately earned access states? Reuse the retained legal routes to regenerate source-compatible prefixes in the private Crown Search candidate, then compare paid Search/Brief work against skip with unchanged rewards. No canonical exposure or extra balance change follows from this research. Keep the existing grade-preview/migration/world/UI/export gates.

'''
    p=THREAD/finding;text=p.read_text(encoding='utf-8');assert '## Result and recommendation' not in text;text=text.replace('## Exact source and comparison',interpretation+'## Exact source and comparison',1);p.write_text(text,encoding='utf-8')
    comparison='\n'.join(f"| {d['seed']} | {d['baseline_access_cycle'] if d['baseline_access_cycle'] else 'Not reached'} | {d['candidate_access_cycle']} | {d['cycle_delta'] if d['cycle_delta'] is not None else 'New access'} | ${d['final_cash_delta_cents']/100:,.2f} |" for d in differences)
    text=f'''# Puzzle Research — versioned review handoff v1

2026-10-25. **DESIGN review; zero canonical implementation delta.** [Finding]({finding}) · [preregistration](studies/puzzle-research-20261025-v1/PLAN.md) · [exact source/verification](studies/puzzle-research-20261025-v1/verification.json).

## Decision requested / recommendation

Retain8-bit Sound + Sprites as an additional access fixture, preserving the original8-bit Sound + General Combat fixture. Do not mandate either pair or change rewards. Sprites reaches Crown4/4 versus baseline3/4, including the original4417 failure, but does not reliably accelerate progression. The two unseen confirmation seeds both unlock with either pair: Sprites is1 cycle earlier in4418 and20 later in4522. Every Sprites comparison finishes with less cash. Only discovery selected this candidate; the extra seeds provide separate, mixed confirmation.

| Seed | Baseline Crown cycle | Sprites Crown cycle | Cycle difference | Final cash difference |
|---|---:|---:|---:|---:|
{comparison}

Cash is compared at the same four-release horizon, sometimes at different calendar cycles; it is not a fixed-calendar revenue estimate. Both pairs cost$900/two Research actions and begin Game2 with equal cash/cycle. All12 measured cases complete without arrears. No participant earns cash or Reputation from Crown Briefs in this study.

## Tasks and dependencies

| ID | Status | Task | Acceptance / dependencies |
|---|---|---|---|
| PR1 | **implemented and verified — evidence only** | Preserve8 discovery +4 confirmation campaigns and legal purchase fixtures | Exact original controls, four equal-start groups, eight shared-prefix checks, actual two purchases/$900/two actions/six Searches, all outcomes, fresh replays and Studio Continue. Source/policy hashes and commands retained. |
| PR2 | **proposed** | Retain Sprites as an additional accessibility fixture | Keep both routes; no canonical auto-shopping, starter grant, price/reward/Review-gate change or guarantee of optimality. Preserve the negative4522 pacing result and original4417 baseline failure. |
| PR3 | **proposed** | Test paid Crown Brief affordability from earlier earned access | Use actual first-unlock prefixes:4417 Sprites Game4/cycle80,4418 Sprites Game3/cycle62,4521 Sprites Game3/cycle65,4522 Sprites Game4/cycle83. Regenerate legal prefixes in the compatible private Crown runtime; prove source/state/RNG differences, then matched take/skip trials with predeclared horizon/cash/reputation/arrears measures. No synthetic R7/money/cards; no checkpointer identity edits. Do not count these study saves as cross-version compatible without verification. |
| PR4 | **approved — unchanged pilot terms only** | Retain Crown Brief numeric terms and current base rewards | [Approval](BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md); canonical activation remains gated. No new reward formula or unlock gate is approved here. |
| PR5 | **proposed; gated** | Review preview and eventual canonical adoption | [Paid-Search preview v2](CROWN-PREVIEW-HANDOFF-2026-10-25-v2.md), [existing runtime packet](handoffs/crown-search-brief-20261025-v1/HANDOFF.md), named migration, atomic settlement, active-rival/world, current native/export/human acceptance. These are not closed by access-only policy results. |

## Source and precise delta

Main HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f; dirty shared checkout preserved. Named simulator `puzzle-research-20261025-v1` retains immutable ancestry from `crown-access-policy-20261025-v1`; full source identity434971b9525f09fab3fa0846ed094f53d6ee778f76ae8b97740a136c7b0fda3f. Runtime delta: zero. External `studies/puzzle-research-20261025-v1/policy.gd` chooses explicit legal purchase pairs and adds observable Core diagnostics; card selection, phase exits and all rules stay unchanged. It is research code, not an approved gameplay patch. No new sealed gameplay adoption packet is necessary; preserve the existing Crown packet.

Review routing only. No cross-chat dispatch, automatic adoption, commit, push or release claim.
'''
    (THREAD/handoff).write_text(text,encoding='utf-8')
    note=f'**2026-10-25 Puzzle Research complete.** [12-case finding]({finding}):8-bit Sound + Sprites reaches Crown4/4 versus baseline3/4, fixing the retained4417 access case. Confirmation pacing is mixed (1 cycle earlier/20 later), and final cash is lower in all4 comparisons. All12 finish four releases without arrears; rewards unchanged. [Review handoff]({handoff}): retain both test routes; next evaluate paid Brief affordability from earlier earned starts. Preview and canonical exposure gates remain open.'
    for name in ['README.md','HANDOFF.md']:
        p=THREAD/name;b=p.read_bytes();(HERE/(name+'.before')).write_bytes(b);end=b.index(b'\n')+1;nl=b'\r\n' if b[end-2:end]==b'\r\n' else b'\n';assert p.read_bytes()==b;p.write_bytes(b[:end]+nl+note.encode()+nl+b[end:])
    p=ROOT/'docs/codex/TODO.md';b=p.read_bytes();(HERE/'TODO.before').write_bytes(b);start=b.index(b'**Crown paid-Search Brief');nl=b'\r\n' if b'\r\n' in b else b'\n';end=b.index(nl+nl,start);old=b[start:end]
    new=('**Crown paid-Search Brief — DESIGN review needed; approved pilot terms and private evidence,2026-10-25.** '
    '[Exact pilot approval](threads/contracts/BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md) retains2 hands,Scope9/Core4/spread2/fade6,up-to10R,zero other rewards. '
    '[Earlier18-case access study](threads/contracts/CROWN-ACCESS-POLICY-FINDINGS-2026-10-25-v1.md) established cheaper legal routes with six paid Searches. '
    f'[Puzzle Research12-case follow-up](threads/contracts/{finding}):8-bit Sound + Sprites unlocks4/4 versus baseline3/4; all12 survive four releases. Extra-seed pacing is mixed (1 cycle earlier/20 later), with lower final cash in all4 Sprites comparisons. '
    f'[PR1–PR5 review handoff](threads/contracts/{handoff}) retains both fixtures and proposes actual paid Brief affordability from earlier earned starts; no mandatory shopping or reward/gate change. '
    '[Preview v2](threads/contracts/CROWN-PREVIEW-HANDOFF-2026-10-25-v2.md), [existing sealed runtime packet](threads/contracts/handoffs/crown-search-brief-20261025-v1/HANDOFF.md), and [CSB adoption gates](threads/contracts/CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md) retain explicit presentation/activation review, named migration, atomic settlement, UI/world/export acceptance. '
    '[Prior post-access Brief evidence](threads/contracts/CROWN-SEARCH-BRIEF-FINDINGS-2026-10-25-v1.md) does not establish affordability at these earlier starts. No canonical activation or duplicate SideStreet queue; redraws parked. Crown cash/commission/support and broader catalog remain OPEN.').encode()
    assert p.read_bytes()==b;p.write_bytes(b[:start]+new+b[end:]);assert p.read_bytes().replace(new,old,1)==b;(HERE/'TODO-replaced-paragraph.before').write_bytes(old)
    write(HERE/'publication.json',dict(unrelated_todo_bytes_preserved=True,todo_sha256=hashlib.sha256(p.read_bytes()).hexdigest(),finding=finding,handoff=handoff))
    session=f'''# Contracts session — 2026-10-25 Puzzle Research

User authorized Puzzle Research, keeping rewards. Main HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f; current state/TODO, design, relevant prior findings and simulator conventions read. Branch/worktree/status/diff captured. Shared edits and .codex-godot-temp preserved.

Changed: thread-owned simulator fork (zero runtime delta), `studies/puzzle-research-20261025-v1/`, [{finding}]({finding}), [{handoff}]({handoff}), README/HANDOFF, this session log and the single existing Crown DESIGN TODO paragraph. All other TODO bytes preserved.

Commands: `run.py setup`, `run.py discover`, `analyze.py`, `confirm.py`, `analyze.py`, `verify.py`, `run.py source`, `report.py`, `closeout.py`, final publication checks. Exact argv/exits and full source/policy/plan pins are in the study folder; raw sources/saves/logs outside OneDrive in Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/puzzle-research-20261025-v1. The discovery analysis is frozen separately and its hash matches selection.json.

PASS:12 complete campaigns with no arrears; unchanged$900/two-action Research and six paid Searches; original two baselines exactly reproduce; four state/RNG groups and eight exact shared prefixes; selected4417/4418 fresh replays; Studio Continue to fifth release; source/policy/ownership checks. No rejected/incomplete/timed-out cases; reducer NOT APPLICABLE. Retained ObjectDB exit warnings, no engine errors in study import/run logs. No native/UI/export tests claimed.

Result: Sprites route earns Crown4/4 against baseline3/4, but confirmation is1 cycle earlier and20 later; final cash is lower in all4 matched comparisons. Recommendation: retain as additional fixture, no universal purchase mandate or balance change. Open: actual paid Brief affordability at these earlier starts, preview/activation decision, migration/world/UI/export/human gates. No canonical gameplay changes, commits, pushes, Drive mutation or cross-chat message.
'''
    (THREAD/'SESSION-2026-10-25-PUZZLE-RESEARCH-v1.md').write_text(session,encoding='utf-8')
    print(json.dumps(differences));print('Review documents published; other TODO bytes preserved.')
if __name__=='__main__':main()
