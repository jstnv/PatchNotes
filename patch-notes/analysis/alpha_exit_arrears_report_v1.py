"""Verify unchanged economics and archive the bounded Alpha exit repair."""
from pathlib import Path
import gzip
import hashlib
import json
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/alpha-exit-arrears-v1'
DEST = Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')
BUNDLE = DEST / 'Alpha Free Exit Arrears Repair v1'
BUNDLE.mkdir(exist_ok=True)
gate = json.loads((OUT / 'final-gate.json').read_text())
focused = json.loads((OUT / 'focused-gate.json').read_text())
assert gate['passed'] and focused['passed']
before_source = json.loads((OUT / 'source-before.json').read_text())
source = json.loads((OUT / 'source-final.json').read_text())
assert all(hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest for name, digest in source['files'].items())
changed = [name.replace('\\', '/') for name, digest in before_source['files'].items() if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != digest]
assert sorted(changed) == ['scripts/phases/alpha_phase.gd', 'scripts/run_state.gd']
before = json.loads((OUT / 'route-before.json').read_text())
after = json.loads((OUT / 'route-after.json').read_text())
def normalize(value):
    return json.loads(re.sub(r'release_[0-9a-f]{32}', 'RELEASE_ID', json.dumps(value, sort_keys=True)))
assert normalize(before['actions']) == normalize(after['actions'][:len(before['actions'])])
assert normalize(before['finance_observations']) == normalize(after['finance_observations'])
assert not before['discrepancies'] and not after['discrepancies']
assert before['target_observations'][0]['free_exit_allowed'] is False
assert after['target_observations'][0]['free_exit_allowed'] is True
assert after['target_observations'][0]['productive_allowed'] is False
audit = {'action_prefix_equal': True, 'prefix_actions': len(before['actions']),
         'finance_observations_equal': True, 'finance_observations': len(before['finance_observations']),
         'normalization': 'Random release UUID text only; no cash/cycle/scoring fields removed',
         'before': before['target_observations'], 'after': after['target_observations'],
         'changed_existing_files': changed}
(OUT / 'paired-replay-audit.json').write_text(json.dumps(audit, indent=2), encoding='utf-8')
assert subprocess.run(['git', 'diff', '--check'], cwd=ROOT, capture_output=True).returncode == 0
status = subprocess.check_output(['git', 'status', '--short'], cwd=ROOT).decode()
(OUT / 'final-status.txt').write_text(status, encoding='utf-8')
(OUT / 'implementation.patch').write_bytes(subprocess.check_output(['git', 'diff'], cwd=ROOT))
count = len(gate['results']) - 1
passes = sum(r['assertion_passes'] for r in gate['results'])
regression_checks = next(r['assertion_passes'] for r in gate['results'] if r['name'] == 'verify_alpha_exit_arrears')
text = f'''PATCH NOTES — ALPHA FREE EXIT / ARREARS REPAIR v1
STATUS: COMPLETE locally, verified. No rent, sales, Store price, card effect or balance changes.

SOURCE
main {source['head']} (Hidden avg cycle), initially clean status/diff. Prior hidden-cycle tracker, Store, finance, traits, animations and retained candidates are committed in this baseline and preserved byte-for-byte. No repository/ancestor AGENTS.md found. .codex-godot-temp untouched. The only existing runtime files changed are scripts/phases/alpha_phase.gd and scripts/run_state.gd; source-before/final SHA256 manifests and an explicit unchanged-file audit confirm all other existing scripts/scenes/data remain unchanged.
Cached origin/main matches HEAD. Fresh `git ls-remote origin refs/heads/main` failed exit1: git: 'remote-https' is not a git command; fatal: remote helper 'https' aborted session. No independently verified new remote state; no commit/push performed. This repair, regression and evidence tools remain LOCAL/UNCOMMITTED.

AUTHORITY
Direct user instruction: reproduce cycle28 with $141.61 overdue rent, fix only the free Alpha-to-Beta guard, preserve productive rent checks and validity/Feature-work/overflow guards, run affected/full suites, log and update queue.
Live To Do List (modified2026-10-06T10:57:08.131Z) read before changes: https://docs.google.com/document/d/1n6o5g8Gj_sDTs5Ku6PLM37OWPPyLpDM_ASfNiD9MRkY/edit . Its OPEN integration defect under the retained-pool Store findings and Task29 follow-up name this exact reproduction.
Cumulative authority §§68–69 and existing free phase-transition rules inspected: https://drive.google.com/file/d/1kmlzNwRbckS9OxucMd5WPYNOF2Dx6QT1/view . Retained Pool Feature Store Rebaseline v1 log/probe and current finance/phase/transition code inspected. $500 rent and all sales coefficients retained.

REPRODUCED FAILURE
Existing historical route: Adventure, ordinary visible-choice policy, seed1104, early first release, Background Music analysis arm. On unmodified runtime at the source HEAD: cycle28, cash0 cents, rent unpaid14161 cents, valid pool/history/positive finite Feature work, Alpha unfinalized. Productive preflight false; free Alpha exit false. One release reached; phase transition rejected.
The historical harness predates trait creation. Its adapter explicitly uses the supported legacy $5,500 no-trait fixture instead of granting the new $200 unused-point receipt. Background Music remains a process-local unapproved trial card in the existing read-only harness; no playable ledger/card changes. This is the exact historical economic case, not a claim that Background Music ships or that every current Start Game uses $5,500 total funding.
The initial probe adapter missed its own observation point (exit1), while its trace already showed the exact arrears state. Observation was moved to the stable post-action/state snapshot. The reproducible before/after runs both then exit0 with matched=true and zero accounting discrepancies. This instrumentation changes no decisions/RNG/cash/cards.

BOUNDED REPAIR
Alpha _can_proceed_to_beta now asks RunState.can_transition_without_productive_cycle rather than can_advance_calendar_cycle (which delegates to paid-cycle preflight).
The new query validates present run state: no productive/publishing/purchase transaction in progress, no pending Contract completion, valid nonnegative central calendar below overflow, valid redraw bank/nonnegative cash, valid existing released-sales identities/provenance, and current finance ledger consistent with cash/calendar. It neither forecasts a productive cycle nor services arrears/earns sales/settles cash.
Existing Alpha guards remain: active phase, non-null ProjectState, project cycle capacity, not finalized, valid candidate pool and Feature history, positive finite Feature work, input unblocked. Finalization still validates rolls and bug-addition overflow. Under-Scope confirmation/cancellation and Gameplay's source-scene/in-flight/one-shot replacement checks are untouched.
Actual hands, Host Playtest, changed priorities, Store actions and central productive transactions retain the original rent-aware preflight. Future hypothetical sales settlement is deliberately not a prerequisite for a zero-cycle exit. No debt forgiveness, payment, bailout or new clock.

MATCHED REPLAY AFTER FIX
The same cycle28 state now permits the free exit while productive_allowed remains false. Game2 enters Beta, its attempted production is rejected by arrears, and the existing zero-cycle launch succeeds at cycle28: Scope29/30, Review4.3, cash$0, arrears$141.61. Game1 remains cycle12, Scope23, Review3.5, cash$1480. The route then stops at Game3 Pre-Development: a genuine productive action cannot clear overdue rent at that next boundary. No free Wait, injected compensation or expanded repair bypasses that block.
All {len(before['actions'])} actions in the pre-repair prefix match exactly after normalization of random release UUIDs only. All {len(before['finance_observations'])} financial observations match. Each route records16 ledger and72 monthly-row reconciliation checks with zero discrepancies. This demonstrates that the fix changes free-transition reachability, not the preceding economy. Full before/after draws, purchases, hands, releases, finance and stop records are retained.

VERIFICATION
Godot4.7.1.stable.official.a13da4feb headless editor import exit0.
Affected gate: {len(focused['results'])-1} suites passed (Alpha arrears, Alpha finalization, Alpha phase, Gameplay transitions, zero-work release, finance integration, run calendar/Studio, sales earning/settlement, plus the import).
Final maintained gate: all {count} discovered verify_*.gd suites passed, {passes} PASS markers. New verify_alpha_exit_arrears has {regression_checks} checks. All exits0 and no unexpected error/script/failure markers. Expected pre-existing scene-instantiation negative fixtures and Windows root-certificate-store warning are classified in gate JSON. Historical replay also emits known missing-artwork warnings; no media changed.
Regression creates an explicitly synthetic exact-cent fixture through the real finance journal: $5,500 legacy base + recorded$1,358.39 test receipt = $6,858.39;14 real monthly rent dues produce $141.61 unpaid at cycle28. This fixture is not a claimed played route. It exercises live Alpha/Beta/Studio scenes, repeated preflight, under-Scope confirmation/cancel, genuine finite Feature-work guard, malformed pool/history, invalid clocks/redraw/sales/journal state, in-flight callbacks, project/calendar/bug overflow, invalid finalization rolls, rejected actual Alpha/Beta hands, playtest/priority rejection, stale callback idempotence and free launch. No-cash/no-calendar/no-journal/no-sales mutation is checked around the free exit; existing redraw-on-phase-entry behavior remains unchanged.
git diff --check exit0. Source hash guard permits only the two named existing runtime changes. Full maintained suites include hidden spending advice, Store, Contracts, finance/credit, retained candidates, card motion, tutorial, Review and lifespan/report coverage. No exported executable or human graphical acceptance is claimed or required for this bounded repair.

COMMANDS
From repository root:
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B patch-notes/analysis/alpha_exit_arrears_verify_v1.py --route before
(The before command ran against unmodified {source['head']} runtime with only the added reproduction harness; on repaired runtime its expected-failure assertion intentionally no longer holds.)
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B patch-notes/analysis/alpha_exit_arrears_verify_v1.py --route after
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B patch-notes/analysis/alpha_exit_arrears_verify_v1.py verify_alpha_exit_arrears verify_alpha_finalization verify_alpha_phase verify_gameplay_transition verify_zero_work_release verify_studio_finance_integration verify_run_calendar_and_studio_entry verify_sales_earning_and_settlement
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B patch-notes/analysis/alpha_exit_arrears_verify_v1.py
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B patch-notes/analysis/alpha_exit_arrears_report_v1.py
git diff --check
Each suite: Godot console --headless --path <patch-notes> --script res://scripts/debug/verify_NAME.gd; editor import adds --editor --import. Routes use res://analysis/alpha_exit_arrears_route_v1.gd -- --stage=before/after. Exact engine path, argv, isolated APPDATA/LOCALAPPDATA profiles, exits and errors are in *.command.json. Gate scripts discover all maintained suites automatically.

FILES / EVIDENCE
Modified runtime: scripts/phases/alpha_phase.gd; scripts/run_state.gd.
New: scripts/debug/verify_alpha_exit_arrears.gd (+uid); analysis/alpha_exit_arrears_route_v1.gd (+uid); analysis/alpha_exit_arrears_verify_v1.py; analysis/alpha_exit_arrears_report_v1.py.
Evidence: {OUT.as_posix()}; portable copy (raw route traces gzip-compressed): {BUNDLE.as_posix()}.
Versioned TXT: New Data Logs/Patch Notes - Alpha Free Exit Arrears Repair v1.txt.
Queue update closes the two named free-Alpha-exit defect references with this evidence; older broad Store balance findings remain historical and are not silently rebaselined by one repaired replay. Canonical authority not changed. Google Docs advisory trusted-read bridge rejected the valid Windows C:/ workspace path as non-absolute; native full-document/revision reads and narrow verified writes used instead. This advisory does not require user approval or block edits.

REMAINING BOUNDARIES
No remaining blocker for this requested repair. The reproduced post-release Game3 funding stop is still enforced and is not a new insolvency policy. Broad read-only Store rebaseline, loan design, missing media, durable saves and exported interactive smoke remain separate tasks. No balance change or proposed card approval.

FINAL LOCAL STATUS
{status}
'''
path = DEST / 'Patch Notes - Alpha Free Exit Arrears Repair v1.txt'
path.write_text(text, encoding='utf-8')
for file in OUT.iterdir():
    if not file.is_file(): continue
    if file.name in ['route-before.json', 'route-after.json']:
        (BUNDLE / (file.name + '.gz')).write_bytes(gzip.compress(file.read_bytes(), mtime=0))
    else: shutil.copy2(file, BUNDLE / file.name)
for name in ['analysis/alpha_exit_arrears_route_v1.gd','analysis/alpha_exit_arrears_verify_v1.py','analysis/alpha_exit_arrears_report_v1.py','scripts/debug/verify_alpha_exit_arrears.gd']:
    target = BUNDLE / 'reproduce' / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / name, target)
print(json.dumps({'log': str(path), 'suites': count, 'passes': passes, 'regression_checks': regression_checks, 'changed_existing': changed}))
