"""Archive verified spending-advice evidence; never change gameplay or Drive."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/spending-advice-v1'
DEST = Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')
BUNDLE = DEST / 'Hidden Cycle Tracker and Spending Advice v1'
gate = json.loads((OUT / 'final-gate.json').read_text(encoding='utf-8'))
render = json.loads((OUT / 'render.command.json').read_text(encoding='utf-8'))
assert gate['passed'] and render['exit'] == 0 and not render['errors']
source = json.loads((OUT / 'source-final.json').read_text(encoding='utf-8'))
assert all(hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest for name, digest in source['files'].items())
assert source['head'] == subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip()
status = subprocess.check_output(['git', 'status', '--short'], cwd=ROOT).decode()
diff = subprocess.run(['git', 'diff', '--check'], cwd=ROOT, capture_output=True)
assert diff.returncode == 0
(OUT / 'final-status.txt').write_text(status, encoding='utf-8')
(OUT / 'implementation.patch').write_bytes(subprocess.check_output(['git', 'diff'], cwd=ROOT))
count = len(gate['results']) - 1
passes = sum(r['assertion_passes'] for r in gate['results'])
focused = next(r['assertion_passes'] for r in gate['results'] if r['name'] == 'verify_feature_spending_guidance')
text = f'''PATCH NOTES — HIDDEN CYCLE TRACKER AND SPENDING ADVICE v1
STATUS: IMPLEMENTED AND VERIFIED LOCALLY. This is an advisory, not a purchase lock or an approved balance target.

CHATGPT HANDOFF
The run now exposes get_development_pacing(): a hidden arithmetic mean of the immutable development_cycles of committed releases, one sample per release ID. Feature Store uses get_feature_spending_advice() to suggest preserving cash for playing every owned Feature once plus $500 monthly rent over the player's observed pace. Selected-purchase quotes add the new Feature's known play cost and current discounted purchase price. Players can ignore the advisory. No Review, price, rent, lifespan, credit, draw or purchase rules were retuned.

SOURCE AND AUTHORITY
Latest direct user request: create a hidden average-cycle tracker and use it for spending advice; log for ChatGPT.
Live To Do List read: https://docs.google.com/document/d/1n6o5g8Gj_sDTs5Ku6PLM37OWPPyLpDM_ASfNiD9MRkY/edit (modified2026-10-06T10:57:08.131Z).
Cumulative authority read, especially §§68–69: https://drive.google.com/file/d/1kmlzNwRbckS9OxucMd5WPYNOF2Dx6QT1/view (modified2026-10-06T09:15:08.381Z).
Task33 local implementation log, current RunState, finance ledger, frozen release reviews, Store/price catalog, predevelopment boundary and editor capture inspected. No repository/ancestor AGENTS.md found.
Started on CLEAN main {source['head']} (Bank update). Task29/33 foundation is in this commit. Cached origin/main matches. Independent command `git ls-remote origin refs/heads/main` failed exit1: git: 'remote-https' is not a git command; fatal: remote helper 'https' aborted session. Remote state is not freshly verified. All work here is LOCAL/UNCOMMITTED; no commit or push was performed. .codex-godot-temp untouched. No other overlapping local implementation appeared in inspected thread inventory.

TRACKER DEFINITION AND OWNERSHIP
Mean = sum(frozen release review.development_cycles) / number of valid committed release IDs. Keep exact integer numerator/denominator, individual IDs/cycle samples, display-only float mean, excluded-history count and integer ceiling. An unfinished project, passive navigation, redraw, duplicate registration, scene reconstruction, Contract, campaign or Studio purchase is not another sample. Paid in-project priority/production actions remain included through the existing ProjectState count.
Pre-Development costs one central run cycle outside ProjectState. The average deliberately reports project development cycles; the spending horizon adds one setup cycle for the next game. It does not measure elapsed cycles between releases or include unrelated Studio time.
Derive history from existing immutable metadata, rather than maintain another mutable counter or clock. Duplicate game names still have distinct release IDs. Returned samples are defensive. A new run has no observations. Missing/invalid legacy counts are excluded and flagged; no backfilled fake samples. Overflow returns unavailable. Value reconstruction from release metadata/IDs reproduces the mean; durable saves remain unimplemented.

EXACT SPENDING MODEL (owned_pool_spending_advice_v1)
Let C=current central run cycle; D=ceil(exact average development cycles); P=0 for an initial Primitive purchase/no purchase, otherwise1 for a selected later purchase.
H=D+1+P. Due_count=floor((C+H)/2)-floor(C/2).
Reserve_cents = known cost to play all owned Features once + existing unpaid rent + Due_count*50000.
Cash_after_price = actual current cash cents - selected current purchase price cents.
Warn when Cash_after_price < Reserve_cents, including a one-cent shortfall. Equality does not warn. Actual purchases still use their existing authoritative affordability/settlement path; advice never rejects, delays, charges or confirms an action.
Quote a selected unowned eligible Feature by including it in a temporary pool only. Primitive play pricing calls the existing primitive_feature_hand_cost_cents path; no copied formula. Familiarity uses the current exact Store offer. Owned nodes do not receive another purchase price/cycle. Merely unlocked, unowned Store branches are NOT part of the play budget. Features owned for the next project's supply are the intended meaning of unlocked Features here. Passes are free. Finite exhaustion in a current project does not reduce this NEXT-project budget.
Later Store Features still have play cost TBD. Count and label them, but do not invent prices or pretend the known-cost reserve is complete. No released game means no rent horizon: show known play/bill costs and the ongoing $500/month obligation, explicitly unavailable pacing, never '$0 rent'. There is no silently invented14-cycle starting average.
Future/unpaid sales, predicted publisher receipts, loans and hoped-for revenue are not available cash. Advice conservatively reserves gross future outflows, ignoring even genuine future portfolio settlements. Current cash already includes any actual prior settlement. Purchase-cycle rent is included in the horizon; it is not additionally subtracted from cash-after-price. Existing unpaid rent is included once.

UI AND ANALYSIS ACCESS
Store has a compact advisory beneath the owned-pool summary. Selecting a node recalculates its after-purchase quote; dismissing details restores the owned-only budget. Low-reserve text is amber. Hover explains inputs and limitations. The raw cycle average is not a visible player stat. Legal Purchase and existing Back/Close/drag/keyboard navigation remain available.
RunState.get_development_pacing() and get_feature_spending_advice() are narrow read-only APIs. Editor-only Lifespan capture now includes development_pacing, feature_spending_advice and the helper's source hash alongside live cash/cycles/finance/frozen releases. Capture doesn't mutate gameplay. It is not a durable save.

OBSERVED VERIFICATION
Godot4.7.1.stable.official.a13da4feb headless import passed. All {count} verify_*.gd suites passed on final source with {passes} PASS markers; new focused suite has {focused} checks. Zero unexpected script/errors/failures. Known pre-existing negative-fixture scene errors and Windows root-certificate-store warning are classified in final-gate.json. git diff --check exit0.
New fixtures: no history, owned-only supply, selected Feature cost/cycles, locked/invalid quote, failed launch, two distinct releases, exact11/14→12.5 mean and ceiling13, duplicate callbacks, defensive snapshots, phase/Studio independence, reconstruction, missing/invalid provenance, sum/calendar/money overflow, current familiarity discount, undefined play costs, exact arrears, one-cent threshold, passive state conservation, capture data and legal purchase despite warning.
Exact example (SYNTHETIC):13 development cycles plus1 setup; $1,150 known play costs +7*$500 rent +$123.45 existing arrears = $4,773.45 reserve. Spending1 cent from$4,773.46 leaves exactly enough; from$4,773.45 warns. No balance recommendation is inferred from this fixture.
Exact warning fixture (SYNTHETIC): Action owned Primitive play cost$1,360, prior23-cycle development, selected Colored Text$650/1cycle. At C0, H25,12 dues=$6,000; known reserve$7,360 exceeds$5,050 cash after price from a real$5,700 creation fixture. The purchase remains legal and succeeds. This is a calculation test, not a claimed human/automated playthrough or a tuned economic target.
GL compatibility rendered and inspected warning/no-history Store component views at1152x648 and1280x720. Bounds tests cover advice and enabled Purchase; repeated open/close/selection/animation preserves cash/calendar/redraws/ownership/finance/sales. Existing maintained gameplay, retained-candidate, Contract, Store navigation, Review, calendar, monthly-report, finance, credit and trait suites pass. No exported-demo rebuild or human input test is claimed.

REPRODUCTION
From the patch-notes directory:
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B analysis/spending_advice_verify_v1.py
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B analysis/spending_advice_verify_v1.py --render
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B analysis/spending_advice_report_v1.py
Godot engine: C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe.
Each verifier uses --headless --path <project> --script res://scripts/debug/verify_NAME.gd; import uses --headless --path <project> --editor --import. Independent temporary APPDATA/LOCALAPPDATA profiles; exact argv/profile/exit/error markers in command JSONs. Rendering uses --rendering-method gl_compatibility --position -5000,-5000 with the focused script and -- --capture. No gameplay UI transactions are driven by animations.
Evidence: {OUT.as_posix()} (gate/commands/logs/source hashes/fixtures/screenshots), copied to {BUNDLE.as_posix()}.

CHANGED FILES
Modified: scripts/run_state.gd; scripts/ui/feature_store.gd; scripts/ui/feature_store_map.gd; scripts/debug/lifespan_capture.gd.
New: scripts/finance/feature_spending_guidance.gd (+uid); scripts/debug/verify_feature_spending_guidance.gd (+uid); analysis/spending_advice_verify_v1.py; analysis/spending_advice_report_v1.py.
Local TXT: New Data Logs/Patch Notes - Hidden Cycle Tracker and Spending Advice v1.txt. Canonical authority and task statuses were not rewritten for this direct standalone request.

LIMITATIONS / NEXT DESIGN DISCUSSION
This is an advisory reserve for a next project, not a solvency guarantee or a forced pace. Actual play choices, project size/Genre/pool changes, longer development, other paid actions and additional Store/Contract/campaign time can alter cost. The all-released-games mean weights each completed game once; outliers can move it. The full-pool play assumption can overestimate spending when players skip Features, and ignoring later undefined prices can underestimate it. Future portfolio income is intentionally not spendable in this guard, so profitable studios may receive conservative warnings. A first-game fallback, rolling/size-specific averages, income forecasting and a hard guard require a separate decision; none silently introduced.
No new bill producers, payroll, Student Loan effect, borrowing, Fanbase, era nodes, campaign rules, durable persistence or balance changes. No blocker to the requested local tracker/advisory; remote verification and exported/human acceptance remain outside this evidence.

FINAL WORKTREE
{status}
'''
(DEST / 'Patch Notes - Hidden Cycle Tracker and Spending Advice v1.txt').write_text(text, encoding='utf-8')
shutil.copytree(OUT, BUNDLE, dirs_exist_ok=True)
for name in ['analysis/spending_advice_verify_v1.py', 'analysis/spending_advice_report_v1.py', 'scripts/finance/feature_spending_guidance.gd', 'scripts/debug/verify_feature_spending_guidance.gd']:
    target = BUNDLE / 'reproduce' / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / name, target)
print(json.dumps({'suites': count, 'passes': passes, 'focused': focused, 'log': str(DEST / 'Patch Notes - Hidden Cycle Tracker and Spending Advice v1.txt')}))
