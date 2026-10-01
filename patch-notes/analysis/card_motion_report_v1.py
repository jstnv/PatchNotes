"""Save the motion milestone source guard and verified implementation record."""
import datetime
import difflib
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/card-motion-v1'
LOG = Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs/Card_Fan_Hand_Animations_and_Store_Focus_v1.txt')
before = json.loads((OUT / 'initial-source.json').read_text(encoding='utf-8'))
after = {str(f.relative_to(ROOT)).replace('\\', '/'): hashlib.sha256(f.read_bytes()).hexdigest()
         for d in ['scripts', 'scenes', 'data', 'resources'] for f in (ROOT / d).rglob('*') if f.is_file()}
changed = [s for s, h in before.items() if after.get(s) != h]
new = sorted(set(after) - set(before))
allowed = {
    'scripts/cards/card_view.gd', 'scripts/debug/verify_alpha_phase.gd',
    'scripts/debug/verify_beta_finalization_and_launch.gd', 'scripts/debug/verify_design_phase.gd',
    'scripts/debug/verify_feature_store_navigation.gd', 'scripts/debug/verify_feature_store_radial.gd',
    'scripts/debug/verify_shared_redraw_and_priority_adjustment.gd', 'scripts/phases/contract_phase.gd',
    'scripts/phases/design_phase.gd', 'scripts/ui/feature_store.gd', 'scripts/ui/feature_store_map.gd',
    'scripts/ui/gameplay_hud.gd', 'scripts/ui/phase_workspace.gd',
    'scenes/phases/alpha_phase.tscn', 'scenes/phases/beta_phase.tscn', 'scenes/phases/design_phase.tscn',
}
assert set(changed) == allowed
assert set(new) == {p + ext for p in ['scripts/debug/verify_card_motion.gd', 'scripts/ui/card_fan.gd', 'scripts/ui/hand_presentation.gd'] for ext in ['', '.uid']}
guard = dict(changed=changed, new=new, unchanged_count=sum(after.get(s) == h for s, h in before.items()), missing=[s for s in before if s not in after])
assert not guard['missing']
for name, data in [('source-guard.json', guard), ('final-source.json', after)]:
    (OUT / name).write_text(json.dumps(data, indent=2), encoding='utf-8')
patch = []
for name in changed + new:
    a = (OUT / 'before' / name).read_text(encoding='utf-8').splitlines(True) if (OUT / 'before' / name).exists() else []
    b = (ROOT / name).read_text(encoding='utf-8').splitlines(True)
    patch.extend(difflib.unified_diff(a, b, fromfile='before/' + name, tofile='after/' + name))
(OUT / 'task-only.diff').write_text(''.join(patch), encoding='utf-8')

def git(*args):
    return subprocess.run(['git', *args], cwd=ROOT, capture_output=True, text=True, encoding='utf-8')

check = git('diff', '--check')
(OUT / 'diff-check.log').write_text(check.stdout + check.stderr, encoding='utf-8')
assert check.returncode == 0
head = git('rev-parse', 'HEAD').stdout.strip()
branch = git('branch', '--show-current').stdout.strip()
assert head == (OUT / 'initial-head.txt').read_text(encoding='utf-8-sig').strip()
status = git('status', '--short').stdout
(OUT / 'final-status.txt').write_text(status, encoding='utf-8')
checks = json.loads((OUT / 'full-verification.json').read_text(encoding='utf-8'))
render = json.loads((OUT / 'render.command.json').read_text(encoding='utf-8'))
assert len(checks) == 49 and all(x['exit'] == 0 and not x['errors'] for x in checks)
assert render['exit'] == 0 and not render['errors']
motion_passes = sum(s.startswith('PASS:') for s in (OUT / 'verify_card_motion.log').read_text(encoding='utf-8').splitlines())
render_passes = sum(s.startswith('PASS:') for s in (OUT / 'render.log').read_text(encoding='utf-8').splitlines())
commands = '\n'.join(f"{x['name']}: {subprocess.list2cmdline(x['command'])} => exit {x['exit']}; script/parse/FAIL markers: {x['errors']}" for x in checks)
files = '\n'.join('  ' + p for p in changed + new + ['analysis/card_motion_verify_v1.py', 'analysis/card_motion_report_v1.py'])
text = f'''Patch Notes - Card Fan, Hand Animations and Store Focus v1
Recorded: {datetime.datetime.now().astimezone().isoformat()}
Status: IMPLEMENTED AND VERIFIED LOCALLY; uncommitted and not pushed.
Branch: {branch}
HEAD: {head}
Workspace: {ROOT}

REQUEST AND SOURCE BOUNDARY
Direct user request: Store node selection zooms toward the node and opens its menu by sliding right from the border. Seven candidates form a fan; selected cards remain raised. Redraw gathers selected cards at center then slides them right, with other candidates lowered/shrunk. Play gathers the hand and bounces left-to-right; a card starts only after the previous card lands, revealing score gains with +N indicators.
Inspected current branch/HEAD/status/diff and existing Store map, CardView, shared workspace/HUD, Design/Alpha/Beta and Contract lifecycle code before editing. No applicable AGENTS.md was found in the repository/ancestors. The initial worktree was already heavily modified; initial status/diff, exact source hashes and before-copies are preserved under design-logs/card-motion-v1. This direct UI request is the scope authority; it does not approve a balance, ledger, calendar or economics change. No canonical authority or task queue was edited for this milestone.

IMPLEMENTED PRESENTATION
- Store selection animates camera centering/zoom for 0.30 seconds, then slides/fades details right from the node border for 0.20 seconds. The camera reserves right-side menu room even at outer nodes. Rapid selection, dismissal, zoom and pan cancel obsolete transitions. Existing mouse drag, wheel and arrow navigation remain.
- Shared CardFan keeps seven cards visible in an arc. Selected cards rise 48 logical pixels and stay above the fan, including correct mouse hit routing by visible stacking order. Keyboard card activation remains available.
- Design, Alpha, Beta and Contract buttons use a shared HandPresentation. Remaining candidates lower, shrink and dim while the selected hand centers. Redraw then slides the selected cards right. Play raises and lands each card once in visual left-to-right order, independent of selection click order.
- Scoreboard values are held during playback and advanced with gold +N pulses at each bounce. The final display exactly equals the native resolved hand. Scope uses printed card Scope. Beta shows native Marketing Output and found/fixed Bugs; no invented Core gains. Contract scores retain their half-unit precision.
- The presentation receives keyboard focus and blocks duplicate action callbacks while active. Resize/cancellation restores the authoritative scoreboard and visible pool. Contract completion appears after the last bounce.

AUTHORITY AND TRANSACTION SAFETY
Existing gameplay callbacks execute synchronously once. Presentation clones the pre-action cards, calls the existing action, then reads the confirmed state. Animation starts only if the native action advanced its cycle or consumed redraw budget. A rejected action leaves the selection and state intact. The tween never resolves a card, changes cash, advances a cycle, redraws, exhausts a Feature, changes ownership/familiarity, settles sales, pays a contract or publishes a release.
Per-card visual increments apportion the already-confirmed hand gain using cumulative printed contribution. Differences between successive cumulative integer allocations preserve the hand's existing synergy rounding exactly. This is a display allocation, not a new per-card production rule. Quotient/remainder arithmetic avoids multiplying the full gain by weights; the signed-integer-limit fixture passes. QA visual Known Bugs clamp at zero when left-to-right Debug precedes Search, while the underlying native Search-before-Debug transaction remains unchanged.
No changes were made to RunState, ProjectState, CardDatabase, card ledgers, scoring/Review calculators, sales, contract state, publisher gates, or starting specialty rosters in this task. The source guard confirms {guard['unchanged_count']} existing source/data/resource files are byte-identical; no existing source files were removed. All source differences from the task-start snapshot match the listed UI/test files. .codex-godot-temp was not targeted or modified by task commands. Godot import updates normal generated caches.

CHANGED AND ADDED FILES (relative to the project directory)
{files}
Evidence/report output: design-logs/card-motion-v1/ (including before snapshots, task-only.diff, source manifests, command JSON, process logs, animation-traces.json and 12 PNGs).
Standalone local TXT: {LOG}

VERIFICATION RESULTS
PASS: Godot 4.7.1 headless editor import; exit 0.
PASS: all 48 available verify_*.gd scripts, including 47 existing suites plus the new card-motion verifier; exit 0 for every process, no SCRIPT ERROR, Parse Error or FAIL markers.
PASS: new native animation verifier, {motion_passes} assertions headlessly and {render_passes} assertions with the compatibility renderer; zero failures in both.
PASS: 1152x648 and 900x600 fan, centered hand, bounce/+score, redraw exit, Beta and actual Studio Store captures. Images inspected for fit/overlap; focused Store node and menu remain inside the view. Lowered candidates do not obscure the action row/footer.
PASS: actual native mouse events on overlapping fanned cards; selected foreground card receives the click. The other action tests activate native buttons/signals, with deterministic card fixtures for timing and synergy output. Keyboard focus is verified while a hand animates.
PASS: exact paid native Feature hand using seed 240930, named Action Studio ownership and the current priced economy; native seeded pool, one-cent remainder retained, familiarity/exhaustion once. An unaffordable hand changes no cash/cycle/redraw/selection and starts no animation.
PASS: shared redraw cost, repeated callbacks, phase transitions, animation cancellation, Marketing/QA output, two Contract hands, native completion and frozen released Project preservation.
PASS: git diff --check; exit 0. Git reported line-ending normalization notices for existing working copies, not whitespace errors.
Existing suites adapted only where their old HBox/scroll assumptions no longer apply or camera motion needs time to settle. Design/Alpha transactional tests explicitly end the visual presentation before their next synchronous fixture; the dedicated motion verifier tests real timing and repeated callbacks without skipping animations.

COMMANDS
Working directory for all commands: {ROOT}
PowerShell:
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B analysis/card_motion_verify_v1.py --full
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B analysis/card_motion_verify_v1.py --render
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B analysis/card_motion_report_v1.py
git diff --check
The verification runner uses fresh temporary APPDATA/LOCALAPPDATA profiles. Exact native commands and outcomes:
{commands}
Rendered verification: {subprocess.list2cmdline(render['command'])} => exit {render['exit']}; script/parse/FAIL markers: {render['errors']}.

LIMITATIONS AND REMAINING WORK
These are automated native scene/input and rendering checks, not a human playtest or balance simulation. Controlled Pass/QA/Marketing pools isolate visual timing; they do not establish ordinary draw odds. The separate paid-hand fixture uses a seeded native draw and the priced economy. Existing missing-artwork placeholders remain; artwork creation was outside this request. Godot emitted its existing Windows root-certificate-store warning and missing-artwork warnings; the fixtures also emit a nonfatal anchored-Control sizing warning. No network operation or gameplay result depends on these warnings.
The initial paid-hand test incorrectly used the legacy unnamed/free economy; it was corrected to use the current named Studio before claiming cash/exhaustion verification. Initial legacy UI verifier failures were due to HBox casts and instantaneous-camera assertions; corrected tests now pass on final source.
No implementation blocker remains for this animation milestone. Human feedback on motion pace and overlapping-card readability is still useful. All work remains local and uncommitted; no branch, commit, push or deployment was performed.
'''
LOG.write_text(text, encoding='utf-8')
(OUT / LOG.name).write_text(text, encoding='utf-8')
print(json.dumps({'log': str(LOG), 'checks': len(checks), 'motion_assertions': motion_passes, 'render_assertions': render_passes, 'unchanged_sources': guard['unchanged_count'], 'diff_check_exit': check.returncode}))
