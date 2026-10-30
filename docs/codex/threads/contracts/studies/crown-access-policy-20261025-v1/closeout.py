from run import *
def main():
    summary=load(HERE/'summary.json');a=load(HERE/'analysis.json');verification=load(HERE/'verification.json')
    assert verification['source_unchanged']
    findings='CROWN-ACCESS-POLICY-FINDINGS-2026-10-25-v1.md';handoff='CROWN-ACCESS-POLICY-HANDOFF-2026-10-25-v1.md';preview='CROWN-PREVIEW-HANDOFF-2026-10-25-v2.md'
    scores={r['arm']:r for r in summary}
    line=f"Shorter production reaches Crown in{scores['exit']['access']}/6 cases; adding the Research cap/reserve reaches{scores['reserve']['access']}/6. Each revised policy completes{scores['exit']['completed']}/6 and{scores['reserve']['completed']}/6 cases respectively; fixed controls complete0/6."
    text=f'''# Crown access policy and preview — review handoff v1

2026-10-25. **DESIGN review; no new gameplay patch.** [Finding]({findings}) · [24-assertion paid-Search preview]({preview}) · [original runtime adoption gates](CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md).

## Recommendation

Keep approved rewards and Review7 unlock unchanged. {line} Six paid cash searches can support earned access in multiple actual routes, so eighteen searches are not established as a prerequisite. Preserve the successful shorter routes as regression/research fixtures. The fixed purchase order, two-purchase cap and$6,000 quoted reserve are policy experiments, not player rules. Do not mandate them or silently change automatic game behavior.

Use the two-purchase policy as the next liquidity-conscious comparison fixture, alongside the unchanged exit-only fixture: it trades ownership/cadence for runway, and cannot be declared universally optimal. The$6,000 filter never changes the first two purchases in these cases; do not credit that threshold with an independently measured benefit. Likewise all36 Design exits hit the shorter cap, so the combined exit strategy does not establish that its quality trigger caused success. Keep the unresolved Puzzle seed4417 in the next accessibility gate rather than replacing its seed or treating survival as access. The next focused question is whether publicly chosen specialty-relevant Research/Feature selections improve its quality at the same bounded funding budget. Any such experiment needs a new preregistration/version; do not extend these four-release results after the fact.

## Items and dependencies

| ID | Status | Task | Acceptance and dependencies |
|---|---|---|---|
| CAP1 | **implemented and verified — research only** | Preserve18-case access comparison and evidence | Six identical-start triples, six exact historical control outcomes, unchanged runtime hashes, all economic failures retained, representative success/failure replay, reduction and Studio Continue. No canonical implementation inferred. |
| CAP2 | **approved — pilot terms only** | Preserve existing bounded Crown Brief formula/rewards | [Approval](BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md):2 hands,Scope9/Core4/spread2/fade6,min(completion,balance),up-to10R,zero other rewards. Canonical activation remains a separate gate. |
| CAP3 | **proposed** | Review/approve current paid-Search grade-preview contract | CP2 tasks in preview v2: Search1cycle+work2hands, raw scores, separate completion/balance, provisional hand1, exact final capped credit, pure inert query and legal confirmation. Native/export/human coverage still required. |
| CAP4 | **proposed** | Resolve remaining specialty-access uncertainty | Preserve Puzzle4417, legal current source/roster, six Searches, unchanged rewards and no redraws; compare specialty-aware purchases/selection against both frozen policies with declared budget and source/state/RNG checks. Report non-access and failures; no Review-gate tuning by inference. |
| CAP5 | **proposed; gated** | Reconcile existing Crown runtime packet for canonical exposure when explicitly approved | Use the existing13-path sealed packet as review evidence; reconcile current source, named save migration, actual paid receipts/atomic settlement, supported/native UI and active-rival/world/required export gates. No duplicate SideStreet queue or overwrite of current gameplay. |

## Exact change boundary

New named simulator `crown-access-policy-20261025-v1` preserves immutable parent `crown-search-access-20261025-v1` and baseline ancestry. Runtime delta: **zero files**. Both full source identities are434971b9525f09fab3fa0846ed094f53d6ee778f76ae8b97740a136c7b0fda3f. External standalone policy/experiment configs and local records are the new work. Do not copy that research policy into gameplay as an approved production strategy. Existing Crown Search runtime packet remains `handoffs/crown-search-brief-20261025-v1/` unchanged.

This handoff is review routing only, not dispatch to another chat, implementation approval, commit, push or release acceptance.
'''
    (THREAD/handoff).write_text(text,encoding='utf-8')
    recommendation='''\n## Recommendation and next decision\n\nKeep rewards and the Review7 gate unchanged. Retain the shorter policies as useful access fixtures; neither the former18-search route nor the new cash/Research thresholds are player requirements. The reserve policy is a useful next liquidity-conscious baseline, but its purchase cap and reserve are combined and its cadence is not uniformly faster. Puzzle4417 still misses Crown within four releases, so preserve that seed for a separately preregistered specialty-aware purchase/selection comparison. Review the updated paid-Search grade preview before canonical Brief exposure. Do not expand to Crown commissions/support on the strength of these access results.\n'''
    p=THREAD/findings;p.write_text(p.read_text(encoding='utf-8')+recommendation,encoding='utf-8')
    note=f'**2026-10-25 Crown access follow-up complete.** [{line}]({findings}) Both revised policies retain six paid cash Searches and unchanged rewards. [Current preview/review tasks]({handoff}) include twelve paid-Search projections/six final settlements and the zero-award/full-completion warning. Replay, cold Continue and source/prefix checks pass; canonical exposure/UI/migration remain gated. Preserve the non-access Puzzle seed for further research.'
    for name in ['README.md','HANDOFF.md']:
        p=THREAD/name;b=p.read_bytes();(HERE/(name+'.before')).write_bytes(b);end=b.index(b'\n')+1;nl=b'\r\n' if b[end-2:end]==b'\r\n' else b'\n';assert p.read_bytes()==b;p.write_bytes(b[:end]+nl+note.encode()+nl+b[end:])
    p=ROOT/'docs/codex/TODO.md';b=p.read_bytes();(HERE/'TODO.before').write_bytes(b)
    start=b.index(b'**Crown paid-Search Brief');nl=b'\r\n' if b'\r\n' in b else b'\n';end=b.index(nl+nl,start);old=b[start:end]
    new=('**Crown paid-Search Brief — DESIGN review needed; approved pilot terms, private runtime and access evidence,2026-10-25.** '
    '[Exact approval](threads/contracts/BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md) retains2 hands,Scope9/Core4/spread2/fade6,up-to10R,zero other rewards. '
    f'[18-case access follow-up](threads/contracts/{findings}): shorter production reaches{scores["exit"]["access"]}/6; capped/reserve Research reaches{scores["reserve"]["access"]}/6; each completes6/6 without arrears versus0/6 fixed controls, with six paid Searches unchanged. '
    'Exact baseline/prefix/state/RNG checks, fresh replay/reduced failure and Studio Continue pass. '
    f'[Review handoff](threads/contracts/{handoff}) preserves the remaining Puzzle4417 access question; [preview v2](threads/contracts/{preview}) adds current paid-Search cost/grade fixtures and requires explicit presentation review. '
    '[Existing sealed runtime packet](threads/contracts/handoffs/crown-search-brief-20261025-v1/HANDOFF.md) and [CSB adoption gates](threads/contracts/CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md) remain the source for reconciliation, activation, named migration, atomic settlement, UI/world/export acceptance. '
    '[Earlier post-access study](threads/contracts/CROWN-SEARCH-BRIEF-FINDINGS-2026-10-25-v1.md) remains separately scoped; new earlier access does not prove Brief affordability there. '
    'No canonical activation, reward/gate tuning or duplicate SideStreet queue. Research-policy thresholds are not gameplay rules; redraws parked. Crown cash/commission/support and wider catalog remain OPEN.').encode()
    assert p.read_bytes()==b;p.write_bytes(b[:start]+new+b[end:]);assert p.read_bytes().replace(new,old,1)==b
    (HERE/'TODO-replaced-paragraph.before').write_bytes(old)
    write(HERE/'publication-check.json',dict(todo_other_bytes_preserved=True,todo_sha256=hashlib.sha256(p.read_bytes()).hexdigest(),findings=findings,handoff=handoff,preview=preview))
    session=f'''# Contracts session — 2026-10-25 access policy follow-up

User delegated cheaper-access and preview follow-up. Main HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f; shared dirty checkout and other worktrees preserved. Read current state/TODO, repo conventions, publisher authority, simulator usage/variants, prior access/Brief/preview evidence. Branch/status/diff/worktree inventory retained in study folder.

{line} See [{findings}]({findings}) for all18 cases, failures, phase triggers, hashes and exact command/exit manifests. Rewards, gates and canonical source unchanged. Representative replays, reduced failure and fresh Studio Continue pass. Preview:12 legal selections/six frozen settlements,24 recomputation assertions; no UI acceptance claimed.

Changed: thread-owned `studies/crown-access-policy-20261025-v1/`, named owned simulator fork (zero runtime delta), findings, access handoff, preview v2, README/HANDOFF, this session log; minimal replacement of existing Crown DESIGN paragraph in docs/codex/TODO.md. Publication receipt proves all other TODO bytes preserved. Large raw bundles retained outside OneDrive under Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-access-policy-20261025-v1.

Checks: `run.py setup`, `source.py`, `run.py run`, `analyze.py`, `verify.py`, `preview.py`, `source.py`, `publish.py`, `closeout.py`, then final link/hash/source publication checks. Three economic-control batch return codes1 are expected retained failures; verification actions must return0. See exact argv and bounded results under the study folder.

Open: Puzzle4417 access within stated horizon; post-unlock affordability at earlier new starts; explicit preview/canonical exposure decision, named migration, actual UI/world/export/human acceptance. No commits, pushes, canonical gameplay changes or cross-chat dispatch. No new Drive sync requested for this follow-up.
'''
    (THREAD/'SESSION-2026-10-25-CROWN-ACCESS-POLICY-v1.md').write_text(session,encoding='utf-8')
    print('Published review records; unrelated TODO bytes preserved.')
if __name__=='__main__':main()
