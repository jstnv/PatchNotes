"""Preserve the task-only diff, source guard, checkpoint delta and findings."""
from pathlib import Path
import json,hashlib,difflib,subprocess,shutil
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design-logs/task25-v1'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
before=read(OUT/'source-before.json')
after={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for f in ['scripts','scenes','data','resources'] for p in (ROOT/f).rglob('*') if p.is_file()}
changed=sorted(k for k in set(before)|set(after) if before.get(k)!=after.get(k))
allowed=['scripts/debug/'+x for x in ['capture_first_game_tutorial.gd','verify_feature_store_cycle_purchase.gd','verify_feature_store_navigation.gd','verify_first_game_and_tips.gd','verify_first_game_scripted_tutorial.gd','verify_first_studio_feature_economy.gd','verify_main_menu_history.gd','verify_primitive_run_initialization.gd','verify_sidestreet_scope_and_year.gd','verify_studio_specialties.gd','verify_studio_specialties.gd.uid','fixtures/studio_specialties_v1.json']]
allowed+=['scripts/'+x for x in ['gameplay.gd','phases/main_menu.gd','phases/studio_phase.gd','run_state.gd','studio_specialties.gd','studio_specialties.gd.uid','ui/feature_store.gd','ui/feature_store_map.gd','ui/gameplay_hud.gd','ui/tutorial_overlay.gd']]
assert set(changed)<=set(str(Path(x)) for x in allowed)
assert (ROOT/'project.godot').read_bytes()==(OUT/'before/project.godot').read_bytes()
diff=subprocess.run(['git','diff','--check'],cwd=ROOT,capture_output=True);(OUT/'diff-check.log').write_bytes(diff.stdout+diff.stderr);assert diff.returncode==0
patch=''
for k in changed:
    prev=OUT/'before'/k;curr=ROOT/k
    patch+=''.join(difflib.unified_diff(prev.read_text(encoding='utf-8').splitlines(True) if prev.exists() else [],curr.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+k,tofile=k))
(OUT/'task-only.diff').write_text(patch,encoding='utf-8')
(OUT/'source-after.json').write_text(json.dumps(after,indent=2),encoding='utf-8')
(OUT/'changed-files.json').write_text(json.dumps(changed,indent=2),encoding='utf-8')
(OUT/'source-guard.json').write_text(json.dumps(dict(unrelated_runtime_preserved=True,changed_files=changed,diff_check=0),indent=2),encoding='utf-8')
(OUT/'final-status.txt').write_bytes(subprocess.check_output(['git','status','--short'],cwd=ROOT))
gate=read(OUT/'full-verification.json');assert len(gate)==47 and all(r['exit']==0 and not r['errors'] for r in gate)
summary=read(OUT/'summary.json');fixtures=read(OUT/'roster-fixtures.json')
report='''PATCH NOTES - TASK 25: STUDIO GENRE SPECIALTIES AND AUTOMATIC ROSTERS v1
Date: 2026-09-29 (America/Los_Angeles)
Status: IMPLEMENTED AND VERIFIED LOCALLY. No commit or push by this task.

AUTHORITY AND SOURCE
Current Miss Codex Task Queue, Task25, and cumulative Implementation Discoveries
and Locked Rules section63, refreshed before starting. Task25 explicitly names
itself the next overlapping gameplay implementation. Earlier First_Studio_Feature_
Economy_v2 caps/optional-specialty assumptions are superseded where they conflict.
Also inspected live Genre targets, Primitive ledger, Studio/Store/MainMenu,
RunState, Task10 Studio_Checkpoint_Save_Contract_v1, and related regression code.
Branch main; HEAD 608a2c62ab0850cf607f7ff627b042a49b5d2dfb plus existing local work.
No AGENTS.md found in repository/inspected ancestors. Initial status/diff and a
229-file source manifest were captured before editing. The isolated historical
project contains that exact pre-Task25 runtime, including Task21 Scope gating,
tutorial repair and mouse/keyboard Feature-map changes. No tracked ledger values,
Review, synergies, sales, Contract formulas or calendar implementation changed.
.codex-godot-temp was left untouched; unrelated source hashes match.

IMPLEMENTATION
Studio creation requires a name and one permanent specialty. An explicit choice
previews favored Core/secondary emphasis, exact Feature names, count and Scope.
Valid confirmation commits identity and the specialty roster before observers
are notified. Existing 550000-cent starting funding remains; no charge or cycle
for the roster. Missing, invalid and repeated confirmation rejects atomically.
Back clears the uncommitted choice; scene reconstruction reads the same RunState.

StudioSpecialties uses current printed primary AND secondary values, the six
common IDs and exact section63 signatures. A fixed 27-ID Primitive allowlist
prevents future authored cards from auto-granting. Counts are independently
cross-checked against the live ledger and exact fixture membership:
'''
for name,f in fixtures.items():report+=f"  {name}: {f['count']} Features / {f['scope']} printed Scope\n"
report+='''
Unowned Primitive cards remain optional zero-cycle initial Store purchases at
the unchanged 30000/45000/60000-cent prices while cash permits. Removed the
400000-cent spending cap, 23-Scope cap, stale labels and obsolete spending state.
For example a Sports start can buy all remaining cards for 405000 cents, own
39 Scope, retain 145000 cents, and remain at cycle0. Play costs still apply.
The successful first-project transaction ends initial purchasing; later reserves
still cost one productive cycle. Failed starts leave initial purchasing open.
Existing branch prerequisites, later purchase boundary, familiarity, finite
Features, project supply and shared redraw rules are unchanged. No specialty
bonus to Core, Review, Awareness, sales or Genre Fit was added. Each project
freely chooses any Genre, including one different from the studio's specialty.
SideStreet still tests committed played Scope, never owned or affordable Scope.
Background/trait systems remain separate and unimplemented.

PLANNED CHECKPOINT FIELD ADDENDUM (Task10 v1 -> current section63 mapping)
Task10 delivered a SPECIFICATION; there is no durable save/load service in the
live game. This task does not claim a restart/Continue test passed.
Add required run.studio_specialty <- RunState._studio_specialty as the exact
stable Genre ID (one of the eight current IDs). Keep run.studio_name and the
existing run.owned_features <- _owned_features exact unique-ID set. Owned IDs
include optional purchases; do not recompute them or rerun the creation grant
while restoring. Keep first_studio_economy and starter_selection_confirmed.
Remove run.starter_purchase_spent_cents from the planned schema/validation and
initial-format fixtures; it is no longer runtime state or a gate. The retired
Task10 six-card/capped fixture is historical, not a compatible new checkpoint.
Use a new compatible content revision when the loader is implemented. No legacy
save migration exists or is silently promised. A01 must require the selected
specialty's exact roster, 550000 cents, cycle0 and redraw4; A02 must test optional
purchases beyond both old caps. Retain the remaining atomic-write, recovery,
identity, RNG and no-repeat-payout requirements. Actual process-restart recovery
remains the separate save-system implementation boundary.

VERIFICATION
Godot 4.7.1.stable.official.a13da4feb editor import and all 46 current verify_*.gd
suites passed with error-marker scans. New specialties verifier: 245 PASS, zero
failures, including all eight roster fixtures, invalid/duplicate/cancel paths,
free cash/calendar behavior, one-cent-short purchase rejection, parent unlocks,
no auto-descendants/familiarity, matching/nonmatching Genres, scene reconstruction,
failed/successful first start and frozen first/next-project supplies.
Existing Store navigation, first-Studio economy, tutorial, SideStreet, Review,
Genre Fit, cash/calendar and sales regressions pass. Their old setup fixtures now
explicitly choose a specialty; obsolete six-card/cap assertions were replaced
with the new approved behavior, preserving existing underlying economy checks.
Graphical verifier: 245 PASS; native Godot capture inspected at1152x648. Preview,
roster, Enter Studio and Back fit on screen. This is automated scene/input
evidence, not a human mouse playtest. git diff --check passed. Pre-existing root
certificate-store and missing Feature-art warnings remain non-failing.
Early development runs exposed and corrected an implicitly selected dropdown
default, StringName-versus-JSON-string fixture comparison, a verifier API typo,
and text encoding issues. Final source/labels and the complete gate pass.

PAIRED LEGAL PLAYTEST PROTOCOL
72 matched pairs = 144 native-Godot two-release executions: 24 paired seeds under
each cautious, ordinary and synergy/Genre-aware policy. Those are 24 seed inputs
reused across policies, not 72 independent random seeds. Eight specialties each
have three cases per policy. First8 cases match project Genre to specialty;
remaining16 choose a different Genre. Sound/mixed production and QA/Marketing
Beta vary by case parity. Both arms use the same environment and phase seeds.
Historical arm legally purchases one frozen 20-23-Scope capped roster. New arm
uses the free specialty roster plus no optional purchases for cautious, a target
of31 owned Scope for ordinary, or35 for synergy, retaining180000 cents when
shopping. These are declared automated purchase policies, not design locks.
Exactly two Design and three Alpha hands commit20 production cards per game.
Beta lasts2/4/6 hands by policy. Normal policies follow the two tutorial lessons;
ordinary/synergy use redraws and a changed-priority action. All draws, exhaustion,
play costs, bugs, Review, sales and payouts run through current Godot behavior.
The20-card bound is this test protocol, not a new gameplay restriction. The live
game permits longer development. User observations (~4.6 first Review, ~8.9 later
and >9 later releases) remain qualitative human evidence; these short automated
runs are NOT a human progression ceiling or a request to rebalance Review.
After Game1, each route completes native Ironclad, uses SideStreet only when
truly available, makes affordable reserve purchases, and develops Game2. No
free Wait, fabricated scores, grants or money is injected. Raw traces record
purchases, draws/redraws, selected cards, printed Core/Scope, resolved states,
Bugs, Genre Fit, Review components, exact cash/cycles, sales and Contract payouts.

OBSERVED RESULTS (medians; cash minima are actual exact-cent route values)
Arm / policy           G1 Scope  G1 Review  G1 full  Lowest G1 cash  Min cash before G2
'''
for arm in ['historical','specialty']:
 for policy in ['cautious','ordinary','synergy']:
  s=summary[arm+'_'+policy]
  report+=f"{arm+'/'+policy:23} {s['game1_scope']['median']:7g} {s['game1_review']['median']:10g} {s['game1_full_scope']:7}/24 ${s['game1_cash_low_cents']['min']/100:12.2f} ${s['before_game2_cash_cents']['min']/100:17.2f}\n"
report+='''
All144 routes reached Game2 release. No attempted legal next action stalled for
cash or supply. New-roster Game2 starting cash exceeded its matched historical
case in all72 pairs, by299872-883894 cents. This includes the effects of optional
purchase policy, native sales timing and Contract ownership/payouts; it is not
an isolated cash-grant or trait effect. No compensation was added.
First-game full Scope: historical0/72, new2/72 (both synergy policy). Only those
two new first releases generated SideStreet entitlements; all other first
releases correctly remained under-Scope. Both new qualifying routes committed
exactly20 production cards. Game1 Reviews were below5 in all historical runs and
71/72 new runs; one new run reached5.6, none7.0. The short hand budget drives this
limited cohort; do not generalize it to longer or human play.
Important finding: free rosters substantially increase early liquidity, but owned
Scope still differs from the amount actually played in a short project. Future
trait/Contract/era studies must recapture on this baseline, not reuse old cash.

REPLAYABLE QUALIFYING EXAMPLE
Case1, synergy policy, Adventure specialty/project Genre, phase seed250930197,
environment seed250930001. It purchases optional cards to36 owned Scope, then
commits30 Scope in20 cards. Game1 Core21/25/42/30,9 fixed Bugs, none remaining,
Genre Fit0.8422033898, Review5.6, Awareness121,577 projected Month1 units,
576423-cent projected gross and403496-cent projected net. Cash at launch184000;
after native Contracts/earning/settlement, cash before Game2 is1078084 cents at
cycle19. This is an automated legal trace, not a human or high-Review capture.
Re-running that exact seed/choice policy matched every recorded field after
normalizing only cryptographically generated release IDs.

SEPARATE SCOPE-FIRST FEASIBILITY CASE
One separately labeled scope-first route (case100, seed250939800, environment
250930100) uses Simulation specialty and Racing project Genre. Optional shopping
reaches38 owned Scope under its cash reserve policy. Ignoring suggested synergies
and choosing visible Scope, it commits31 Scope in20 cards, Review3.8, and reaches
a43000-cent first-game cash low. SideStreet is genuinely eligible and pays107500
cents. Game2 begins with759817 cents. This proves legal full-B feasibility; it
is not mixed into the normal-policy success probabilities.

COMMANDS (working directory = PatchNotes/patch-notes)
Use bundled Python:
C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe
  -B analysis/task25_verify_v1.py --full
  -B analysis/task25_render_v1.py
  -B analysis/task25_batch_v1.py
  -B analysis/task25_analyze_v1.py
  -B analysis/task25_finalize_v1.py
Scope case:
  Godot --headless --path <project> --script res://analysis/task25_scope_route_v1.gd -- --scope-trial=1
Replay:
  Godot --headless --path <project> --script res://analysis/task25_routes_v1.gd -- --arm=specialty --policy=synergy --start=1 --count=1
  git diff --check
All expanded Godot executable paths, arguments, isolated APPDATA/LOCALAPPDATA
profiles, exit codes and marker scans are preserved in *.command.json and the
verification manifests. No user's save data is reused by these checks.

CHANGED RUNTIME/VERIFIER FILES (relative to patch-notes)
'''
report+='\n'.join('  '+p.replace('\\','/') for p in changed)
report+='''
New reproducibility files: analysis/task25_verify_v1.py, task25_render_v1.py,
task25_batch_v1.py, task25_routes_v1.gd (+UID), task25_scope_route_v1.gd (+UID),
task25_analyze_v1.py and task25_finalize_v1.py. Evidence: design-logs/task25-v1/.
No source commit/push. Preserve the pending tutorial, Studio, Feature-map and
publisher changes as part of the integrated worktree.

EVIDENCE AND FOLLOW-UP
source-before/after.json, initial status/HEAD/diff, before/ isolated native project,
task-only.diff, source-guard.json, full-verification.json, render.command.json,
studio-specialty-1152.png, routes-verification.json, raw-manifest.json,
routes_specialty_*.json, before/design-logs/task25-v1/routes_historical_*.json,
scope-feasibility.json, paired-table.json, summary.json and replay-parity.json.
Raw JSON traces and source remain local. This TXT is copied to New Data Logs and
uploaded to the requested Drive logs folder; no ZIP/source archive upload.
No gameplay implementation blocker. Durable checkpoint/restart behavior remains
unimplemented as explicitly described above. Proposed traits, employees, fan
rates, Crown/Neon values, era gates and new cards remain unimplemented/unapproved.
Revisit Tasks22-24 against this baseline; standalone demo export/settings are
also open queue work. The canonical cumulative authority is not rewritten here.
'''
name='Task25_Studio_Genre_Specialties_and_Roster_Rebaseline_v1.txt'
(OUT/name).write_text(report,encoding='utf-8')
dest=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')/name
shutil.copy2(OUT/name,dest)
print('PASS: source guard, full gate, diff check; report:',dest)
