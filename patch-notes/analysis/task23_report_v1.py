"""Verified Task23 report and reproducible local evidence, no runtime changes."""
import json,shutil,subprocess,zipfile,hashlib
from pathlib import Path
from task23_batch_v1 import OUT,manifest,v
ROOT=v.ROOT;LOG=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')
r=json.loads((OUT/'results.json').read_text(encoding='utf-8'));h=json.loads((OUT/'historical-rescore.json').read_text(encoding='utf-8'))
assert manifest()==json.loads((OUT/'source-before.json').read_text())['files']
assert subprocess.run(['git','diff','--check'],cwd=ROOT,capture_output=True).returncode==0
assert all((lambda x:x['exit']==0 and not x['errors'])(json.loads(p.read_text())) for p in OUT.glob('*.command.json'))
lines=[]
for name in ['crown','neon']:
 route=json.loads((OUT/f'route_{name}.json').read_text(encoding='utf-8'))
 lines.append(f"{name}: "+'; '.join(f"G{i+1} Review{x['final_review']}, Awareness{x['awareness']}, printed Scope{x['scope']}/{x['required_scope']}, cycle{x['cycle']}" for i,x in enumerate(route['releases']))+f". Final native cash ${route['final']['cash_cents']/100:.2f} at cycle{route['final']['cycle']}.")
summary=['%s: early-minus-late cash at matched played endpoint median $%.2f [$%.2f..$%.2f]; at projected G5 ageMonth12 median $%.2f [$%.2f..$%.2f].'%(k,g['end']['median']/100,g['end']['min']/100,g['end']['max']/100,g['later']['median']/100,g['later']['min']/100,g['later']['max']/100) for k,g in r['summary'].items()]
completion=['%s: full %d/%d, p10/median cash $%.2f/$%.2f, p10/median whole Promotion %s/%s.'%(k,g['full'],g['count'],g['cash_p10']/100,g['cash_median']/100,g['promo_p10'],g['promo_median']) for k,g in r['completion'].items()]
txt='''PATCH NOTES — TASK23 FIXED-SHARE CONTRACTS AND GAME5 PROMOTION v1
COMPLETE bounded read-only analysis. Offers, targets, caps and Promotion remain UNAPPROVED CANDIDATES; no runtime publisher implementation.

Source and controls
Main68db13527c8b7f6aadb49925a9e9bb36613cc4d6, after Task22 verification on the same unchanged runtime. Refreshed live queue before starting; read Task23, cumulative§59/61/63/66, Task20 findings/raw hands/policies, Task17 strong-route policy and current native Contract/draw/sales/launch code. Preserved Task22 additions and every gameplay/UI change and .codex-godot-temp. Runtime hash manifest remains unchanged. Lifespan/report/menu work is committed in68db135; this analysis is local/uncommitted. Local origin/main matches, but independent remote verification is unavailable (git remote-https missing); no push is asserted. No commit/push by this task.

Exact formula rescore
H_i=2*resolved Core. Crown(S9/10): [18*min(Scope/S,1)+sum min(H_i,8)+2*min_i(min(H_i,8))]/66. Neon(S10/11): [20*min(Scope/S,1)+3*min(H_focus,18)+sum_other min(H_i,4)]/86. Fractions remain exact rational values, clamped0..1; only final cash_cents and whole Promotion are floored separately. Caps192000c/12 and156000c/20 are trial values. Increasing a Core requirement is checked with that Core share fixed and its attainment normalized, not by growing the denominator. Zero payszero and fully met targets reach exact caps.
Rescored all960 immutable Task20 hands into1920 target results without changing draws, choices, ownership or random seeds. Every stricter-Scope pair is nonincreasing under fixed shares;879 ties are expected because both Scope targets are already met or rounding ties. Old target-dependent weighting increased completion in460 pairs. Example: CrownScope13, H=(6,4,40,18). OldS9 pays151272c/9Promotion; S10 perversely pays152470c/9. Fixed shares pay151272c/9 forboth. Current native replay confirms all historical15360draws/1920hands still agree with native Contract rules. Raw table and p10/median/full results are stratified by publisher, policy, acceptance timing, Scope target and historical first-eligible Game1/Game2 cohort in historical-rescore.json. Historical source SHA256 is recorded; those old routes are NOT current cash baselines.

Current legal five-game capture
Two accepted native five-release routes, Action specialty case0: production seed240930100 (+500000 per subsequent game), environment240930000. Shared visible-choice synergy policy with actual purchases/draws/finite cards/redraws/priorities/costs/QA/Review. Crown first qualifies on actualG1 Review9.7. Neon arm uses six QA hands then a legal changed QA25/Marketing50/Insider25 priority and visible Marketing choices inG2, including implemented four-Marketing specialization, to actualAwareness142. It needs no fabricated launch inputs. Bounded300actions/180seconds per route; both finish without blocker or injected cash/time/cards.
'''+ '\n'.join(lines)+'''
Game1Scope29 correctly earns no SideStreet entitlement despite its high Review; subsequent qualifying releases retain live SideStreet cash. Existing Ironclad and SideStreet complete normally. These two routes share the same underlying production seed and are targeted reachability evidence, not player frequencies. Automated strong outcomes neither replace nor bound the user's uncaptured human playtests.
Initial captures with a native campaign were excluded from paired timing: inserting three hypothetical Contract cycles could put the campaign outside its legal half-month window. Repeated both captures with the predeclared same seeds and a no-campaign arm; the original valid native traces remain in excluded-campaign-prefix with a method-amendment note. Only the two accepted no-campaign paths enter results. No campaign rule was changed.

Owned pool and modeled offers
Crown acceptance freezes18 actual owned Primitive Features early,22 afterG4; Neon22 at either acceptance. Later-era Store cards remain excluded even when owned. Affordable/unpurchased nodes do not enter these pools. Four renewable Core Passes remain separate; no automatic grant. Neon focus freezes Graphics at acceptance using greatest owned printed-primary total with stable tie order; identical focus in both arms. One persistent nonexpiring offer, no repeat/failure/abandonment, no simultaneous offered Contract play. Offer is modeled separately from RunState; no native Crown/Neon offer is claimed.
160 current modeled Contracts=2publishers x2timings x2visible Contract policies x20paired seeds200929000..200929019. Same historical ordinary/synergy selection algorithms; seven candidates, four commits, one same-type redraw per hand, finite Feature exhaustion, renewable Passes. Two hands plus one valid changed priority=three productive-cycle opportunities. Native replay passes2560draws/320hands; actual ContractState scoring/exhaustion completes twice, while its Ironclad cash result is discarded. A synthetic publisher result is calculated only from the fixed-share trial formula. This is not a gameplay integration test for nonexistent offers.
'''+ '\n'.join(completion)+'''

Timing and exact cash
727 native per-title earned/settled observations and403 cash transactions reconcile before overlays. Pair each current Contract seed/policy at first eligible Studio and afterG4. Insert hand1/priority/hand2 immediately after that exact successful launch callback; pay trial cash once on finalhand, before calendar settlement. Shift later recorded actions/releases bythree cycles, preserve frozen Review/market, then call native ReleasedGameSales for each title and calendar boundary. Promotion changes only first subsequent successful launch: CrownearlyG2, NeonearlyG3, latebothG5. Exact once-only consumption and repeat-receipt payout guards pass in the analysis model. No repeated callback creates a second receipt payment. Frozen older releases remain unchanged.
All160 timelines can fund each recorded purchase/production cost; first_unaffordable=null. Checkpoints compare each of five release milestones. monthly.csv compares common even calendar cycles; contract-receipts.csv separates direct publishercash from coincident older-title settlements at each inserted action. Every native baseline earning/settlement is reproduced. Earned/unpaid never funds the next action. Observed-action overlay endpoints are native184+3=187 forCrown and185+3=188 forNeon; Game5Month1 is fully earned and settled in both. Exact action-by-action native traces and separate overlay schedules make the distinction replayable.
Longer comparison through Game5release-ageMonth12 is explicitly a conditional ledger projection with no subsequent releases/costs/campaigns assumed; it is not24cycles of legal free Wait. Actual current fifth launches now exist, unlike Task20's old four-game cutoff. Proposed-offer calendars remain fixed-action finance overlays, not full interactive native offers; changed markets/project choices or adaptation to extra cash are deliberately not resampled. A graphical human route and integrated Promotion UI remain unverified.
'''+ '\n'.join(summary)+'''
Neon's early/late owned pools and payouts match seed-for-seed, so its remaining advantage comes from where the single Promotion is used and earning timing. Crown's differing pools make payout differences important: early-minus-late direct cash spans-$523.64..+$698.19 under ordinary selection and-$349.09..+$174.55 under synergy selection. Its lateG5 Promotion catches up enough to leave the synergy median about-$7 by G5Month12, versus an early+$384.61 at the played endpoint. Thus the older Task20 positive early-value projection cannot justify universally accepting early. No optimal timing or numerical cap is approved by these two correlated routes. Full per-title native ledgers, incremental Promotion settled-cash, direct payout, delay-only settlement and portfolio cash remain distinct in raw data.

Recommendation / decisions
Prefer fixed-share proportional requirements over target-dependent weighting: harder targets should not accidentally improve payout. Retain persistent one-shot offers, frozen owned-Primitive pools and next-successful-launch Promotion as structural trial direction. Crown9Scope/4eachCore and Neon10Scope/9focus are shortlists only. Need explicit approval of requirement targets, cash/Promotion caps, focus UI/timing, payout/promotion atomic persistence and offer ordering before implementation. Crown timing merits transparent choice rather than an assumed early optimum; no broader target grid, Starwave/reputation/revenue-share, staff/traits/fans, era cards or balance edits were added.

Verification / files / reproduce
Godot4.7.1 final editor import, balanced Primitive Contract, SideStreet Contract, Scope/year, lifespan sales, monthly report and Pre-Development suites all pass with exit0 and no script/parse/assert/FAIL markers. Both native routes, historical/current Contract replays and94 native sales ledgers pass. Runtime SHA256 guard and git diff --check pass. Known Windows root-certificate warning and missing-artwork fallback warnings are retained in logs; neither is hidden as an all-clean console claim. No exported build or human UI smoke result is claimed.
From repository root use bundled Python -B:
 patch-notes/analysis/task23_batch_v1.py
 patch-notes/analysis/task23_prepare_v1.py
 Godot --headless --path <patch-notes> --script res://analysis/task23_native_rules_v1.gd
 Godot --headless --path <patch-notes> --script res://analysis/task23_ledgers_v1.gd
 patch-notes/analysis/task23_analyze_v1.py
 patch-notes/analysis/task23_report_v1.py
Exact absolute commands/profiles/exits are archived in design-logs/task23-v1/*.command.json; final-gate.json and source-before.json record verification and revision. Added analysis/task23_routes_v1.gd,task23_batch_v1.py,task23_prepare_v1.py,task23_native_rules_v1.gd,task23_ledgers_v1.gd,task23_analyze_v1.py,task23_report_v1.py andGDScriptUIDs. Reusable task22_prepare_v1 event accounting accepts the additional Beta-priority label; Task22 behavior is unchanged. Local New Data Logs/Task23_Fixed_Share_and_Game5_v1 contains raw/reproducible evidence and a runtime-code source snapshot (scripts/scenes/data/project.godot; not a shipping package). All source-only evidence stays local; standalone TXT is uploaded to Drive.
No blocker to this bounded analysis. Remaining gameplay value decisions belong to the design/user ruling. Separate release gaps persist: durable Studio checkpoints, settings/audio and exported interactive two-game smoke. Next independently READY implementation in the current queue is Task12, minimum Windows settings/input/audio; approved media availability must be checked before claiming its audio gate complete.
'''
path=LOG/'Task23_Fixed_Share_Contracts_and_Game5_Promotion_v1.txt';path.write_text(txt,encoding='utf-8')
evidence=LOG/'Task23_Fixed_Share_and_Game5_v1';evidence.mkdir(exist_ok=True)
shutil.copytree(OUT,evidence,dirs_exist_ok=True)
for f in (ROOT/'analysis').glob('task23_*'):
 if f.is_file():shutil.copy2(f,evidence/f.name)
for name in ['task22_prepare_v1.py','task20_compare_v1.py','remaining_publisher_contracts_rebaseline_v1.py']:
 shutil.copy2(ROOT/'analysis'/name,evidence/name)
with zipfile.ZipFile(evidence/'runtime-code-source.zip','w',zipfile.ZIP_DEFLATED) as z:
 for folder in ['scripts','scenes','data']:
  for f in (ROOT/folder).rglob('*'):
   if f.is_file():z.write(f,str(f.relative_to(ROOT)))
 z.write(ROOT/'project.godot','project.godot')
(evidence/'evidence-sha256.json').write_text(json.dumps({str(f.relative_to(evidence)):hashlib.sha256(f.read_bytes()).hexdigest() for f in evidence.rglob('*') if f.is_file() and f.name!='evidence-sha256.json'},indent=2),encoding='utf-8')
print(path)
