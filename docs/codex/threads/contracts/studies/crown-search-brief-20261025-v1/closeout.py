from run import *
def seal():
 handoff=THREAD/'handoffs/crown-search-brief-20261025-v1'
 args=[sys.executable,'tools/simulator_variant.py','handoff','--variant',str(VAR),'--design-record',str(THREAD/'CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md'),'--summary','DESIGN review: approved bounded Crown Brief terms, private paid-Search integration; canonical activation remains gated. Preserve rewards and current SideStreet behavior.','--acceptance','Reconcile only scoped runtime delta; explicit activation review, strict named save migration, grade preview/native UI, atomic settlement, active-rival and requested export acceptance remain required.','--acceptance','Preserve fixed two-hand Scope9/Core4/spread2/fade6 minimum-grade up-to10R and zero cash/Promotion/Investment; record access failures without reward tuning.','--output',str(handoff)]
 # The packager accepts mode=run bundles only. Replays remain linked and hashed in the review record.
 for name in ['prefix','branches','cold']:args+=['--evidence',str(RAW/name)]
 assert not handoff.exists()
 return execute('seal-v2',args)
def publish():
 assert load(HERE/'seal-v2-exit.json')['exit_code']==0
 assert load(HERE/'source-closeout.json')['candidate_unchanged_since_execution']
 link='CROWN-SEARCH-BRIEF-FINDINGS-2026-10-25-v1.md'
 note=f'**2026-10-25 Crown paid-Search study complete privately.** [Findings]({link}) · [gated adoption/research handoff](CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md). Four of12 fixed access routes earn Crown; eight fail financially before Game2. Both earned Action/Simulation starts afford three Briefs, earning12.50R over9 extra cycles with one zero award each; next-release cash is$870.63/$1,520.98 below skip. Two matched pairs, exact cross-version prefixes,32 structural checks, maintained suites, four replays, failure reduction and cold Continue pass. Keep rewards unchanged/redraws parked. Next: cheaper quality-aware access and grade-preview review. Pilot terms are approved; canonical activation, migration/UI/world/export gates and broader catalogs remain open.'
 for name in ['README.md','HANDOFF.md']:
  p=THREAD/name;b=p.read_bytes();(HERE/(name+'.before')).write_bytes(b);end=b.index(b'\n')+1;nl=b'\r\n' if b[end-2:end]==b'\r\n' else b'\n';assert p.read_bytes()==b;p.write_bytes(b[:end]+nl+note.encode()+nl+b[end:])
 # Re-read shared authority immediately before replacing only this owned queue paragraph.
 p=ROOT/'docs/codex/TODO.md';b=p.read_bytes();(HERE/'TODO.before').write_bytes(b)
 marker=b'**Searchable publisher catalog and post-search pacing';start=b.index(marker);nl=b'\r\n' if b'\r\n' in b else b'\n';end=b.index(nl+nl,start)
 old=b[start:end]
 new=('**Crown paid-Search Brief — DESIGN review needed; approved pilot terms and completed private evidence,2026-10-25.** '
 '[Exact approval](threads/contracts/BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md) retains two hands,Scope9/Core4/spread2/fade6,up-to10R and zero other rewards. '
 '[Current-Search study](threads/contracts/CROWN-SEARCH-BRIEF-FINDINGS-2026-10-25-v1.md):4/12 fixed access cases reach Crown;8 fail financially. Two legal matched post-access pairs afford3 Briefs/9 cycles and earn12.50R each, including a zero award. '
 'Cross-version prefix state/RNG,32 structural checks, focused maintained suites, four replays, reduced failure and cold Continue pass. '
 '[Versioned private packet](threads/contracts/handoffs/crown-search-brief-20261025-v1/HANDOFF.md) and [CSB1–CSB4 review/adoption gates](threads/contracts/CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md) define the exact delta and remaining activation, migration, preview/UI, world and export acceptance. '
 'Next design research: cheaper quality-aware phase exits/Research reserves on retained failed routes. No canonical activation or duplicate SideStreet Search queue; rewards unchanged, redraws parked. '
 '[Broader Crown catalog](threads/contracts/CROWN-SEARCH-CATALOG-DESIGN-2026-10-25-v1.md), cash/commission/support terms and other tiers remain OPEN.').encode()
 assert p.read_bytes()==b;p.write_bytes(b[:start]+new+b[end:]);assert p.read_bytes().replace(new,old,1)==b
 (HERE/'TODO-replaced-paragraph.before').write_bytes(old)
 session='''# Contracts session — 2026-10-25 paid Search pilot

User: "Go ahead and cook" after verified Search implementation. Branch main, HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f. Inspected current state/TODO/design/simulator guides, branch/HEAD/status/diff and worktree list; canonical checkout retained, separate fanbase-quarter worktree untouched.

Completed current-source access comparison and approved private Crown paid-Search pilot. [Results, commands, assumptions, source identities, failures and limits](CROWN-SEARCH-BRIEF-FINDINGS-2026-10-25-v1.md). [Versioned adoption/design handoff](CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md).

Checks:12 access cases4 completed/8 economic rejections;2 initial adapter rejections retained. Four post-access cases complete;32 structural assertions,3 maintained suites,2 cross-version prefix comparisons,4 independent replays,92-to24-command reduced failure with fresh confirmation, and2 exact cold Studio continuations PASS. Original ObjectDB warnings and merge diagnostics retained. No native/device/whole-release claim. No new balance approval.

Changed only thread-owned study/policy/probe scripts, two named private simulator folders, sealed handoff packet, versioned finding/handoff/session, README/HANDOFF notices and the existing Crown catalog paragraph in TODO. Shared TODO re-read and all other bytes verified preserved. See studies/crown-search-brief-20261025-v1/source-closeout.json: canonical source matches original captured identity, candidate unchanged since execution. Existing dirty edits and .codex-godot-temp preserved. No canonical gameplay/tests/assets/config edits, computer control, player-save access, commit, push or cross-chat message.

Follow-up: CSB4 reserve/quality-aware access research and Crown preview/adoption review. Canonical activation, migration, active-rival/native/export acceptance remain gated. Drive was not edited in this session.
'''
 (THREAD/'SESSION-2026-10-25-CROWN-SEARCH-PILOT-v1.md').write_text(session,encoding='utf-8')
 print('Updated owned indexes and one TODO paragraph; unrelated TODO bytes preserved.')
if __name__=='__main__':
 if sys.argv[1]=='seal':seal()
 elif sys.argv[1]=='publish':publish()
