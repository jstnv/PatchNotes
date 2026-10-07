"""Generate the bounded findings from audited traces; never edit gameplay."""
import csv, gzip, hashlib, json, statistics, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design-logs/feature-store-rebaseline-v1'
LOGS=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')
DEST=LOGS/'Patch Notes - Retained Pool Feature Store Rebaseline v1.txt'
data=json.loads((OUT/'compact-results.json').read_text())
rows=data['routes']; pairs=data['pairs']; releases=data['releases']
audit=json.loads((OUT/'audit.json').read_text())
gate=json.loads((OUT/'final-gate.json').read_text())
commands=json.loads((OUT/'commands.json').read_text())
purchase=list(csv.DictReader((OUT/'purchases.csv').open()))
money=lambda cents:f'${cents/100:,.2f}'
lines=[]
def add(s=''):lines.append(s)
def load_route(key):return json.loads(gzip.decompress((OUT/(key+'.json.gz')).read_bytes()))
add('PATCH NOTES — RETAINED-POOL FEATURE STORE REBASELINE v1')
add('Read-only findings • 2026-10-06 • automated legal scene/API routes, not human playtests')
add()
add('RECOMMENDATION: RETAIN the current lifespan/rent rules and the candidate printed definitions for further study. REVISE the tested shopping policy: evaluate whole parent-chain cost and a rent buffer before committing, and compare deferring a purchase until after a stronger release. First repair the reproduced zero-cycle Alpha-exit integration defect in a separately authorized implementation task, then rerun affected arms. DEFER candidate rollout, price/play-fee approval and era thresholds. This study does not authorize changing any gameplay value.')
add('The main result is a timing/liquidity risk, not proof that either candidate is intrinsically bad. Background Music and Sub-Areas improved matched Game 2 Review among routes that reached it, but early purchase commitments frequently prevented a later release. A genuine 9.0 Game 2 still stopped with $147.65 unpaid rent before its next sales settlement.')
add()
add('1. SOURCE AND AUTHORITY')
add('Live branch main; HEAD e054791d0348d90faf70e9d827892c351fa018bc (Bank). Task29 finance is in this committed source; the older finance log/queue description of it as local work on 85b6874 is stale. Retained-three/four-replacement changes were pending at entry and remain pending. Cached origin/main matches HEAD; a fresh remote push check was not made. This task made no commit or push.')
add('Initial status/diff and SHA-256 inventory are in initial-status.txt, initial-diff.patch and source-before.json. The final gate found zero changes to all snapshotted scripts/scenes/data. Existing tutorial, animation, Pre-Development, Store, finance and retention work was preserved; .codex-godot-temp was not edited.')
add('Sources read live before work:')
add('To Do List / historical Task2: https://docs.google.com/document/d/1n6o5g8Gj_sDTs5Ku6PLM37OWPPyLpDM_ASfNiD9MRkY/edit')
add('Cumulative Implementation Discoveries and Locked Rules, especially §§64–68: https://drive.google.com/file/d/1kmlzNwRbckS9OxucMd5WPYNOF2Dx6QT1/view')
add('Task29 finance: https://drive.google.com/file/d/1WqaS151Zk1GdTHndB4G3BDQxD8DncN57/view')
add('Retained candidate pools: https://drive.google.com/file/d/1qlQJJ_ERpug2q0x7xo16d4KuQWBIMztH/view')
add('Candidate definitions/prices: local Patch_Notes_Multi_Era_Feature_Store_Design_v1.md, Patch_Notes_Feature_Store_Test_Handoff_v1.md and existing feature_pair_game3_trial_v1.gd. Background Music: authored S3, Scope1, Music parent; center-price trial $950. Sub-Areas: authored G3/D2, Scope2, Levels parent; center-price trial $1,700. Prices and later play fees remain unapproved. Old full-redeal Store/economy traces were not reused as results.')
add('The Docs trusted-read bridge was attempted and rejected the Windows absolute path ("workspaceRoot must be an absolute path"). Queue updating therefore uses a fresh native all-tab/revision read, targeted insertion, requiredRevisionId and readback; no document reconstruction or canonical-authority edit.')
add()
add('2. PREDECLARED EXPERIMENT')
add(f"304 routes: 192 primary (8 specialties × seeds1104/4417 × 2 policies × 6 arms); 96 longer-first-game sensitivity (all8 × seed1104 × 2 policies × 6 arms); 16 separate campaign routes. {sum(r['release_count'] for r in rows)} committed releases. Main cohort elapsed {commands['seconds']:.1f}s; three isolated-profile workers, 180s per-route timeout and 2400s cohort limit. No timeout or skipped job. These are 48 distinct no-campaign first-game policy/start configurations replicated across six Store arms, not 288 independent seeds.")
add('Primary first-game budget: one departure +3 Design +4 Alpha +4 Beta =12 productive actions (a declared representative of the requested10–14 range). Long sensitivity:1+5+6+6=18 (representative of16–20). Exact10/14/16/20 budgets were not sampled. Games2–4 use1+5+6+6=18 in all arms; a rejected hand permits remaining free phase transitions and a legal launch if possible. Stop after release4 or an unrecoverable action block. Newly released Game4 has no manufactured follow-up earnings.')
add('Ordinary: equal Core priorities; visible printed Core plus unmet Scope ranking; one redraw attempt per hand while available. Synergy-aware: initial Design50/30/15/5 ranked by the chosen Genre; Alpha priorities ranked by visible Core deficit; enumerate the35 visible four-card combinations, value specialization/Core deficits/Scope, up to two redraws. Both follow the two tutorial suggestions, use QA-heavy Beta and only known Bugs for decisions. No hidden Bug/Review search, free Wait, injected cash or selected favorable Review rolls. Genre remains the chosen studio specialty for all four games. Priorities change at free initial planning only, not by free mid-phase commits.')
add('Same real RNG seeds across arms and policies: project offset500000, phase offsets1–7, Ironclad+30000, SideStreet+40000+100*release number. Both policies choose actual displayed cards and use native transaction/draw/exhaustion/scoring/Review/calendar/sales functions. Headless native scenes and button signals/APIs were exercised; the visible mouse-driven UI was not tested.')
add('All arms use automatic Genre rosters without extra first-game purchases. First-game draws/actions match exactly across shopping arms for every start/policy. Native Ironclad is taken after Game1; SideStreet only when actually available after Games1–3. Each missing Primitive parent is purchased legally before its child, with its own price/cycle/rent. A failed child purchase does not refund an already bought parent. No compensating action or purchase retry is invented.')
add('Arms: none; Colored Text after Game1 (existing_value); Recorded Sounds after Game1 (existing_sound); Background Music after Game1; Sub-Areas after Game1; staged Background Music after Game1 then Sub-Areas after Game2. These are fixed purchase interventions, not an optimal adaptive shopping strategy or a screen of every existing upgrade.')
add('Proposed cards are registered only in each analysis process, after studio creation, with native ownership/quote/discount/next-project supply APIs. No runtime card/ledger file was edited. They are absent from the live game and are never added to the Primitive Contract pool. Their zero later-Feature play fee inherits the current implementation boundary; it is not an approved fee. No alternative play-fee, platform-compatibility or era-gate trial is included in this bounded run.')
add('Automatic starter printed Scope: '+', '.join(f"{s} {load_route('route_early_'+s+'_ordinary_none_1104_0')['starter_summary']['scope']}" for s in ['action','adventure','role_playing','strategy','simulation','puzzle','sports','racing'])+'. All are below the30 required Scope; no first-game SideStreet entitlement was invented.')
add()
add('3. MATCHED RESULTS')
add('Columns: arm | routes | reached G2/G3/G4 | mean matched G2 Review delta (paired surviving denominator) | median cash difference at common observed cycle. The common cycle is the smaller route-end cycle for each pair, not one fixed horizon for the entire cohort. Endpoint cash differences are not purchase ROI.')
for band,label in [('early','PRIMARY —12-cycle first game'),('slow','SENSITIVITY —18-cycle first game')]:
    add(label)
    for arm in ['none','existing_value','existing_sound','background','sub_areas','staged']:
        rr=[r for r in rows if r['band']==band and r['arm']==arm and not r['campaign']]
        pp=[p for p in pairs if p['band']==band and p['arm']==arm and not p['campaign']]
        delta=[p['g2_review_delta'] for p in pp if 'g2_review_delta' in p]
        common=[p['common_cycle_cash_delta_cents'] for p in pp if p['common_cycle_cash_delta_cents'] is not None]
        add(f"{arm:16} | {len(rr):2} | {'/'.join(str(sum(r['release_count']>=i for r in rr)) for i in [2,3,4]):9} | {statistics.mean(delta):+.3f} (n={len(delta)}) | {money(statistics.median(common))}")
    for policy in ['ordinary','synergy']:
        rr=[r for r in rows if r['band']==band and r['arm']=='none' and r['policy']==policy and not r['campaign']]
        scores=[r['g1_review'] for r in rr]
        add(f"Unique {policy} first games n={len(rr)}: mean Review {statistics.mean(scores):.3f}, range {min(scores):.1f}–{max(scores):.1f}; all first releases occurred at cycle{12 if band=='early' else 18}.")
add('First-game Review remains identical across arms because shopping begins after Game1. The twelve-action policies here scored below5 in every unique first game; the eighteen-action policies scored5.0–6.8. This does not establish a human ceiling or justify retuning Review: the fixed phase budgets, equal-vs-Genre priorities, QA policy, no initial reserve buying and only two seeds are material coverage limits. Human observations of about4.6 Game1, about8.9 later, and all current Features affordable by Game4 are observations, not captured traces or exact targets. This experiment did capture one legal9.0 later Review.')
add('All16 long-first-game controls hit $0 at launch with $20–$360 unpaid rent. The actual $400 Ironclad guarantee then allowed recovery; all16 reached Game4. Thus a higher first Review helped this tested continuation, but its reliance on the one-shot guarantee and interim arrears is not a safe general recommendation to develop longer.')
add('In the primary controls the ordinary policy triggered331 synergies in924 production/Beta hands; synergy-aware triggered494 in939. Both reached Game4 in14/16 controls. More synergies did not uniformly solve Scope or liquidity. These counts include Balanced Production/Operations and QA/Marketing specializations, not just Core specialization.')
add()
add('4. ELIGIBILITY, PURCHASE, DRAW AND PLAY ARE DIFFERENT')
action_csv=list(csv.DictReader((OUT/'actions.csv').open()))
for arm,card in [('existing_value','colored_text'),('existing_sound','recorded_sounds'),('background','background_music'),('sub_areas','sub_areas'),('staged','background_music')]:
    bought={p['route'] for p in purchase if p['route'].startswith('route_early_') and '_'+arm+'_' in p['route'] and p['route'].endswith('_0') and p['id']==card and p['success']=='True'}
    g2=[r for r in releases if r['route'] in bought and r['game']==2]
    played=sum(r[card+'_plays']>0 for r in g2)
    all_played={a['route'] for a in action_csv if a['route'] in bought and a['game']=='2' and a['phase'] in ('design','alpha') and a['success']=='True' and card in json.loads(a['selected'])}
    add(f"{arm}: purchased {len(bought)}/32; actually committed the target in Game2 on {len(all_played)}/32 routes (including unfinished games); reached Game2 release {len(g2)}/32; played target in {played}/{len(g2)} completed Game2s. Failed-horizon draws/commits remain in actions.csv and raw traces.")
stage=[p for p in purchase if p['route'].startswith('route_early_') and '_staged_' in p['route'] and p['route'].endswith('_0') and p['id']=='sub_areas' and p['success']=='True']
add(f"Only {len(stage)}/32 primary staged routes completed the second purchase. Missing-parent purchases, unlocked-vs-affordable flags, exact familiarity quotes and cash/settlement/rent deltas are in purchase-eligibility.csv and purchases.csv. Child eligibility alone is not a playable card, and owning a card is not proof it was drawn or committed.")
add('Negative next-release delays in matched-comparisons.csv mean a financial rejection shortened development before a free launch; they must not be called faster productive efficiency. Positive delays include real Store/campaign/Contract actions and their settlements/rent. No waiting was inserted to equalize dates.')
add()
add('5. THREE REPLAYABLE CASES AND MONTHLY MONEY')
case_keys=['route_early_action_ordinary_none_1104_0','route_early_sports_synergy_staged_1104_0','route_early_action_synergy_existing_sound_4417_0']
for key in case_keys:
    r=load_route(key);final=r['final'];rep=r['final_finance_report']
    add(key)
    add('Releases (cycle / committed Scope / Review / cash): '+ '; '.join(f"{x['cycle']} / {x['scope']} / {x['final_review']:.1f} / {money(x['cash_cents'])}" for x in r['releases']))
    add(f"Stop={r['stop']}; final cash {money(final['cash_cents'])}; rent arrears {money(rep['unpaid_rent_cents'])}; earned net {money(sum(s['entitlement_cents'] for s in final['sales']))}; settled {money(sum(s['settled_cents'] for s in final['sales']))}.")
    for b in r['blockers']:
        add(f"  Block: {b['phase']} at cycle{b['state']['cycle']}: {b['reason']}; cash {money(b['state']['cash_cents'])}.")
add('The9.0 Action Game2 had Scope31 at cycle32, $0 cash and $147.65 arrears. Its SideStreet acceptance was legal, but the first productive hand was rejected; upcoming unearned/unchecked sales could not be spent to clear current rent. This is a reproduced liquidity trap under the approved transaction rules, not an accounting discrepancy. No financing or free cycle was invented to escape it.')
add('SEPARATE REPRODUCED INTEGRATION DEFECT — Alpha exit: scripts/phases/alpha_phase.gd:235 checks run.can_advance_calendar_cycle() inside _can_proceed_to_beta(), although _finalize_alpha is zero-cycle. run_state.gd:473 now delegates that check to the finance-aware productive-cycle preflight. Adventure/ordinary/1104/Background Music stops at cycle28, cash$0, arrears$141.61: active Alpha, valid pool/history, positive finite Feature work, project capacity and no input block; only the run productive-cycle check is false. The dedicated alpha-exit-probe.json reproduces every guard with no bypass or gameplay edit. This blocks the otherwise free route to Beta/launch. Existing58-suite regressions pass but do not cover this interaction. It must be reviewed/repaired before these stalled-Alpha outcomes are used as pure price or balance evidence. The study leaves it unchanged, as requested.')
add('monthly-portfolio.csv contains every actual calendar month (including partial final months): units, gross/net earned, settled receipts, expenses, rent due/paid/unpaid and closing cash. title-months.csv preserves each release-ID/age-month row, both earning halves and payment cycles. Forecasts remain in raw capture.forecast and are excluded from earned/settled totals. Older-title earnings and purchase-cycle settlements are attributed to their own ledger, never credited as new-card ROI. routes.csv includes each cash low point/cycle; releases.csv records next-release timing, Scope/Core/Bugs/Genre Fit/Review and card play counts. actions.csv carries purchases, draws, redraws, selected cards, printed/resolved Core/Scope, cycles and cash.')
add()
add('6. SEPARATE SENSITIVITIES')
cp=data['campaign_pairs'];used=[p for p in cp if p['campaigns']]
add(f"Campaigns: {len(cp)} matched routes (Action/Sports, both seeds/policies, none/staged arms), {sum(p['campaigns'] for p in cp)} successful campaigns. Native fee$100/one productive cycle; other attempts rejected unchanged. No alignment purchase/Wait. At common observed cycles the successful arms' incremental earned net ranged {money(min(p['common_cycle_earned_delta_cents'] for p in used))}–{money(max(p['common_cycle_earned_delta_cents'] for p in used))}, below the fee in this sample. No campaign improved releases reached. Some different-endpoint comparisons include additional ordinary earning because the campaign spent a cycle; those are not pure campaign benefit. No repeat-profit loop is established by these first/attempted repeat decisions.")
add('Loans: loan-overlay.csv is a separate96-path accounting overlay for none/staged arms, not96 played loan routes. Candidate-only $500 startup,10% total interest,12 monthly installments; native observed rent takes priority, principal is financing, interest expense. Exact cents: first11 installments $41.66 principal+$4.16 interest, final $41.74+$4.24. Keep the existing native actions/cash receipts; mark negative hypothetical cash as an infeasible fixed path. One path becomes infeasible. A completed loan costs $50 interest; principal never counts as operating revenue. This overlay does not test changed choices, underwriting, post-settlement loan eligibility or debt-enabled recovery. There is no playable loan or approved rate, and the earlier Task30 startup-caution is not overturned.')
add()
add('7. VERIFICATION AND REPRODUCTION')
add(f"All304 native jobs exited0 without unexpected error markers. Native per-title cycle/monthly checks and independent finance audit passed: {audit['counts']}; discrepancies={len(audit['errors'])}. All first-game arm fingerprints match; purchase/campaign cents and rejection rollback checked. Retained-three pool prefixes and finite Features checked across actual routes. Core/Review randomness was never substituted with a fabricated profile.")
add(f"Godot4.7.1.stable.official.a13da4feb editor import plus58/58 available verify_*.gd suites passed ({sum(r['assertion_passes'] for r in gate['results'])} PASS markers). Includes retention, tutorial, Design/Alpha/Beta, Contracts, Store, calendar, settlement, monthly reporting, lifespan, finance, Pre-Development priorities and card motion. Known intentional negative-fixture errors were classified explicitly; existing missing-art/root-certificate warnings are not counted as new gameplay failures. git diff --check exited0. scripts/scenes/data hashes unchanged.")
add('Two full-seed replays reproduced all gameplay/finance fields after mapping chronological random release IDs and ignoring only capture.utc. Initial raw byte equality failed for those volatile metadata fields; replay-comparison-v2.json records the exact normalization, raw before/after captures and commands. The two trace copies in the final bundle are faithful replay instances; commands.json retains original cohort hashes and replacement provenance.')
add('Exact top-level commands (PowerShell from repository root; runner logs every native Godot command and isolated profile):')
py="& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B "
for script,arg in [('feature_store_rebaseline_v1.py','--pilot'),('feature_store_rebaseline_v1.py',''),('feature_store_rebaseline_v1.py','--gate'),('feature_store_rebaseline_audit_v1.py',''),('feature_store_rebaseline_report_v1.py','')]:add(py+'patch-notes/analysis/'+script+' '+arg)
add("& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --headless --path patch-notes --script res://analysis/feature_store_rebaseline_v1.gd -- --band=early --specialty=action --policy=ordinary --store=none --seed=1104 --campaign=0")
add('git diff --check')
add('Additional diagnostic command: the same Godot --headless --path patch-notes invocation with --script res://analysis/feature_store_alpha_exit_probe_v1.gd (exit0, reproduced the guard conflict).')
add('New source files only: analysis/feature_store_rebaseline_v1.gd (plus generated .uid), feature_store_rebaseline_v1.py, feature_store_rebaseline_audit_v1.py, feature_store_rebaseline_report_v1.py, feature_store_alpha_exit_probe_v1.gd. All are analysis/reproduction tools; no gameplay script, scene, card ledger or price was edited in this task.')
add('Working evidence: '+str(OUT))
add('Portable local evidence: '+str(LOGS/'Feature Store Rebaseline v1'))
add('This TXT: '+str(DEST))
add('Remaining limits: only two main seeds, representative12/18 rather than each endpoint, fixed later hand budgets and shopping decisions, no full adaptive affordability search, only two existing-upgrade anchors, zero trial play fees only, no alternate Genre switching, no mouse-driven UI, no exported executable test, no loan gameplay, and no human acceptance clearance. None blocks this bounded read-only deliverable. Do not generalize the survivor-only Review gains to all purchases or call the completed-seed count an independent sample of players.')
add('Next recommendation: separately repair/retest the free Alpha-exit guard first; then compare a defer-until-buffer shopping policy, whole-chain quote/reserve decisions and earlier legal next-game launch. Keep accepted lifespan, $500 rent, printed effects and current prices unchanged. Expanded era implementation and all numerical approval remain deferred. Accounting reconciliation passed; the Alpha-exit defect remains OPEN and limits balance interpretation, rather than blocking completion of this read-only study.')
assert not audit['errors'] and gate['passed']
DEST.write_text('\n'.join(lines)+'\n',encoding='utf-8')
(OUT/'findings.txt').write_bytes(DEST.read_bytes())
print(str(DEST),len(DEST.read_bytes()),hashlib.sha256(DEST.read_bytes()).hexdigest())
