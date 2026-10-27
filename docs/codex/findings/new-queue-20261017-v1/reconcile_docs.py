from run_checks import *

changed=[]
def edit(relative,fn):
 path=ROOT/relative
 raw=path.read_bytes();text=raw.decode('utf-8');crlf='\r\n' in text
 text=text.replace('\r\n','\n');updated=fn(text)
 assert updated!=text,relative
 path.write_bytes(updated.replace('\n','\r\n').encode('utf-8') if crlf else updated.encode('utf-8'))
 changed.append(relative)
def paragraph(text,prefix,value):
 lines=text.splitlines()
 matches=[i for i,line in enumerate(lines) if line.startswith(prefix)]
 assert len(matches)==1,(prefix,len(matches))
 lines[matches[0]]=value
 return '\n'.join(lines)+'\n'
def insert_after(text,heading,value):
 assert text.count(heading)==1,heading
 return text.replace(heading,heading+'\n'+value+'\n',1)

evidence='findings/new-queue-20261017-v1/README.md'
review='findings/new-queue-20261017-v1/DESIGN-REVIEW.md'
variety='findings/new-queue-20261017-v1/AI-VARIETY.md'
summary='**2026-10-17 new queue — approved implementation COMPLETE; bounded reviews and private variety refresh recorded.** [Source-pinned evidence and remaining work]('+evidence+') · [session log](logs/2026-10-17-new-queue-implementation-v1.md). Added the four approved ACTIVE/TRIAL Alpha Store cards, neutral real-release index and structural Founder victory ledger. Fixed expanded Store branch overlap and post-launch operator handoff; narrow prior-catalog/Founder-source migration preserves actual saved state. Final focused mechanics/cold/replay checks pass, three fresh campaigns complete six releases/108 exactly replayed commands, both-size Store/card captures pass,32 Python tests pass and a byte-current301-entry export starts cleanly. The maintained gate now runs the new cold checks after their producers; eight affected jobs pass459 assertions. Handoffs013/014 reviews explicitly defer unapproved content/effects; Contract challenge terms remain OPEN. The private Theme-variety refresh passes213/213 twice with four legal releases and exact player replay; active-pressure transaction work remains DESIGN. Founder ten-subsidiary gameplay still exceeds the eight-rival save cap. No final balance, human/audible acceptance, commit or push is claimed.'

def todo(text):
 text=insert_after(text,'## Dispatch and shared constraints\n',summary)
 text=text.replace('**Contracts run challenges — DESIGN review needed, 2026-10-17; no canonical challenge gameplay queued.**','**Contracts run challenges — initial DESIGN review COMPLETE; trial terms and full-path candidate OPEN, 2026-10-17.**',1)
 prefix='**Contracts run challenges — initial DESIGN review COMPLETE;'
 line=next(line for line in text.splitlines() if line.startswith(prefix))
 line=line.replace('Review the [proposed handoff]','The [initial integration review]('+review+'#contracts-challenge-review) recommends versioned accepted terms, committed-redraw counting, separate once-only rewards and no retroactive old-Contract bonuses. The [proposed handoff]')
 line=line.replace('): select each publisher',') still needs the design thread to select each publisher')
 text=paragraph(text,prefix,line)
 text=paragraph(text,'**Founder victory ledger first slice —','**Founder victory ledger first slice — IMPLEMENTED locally at structural scope, 2026-10-17.** Reconciled the [sealed candidate](threads/founder-legacy-ownership/handoffs/victory-ledger-v1/HANDOFF.md) against exact source pins, then added the versioned world claim ledger and committed-transaction ten-subsidiary evaluator. [Implementation evidence]('+evidence+') records13 evaluator,30 world,6 fresh-process restore,10 normal Gameplay and17 atomic-commit checks; the prior writer-lease block is resolved. Prior Founder-v1 worlds remain readable without retroactive claims. Current world checkpoints still cap AI Studios at eight, so the larger in-memory commit fixture does not make a ten-subsidiary win reachable in a saved campaign. No victory UI, other route evaluator, larger roster or new numerical threshold is included.')
 text=text.replace('Only the first slice is queued for canonical implementation review; the following items need their own decisions','The ledger first slice is implemented; the following items need their own decisions',1)
 text=paragraph(text,'**Feature Pools Handoff 012 —','**Feature Pools Handoff 012 — IMPLEMENTED locally, 2026-10-17; bounded ACTIVE/TRIAL first Alpha shop pack.** Adopted [Decision012](../../patch-notes/design-logs/feature-pools/decision-012-first-authored-alpha-shop-pack-2026-10-17.md) and its [handoff](threads/feature-pools/handoffs/first-authored-alpha-shop-pack-v1/HANDOFF.md): Turn-Based Combat, Character Classes, Character Development and Branching Dialogue now have exact authored Alpha scores/Scope/parents, temporary$1,700 base/$0 later-card play fee, current one-action Research and future-project supply. [Evidence]('+evidence+') covers174 mechanics+28 cold checks, four exact replays, parent/regression tests,58 both-size UI assertions/ten captures,1,841 card-fit checks and actual prior-catalog/world migration. Expanded-map overlap is repaired. Specialty, Primitive/Contract supply and old active-project supply stay unchanged. Final balance, other cards, era/platform rollout, separate Sub-Areas/Background Music pilots, final art and human Store comprehension remain OPEN/deferred.')
 for number,description in [('013','first Genre/Theme pack'),('014','first Pass effect/terms package')]:
  prefix='**Feature Pools Handoff '+number+' —'
  line=next(line for line in text.splitlines() if line.startswith(prefix))
  line=line.replace('QUEUED DESIGN review','DESIGN review COMPLETE; '+description+' DEFERRED',1)
  line+=' [Implementation-thread review]('+review+') records the recommended typed entitlement/frozen-project model, exact missing decisions and required acceptance. These recommendations are OPEN; no new gameplay is activated.'
  text=paragraph(text,prefix,line)
 text=paragraph(text,'    **2026-10-17 market index foundation —','    **2026-10-17 market index foundation — IMPLEMENTED locally; read-only scope.** Adopted the [structural handoff](threads/ai-competitors/handoffs/market-index-foundation-v1/HANDOFF.md) as `queries/market_release_index.gd`. It derives deterministic player/rival/continuing-former-player rows with frozen optional Core availability and actual units/cents, excluding archives/previews. [Evidence]('+evidence+') passes151 assertions plus4 cold checks/36 replay steps, including six actual releases, real operator transfer and unchanged state/RNG/checkpoint bytes. Missing required records fail with reasons. Optional-Core runtime behavior is verified; old missing-Core save migration is not claimed. No active Review/sales, policy, UI or checkpoint rule comes from the query; simulator/export provenance includes it explicitly.')
 prefix='    **2026-10-17 active market effects —'
 line=next(line for line in text.splitlines() if line.startswith(prefix))
 line=line.replace('The neutral index queue above is unchanged.','The neutral index above is now implemented. A [new private Theme-variety refresh]('+variety+') passes twice; the earlier failed/incomplete versions remain historical. This does not complete the active transaction candidate or select its OPEN values.')
 text=paragraph(text,prefix,line)
 prefix='    2. **Rival variety before pressure:**'
 line=next(line for line in text.splitlines() if line.startswith(prefix))
 line+=' **Bounded Theme refresh COMPLETE:** [two213/213 runs]('+variety+') produce four releases across two Genres/three Themes with exact repeated state/RNG and18-command replay. Specialty Genre choices remain fixed; broader choice/quality coverage and active-effects comparisons are still OPEN.'
 text=paragraph(text,prefix,line)
 return text
# Fresh read immediately before this minimal paragraph update preserves new handoffs.
edit('docs/codex/TODO.md',todo)

def state(text):
 text=insert_after(text,'## Current queue execution\n',summary.replace('**2026-10-17 new queue','**2026-10-17 latest new queue'))
 changes={
 '2026-10-17: **Future Feature Store Genre/Theme and Pass branches queued':'2026-10-17: **Future Feature Store Genre/Theme and Pass branch reviews COMPLETE; first playable packages DEFERRED.** [Review]('+review+') specifies recommended typed ownership gates, baseline-option preservation and frozen-project replacement/migration contracts. Exact effects, terms, definitions/targets and rollout remain OPEN. No current Genre/Theme or Pass rule changed.',
 '2026-10-17: **Founder victory ledger first slice prepared':'2026-10-17: **Founder victory ledger first slice IMPLEMENTED locally at structural scope.** [Evidence]('+evidence+') verifies once-only committed-ownership claims, ordinary Gameplay/Studio Continue and exact prior-source migration. Ten subsidiaries remain unreachable in a saved campaign under the existing eight-rival cap; UI and other victory routes remain OPEN. The earlier candidate and writer-lease limit are retained in their dated records.',
 '2026-10-17: **First authored Alpha Feature Store pack queued':'2026-10-17: **First authored Alpha Feature Store pack IMPLEMENTED locally, ACTIVE/TRIAL.** [Decision012](../../patch-notes/design-logs/feature-pools/decision-012-first-authored-alpha-shop-pack-2026-10-17.md) authorizes Turn-Based Combat, Character Classes, Character Development and Branching Dialogue at temporary$1,700 base/$0 later-card fee. [Adoption/check evidence]('+evidence+') covers exact printed content, ownership/quotes/cents, legal Alpha play, both-size UI, cold Continue and compatible old-source state. Other content and final balance remain OPEN.',
 '2026-10-17: **AI Competitors neutral market index queued':'2026-10-17: **AI Competitors neutral market index IMPLEMENTED locally.** [Evidence]('+evidence+') verifies derived real player/rival/former-player releases, optional frozen Core availability and earned/settled sales without mutation. It is not active market pressure or a leaderboard. The [private Theme-variety refresh]('+variety+') passes twice; active transaction/project/sales-ledger work and numerical decisions remain DESIGN/OPEN.'}
 for prefix,new in changes.items():text=paragraph(text,prefix,new)
 return text
edit('docs/codex/CURRENT_STATE.md',state)

def store(text):
 text=text.replace('**Ordered three-Core foundation — APPROVED structural direction 2026-10-17; canonical implementation QUEUED.**','**Ordered three-Core foundation — IMPLEMENTED locally at structural scope, 2026-10-17.**',1)
 text=text.replace('**APPROVED for a bounded ACTIVE/TRIAL implementation; not yet implemented.**','**IMPLEMENTED locally under the bounded ACTIVE/TRIAL approval.**',1)
 text=text.replace('[Handoff 012](../threads/feature-pools/handoffs/first-authored-alpha-shop-pack-v1/HANDOFF.md) is queued for the main implementing thread; no new card is live until that thread adopts and verifies it.','[Handoff012](../threads/feature-pools/handoffs/first-authored-alpha-shop-pack-v1/HANDOFF.md) is adopted; [source/check evidence](../'+evidence+') covers legal acquisition/play, exact cents, future-project supply, prior-catalog migration, cold replay and both-size UI.',1)
 text=text.replace('**DESIGN/OPEN; DESIGN reviews queued, no implementation.**','**DESIGN/OPEN; bounded reviews COMPLETE, first effect/content packages DEFERRED.**',1)
 return text+'\n[Handoffs013/014 implementation-thread review](../'+review+') recommends typed separate entitlements and per-project frozen Pass effects with one effective Pass per category. These are OPEN recommendations until exact content, effects, acquisition and migration terms receive a bounded ruling; current options/Passes remain unchanged.\n'
edit('docs/codex/design/feature-store-progression.md',store)
edit('docs/codex/threads/ai-competitors/README.md',lambda text:insert_after(text,'# AI Competitors design thread\n','**Latest implementation reconciliation, 2026-10-17:** the [neutral real-release index](../../'+evidence+') is implemented and verified locally. The [new private Theme-variety refresh](../../'+variety+') passes213/213 twice with exact repeated observations/RNG and fresh player replay; older timeout records retain their scope. Active pressure, project/sales ledger changes and detailed AI policy remain DESIGN/OPEN. This supersedes the queued-index and incomplete-variety descriptions in the historical dated entries below.'))
edit('docs/codex/threads/founder-legacy-ownership/README.md',lambda text:insert_after(text,'## Victory ledger candidate — 2026-10-17\n','**Canonical first slice now IMPLEMENTED:** [adoption, exact checks and limits](../../'+evidence+'). The versioned claim ledger, atomic ownership-triggered evaluator, source compatibility and normal Gameplay Continue checks pass. The historical candidate paragraph below is superseded only for this structural slice; saved-population reachability and victory UI remain OPEN.'))
edit('docs/codex/design/publishers-contracts.md',lambda text:text+'\n## Challenge integration review — 2026-10-17\n\n[Initial review COMPLETE](../'+review+'#contracts-challenge-review): recommend versioned terms frozen at acceptance, committed-redraw counters, separately keyed once-only cash/Promotion bonuses and no retroactive bonuses for old Contracts. These remain recommendations pending exact publisher map/targets/fades/caps/rounding and a full legal-path private candidate. Ironclad stays introductory and current base rewards are unchanged; $100/+4 is unapproved candidate data.\n')
edit('docs/codex/threads/contracts/README.md',lambda text:insert_after(text,'# Contracts design thread\n','**Implementation-thread review, 2026-10-17:** [initial challenge review](../../'+review+'#contracts-challenge-review) is complete with concrete counter/settlement/migration recommendations. Publisher maps, attainable targets/fades, caps and rounding still need approval; the full reward path remains a private candidate follow-up, not canonical gameplay.'))
edit('docs/codex/DECISIONS.md',lambda text:text+'\n## 2026-10-17 — New queue implementation boundaries\n\n[Verified adoption]('+evidence+'): the approved four-card Alpha pack uses existing Research/owned-parent rules and ACTIVE/TRIAL$1,700/$0 terms; older active supply remains frozen through narrowly named catalog compatibility. The neutral market index derives releases without changing gameplay identity or save state, while external simulator/export manifests include its query source. Founder victory claims commit atomically with validated ownership/cash and remain structural under the eight-rival save cap. [Genre/Theme, Pass and challenge reviews]('+review+') do not approve unspecified content/effects/bonus terms. The private AI variety result does not approve active market coefficients or skip the transaction-ledger prototype.\n')
edit('docs/codex/findings/new-queue-20261017-v1/DESIGN-REVIEW.md',lambda text:text.replace('../../../..//patch-notes/','../../../../patch-notes/'))
edit('docs/codex/findings/new-queue-20261017-v1/AI-VARIETY-PLAN.md',lambda text:text+'\n**Post-run description correction:** the retained source timer was90 seconds, not45 as written above. No timer changed during the experiment. Both actual process timings and the exact source are recorded in [the finding](AI-VARIETY.md).\n')
sim.write_json(BASE/'documentation-changes.json',changed)
print(json.dumps(changed))
