from pathlib import Path

root=Path(__file__).resolve().parents[4]
todo=root/'docs/codex/TODO.md'
# Fresh read immediately before these targeted replacements; keep every other handoff.
text=todo.read_text(encoding='utf-8')
replacements={
'**Feature Pools Handoff 017 — QUEUED': '**Feature Pools Handoff 017 — COMPLETE locally,2026-10-18.** Implemented the approved future-only Levels-for-Maps swap for Strategy/Simulation/Sports, explicit roster v2 and old-save v1 preservation. Exact counts/Scope, other five rosters, prices and Research stay intact. Roster239/239, native42/42 at both sizes, actual old/new cold restoration and fresh three-release campaigns pass. [Source, screenshots, original/newer parent-gate distinction and limits](findings/queue-20261018-v2/README.md). [Decision017](../../patch-notes/design-logs/feature-pools/decision-017-future-specialty-levels-swap-2026-10-18.md) and [handoff](../../patch-notes/design-logs/feature-pools/handoff-017-future-specialty-levels-swap-implementation-2026-10-18.md) retain authority. Final balance and human understanding remain OPEN.',
'5. **Feature Store Innovation Path — QUEUED': '5. **Feature Store Innovation Path — DESIGN review COMPLETE,2026-10-18; implementation OPEN.** [Handoff019 assessment](findings/queue-20261018-v2/INNOVATION-REVIEW.md) maps42 live IDs and separately labeled1984–95 candidates, all eight starting-roster conditional routes, missing network/3D ancestors, era/platform blockers and path-manifest/release-receipt/capstone gaps. Corrects stale different-root descriptions under the new Gameplay graph. These are source-derived routes, not funded playthroughs or a victory. [Tech-tree direction](../../patch-notes/design-logs/feature-pools/decision-020-store-progression-victory-direction-2026-10-18.md) remains LOCKED; [three-layer proposal](../../patch-notes/design-logs/feature-pools/proposal-022-innovation-progression-foundation-2026-10-18.md), authored content, exact milestones, capstone and migration remain OPEN under the [Founder route-4 contract](threads/founder-legacy-ownership/2026-10-17-five-victory-conditions-v1.md).',
'    **2026-10-18 G4 quote performance follow-up — DESIGN review needed': '    **2026-10-18 G4 quote performance follow-up — implementation-thread intake COMPLETE; adoption OPEN.** [Sealed-byte/current-source reconciliation and gate review](findings/queue-20261018-v2/AI-QUOTE-REVIEW.md) verifies the two-file v5 packet and identifies only nonoverlapping founding-roster drift. Explicit unavailable reasons, legal low-cash/arrears parity and stable population CPU limits remain unresolved; no quote interface was adopted. [Original finding](threads/ai-competitors/2026-10-18-g4-quote-performance-finding-v1.md), [review](threads/ai-competitors/2026-10-18-g4-quote-performance-design-review-v1.md) and [sealed handoff](threads/ai-competitors/handoffs/g4-current-hand-quote-performance-20261018-v1/HANDOFF.md) retain their bounded candidate evidence. The approved synergy selector below does not approve this separate quote API.',
'    **2026-10-18 G4 synergy competence — QUEUED': '    **2026-10-18 G4 synergy competence — IMPLEMENTED locally, ACTIVE/TRIAL, current two-rival Primitive cohort only.** [Adoption, measured outcomes and limits](findings/queue-20261018-v2/AI-SYNERGY.md) reconciles the [v6 packet](threads/ai-competitors/handoffs/g4-synergy-trial-20261018-v1/HANDOFF.md) and [decision](threads/ai-competitors/2026-10-18-g4-synergy-trial-decision-v1.md), enables the approved Beta choice by default and excludes former-player/richer Store pools. Final817/817 choice checks,118/118 actual20-cycle world/save checks, exact old-world cold migration, two fresh AI replays and unchanged player campaigns pass. All eight first-Review pairs improve; two actual incumbent releases improve and two tie, with unchanged hand counts/calendar. Local elapsed/CPU observations are recorded, not a stable population budget. Richer Store choices, distressed liquidity, entrants, active market effects, final balance and demonstrated player challenge remain OPEN.'
}
lines=text.splitlines()
for prefix,new in replacements.items():
    matches=[i for i,line in enumerate(lines) if line.startswith(prefix)]
    assert len(matches)==1,(prefix,matches)
    lines[matches[0]]=new
text='\n'.join(lines)+'\n'
text=text.replace('This also satisfies Feature Pools Decision019/Handoff018; unrelated Handoff017 stays queued.','This also satisfies Feature Pools Decision019/Handoff018; Handoff017 was subsequently completed below.')
text=text.replace('Handoff017 below retains its queued status.','Handoff017 was subsequently completed below.')
marker='Still-unpaid age2+ and every exported credit tier are not claimed.'
assert text.count(marker)==1
text=text.replace(marker,marker+' The [2026-10-18 bounded age2 attempt](findings/queue-20261018-v2/BANK-AGE-ATTEMPT.md) stopped at the ordinary productive-cycle preflight rejection at cycle50/cash0; target-dependent checks failed and the legal rejection is retained. This does not close age2+ acceptance.')
summary='**2026-10-18 queue execution v2 — approved roster and AI synergy implementations COMPLETE locally.** [Results and remaining gaps](findings/queue-20261018-v2/README.md) · [session log](logs/2026-10-18-queue-execution-v2.md). Handoff017 and the approved two-rival G4 synergy task are adopted; Innovation Handoff019 and G4 quote intake reviews are complete with unapproved rules OPEN. Final fresh campaigns finish12 releases/216 commands with exact replay and unchanged player state/RNG. Bank age2+ remains unproven after a retained legal rejection; human, export and deferred design boundaries remain explicit. No commit/push.\n\n'
assert '## Dispatch and shared constraints\n\n' in text
text=text.replace('## Dispatch and shared constraints\n\n','## Dispatch and shared constraints\n\n'+summary,1)
todo.write_text(text,encoding='utf-8')

genre=root/'docs/codex/design/genre-specialties.md'
text=genre.read_text(encoding='utf-8')
text=text.replace('## Future-start founding rosters v2 — LOCKED design, QUEUED implementation 2026-10-18','## Future-start founding rosters v2 — LOCKED design, IMPLEMENTED locally 2026-10-18')
text=text.replace('The table above describes the **implemented v1** founding grants.','The table above describes the **historical v1** founding membership; its counts and Scope also hold for v2.')
text=text.replace('new Strategy, Simulation and Sports Studios will receive','new Strategy, Simulation and Sports Studios receive')
old='[Handoff 017](../../../patch-notes/design-logs/feature-pools/handoff-017-future-specialty-levels-swap-implementation-2026-10-18.md) is queued; the v2 rule is **not yet implemented**.'
assert old in text
text=text.replace(old,'[Handoff017](../../../patch-notes/design-logs/feature-pools/handoff-017-future-specialty-levels-swap-implementation-2026-10-18.md) is implemented with explicit saved version2; absent historical metadata remains v1, without regrant. [Source and verification](../findings/queue-20261018-v2/README.md):239 roster/version checks,42 native checks, exact real prior-save restoration and fresh campaigns pass. The original four gates close for the affected v2 starts; newer parent gates retain legitimate granted-child exceptions, so this is not a claim that every roster is fully ancestor-closed.')
genre.write_text(text,encoding='utf-8')

state=root/'docs/codex/CURRENT_STATE.md'
text=state.read_text(encoding='utf-8')
line='**2026-10-18 queue v2 — implemented locally:** future-only Strategy/Simulation/Sports Levels-for-Maps roster v2, exact prior-save provenance, and approved two-incumbent Primitive synergy choices. Innovation graph and quote-candidate intake reviews are complete; unapproved content/economics remain OPEN. Final roster239/239, AI817/817, actual-world118/118, cold migration and twelve-release/216-command fresh campaigns with exact replays pass. Player state/RNG matches the pre-policy campaigns. Bank age2+ attempt retained a legal rejection; export/human/audio-device acceptance remains separate. [Finding and source boundaries](findings/queue-20261018-v2/README.md) · [session log](logs/2026-10-18-queue-execution-v2.md). No commit/push.\n\n'
first,rest=text.split('\n',1)
state.write_text(first+'\n\n'+line+rest.lstrip('\n'),encoding='utf-8')
print('Updated TODO, genre-specialties and CURRENT_STATE with targeted changes')
