"""Produce the standalone read-only calendar-era findings after verification."""
from pathlib import Path
import csv,hashlib,json,statistics
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design-logs/task24-v1'
load=lambda n:json.loads((OUT/n).read_text(encoding='utf-8'))
summary=load('summary.json');gate=list(csv.DictReader((OUT/'gate-access.csv').open()))
checkpoints=list(csv.DictReader((OUT/'calendar-checkpoints.csv').open()))
catalog=load('catalog-access.json');verify=load('verification-focused.json')
assert verify['source_unchanged'] and verify['diff_check']==0
assert all(r['exit']==0 and not r['errors'] for r in verify['results'])
normal=load('verification-normal.json');long=load('verification-long.json')+load('verification-long-supplement.json')
assert len(normal)==6 and all(r['exit']==0 and not r['errors'] for r in normal)
assert all(any(r['name']==f'normal_{p}_0_1104' and r['exit']==0 and not r['errors'] for r in long) for p in ['cautious','ordinary','synergy'])
lines=[]
def add(s=''):lines.append(s)
def dollars(c):return '$'+format(int(c)/100,',.2f')
add('PATCH NOTES — TASK 24 CALENDAR-ERA SIMULATION FINDINGS v1')
add('2026-09-29 | READ-ONLY current-Godot captures plus labeled access-only shadow analysis')
add()
add('DECISION SUMMARY')
add('Retain the joint calendar-plus-full-Scope-release principle as a proposed rule; revise the numerical candidates before approval. Calendar-only permits empty launches and one-release priority grinding to unlock the whole proposed era schedule. Count requirements stop those shortcuts, but overly high counts reward fast repeat releases over slower high-Review production. Keep existing first-era immediate availability; defer the cycle-24 gate because this sample shows little benefit. No rule, price, payout, card, authority threshold or fan rate was implemented or approved.')
add('Trial recommendation only: cumulative counts [1,3,6,10,14] for 1984/1990/2000/2010/2020. This post-hoc candidate keeps light’s early counts and lowers its last two. It adds no delay beyond the first real Studio opportunity on the captured high-effort route. It needs broader/human and future-card evidence before a lock.')
add()
add('AUTHORITY AND SOURCE STATE')
add('Execution queue: https://docs.google.com/document/d/1n6o5g8Gj_sDTs5Ku6PLM37OWPPyLpDM_ASfNiD9MRkY/edit — Task 24, refreshed before work and before status edit.')
add('Cumulative authority: https://drive.google.com/file/d/1kmlzNwRbckS9OxucMd5WPYNOF2Dx6QT1/view — fresh §61 saved as authority-section61.txt. Supplied Patch_Notes_Multi_Era_Feature_Store_Design_v1.md, Task 2 Stage 3 in Feature_Store_Staged_Simulation_Findings_v1.txt, and Task21_SideStreet_Required_Scope_and_Calendar_Year_v1.txt were reconciled with current source.')
add('Live branch main; HEAD and local origin/main tracking ref: '+verify['head']+'. No fetch/commit/push performed by this task. Seventeen tracked files already contained pending tutorial, Studio, Feature-map, publisher, SideStreet/Scope/year and verifier changes. They remain local/uncommitted, as do this task’s analysis artifacts. No repository/ancestor AGENTS.md was found. Old Stage 3 under-Scope SideStreet cash is not the baseline.')
add(f"Before/after SHA-256 manifests match for all {verify['source_file_count']} scripts/scenes/data files. source-before.json SHA-256: {hashlib.sha256((OUT/'source-before.json').read_bytes()).hexdigest()}. Initial branch/HEAD/status/full diff saved. No gameplay source or .codex-godot-temp was targeted or edited.")
add()
add('PLAYABLE AND SHADOW BOUNDARIES')
add('Live paths exercised headlessly: Main Menu/Studio creation, legal starter purchase API, Pre-Development, native Design/Alpha/Beta draw/selection/redraw/priority actions, Review/launch, Studio Store, Ironclad and available SideStreet, native ongoing sales earning/month settlement. No free Wait/cash/cards/scores or hidden-Bug policy lookahead. Actual market inputs and Review RNG are seeded. No graphical mouse/input playthrough was performed; this is automated policy evidence, not human evidence.')
add('Live supply: 27 Primitive plus 11 Store Features = 38 definitions. The 97-node design includes 13 authored but unimplemented Alpha cards and 46 invented candidates. Later five bands have 10/12/6/4/6 cards. None of those 38 later candidates was purchased, owned, drawn or played. 2026 is the observation horizon, not a sixth card tier.')
add('Missing capabilities: 26 multi-parent nodes require AND ownership support; seven tertiary-effect definitions exceed current two effect slots; 29 directly conditional proposed cards need an absent target-platform selector/compatibility model. No-platform control blocks tagged cards and missing tagged ancestors. ALL-capabilities is only a synthetic upper bound. No parent tag is inherited by a child. Blank 3D Camera Controls / Physics-Based Objects tags are design omissions, not historical compatibility proof.')
add('Affordability is separated from parent readiness, ownership and actual play. Shadow quotes use captured parent familiarity, the proposed summed-parent 50% cap, and low/center/high draft prices. Each complete missing-AND path is priced individually; multiple path quotes share parents and must not be summed. Cash after a hypothetical $1,500 holdback is a separate sensitivity. Each missing-node purchase cycle is counted, without adding future sales to pay upfront costs. No candidate supply dilution, downstream Review, play cost or ROI is simulated. Existing live purchases use native prices/cycles/discounts.')
add()
add('DESIGN, SEEDS, COUNTS AND CENSORING')
add('36 short route executions: 3 policies × 6 matched cases × immediate/cycle-24 existing-Store access. These are 18 distinct policy/seed starts, not 36 independent samples. Four completed case-0 continuations (all three immediate policies plus cautious cycle24) extend existing seeds to the first Studio at/after cycle1104; they add no independent seeds. One separate high-effort Task21 continuation. Three separate stress policies are excluded from normal frequencies; bounded stress counts and any timeout appear below.')
add('Extra ordinary/cycle24 long attempt timed out at300seconds with no completed action trace counted. The original sequential batch stopped there; synergy/cycle24 long was not run. Synergy/immediate continuation was then dispatched independently with a600second bound. The paired cycle24 comparison is complete for the36 short executions, not a six-arm long cohort. Do not infer a cash/card stall from that runtime timeout.')
add('Common calendar checkpoints: cycle96=1984,240=1990,480=2000,720=2010,960=2020,1104=2026; cycle24=1981 for first-era access. January1980 is the live origin, with24cycles/year. Eligibility uses the first ACTUAL Studio opportunity satisfying both date and count, never a mid-production crossing. Counts use unique committed release IDs, frozen printed Scope >= the chosen B-size required30, once at launch. Under-Scope/empty launches never count, even when random Review variance yields sales.')
add('A cohort run ends after the first release Studio meeting its cap; it may overshoot. A gate not reached within that observed route is right-censored, not permanently impossible. High continuation ends at1159 (2028), the first Studio after1104. A late unlock there is after the2026 boundary, not evidence it was available at1104. The 2020-era window ends only at the observation horizon; there is no invented next era.')
add('Normal case i=0..5: draw seed270927000+97*i; environment seed240929000+i; each game adds500000 to draw seed, then Design deal/finalize +1/+2, Alpha +3/+4, Beta +5/+6, Review +7. Genres rotate action/adventure/strategy. Starter total printed Scope20+(i%4), exact roster/cash in raw JSON; all stay within400000-cent purchase cap. These are owned pool totals including six free starter cards, not played Scope guarantees. No below20 starts here.')
add('Cautious:2Design/3Alpha/2Beta hands, follows both tutorial suggestions, then first affordable four; no ordinary redraws. Ordinary:4/6/4 hands, visible capped-Scope/printed-Core scoring with small specialization preference, up to1 redraw. Synergy/Genre-aware:6/8/6 hands, Genre-weighted visible Core and specialization, up to2 redraws. Ordinary/synergy change Design priorities after second hand, paying native cycle. Even cases use initially Sound-biased Design/Alpha priorities and QA; odd cases use mixed priorities and Marketing preference. Sound bias is a priority setting, not a Sound-specific hand utility. QA reads known Bugs only. Tutorial shaping remains active. Short policy labels are heuristics, not measured novice/human behavior.')
add('All normal routes first buy affordable Primitive reserve cards until owned Primitive Scope>=33, retaining $2,000 cautious/$1,800 others; then at most one affordable live Store upgrade per Studio. Contracts are only those actually offered. High route is the distinct balanced Task21 policy; its inherited production_focus="sound" metadata is stale. It requests longer production but the trace records actual committed hands. High environment seed290929000, draw seed270927000, --mode=exact; first88 Design/Alpha/Beta actions reproduce Task21 exactly. Reviews6.4 and9.8 are real results. Human observations4.6 first/8.9 later and all Features affordable byGame4 were not simulated targets or captured human traces.')
add()
add('SHORT COHORT — CURRENT IMMEDIATE STORE ARM, FIRST POST-BOUNDARY STUDIO')
for policy in ['cautious','ordinary','synergy']:
    group=[r for r in summary['routes'] if r['policy']==policy and r['cap']==240 and r['store_gate']==0]
    add(f"{policy}: n={len(group)}, first full-Scope cycles {[r['first_qualifying_cycle'] for r in group]}, final qualified counts {[r['qualifying_releases'] for r in group]}, minimum observed cash {dollars(min(r['minimum_cash_cents'] for r in group))}.")
    for year in [1984,1990]:
        for schedule in ['calendar_only','light','middle','demanding']:
            g=[r for r in gate if r['route'].startswith('normal_'+policy+'_0_240:') and r['era_year']==str(year) and r['schedule']==schedule]
            reached=[r for r in g if r['reached']=='True'];cycles=[int(r['first_studio_cycle']) for r in reached]
            add(f"  {year} {schedule}: {len(reached)}/{len(g)} reached by route endpoint; first eligible cycles {cycles or 'censored'}.")
add('No observed normal route stalled or failed an affordable legal action. Every successful purchase, production hand and cycle is retained; the minimum-cash statistic is an observation, not a recommendation for reserve size. Cautious’s few full-Scope releases despite growing ownership/cash reflect its short production policy, not a human progression ceiling.')
add()
add('REPRESENTATIVE CONTINUATIONS — COMMON CHECKPOINTS')
for policy in ['cautious','ordinary','synergy','high_task21']:
    name=f'normal_{policy}_0_1104:0' if policy!='high_task21' else 'high_task21_1104:0'
    row=next(r for r in summary['routes'] if r['route']==name)
    add(f"{policy}: {row['releases']} releases / {row['qualifying_releases']} qualifying; {row['hands']} hands; final cycle{row['final_cycle']}, cash{dollars(row['final_cash_cents'])}, unpaid{dollars(row['final_unpaid_cents'])}; owned{row['owned']}, distinct actually played{row['actual_played_features']}. Review min/median/max={row['review_min']}/{row['review_median']}/{row['review_max']}. Native Playtest Rival Games cash across route={dollars(row['rival_cash_cents'])}.")
    for c in [r for r in checkpoints if r['route']==name]:
        add(f"  {c['year']}: Studio cycle{c['first_studio_cycle']} (+{c['delay_cycles']}), qualifying{c['qualifying_count']}, cash{dollars(c['cash_cents'])}, earned-unsettled{dollars(c['unpaid_cents'])}, owned{c['owned_count']}.")
    for schedule in ['calendar_only','light','middle','demanding','posthoc_candidate']:
        g=[r for r in gate if r['route']==name and r['schedule']==schedule]
        add(f"  {schedule} first Studio cycles by five eras: "+str([r['first_studio_cycle'] or 'censored' for r in g]))
add('These representative case0 continuations are not population percentages. Large current cash balances reflect native sales, contracts and Beta rival-playtest payouts with current expenses only; they do not include proposed payroll, candidate purchases or future play costs. They cannot establish affordability of an entire future catalog.')
add()
add('SCHEDULE TRADEOFF AND LOST ERA WINDOWS')
add('Predeclared schedules: calendar-only[0,0,0,0,0], light[1,3,6,12,18], middle[2,6,12,24,36], demanding[4,10,20,35,50]. These are all sensitivity inputs. Post-hoc[1,3,6,10,14] was derived AFTER viewing full-Scope cadence and is explicitly unapproved.')
add('High route earliest Studio/count pairs:105/1,291/4,480/7,725/11,973/15. Light adds62cycles for2010 and186cycles for2020 compared with those available visits, reaching2020cards at1159. Middle’s2000cards wait until787, after the2010 boundary; its2010/2020counts are unmet. Demanding delays1984cards to291, past1990, and1990cards to663, past2000; later counts are unmet. That loses pre-next-era windows for10and12cards respectively, not proof cards were bought or skipped by a human.')
add('Post-hoc candidate adds no observed extra delay on the high route; time before the next era is135/189/240/235cycles for its first four tiers. Last tier has131cycles until2026 observation, no next era specified. It still permits one full-Scope release to open1984, but requires more to open1990+. Full-Scope repeat production can still satisfy it; this is a production-milestone gate, not an anti-grind or quality gate. Adding Review/quality gates was outside scope.')
add()
add('FIRST-ERA CYCLE24 PAIR')
pairs=[p for p in summary['pairs'] if p['cap']==240]
same=sum(p['release_scope_review_cycle_equal'] for p in pairs)
add(f'{same}/{len(pairs)} paired short routes have identical release Scope/Review/cycles and final cash. Ordinary and synergy first upgrades were already after24. Only cautious cases1and4 differ:')
for p in pairs:
    if not p['release_scope_review_cycle_equal']:add(str(p))
add('The delay changes draws and sales through changed ownership/timing, so cash differences are whole-route paired outcomes, not a direct price effect. The completed cautious case0 long pair is identical; other long pairs are incomplete as disclosed. This bounded result does not cover a player who immediately buys all upgrades beforeGame1. Retain current immediate access; defer a cycle24 lock rather than install a gate without demonstrated benefit.')
add()
add('SEPARATE STRESS ARMS')
for name in ['stress_priority.json','stress_empty.json','stress_repeat.json','stress_repeat_independent.json','stress_repeat_censored981.json','stress_repeat_checkpoint96.json','stress_empty_checkpoint240.json']:
    if not (OUT/name).exists():continue
    r=load(name)['rows'][0];f=r['final'];rel=r['releases']
    add(f"{name}: valid prefix/trace={r.get('valid')}; final cycle{f['cycle']}, year{f['year']}; {len(rel)} committed releases, {sum(x['meets_required_scope'] for x in rel)} qualifying; cash{dollars(f['cash_cents'])}, unpaid{dollars(f['unpaid_cents'])}; purchases={len(r['purchases']) if isinstance(r.get('purchases'),list) else 'not retained in timed-out prefix'}; blockers={r.get('blockers','not retained')}.")
    for boundary in [96,240,480,720,960,1104]:
        s=next((s for s in r['studio_visits'] if s['cycle']>=boundary),None)
        add(f"  boundary{boundary}: "+(f"Studio{s['cycle']}, qualifying{s['qualifying_count']}, cash{dollars(s['cash_cents'])}, unpaid{dollars(s['unpaid_cents'])}" if s else 'right-censored'))
    for schedule in ['calendar_only','light','middle','demanding','posthoc_candidate']:
        items=[x for x in catalog['records'] if x['source_file']==name and x['schedule']==schedule]
        add(f"  {schedule}: "+str([x.get('cycle','censored') for x in items]))
if (OUT/'stress-limitations.txt').exists():add((OUT/'stress-limitations.txt').read_text())
add('Priority-only aging leaves familiarity and ownership fixed after its sole full-Scope release. Calendar-only passes all dates; light/post-hoc admit1984only, middle/demanding admitnone. Empty releases never earn a new SideStreet entitlement or qualifying credit. Existing earned offers remain preserved. Empty-game positive sales from native Review variance are not fabricated full-Scope success. Repeated full-Scope B production legitimately advances the counter; inspect its actual completed trace above rather than mixing it into normal frequencies.')
add('Measured empty-loop cash attribution: cycle34 after Ironclad875142c → cycle2403650636c, increase2775494c. Remaining first-game settlement264336c; zero-hand releases themselves settled2511158c ($25,111.58). No new Contract payouts or purchase/production fees occur in that sequence. The206 zero-hand releases have Scope0 and Reviews0.0–0.5. This is a real current sales exploit, even though the new Scope gate correctly blocks its SideStreet/qualifying credits. Recommend a separately authorized launch/sales-rule review; no fix or compensation was added here.')
add()
add('AND-PARENT / PLATFORM / MONEY ACCESS')
add('catalog-access.json has every first-eligible-era-visit shadow node row, missing direct parents, complete missing path, hypothetical purchase cycles, quotes, affordability with/without reserve, actual owned IDs and actual played IDs. candidate-first-ready.csv separately scans all actual Studio visits for each node’s first observed date+count+AND+cash readiness, with no-platform and ALL synthetic cases. Never-observed readiness is censored; it does not imply a permanent lock. At late dates a node may be affordable but still lack parents/platform/schema. No-platform control permits zero2010quotes because all four proposals have direct capability tags; unlimited cash does not fix that.')
for year in [1984,1990,2000,2010,2020]:
    records=[r for r in catalog['records'] if r['source_file'] in ['normal_cautious_0_1104.json','normal_ordinary_0_1104.json','normal_synergy_0_1104.json','high_task21_1104.json'] and r['schedule']=='calendar_only' and r['era_year']==year and r['reached']]
    for r in records:
        s=r['normal_summary'];a=r['synthetic_summary']
        add(f"  {year} {r['policy']}: actualownedparents{s['direct_parents_owned']}/{s['nodes']}; no-platform direct quotes{s['quote_available']}, affordable low/center/high{s['quote_affordable_low_center_high']}; whole missing path affordable{s['whole_path_affordable_low_center_high']}; ALL synthetic path{a['whole_path_affordable_low_center_high']}.")
add()
add('VERIFICATION AND REPRODUCTION')
add('PASS headless editor import + nine current-source suites: SideStreet Scope/year, SideStreet lifecycle, run calendar/Studio entry, scripted tutorial, Store cycle purchase, Store, Primitive run initialization, Main Menu/history, and sales earning/settlement. Every recorded command has exit0 and no script/parse/FAIL/assert markers. This is focused verification, not a fresh entire44-suite run.')
add('PASS independent chronology, immutable IDs/Scope count, exact-cent settlement-adjusted production/purchase cash, finite Feature exhaustion, four-of-seven selections, native one-cycle actions, nonnegative cash and monthly fully settled boundaries. Counts: '+str(summary['checks'])+'. Mid-signal old HUD labels are recorded listener-order observations; inherited completed-action HUD checks pass, and they do not alter the calendar. Not a new visible UI bug.')
add('Existing missing-card-artwork warnings remain in native logs. They do not change card effects or calculation checks; this task does not claim artwork/UI completeness. Runtime timeouts remain recorded failures of bounded capture, not successful1104 traces and not affordability failures.')
add('PASS short/long prefix replays and Task21 first88action replay: '+str(summary['replay'])+'. Runtime source manifest unchanged; git diff --check passes. Stress independent audit is stress-summary.json. Catalog graph/AND/discount/tag assertions pass. Remaining limitation: no native graphical input and no actual proposed-era gameplay; those are not claimed verified.')
add('Run from '+str(ROOT)+'. Python: C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -B. Godot: C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe. Each Godot command uses isolated APPDATA/LOCALAPPDATA profiles; exact argv and profile paths are in *.command.json.')
for command in ['python -B analysis/task24_batch_v1.py --snapshot','python -B analysis/task24_batch_v1.py --smoke',
                'python -B analysis/task24_batch_v1.py','python -B analysis/task24_batch_v1.py --long',
                'Godot --headless --path . --script res://analysis/task24_high_v1.gd -- --mode=exact',
                'Godot --headless --path . --script res://analysis/task24_normal_v1.gd -- --policy=synergy --store-gate=0 --cap=1104 --count=1',
                'python -B analysis/task24_stress_batch_v1.py',
                'python -B analysis/task24_catalog_v1.py',
                'python -B analysis/task24_catalog_access_v1.py --schedules design-logs/task24-v1/posthoc-schedule.json',
                'python -B analysis/task24_node_readiness_v1.py',
                'python -B analysis/task24_analyze_v1.py','python -B analysis/task24_stress_analyze_v1.py',
                'python -B analysis/task24_verify_v1.py','python -B analysis/task24_report_v1.py','git diff --check']:
    add('  '+command)
add('Do not rerun --snapshot over the retained before-state when reproducing; use a separate evidence directory. Smoke/import/regression executions are excluded from simulated policy counts. UUID release IDs vary across replays; comparisons normalize UUIDs while preserving order and all action values. Harness versions/dependencies are archived by evidence-manifest.json and harness-provenance; native routes inherit existing Task21/Task17 capture helpers without editing them.')
add()
add('FILES, DATA AND FOLLOW-UP')
for p in sorted((ROOT/'analysis').glob('task24*')):add('  '+str(p.relative_to(ROOT)))
add('  design-logs/task24-v1/: native JSON traces, command/log pairs, source manifests, catalog, route-summary.csv, release-table.csv, calendar-checkpoints.csv, gate-access.csv, first-era-pairs.csv, month-boundaries.csv, summaries and this report. The CSV files are derived tables; raw draws/redraws/actions/cash remain in JSON.')
add('Standalone copy: C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs/Task24_Calendar_Era_Simulation_Findings_v1.txt. Only the findings TXT is published to the requested Drive folder; raw traces remain local. No gameplay implementation blocker prevents this access-only deliverable. Proposed-card schema/platform support is a boundary for future gameplay tests, not permission to fabricate playable nodes.')
add('Ranked findings: (1) zero-hand releases still produce real profitable sales while calendar-only would also grant era access; (2) demanding release counts punish slower high-Review production while efficient full-Scope repetition progresses quickly; (3) platform/AND/schema omissions prevent treating affordable shadow cards as playable. Keep the calendar condition; trial a gentler monotone count alongside human progression traces. Human follow-up: record first full-Scope game, releases/cycles per later game, first Studio date at each era, whether delayed cards still feel useful, and whether the Store communicates missing AND parents/platform needs. No numerical recommendation becomes authority through this report.')
text='\n'.join(lines)+'\n'
name='Task24_Calendar_Era_Simulation_Findings_v1.txt'
(OUT/name).write_text(text,encoding='utf-8')
dest=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')/name
dest.write_text(text,encoding='utf-8')
print(dest)
