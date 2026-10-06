"""Package bounded verification evidence; keep project source snapshot local only."""
from pathlib import Path
import collections,hashlib,json,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design-logs/lifespan-verification-v2'
DEST=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
before=json.loads((OUT/'source-before.json').read_text(encoding='utf-8'))
after={str(p.relative_to(ROOT)):sha(p) for folder in ['scripts','scenes','data','resources'] for p in (ROOT/folder).rglob('*') if p.is_file()}
change={'changed_existing':[k for k in before if k in after and before[k]!=after[k]],'added':[k for k in after if k not in before],'missing':[k for k in before if k not in after]}
(OUT/'source-after.json').write_text(json.dumps(after,indent=2),encoding='utf-8')
(OUT/'source-change-audit.json').write_text(json.dumps(change,indent=2),encoding='utf-8')
for name,args in [('final-status.txt',['status','--short']),('final-diff.txt',['diff']),('final-head.txt',['rev-parse','HEAD']),('final-branch.txt',['branch','--show-current']),('final-diff-check.log',['diff','--check'])]:
    p=subprocess.run(['git',*args],cwd=ROOT,capture_output=True);(OUT/name).write_bytes(p.stdout)
    assert p.returncode==0,(name,p.stderr)
markers=collections.defaultdict(list)
for p in OUT.glob('final-*.log'):
    for line in p.read_text(encoding='utf-8',errors='replace').splitlines():
        if any(s in line for s in ['ERROR:','SCRIPT ERROR','Parse Error','FAIL:','Assertion failed']):markers[line].append(p.name)
(OUT/'final-error-marker-audit.json').write_text(json.dumps(markers,indent=2),encoding='utf-8')
audit=json.loads((OUT/'accounting-audit.json').read_text(encoding='utf-8'))
gate=json.loads((OUT/'final-gate.json').read_text(encoding='utf-8'))
additional=json.loads((OUT/'additional-discovered-suites.json').read_text(encoding='utf-8'))
build=json.loads((OUT/'export-stable/build-manifest.json').read_text(encoding='utf-8'))
assert gate['passed'] and not audit['discrepancies']
routes=[json.loads(p.read_text(encoding='utf-8')) for p in OUT.glob('route_*.json')]
assert len(routes)==38 and all(r['valid'] and not r['discrepancies'] and len(r['captures'])==1 for r in routes)
summary=json.loads((OUT/'findings-summary.json').read_text(encoding='utf-8'))
text=f'''PATCH NOTES — TEMPORARY RELEASED-GAME LIFESPAN VERIFICATION v2
2026-10-05 | Current local worktree | Automated evidence, not human acceptance

ASSESSMENT
Monthly units, cumulative 70% net entitlement, central settlement, concurrent-title earnings and the selected-title report reconcile on the tested local build. No financial discrepancy was found. Two reproduced reporting/navigation defects were repaired: invalid fractional release-cycle provenance and a deferred slide callback receiving a freed menu. All 52 final verify_*.gd suites returned zero, with no assertion/parse/script failures; import and diff check passed. Environmental, negative-fixture and teardown diagnostics remain classified below. Exported Windows renderer/process launch passed, but interactive two-game play remains UNVERIFIED. Human acceptance and the new-feature hold remain pending.

AUTHORITY / SCOPE
Read live To Do List: https://docs.google.com/document/d/1n6o5g8Gj_sDTs5Ku6PLM37OWPPyLpDM_ASfNiD9MRkY/edit
Cumulative §§64–65: https://drive.google.com/file/d/1kmlzNwRbckS9OxucMd5WPYNOF2Dx6QT1/view
Task28 implementation: https://drive.google.com/file/d/1k8QiZyBy8-cq7XoHIcHtUcRNrSH3WNsN/view
Also inspected latest local monthly-report, phase-entrance/Predevelopment and Task27 route/calibration logs, live source, instructions search, branch, HEAD, status and diff before editing. No AGENTS.md was found in inspected repository/ancestor paths. Current dispatch holds new gameplay until natural human strong-release capture and review; Task22/23 remain independent read-only options, not part of this bounded task. §§64–65 values remain temporary first-version rules. No coefficients, campaign fee/eligibility, prices, payouts or 70% net share changed.

SOURCE STATE / PRESERVATION
Branch main, HEAD 0c34df5ae3c09e21bc1a3871a2038404883100d3. Initial and final status/diff plus per-file SHA256 manifests accompany this report. Verified the worktree, not an assumed GitHub build. Monthly report/capture and pending animation/Studio/Predevelopment changes were local at entry. No commit, push, remote synchronization or durable save claim. Existing source files changed by this task relative to initial SHA256 inventory: {', '.join(change['changed_existing'])}. No initial source file was removed. .codex-godot-temp and unrelated pending work preserved. Existing verifier runs regenerate diagnostic screenshots such as design-logs/predevelopment.png.

REPAIRS
1. RunState.get_released_game_monthly_report previously coerced release_cycle=0.5 to integer 0, reconstructing misleading history. New fixture reproduced failure before repair. Getter now requires an existing release and an actual nonnegative integer provenance value; invalid/missing values return unavailable history. Does not alter valid release IDs or sales calculations.
2. MenuTransitions deferred _bind/_slide typed Control arguments rejected a previously freed Object before their is_instance_valid guards could execute. Full generic ERROR scan caught this despite passing suite exit codes. Deferred entry arguments now accept Variant, validate immediately, and retain typed visual/tween locals. Rapid menu deletion/reopening has no economic callback. The affected release-menu and integrity suites pass after repair; the final full gate and Windows package were rebuilt afterward.

FILES ADDED / CHANGED FOR THIS TASK
Runtime: scripts/run_state.gd; scripts/ui/menu_transitions.gd.
Regression: scripts/debug/verify_lifespan_reporting_integrity.gd and .uid.
Read-only tooling: analysis/lifespan_verify_routes_v2.gd (+.uid), lifespan_verify_batch_v2.py, lifespan_verify_final_v2.py, lifespan_verify_analyze_v2.py, lifespan_verify_projections_v2.gd (+.uid), lifespan_verify_campaign_delta_v2.gd (+.uid when imported), lifespan_verify_package_v2.py.
Evidence: design-logs/lifespan-verification-v2, this TXT and evidence/source ZIPs in New Data Logs. Queue status addendum is separate; cumulative authority untouched.

LEGAL ROUTES / DECLARED BOUNDS
Established ordinary and synergy three-release routes were replayed first on the new initial-priority flow. Cohort: 32/32 accepted routes, 96 releases, eight specialties (Action, Adventure, Role Playing, Strategy, Simulation, Puzzle, Sports, Racing), two seed pairs per specialty, ordinary and synergy policies on matching starts. Case index 0..15; specialty=case%8. Environment seed=240930000+case. Card seed=240930100+97*case+500000*(game-1), phase offsets1..7. Actual Predevelopment controls set initial priorities and start the automatic first deal; RNG seeded before that deal, no replacement/redeal. Existing native phase actions, actual purchases, finite Feature exhaustion, renewable Passes, redraws, cash and launch logic are used. No free Wait, forced Review, cash/cards injected or synthetic launch in played routes.
Predeclaration: predeclared-plan.json; per-route timeout180s, cohort wall cap25minutes, three workers/isolated profiles. Case0..7 use specialty roster; case8..15 buy legally toward33 printed Scope with180000-cent reserve. Subsequent shopping/Contracts use inherited native Task27 rules. Ordinary budgets4 Design/5 Alpha/6 QA-oriented Beta hands; synergy permits up to10/14/12, stops on visible score/Scope targets, and uses visible candidates, priorities, redraws and Genre fit. Longer budget is a confound: this is not a causal synergy-only comparison or human frequency estimate. Broad Marketing-heavy optimization was not a cohort policy; Marketing remains covered by existing focused regressions.

Ordinary 48 releases: Review3.1–7.6, median5.75; 6/48 below5, none9+. Synergy48: Review7.7–10.0, median8.95; 24/48 at least9. No ordinary/synergy cohort stalled for cash or card supply. Reserve-based shopping skips are policy decisions, not proof that a next action is unaffordable. Actual draws, chosen cards, redrawn cards, scores, Bugs, Scope, Review components, launch profiles, purchases, calendar/cash states and Contract actions remain in each route JSON. These genuine automated9+ profiles do not replace the user's uncaptured human observations.

Longer continuations (replayed prefixes, not independent seeds):
  ordinary case6 / Sports: Reviews3.1,5.8,6.6,5.7,5.1; five releases at cycles16,43,64,83,102; stopcycle105; cash3276046 cents.
  ordinary case5 / Puzzle: Reviews5.9,6.2,5.0,5.3,5.7; five releases at cycles16,41,62,81,100; stopcycle103; cash3063391 cents. Added before execution as nearest-first-Review-to6 middling representative.
  synergy case0 / Action: Reviews9.7,9.2,9.2 at41,78,112; stopped during Game4 at120 productive actions; cash4798321 cents.
  synergy case4 / Simulation: Reviews7.7,8.1,9.8 at40,79,113; stopped during Game4 at120 actions; cash3961347 cents. This was the cohort-median-first-Review selection; retained as an upper-middling case.
The two Game4 stops are declared horizon limits, not demonstrated economic dead ends; their legacy trace 'blockers' entries record the state where the cap stopped progress. No five-release result is claimed for them. Two additional native ordinary/synergy case0 repeat-campaign arms reach three releases each. Total stored route executions38, including prefixes/continuations/repeat arms; not38 independent seed pairs. Initial established replays are not counted again. The cohort preceded the two narrow provenance/menu repairs; valid numeric sales code stayed byte-identical. The final middling five-game continuation and all52 suites were rerun on the stable repaired source.

ACCOUNTING AND CAPTURE
Independent transaction audit: {audit['transactions']} actions, {audit['monthly_rows']} monthly-row observations, zero discrepancies. These rows include repeated observation of a title/month as time advances, not unique months. Native after-action ledger replay: {summary['ledger_checks']} per-title checks. Every committed productive cycle is represented once without gaps or duplicates; final run cash equals550000 initial cents + all direct cash transactions + all sales settlements. Costs include quoted Store/Feature fees, campaigns; income includes actual Contract upfront/completion and playable Insider transactions. Report row sums match actual lifetime units, gross/net earned, paid/unpaid. Native record fields agree after each committed action. See transaction-audit.csv, observed-monthly-rows.csv and accounting-audit.json (empty discrepancy list).
All38 editor-only capture JSON readbacks match their live run's cash, cycle, release metadata, frozen inputs, campaign histories and monthly rows; serialized captures are embedded in route JSON. They are current-state diagnostics, not save files. Existing monthly report suite separately passes6326 synthetic row checks, both release/calendar alignments, Month1 odd splits and transition to Month2+, concurrent earnings, zero-unit months/dormancy and revival, partial rows and settlement attribution. Invalid/repeated/unaﬀordable/overflow campaigns reject atomically under existing lifespan/finance suites. Fixed synthetic invalid-provenance case returns no fabricated rows.

CAMPAIGN ACCOUNTING / FUTURE PROJECTIONS
Repeat arms use real legal Store/Contract/production actions to reach campaign windows, never free time. Repeated callback rejects without a second fee/cycle. Exact native same-cycle counterfactual isolates settlements that would happen anyway:
  ordinary repeat atcycle47: fee10000, no settlement on either arm, +7 units/+4896 earned net cents, immediate incremental cash -10000.
  synergy repeat atcycle84: visible cash rises140351 cents after fee; without campaign that cycle would settle142658 cents. With campaign it settles150351; incremental cash after fee is -2307 cents, not +140351. +11 incremental units/+7693 earned net cents.
These same-cycle controls are conditional ledger counterfactuals, not extra played routes.
96 actual frozen cohort release profiles each projected through ageMonth30 with native ReleasedGameSales:384 scenarios (none; first campaignM2; repeatM2/M3; first dormant-month revival). Projection cash starts actual cash at release and includes this title's settlements and campaign fees only; excludes future project costs/other-title cash. Future cycles are projections, explicitly not observed gameplay/free Wait. Both calendar alignments retained. Native projections had0 failures. No-campaign first-zero month range8–29. All96 dormant scenarios found a zero-unit month by30 and could afford the candidate campaign at that projection boundary.
At Month30, first-campaign incremental cash after fee spans -2307..21468 cents;92/96 positive. Two-campaign schedule versus none spans -8112..26853;82/96 positive. Second campaign's marginal return versus first-only spans -5805..5385;39/96 positive. Dormant revival versus none spans -2307..21469;93/96 positive. These are bounded ledger effects excluding opportunity cost, not proof of a profitable repeat loop or infinite campaign strategy. Repeated investment is situational; large visible cash deposits during a campaign are often mostly baseline settlements. Current values left unchanged. projections-month30.json contains exact monthly units/cents and cash at every central month boundary; campaign-same-cycle-deltas.json records the control.

REPORT / RENDER / UI
1152x648 programmatic graphical render inspected: report-integrity.png. Selected title, actual lifetime totals, partial first-month row, observed half/calendar/cycle detail, unpaid status, separate Forecast-only line and editor capture button fit without overlap. Duplicate-name synthetic titles have distinct release IDs and independent selector entries; selecting newer/older titles never borrows history. Passive navigation and menu animations do not commit or defer cash/calendar transactions. Missing/fractional/wrong-alignment provenance returns unavailable. This render is a synthetic fixture, not a human gameplay screenshot. Existing report suite checks both supported viewport sizes; no claim of exported interactive clicks.

SOURCE HEALTH / ERROR MARKERS
Repository-wide discovery found55 verify_*.gd files:52 maintained suites under scripts/debug plus3 historical analysis verifiers. All were run on final source. The maintained52, analysis/verify_fan_tooltip_v1.gd and analysis/verify_organize_pool_v2.gd pass (54 total). Historical analysis/verify_organize_pool_v1.gd fails its second-click assertion and reaches the40-second timeout: it expects a second Organize click to preserve category order, whereas the later approved behavior cycles to Scope and is tested by v2. This is a stale/superseded test expectation, not a lifespan defect; no gameplay change or deletion of that historical file was made. Therefore the repository-wide sweep is NOT an all-green55/55 result. additional-discovered-suites.json and logs retain exact commands and results.
Baseline import and51 discovered verify suites passed before adding the new test. Final import plus all52 suites passed (exit0, no FAIL/assertion/parse/script markers) after repairs; git diff --check exit0. Exact per-suite commands, profiles, outputs and codes: final-gate.json and final-*.command.json/log. Generic ERROR scan is retained separately, not hidden behind exit codes:
  Windows root certificate-store diagnostic appears in editor/EXE processes (environmental; no network-dependent gameplay tested).
  Gameplay transition/initialization negative fixtures deliberately reject invalid scene/snapshot inputs and emit expected errors.
  Existing Balanced Primitive Contract verifier reports3 resources still in use at teardown; existing calendar verifier attempts grab_focus before its fixture is in-tree. Assertions pass, but these diagnostics are not a clean shutdown claim; no financial failure reproduced.
  Freed-menu deferred callback error was repaired and is absent in final release-menu/integrity results.
Analysis-only campaign counterfactual initially timed out after JSON omitted StringName/int-key ledger types; normalization repaired in the harness, rerun exit0. One intermediate gate restart while fixing typed Tween inference is recorded; only final stable-source results support the pass claim. No gameplay change was made to satisfy a simulated target.

WINDOWS EXPORT / LIMITATIONS
Godot4.7.1 stable official a13da4feb; Task11 templates pinned to4.7.1, archive SHA25686409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72. Reused cached verified archive; no substitute editor version. Final clean temporary build: {build['workspace']}
EXE: {build['artifacts']['Patch Notes Demo.exe']}
PCK: {build['artifacts']['Patch Notes Demo.pck']}
Actual PCK167 entries, every payload MD5 verified; all positive-allowlist runtime resources retained. Compiled MonthlySalesReport and ReleasedGameMonthlyReport ship. analysis/design-logs/scripts/debug/editor capture are absent. No Steam upload; missing art/audio/credits and other previously documented production gaps remain, no release-readiness claim.
Final EXE started under isolated APPDATA/LOCALAPPDATA with --quit-after120, initialized OpenGL3.3 NVIDIA Compatibility and loaded40 cards, exit0. Exact command/logs in export-stable/launch.json and standalone-runtime.log. Earlier --path attempt was rejected because the export disables path overrides; rerun without it succeeds.
Computer Use could not discover/access the running Demo window. Explicit sky.launch_app on the initial demo returned 'Windows failed to launch app (ShellExecuteW returned5)'. The native editor/debug window is not the exported game. Therefore exported two-game interaction smoke is BLOCKED/UNVERIFIED, despite successful package/build/renderer launch. Editor suites are not substituted for it.

REPRODUCTION
Working directory: {ROOT}
Python: C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -B
Godot: C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe
python -B analysis/lifespan_verify_batch_v2.py
python -B analysis/lifespan_verify_final_v2.py --gate-only
python -B analysis/lifespan_verify_analyze_v2.py
Godot --headless --path <project> --script res://analysis/lifespan_verify_routes_v2.gd -- --policy=<ordinary|synergy> --case=<0..15> [--games=5 --limit=120] [--experiment=repeat]
Godot --headless --path <project> --script res://analysis/lifespan_verify_projections_v2.gd
Godot --headless --path <project> --script res://analysis/lifespan_verify_campaign_delta_v2.gd
Godot --path <project> --script res://scripts/debug/verify_lifespan_reporting_integrity.gd -- --capture
Every launch uses a fresh profile. Build script: analysis/task11_windows_export_v1.py (override OUT to this evidence export-stable directory); PCK inspector: analysis/task11_inspect_pck_v1.py with matching OUT. Exact resolved commands and template/editor hashes are saved with each operation. Local source ZIP preserves all runtime files and analysis inheritance dependencies; the evidence ZIP contains findings, traces, commands, screenshots and manifests only, no project source/diff. Findings TXT is uploaded to Drive. Automatic approval review rejected the evidence ZIP upload because it may contain internal traces/screenshots beyond the authorized findings-log upload. It remains local pending explicit permission; no upload workaround was attempted.

HUMAN ACCEPTANCE CHECKLIST / REMAINING WORK
1. Play a natural strong release; retain its title/ID, frozen Review/Scope/Core/Awareness, cash and calendar. Use Monthly Sales -> Save local playtest capture in the editor after release and several actual productive calendar boundaries.
2. With a second released title, select both histories; compare Month1 halves, partial Month2+, units, net paid/unpaid and bottom-HUD cash at settlement. Keep spending and campaign fee separate from baseline sales deposits. Capture before/after one eligible campaign, then continue legally.
3. Confirm report readability, duplicate-title selection, rapid menu navigation and no repeated transactions by eye. Run the packaged EXE through two releases on accessible Windows and check its report; editor capture is intentionally unavailable there.
4. Review that human evidence and exact matched future projections before explicitly lifting §65's feature hold. Automated9+ routes do not clear this gate. No traits, fans, employees, offers, eras, durable saves or balance additions were implemented.

FINAL VERIFIER MANIFEST
'''
for r in gate['results']:text+=f"{r['name']}: exit={r['exit']}; failure markers={r['errors']}\n  {' '.join(r['command'])}\n  profile={r['profile']}\n"
for r in additional:text+=f"{r['name']}: exit={r['exit']}; failure markers={r['errors']}\n  {' '.join(r['command'])}\n  profile={r['profile']}\n"
log=DEST/'Patch Notes - Temporary Lifespan Verification v2.txt';log.write_text(text,encoding='utf-8')
(OUT/'findings.txt').write_text(text,encoding='utf-8')
source=DEST/'Patch Notes - Lifespan Verification v2 Local Source.zip'
with zipfile.ZipFile(source,'w',zipfile.ZIP_DEFLATED) as z:
    for folder in ['scripts','scenes','data','resources','assets','analysis']:
        for p in (ROOT/folder).rglob('*'):
            if p.is_file() and '__pycache__' not in p.parts:z.write(p,p.relative_to(ROOT))
    for name in ['project.godot','export_presets.cfg','icon.svg']:z.write(ROOT/name,name)
evidence=DEST/'Patch Notes - Lifespan Verification v2 Evidence.zip'
with zipfile.ZipFile(evidence,'w',zipfile.ZIP_DEFLATED) as z:
    for p in OUT.rglob('*'):
        if p.is_file() and p.suffix in ['.json','.csv','.txt','.log','.png'] and 'diff' not in p.name:z.write(p,p.relative_to(OUT))
    z.write(log,log.name)
manifest={'log':str(log),'local_source_zip':{'path':str(source),'sha256':sha(source),'bytes':source.stat().st_size},'evidence_zip':{'path':str(evidence),'sha256':sha(evidence),'bytes':evidence.stat().st_size},'changes':change}
(OUT/'deliverables.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps(manifest,indent=2))
