"""Save verified Task22 findings and local reproducible evidence."""
import json,csv,shutil,hashlib,subprocess
from task22_prepare_v1 import OUT,ROOT
from task22_batch_v1 import manifest
LOG=__import__('pathlib').Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')
d=json.loads((OUT/'results.json').read_text(encoding='utf-8'));p=json.loads((OUT/'prepared.json').read_text(encoding='utf-8'))
assert manifest()==json.loads((OUT/'source-before.json').read_text())['files']
assert subprocess.run(['git','diff','--check'],cwd=ROOT,capture_output=True).returncode==0
commands=[json.loads(x.read_text()) for x in OUT.glob('*.command.json')]
assert all(x['exit']==0 and not x['errors'] for x in commands)
route_lines=['%s: Reviews %s; launch cycles %s; endpoint cycle %d, cash $%.2f; seed %d; optional purchases %d.'%(x['id'],[r['final_review'] for r in x['route']['releases']],[r['cycle'] for r in x['route']['releases']],x['route']['final']['cycle'],x['route']['final']['cash_cents']/100,x['route']['seed'],len(x['route']['purchases'])) for x in p['routes']]
table=['%s: post-G2 median $%.2f [%+.2f,%+.2f]; 24-month median $%.2f [%+.2f,%+.2f].'%(s['scenario'],s['post_game2_delta_median']/100,s['post_game2_delta_min']/100,s['post_game2_delta_max']/100,s['month24_delta_median']/100,s['month24_delta_min']/100,s['month24_delta_max']/100) for s in d['summaries'] if s['scenario'] in ['buzz3_p1','buzz5_p2','buzz7_p3','buzz10_p1','matching3_p1','matching3_free_effect','buzz3_match3_p2','loan_buzz3_p1','loan_cash_only','cult25_retain100','cult25_retain95','cult200_retain100','cult200_retain95']]
text='''PATCH NOTES — TASK22 NARROW TRAIT COMPARISON v1
COMPLETE bounded read-only analysis. Numerical trait effects below are UNAPPROVED CANDIDATES.

Source and scope
Main 68db13527c8b7f6aadb49925a9e9bb36613cc4d6 (Lifespan!), clean at inspection before these analysis additions. The previously local lifespan/report/menu changes are now committed in this source. Local origin/main also points here; independent remote verification failed because this environment's git lacks remote-https. No commit/push by this task, and no assertion of a freshly verified GitHub push. Runtime scripts/scenes/data SHA256 manifest is unchanged throughout this analysis; .codex-godot-temp preserved.
Read live queue Task22 and cumulative authority including accepted lifespan §66; historical Task19 strong-route/96-dues findings; Studio Trait/Post-Integration/point-budget logs and original fan-awareness proposal; inspected current native launch guard, specialty/predevelopment and sales paths. The working creation rules are specified directly by Task22; a separately named working-V1 file was not returned by the Drive title search. The old archive's optional specialty is superseded by required free §63 rosters. Exactly-one manually chosen background stays separate from the required specialty. No creation UI, trait, fan, loan, bill, payroll or gameplay effect was implemented. No lifespan, campaign, price, supply, Review or payout changed.

Native recapture
Eight fresh two-release routes: six synergy-focused cases 0,1,3,5,8,15 and ordinary low controls 5,6. These are deliberately selected policy cases, not population frequencies or human evidence. Two specialties repeat with a different optional-purchase start. Production RNG =240930100+97*case, +500000 for second game, phase offsets inherited; environment RNG=240930000+case. Uses actual initial specialty ownership, purchases, Design/Alpha/Beta/Review, finite Features, costs, redraws, priorities, SideStreet Scope gate, Contracts and campaign. No injected cash/cards/Review or free Wait. Historical Task19 policy targets are replaced by current visible-choice native route policies because old ownership/caps differ.
'''+ '\n'.join(route_lines)+'''
Four of six synergy cases have Game2 Review >=9; the other two reach 8.9/8.1. No synthetic high Review needed. All eight finish; no native unaffordable-action stall. Full action/draw/cash/campaign traces are retained. 649 transactions reconcile starting $5500 + actual direct cash sources - costs + settled portfolio sales; 364 native per-title earned/settled ledger observations match recomputed Godot ledgers exactly. 281 deduplicated native trait ledgers feed 34 scenarios x8 routes=272 fixed-action shadows and 15,810 monthly rows. Neutral shadows reproduce every action's native cash.

Model boundaries
Preserve each route's committed actions, frozen Reviews/markets, release IDs/cycles and campaign schedule. Only hypothetical launch Awareness and initial trait cash change. Month1 formula is the current exact integer formula; all later earning/settlement calls use actual ReleasedGameSales.next_cycle. Both older/newer titles contribute. Earned/unpaid is never spent. Results identify native endpoints versus conditional fixed-two-title projections through 24 calendar months AFTER Game2 launch (48 additional productive-cycle opportunities assumed, not legally played waiting). No additional releases, purchases, bills, staff or campaigns are invented after capture. Ordinary and synergy horizons differ; comparisons are paired within each route at common calendar boundaries and same release milestone, not cross-policy estimates of skill.
Current 4-point/$50 conversion/$300 cap is held fixed. Cash-only adds $200; Buzz +3/+5/+7 costs1/2/3 points; old+10 at1 point is a benchmark. Matching +3/+5/+7/+10 is evaluated free as a hypothetical specialty effect and separately with a1-point price for ONLY that extra effect, never the required specialty or starting roster. Combined +3/+3 at2 points and +5/+3 at3 points are labeled hypothetical packages. These traces match their permanent specialty only on Game1; Game2 deliberately uses another Genre, so no matching bonus is applied there. No Review modifier or fan increase is inferred.
Launch Awareness adds bonuses once and floors at zero. No new global Awareness ceiling is invented; the proposed fan curve saturates below150. All realized inputs are nonnegative exact integers, with floors at units/net. Family+$300 is a separate background reference, never stacked with Cult/Publisher. Two-approval package pricing remains a design decision. Old +10 Buzz gives both more cash and greater income than +3/+5/+7 in this cohort; prune it from the shortlist, not expand a Cartesian grid. Higher same-price matching values similarly have no modeled downside, so ranking alone cannot approve them.

Results versus $200 cash-only conversion (currency dollars)
'''+ '\n'.join(table)+'''
All 272 fixed-action shadows remain affordable on these no-staff routes. Scope and Reviews are unchanged. Results.json includes both launches' Awareness/units/cash/earned/settled, first shortfall (none), endpoint cash, paid loan/arrears; monthly.csv and attribution.csv expose each boundary and title's incremental contribution. Larger/stronger titles amplify Buzz; first-game matching income cannot be mistaken for a later matching benefit. A one-point +3 matching effect loses $8.04 versus cash in the lowest first-game case but gains up to $250.70 in the strongest; free+3 ranges+$41.96..$300.70. Buzz works on BOTH launches and continues to benefit strong later releases; recurring effect and liquidity timing both matter. These automated Reviews do not contradict or bound the user's human later-game >9 observations.

Cult uncertainty
Proposed fan Awareness=floor(150*F/(F+300)), from the earlier fan proposal. Endowments25/50/75/100/200 initially imply11/21/30/37/60 Awareness. Separate illustrative neutral/weak/strong attrition retains100%/99%/95% of those endowment fans per calendar month, flooring fans each boundary, beginning before launch. No new fan gains, returning-buyer identities, review-dependent fan changes or runtime fanbase is asserted. This isolates attrition uncertainty rather than approving a fan model; even 1% flooring can remove at least one fan per month from small endowments. At25 neutral fans the median long-run benefit is$1356.64 versus only$45.46 under strong attrition; +200 fans remain very large. Family's bounded+$300 reference changes neither Review nor sales. DEFER Cult values until gain/loss/rounding and pre-first-launch attrition are ruled; do not infer fans from units.

Loan and Publisher guards
Student Loan refunds2 points, costs$10 at exactly96 monthly boundaries; no interest. Loan+Buzz3 starts with5 unspent points=$250, compared with$150 without loan; loan cash-only=$300 cap. Extra initial liquidity is a liability, not a recommended instant-cash reward. By this horizon loan-only trails cash-only on every route. Full96 dues cost$960; +$100 conversion offsets only part. Current captures do not span96 dues: the earlier Task19 native96-boundary continuation is historical, not relabeled current. A separate exact isolated boundary test pays300c against1000c due, carries700c arrears, collects it from later1200c inflow without negative cash, rejects failed-action charge, ignores duplicate boundary dues, totals96000c across96 unique boundaries and charges no97th due. Repayment uses available cash after same-boundary sales; no live debt or penalty was added.
Publisher+15% remains unresolved funding: at240000c base the external bonus would36000c but within-budget allowance is0; at200000c base both can allow30000c. No Publisher sweep or extra runtime payout.

Recommendation and required rulings
For the next design discussion shortlist Buzz +3 at1 point and a matching-project +3 Awareness effect, with the required specialty/roster itself always free. This is a modest candidate, not implementation approval; matching-effect point cost/free treatment and interaction with other secondary perks need explicit approval. Reject the old+10 benchmark as too large relative to the smaller shortlist. Defer Cult amounts and Publisher funding; retain the specified4points/$50/$300 and96-dues loan structure rather than reopening them. Confirm numerical trait bonuses/prices, fan gain/loss/rounding, loan collection event order and persistence before gameplay implementation. No balance value is locked by this report.

Verification and reproduce
Godot4.7.1 import; zero-work release; eight specialty fixtures; Pre-Development; lifespan sales; monthly report; SideStreet Scope/year suites all exit0 without script/parse/assert/FAIL markers. All8 native recaptures and native shadow ledger command pass. Known Windows root-certificate warning is nonfinancial; exact logs retain any fixture/teardown diagnostics. Runtime SHA guard and git diff --check pass. No graphical human route or exported demo test was claimed, and no broad duplicate lifespan cohort was rerun.
Use bundled Python with -B from repository root:
 patch-notes/analysis/task22_batch_v1.py
 patch-notes/analysis/task22_prepare_v1.py
 Godot --headless --path <patch-notes> --script res://analysis/task22_ledgers_v1.gd
 patch-notes/analysis/task22_analyze_v1.py
 patch-notes/analysis/task22_report_v1.py
Exact absolute command vectors, isolated APPDATA/LOCALAPPDATA, exits, source hashes and status/diff: patch-notes/design-logs/task22-v1. Added analysis/task22_routes_v1.gd(+UID),task22_batch_v1.py,task22_prepare_v1.py,task22_ledgers_v1.gd(+UID),task22_analyze_v1.py,task22_report_v1.py. Analysis additions are local/uncommitted; runtime remains68db135. Local New Data Logs contains this TXT, paired table and reproducible evidence/source folder. TXT is the Drive deliverable; raw evidence remains local. No task blocker; next dispatch Task23 requires refreshed queue and its separate bounded Contract analysis.
'''
log=LOG/'Task22_Narrow_Traits_on_Accepted_Lifespan_v1.txt';log.write_text(text,encoding='utf-8')
evidence=LOG/'Task22_Narrow_Traits_v1';evidence.mkdir(exist_ok=True)
for f in OUT.iterdir():
 if f.is_file():shutil.copy2(f,evidence/f.name)
for f in (ROOT/'analysis').glob('task22_*'):
 if f.is_file():shutil.copy2(f,evidence/f.name)
print(log)
