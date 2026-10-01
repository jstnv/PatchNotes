from pathlib import Path
import hashlib,json,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design-logs/task21-v1'
old=json.loads((ROOT/'design-logs/tutorial-task17-v1/strong_final.json').read_text())['rows'][0]
new=json.loads((OUT/'route_exact.json').read_text())['rows'][0]
keys=['phase','game','draw','final_draw','selected','cost_cents','printed_core','printed_scope','synergy']
def hands(row):
    return [{k:a.get(k) for k in keys} for a in row['actions'] if a['phase'] in ['design','alpha','beta']]
assert hands(old)==hands(new), 'Production decisions/draws diverged'
initial=json.loads((OUT/'source-before.json').read_text())
changed=[k for k,h in initial.items() if hashlib.sha256((ROOT/k).read_bytes()).hexdigest()!=h]
expected=['scripts/run_state.gd','scripts/phases/studio_phase.gd','scripts/publishers/publisher_catalog.gd','scripts/debug/verify_sidestreet_contract.gd','scripts/debug/verify_balanced_primitive_contract.gd','scripts/debug/verify_run_calendar_and_studio_entry.gd']
assert {k.replace('\\','/') for k in changed}==set(expected),changed
checks=[json.loads((OUT/(p.stem+'.command.json')).read_text()) for p in (ROOT/'scripts/debug').glob('verify_*.gd')]
assert len(checks)==44 and all(c['exit']==0 and not c['errors'] for c in checks)
assert json.loads((OUT/'render.command.json').read_text())['exit']==0
diff=subprocess.run(['git','diff','--check'],cwd=ROOT,capture_output=True)
(OUT/'diff-check.log').write_bytes(diff.stdout+diff.stderr)
assert diff.returncode==0
(OUT/'final-diff.patch').write_bytes(subprocess.check_output(['git','diff'],cwd=ROOT))
(OUT/'final-status.txt').write_bytes(subprocess.check_output(['git','status','--short'],cwd=ROOT))
audit={'changed_preexisting_files':changed,'all_verifiers':checks,'production_action_parity':len(hands(new)),'first_divergence':'Absent SideStreet 1 after under-Scope Game 1; omit its acceptance, two hands and changed priority cycle','affordability_divergence':None,'current':{k:new[k] for k in ['seed','game_1','game_2','owned_features','unowned_store_quotes']}}
(OUT/'audit.json').write_text(json.dumps(audit,indent=2),encoding='utf-8')
text='''PATCH NOTES — TASK 21 REQUIRED-SCOPE SIDESTREET AND CALENDAR YEAR v1
Date: 2026-09-29. COMPLETE, verified local work; no commit or push.

Authority and source
Read current execution queue Task 21 (modified 2026-09-29T17:36:11.510Z), cumulative authority section 61, SideStreet_Cash_Contract_Implementation_and_Acceptance_Stress_v1, Feature_Store_Staged_Simulation_Findings_v1, Tutorial_Repair_and_Task17_Strong_Release_Findings_v1, Studio_Entry_Redraw_Refresh_and_Owned_Feature_Prices_v1 and Feature_Store_Artwork_Node_Map_v1. Inspected source, branch, HEAD, status and diff before gameplay edits. No AGENTS.md was present in repository or inspected ancestors. Main HEAD and local origin/main tracking ref remain 608a2c62ab0850cf607f7ff627b042a49b5d2dfb; no remote fetch was performed, so this is not a fresh remote-head assertion. Initial 12 modified source files and all unrelated untracked work were preserved. .codex-godot-temp was not touched.

Implementation
RunState.register_release creates a new SideStreet entitlement only if committed printed Scope >= that ProjectState's required Scope. Validation and duplicate-ID return precede this check. Under-Scope releases still register their ordinary frozen Review and independent sales record. No retroactive filtering of existing pending, accepted or completed offers. Ironclad's completion gate, IDs, payout math, histories and productive transaction ordering are unchanged. The gate reads required Scope rather than hard-coding 30; current playable first size remains B/30. State-level 40/60 fixtures are tests, not new playable sizes.
RunState's existing get_current_year is still START_YEAR + completed cycles / 24. Its shared calendar label now prefixes that year; the existing shared HUD reads it. Studio's existing heading includes studio name and year and refreshes through the existing calendar signal, even before any release. No writable clock was added. Absolute run-month numbering is retained. Publisher profile copy describes required-Scope entitlement.

Changed source files (relative to patch-notes)
scripts/run_state.gd; scripts/phases/studio_phase.gd; scripts/publishers/publisher_catalog.gd.
Updated verification fixtures: scripts/debug/verify_sidestreet_contract.gd (explicit qualifying Scope/default plus parameterized Scope); scripts/debug/verify_balanced_primitive_contract.gd (qualifying fixture); scripts/debug/verify_run_calendar_and_studio_entry.gd (year-prefixed expected strings).
New scripts/debug/verify_sidestreet_scope_and_year.gd and UID; analysis/task21_verify_v1.py, task21_render_v1.py, task21_route_v1.gd and UID, task21_report_v1.py. Evidence is design-logs/task21-v1/. Source hashes confirm exactly the six preexisting files above changed during this task. The pending gameplay_hud.gd tutorial edit is byte-identical to its pre-task state; the year reaches it through the existing formatter.

Verification evidence
Godot 4.7.1 editor import: PASS. All 44 verify_*.gd suites: PASS (43 prior + new Task 21 suite). Final import and publisher regression after copy update: PASS. Focused new tests cover zero/one-short/exact/above required Scope, requirements 30/40/60, legal starter Scope 20/21/22/23, duplicate callbacks, before/after Ironclad, failed launch, reconstructed Studio, legacy accepted/completed under-Scope offer and preserved payout. Existing SideStreet suite covers pending qualified offers, payout-once, failed hand and overflow rollback, finite cards, redraws, priority and monthly settlement. Other publisher gates passed unchanged.
Cycle 0/23/24/95/96 yields 1980/1980/1981/1983/1984. Both Studio and HUD tested after committed cycles; Store/reserve/campaign boundary fixtures cross 95->96 and refresh both. Legal route checks HUD after each actual Design/Alpha/Beta hand. Existing action suites verify productive-cycle vs passive/redraw/invalid/unchanged action distinctions. Calendar overflow and unaffordable preflight preserve state. Scene reconstruction adds no cycle. Rendered compatibility-mode captures at 1152x648 and 900x600 pass; screenshots visually inspected. Native mouse-driven play was not performed.
During test development: fixed a typed-loop local in the new verifier; corrected a zero-Scope legacy fixture that expected an offer; set viewport content_scale_size for the small-resolution capture. A mid-calendar-signal instrumentation check ran before the HUD listener after phase reconnection; assertions now occur after the action returns, and pass. These were verification issues, not extra gameplay changes. Existing missing-art/certificate warnings remain. git diff --check exits 0.

Exact commands
Python executable: C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe
python -B analysis/task21_verify_v1.py --snapshot (before edits)
python -B analysis/task21_verify_v1.py --full
python -B analysis/task21_verify_v1.py (final expanded focused suite)
python -B analysis/task21_render_v1.py
Godot executable: C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe
Godot --headless --path <patch-notes> --editor --import
Godot --headless --path <patch-notes> --script res://scripts/debug/verify_<suite>.gd
Godot --headless --path <patch-notes> --script res://analysis/task21_route_v1.gd -- --mode=exact --count=1
Godot --headless --path <patch-notes> --script res://analysis/task21_route_v1.gd -- --mode=adjusted --count=1
Godot --path <patch-notes> --rendering-method gl_compatibility --script res://scripts/debug/verify_sidestreet_scope_and_year.gd -- --capture
git diff --check
Every Godot command uses fresh empty APPDATA/LOCALAPPDATA directories; exact absolute argv, exit and profile are archived in *.command.json, with stdout/stderr in matching logs. audit.json aggregates the final 44 results. Re-run python -B analysis/task21_report_v1.py for parity/source checks.

Legal Game 2 route and lost cash
Production seed 270927000, environment/Contract stream 290929000. One exact historical production/purchase replay after omitting the now-unavailable first SideStreet; one separate unchanged-policy continuation reaches the same result. All 88 Design/Alpha/Beta hands have identical draws, selections, printed values and costs to Task 17. The absent contract's 14 initial-draw random samples are discarded only in the analysis stream to preserve subsequent market inputs; no cards/cash/cycles are granted. No Review, market outcome, supply or balance value is forced.
First action divergence: after Ironclad at cycle 34, Game 1 Scope 20/30 has no SideStreet offer. Its former $1,100 payout and three cycles (two hands plus one changed-priority commit) are absent. Ironclad still pays $2,025 total ($400 acceptance + $1,625 completion). Cash then is $8,751.42, including independently settled Game 1 sales, not all Contract income. Game 1 remains Review 6.4, Awareness 107, 701 Month 1 units, cycle 31, $1,160 at launch.
Recorded Sounds still costs $1,530 with its 10% earned familiarity discount. Sound Effects and the ten same additional Primitive reserves all purchase legally. No purchase or production affordability failure occurs. After these purchases the run owns all 27 Primitive Features plus Recorded Sounds (28 Features); 41 printed Scope is actually resolved in Game 2. Unowned Store quotes in audit.json are affordability opportunities, not purchases or playable supply. Owned cards remain project-finite; later Store nodes do not join the Primitive Contract pool.
Game 2 remains Review 9.8, Awareness 111, cores 104/105/115/189, Scope 41, 979 Month 1 units; launches cycle 105 rather than 108, cash $3,574.78 rather than $4,674.78. This is a $1,100 difference at each route's launch, not a common-calendar comparison. Earlier shopping checkpoints also differ in settlement timing (e.g. the first reserve checkpoint $7,984.36 vs $9,720.72); those differences must not be called lost publisher payout alone. Game 2 qualifies for its own SideStreet; only two total Contract completions now exist, so Starwave is not unlocked yet. No exception, grant, lower Scope, refund, price or payout adjustment was made.

Boundaries and next work
The user's approximately 4.6 first-game / 8.9 later-game Reviews and Game-4 affordability are human observations, not exact targets or traced routes. This single high-effort automated replay does not estimate novice outcomes or prove all players can afford the same path. Task 2's 87 empty-release cash segments and pre-gate Task 17 finance traces stay frozen historical evidence; they cannot establish the new economy baseline. Current trial lifespan/campaign coefficients and all fan rates remain unapproved.
Follow-up era recommendation: test calendar eligibility together with committed full-required-Scope releases; compare explicit candidate qualifying-release thresholds separately. Bare years permit priority-change time grinding, and bare release counts formerly admitted empty games. No threshold, 97-node catalog, later-era card, trait, employee, publisher offer or numerical balance was implemented here. Durable disk save/load remains outside this task; reconstruction checks exercise existing run-owned state. Next eligible queue task: 18, with 19 and 20 also freed from the Task 21 dependency.
Queue read/write method: Windows lacks the POSIX path/runtime assumed by the advisory Docs trusted-read bridge. Use the skill's closest-supported native all-tabs get_document read, inspect plain-text target paragraphs, revision-guard exact replacements, then verify full text and tab topology. No canonical authority edit is made.
'''
dest=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\New Data Logs\Task21_SideStreet_Required_Scope_and_Calendar_Year_v1.txt')
dest.write_text(text,encoding='utf-8')
(OUT/dest.name).write_text(text,encoding='utf-8')
with zipfile.ZipFile(ROOT/'design-logs/Task21_Evidence_v1.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in OUT.rglob('*'):
        if p.is_file(): z.write(p,p.relative_to(ROOT))
    for p in (ROOT/'analysis').glob('task21*'):
        if p.is_file(): z.write(p,p.relative_to(ROOT))
    for p in (ROOT/'scripts/debug').glob('verify_sidestreet_scope_and_year*'): z.write(p,p.relative_to(ROOT))
print(json.dumps({'verifiers':len(checks),'production_hands':len(hands(new)),'changed':changed,'log':str(dest)},indent=2))
