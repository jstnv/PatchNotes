from pathlib import Path
import json, hashlib, zipfile, subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/task27-v1'
DEST = Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')
report = '''PATCH NOTES — TASK 27 LIFESPAN AND CAMPAIGN CALIBRATION v1
2026-10-01 | Read-only findings; no gameplay or numerical authority changes

SOURCE AND SCOPE
main 0c34df5ae3c09e21bc1a3871a2038404883100d3, with f7f3862's tutorial/UI fixes and Task26 guard committed. HEAD matches the cached origin/main reference; this task did not fetch or independently prove the live remote tip. Tracked runtime source was clean before and after; runtime SHA256 comparison passed. This task's eight analysis scripts and generated Godot UIDs are local/uncommitted. No commit or push was performed. Existing work and .codex-godot-temp were preserved.
Authority: live Task27 in queue 1n6o5g8Gj_sDTs5Ku6PLM37OWPPyLpDM_ASfNiD9MRkY; cumulative record 1kmlzNwRbckS9OxucMd5WPYNOF2Dx6QT1; Task24 current findings 1WIhTzZMS8zMjFjo3H6a19WOkEpwmu4K3; Task9 findings 1awRDS6m4bERiTttnAlBqaptEvChvfiou; native lifespan implementation 1ajW5W030_eYtKle-NISiyqbGtjO_-PLV. Copies are in the evidence bundle. No repository AGENTS.md found at inspection.
Native baseline includes separate per-title age/ledgers, concurrent sales, monthly earning/settlement, campaigns, current specialty rosters and positive-Scope finite-Feature launch guard. Fan changes are excluded. All carryover, retention, campaign price/boost/eligibility/limit judgments below remain trials.

METHOD AND REPRODUCTION
32 accepted native headless three-game routes: 24 main (3 policies x 2 starts x 4 Studio arms), 4 repeat-campaign routes, 4 equal-hand-budget sensitivities. These contain 96 release records but share paired prefixes; they are not 96 independent starts. Specialties: Action and Adventure only. Card seed=240930100+97*case+500000*(game-1); environment seed=240930000+case. Policies and scope were predeclared in predeclared-plan.json, with a 35-minute batch bound.
Arms: next project, newer-title first campaign, older-title campaign, one affordable Store purchase. Native production, draws, redraws, priorities, QA, launch, Store and campaign APIs were used. The next arm proceeds through actual Game3; no free wait is represented as gameplay. Campaign eligibility required common legal Store actions before comparison; alignment-addendum.txt and each opportunity's preparation record disclose their costs. The initial unaligned routes are retained under prealignment/ and excluded from accepted comparisons. An initial fixed-budget ordinary control inadvertently retained synergy ranking; it was corrected and both ordinary controls rerun. Final accepted files are authoritative.
12 actual frozen first/two-game profiles cover Reviews 2.3 through 9.7 with original market and Awareness. 256 exact-integer ledger projections cover age Months1–24; four weak/strong none/revival projections extend to Month120. Carryover=0/15/30%; retention sensitivity shifts the native retention intercept by +/-500 basis points, retaining its Review coefficient. Control campaigns compare no campaign, first at age2, first+repeat at ages2/3, every eligible age2–24, and first dormant revival. Fees 5000/7500/10000 cents; boost uses native 10/(1+prior campaigns), including +10/+5. Units are outputs, never decay inputs.
Projected affordability uses the actual release cash plus that title's settled revenue minus fees. It is a single-title sensitivity, not an entire playable future action route. Conditional portfolio projections continue three native ledgers to the same paired calendar endpoint, 48 cycles beyond the latest arm's last release. They isolate sales timing without assuming a legal Wait command; no further production expenses/actions are modeled. monthly.csv, native-calendar-boundaries.csv and portfolio.json distinguish age-month, common calendar and earned/settled cash.
All visible-choice policies are automated; no graphical or human playtest occurred. Human 4.7-to-9.2/strong later-game observations are context, not identical action traces or a frequency/ceiling claim.

NATIVE STUDIO RESULTS
All32 accepted routes reached three legal releases. No accepted route reported a cash blocker, and no projected campaign hit an affordability rejection under the stated single-title budget. Six newer campaigns succeeded; each delayed Game3 by one cycle. Three of six older attempts were legally rejected for their eligibility window, with unchanged state; three succeeded. All six Store arms purchased. Both repeat cohorts accepted a first campaign and then a second on the same older title; the controls retained only the first campaign.
Main no-campaign Reviews (G1/G2/G3): cautious case0 3.3/4.6/3.9; cautious case1 2.3/3.4/4.4; ordinary0 6.5/5.5/6.1; ordinary1 4.0/5.4/5.6; synergy0 9.7/9.2/9.2; synergy1 7.8/8.9/8.2. Full actions, draws, budgets, scores, markets, sales and cash are in route JSONs.
Matched newer campaign results, direct complete-month marginal net after $100:
  cautious0: start cycle33 cash$9638.93; +13 units; -$9.10; G3 cycle45 ->46.
  cautious1: cycle33 cash$8971.15; +15 units; +$4.89; G3 cycle45 ->46.
  ordinary0: cycle44 cash$18181.76; +15 units; +$4.90; G3 cycle60 ->61.
  ordinary1: cycle44 cash$14431.80; +25 units; +$74.82; G3 cycle60 ->61.
  synergy0: cycle82 cash$31930.29; +25 units; +$74.82; G3 cycle111 ->112.
  synergy1: cycle86 cash$25190.86; +41 units; +$186.72; G3 cycle121 ->122.
Common-horizon conditional cash differences are respectively -$9.10,+$4.90,+$4.89,+$74.82,+$74.83,+$186.72; one-cent drift reflects cumulative integer settlement rounding. Cautious0's immediate cash increased $1620.28 despite the campaign's -$9.10 marginal return: already-earned settlements dominate the immediate cash display. Cash at differing release milestones must not be called campaign ROI. Store changes future supply and sometimes production length, so its cash difference is not a pure purchase ROI either.

LIFESPAN, REVIVAL AND REPEAT ECONOMICS
Control first zero-unit age month: Reviews2.3=7,3.3=8,3.4=8,4.0=9,4.6=9,5.4=11,5.5=11,6.5=14,7.8=17,8.9=22,9.2=21,9.7=27. These are individual profiles with distinct markets/Awareness, not a Review-only lookup. Dormant2.3 revived for8units, -$44.06 after$100; dormant9.7 revived for45units, +$214.68. Dormancy does not expire the ledger.
At age2, a3.3 Review in a strong market earned +$4.90 after$100; a5.5 Review in a weaker market lost$2.10. Campaign recommendations must consider market and exact marginal units, not Review alone.
Across12 profiles, profitable first campaigns: $50 12/12 (margin$5.94..264.68); $75 11/12 (-$19.06..239.68); $100 8/12 (-$44.06..214.68). Positive marginal SECOND campaigns: $50 8/12; $75 6/12; $100 3/12. At$100, second margins range -$72.02..53.85.
Campaigns every month through24: cumulative profit $50 1/12 (range -$996.15..10.84); $75 0/12 (-$1571.15..-564.16); $100 0/12 (-$2146.15..-1139.16). The single slightly profitable $50 sequence is not an infinite profitable loop: diminishing boosts eventually yield no material units against a fixed fee. A profitable first/revival campaign does not make unrestricted repetition profitable.
Against15% carryover, 0% changed24-month earned net by -$4349.65..-265.73, 30% by +$272.73..4335.66. Retention -5 percentage points changed it by -$2223.77..-48.95; +5 points by +$62.94..3377.62. Strong9.7 control earned$21384.59 over24months versus$17034.94/$25720.25 at0/30% carryover and$19160.82/$24762.21 for faster/slower retention. Faster decay reaches zero at22 vs control27; slower sensitivity was not extended beyond24, so its first-zero month remains unmeasured.

PRODUCTION-BUDGET CONFOUND
Equal-hand-budget control uses10Design+14Alpha+12Beta hands per game, common adaptive priorities/redraw/QA framework, comparing ordinary versus native synergy hand ranking. It isolates ranking under that framework, not synergies versus no synergies. Across two starts and the first two releases, average Review was9.25 ordinary ranking vs8.975 native synergy ranking. Individual triples: ordinary case0 9.7/9.9/9.8 vs native9.7/9.1/9.5; case1 ordinary8.2/9.2/8.7 vs native7.8/9.3/8.9. All have36hands; extra priority cycles and later supply can differ. Across the first two games, native ranking triggered68 specializations in96 production hands versus57/96 for ordinary ranking, despite its lower average Review. This small ceiling-adjacent test does not show ordinary play generally dominates. It does demonstrate that the large Task24 policy gap cannot be attributed solely to synergy selection; longer production and QA are a major confound.

RECOMMENDATIONS — ALL UNAPPROVED
Carryover: RETAIN15% as comparison control; DEFER approval. Raising30% materially enriches long-lived back catalogs. Obtain an actual strong-run monthly trace before tuning.
Retention coefficients: DEFER retuning. +/-5points creates large strong-tail changes. Validate acceptable lifespan with human monthly observations and multiple markets first.
Campaign price: RETAIN$100 as trial control; do not globally cut to$50 from this evidence. $50 makes all captured first campaigns profitable while repeats still often waste cash. Market-aware decision feedback is preferable to locking a new price now.
Initial boost: RETAIN+10 as trial control; direct returns span losses and meaningful profits, allowing a conditional decision. Broader captured market coverage is needed before approval.
Repeat boost: RETAIN diminishing +10/+5 structure provisionally; REVISE player guidance/forecast proposal so repeated spending is not implied to be always useful. Do not implement here.
Eligibility: RETAIN the current action boundary for this comparison; REVISE its explanation/availability feedback as a separate proposal. Three older attempts were correctly unavailable, and common preparation was necessary; rejected actions are not unaffordability.
Per-title monthly limit: RETAIN as a trial safeguard; DEFER numerical/structural approval until genuine human repeated-campaign choices are recorded. This study did not remove it.
One-cycle cost: RETAIN existing cost for the control. All six newer actions delayed the next release a cycle; evaluate with portfolio timing, not just immediately credited cash.
No approved price/decay/fan/employee/trait/publisher/era change follows from this report.

VERIFICATION AND LIMITATIONS
PASS32/32 accepted native routes. PASS24 normalized matching-state checks. PASS8,448 native/control projection cycles and1,905 native recorded-cycle ledger parity checks, zero mismatches. PASS deterministic synergy-newer case0 replay after normalizing only generated release UUIDs (including IDs embedded in offer strings). PASS runtime SHA256 guard, git diff --check and Godot editor import. PASS five focused suites: verify_game_lifespan_sales, verify_game_lifespan_trial, verify_sales_earning_and_settlement, verify_zero_work_release, verify_studio_specialties. All exit0, no SCRIPT/Parse/FAIL markers. This task did not rerun the full49-suite gate; its earlier result remains historical.
No native future 24-month action route or GUI claim: projections explicitly model sales, not legal time advancement. Exported two-game EXE smoke remains Task11's separate blocker. Two specialties/two starts limit generalization; larger sampling was not needed to find these bounded decision effects. Review/market/Awareness never fabricated. No Contract numerical trial was introduced; the available Store action satisfied the alternative-action arm.
Exact commands, exit codes and isolated profile paths are saved in *.command.json with paired logs. Godot4.7.1 stable a13da4feb executable: C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe.
Reproduce from repository root using Python -B patch-notes/analysis/task27_batch_v1.py, then Godot --headless --path patch-notes --script res://analysis/task27_projection_v1.gd and res://analysis/task27_portfolio_v1.gd, then Python -B patch-notes/analysis/task27_analyze_v1.py. The batch helper uses separate APPDATA/LOCALAPPDATA profiles. Run each listed res://scripts/debug/verify_*.gd via the same headless command (exact actual paths in command JSONs), then Godot --headless --path patch-notes --editor --import and git diff --check. The source-before guard expects repository-root cwd. Final fixed-control/replay commands override the initial batch where noted.
Changed files: analysis/task27_routes_v1.gd, task27_batch_v1.py, task27_trial_calculator.gd, task27_trial_ledger.gd, task27_projection_v1.gd, task27_portfolio_v1.gd, task27_analyze_v1.py, task27_package_v1.py and generated .gd.uid files. Evidence is ignored under design-logs/task27-v1; this standalone TXT and ZIP are in local New Data Logs. All task additions are uncommitted/unpushed. Runtime files unchanged.
Next eligible queue task: Task22, read-only trait/matching-project Awareness/fan trial, after refreshing its full brief and sources. Task23 follows separately. Human follow-up: record a legal9+ route's purchases/actions, release Review/Awareness/market, monthly units/earned/settled cash, campaign target/age/quote, and why a repeat was chosen; record whether the eligibility window and settlement cash confuse the decision.
'''
DEST.mkdir(parents=True, exist_ok=True)
name='Patch Notes - Task27 Lifespan and Campaign Calibration v1'
(OUT/'findings.txt').write_text(report,encoding='utf-8')
(DEST/(name+'.txt')).write_text(report,encoding='utf-8')
summary=json.loads((OUT/'summary.json').read_text())
extra={'native_blockers':{},'projection_unaffordable':[], 'budget_synergies':[]}
for path in sorted(OUT.glob('route_*.json')):
 r=json.loads(path.read_text()); extra['native_blockers'][path.name]=r.get('blockers',[])
 if 'budget_' in path.name:
  for g in range(1,4):
   acts=[a for a in r['actions'] if a.get('game')==g and a.get('phase') in ['design','alpha']]
   extra['budget_synergies'].append(dict(file=path.name,game=g,hands=len(acts),synergies=sum(a.get('synergy','none')!='none' for a in acts),specializations=sum('specialization' in a.get('synergy','') for a in acts)))
extra['projection_unaffordable']=[r for r in summary['projection'] if r['first_unaffordable_month']>0]
(OUT/'additional-checks.json').write_text(json.dumps(extra,indent=2))
paths=[]
for folder in ['scripts','scenes','data','resources','assets','analysis']:
 for p in (ROOT/folder).rglob('*'):
  if p.is_file() and '__pycache__' not in p.parts and p.suffix not in ['.pyc','.import']:
   paths.append((p,'source/patch-notes/'+p.relative_to(ROOT).as_posix()))
paths.append((ROOT/'project.godot','source/patch-notes/project.godot'))
for p in OUT.rglob('*'):
 if p.is_file() and p.suffix not in ['.translation','.import']:
  paths.append((p,'evidence/'+p.relative_to(OUT).as_posix()))
manifest={arc:hashlib.sha256(p.read_bytes()).hexdigest() for p,arc in paths}
zpath=DEST/(name+' Evidence.zip')
with zipfile.ZipFile(zpath,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for p,arc in paths:z.write(p,arc)
 z.writestr('sha256-manifest.json',json.dumps(manifest,indent=2))
with zipfile.ZipFile(zpath) as z:
 assert z.testzip() is None
 for arc,h in manifest.items():assert hashlib.sha256(z.read(arc)).hexdigest()==h
print(json.dumps({'report':str(DEST/(name+'.txt')),'zip':str(zpath),'bytes':zpath.stat().st_size,'sha256':hashlib.sha256(zpath.read_bytes()).hexdigest(),'files':len(paths),'native_blockers':{k:v for k,v in extra['native_blockers'].items() if v},'unaffordable_projection_count':len(extra['projection_unaffordable'])},indent=2))
