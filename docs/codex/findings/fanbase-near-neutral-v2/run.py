"""One predeclared Fanbase route; only disposable analysis scripts are changed."""
from pathlib import Path
import gzip, hashlib, json, os, shutil, subprocess, sys, tempfile

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
OLD = REPO / 'docs/codex/threads/fanbase/near-neutral-v1'
ROOT = Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-near-neutral-v2-20261008')
PROJECT = ROOT / 'patch-notes'
WORK = Path(r'C:/Users/64jus/.codex/worktrees/fanbase-quarter/PatchNotes')
GODOT = r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def git(*args):
    return subprocess.check_output(['git', '-c', 'safe.directory='+str(WORK), '-C', str(WORK), *args])

def replace_once(text, old, new):
    assert text.count(old) == 1, old
    return text.replace(old, new, 1)

def prepare():
    assert not PROJECT.exists(), 'Prepared project already exists; preserve evidence'
    prior = json.loads((OLD / 'source.json').read_text())
    source = Path(prior['project'])
    assert git('rev-parse', 'HEAD').decode().strip() == prior['head']
    for key, value in prior['files'].items():
        assert digest(source / key) == value, key
        if not key.startswith('analysis'):
            assert digest(WORK / 'patch-notes' / key) == value, key
    shutil.copytree(source, PROJECT, ignore=shutil.ignore_patterns('.godot', 'design-logs'))
    path = PROJECT / 'analysis/task29_routes_v1.gd'
    content = path.read_text(encoding='utf-8')
    content = replace_once(content, '[3,3,4] if _arg("--weak=", "none") == "primary" else [3,4,4]', '[4,4,4]')
    path.write_text(content, encoding='utf-8', newline='\n')
    path = PROJECT / 'analysis/task32_routes_v1.gd'
    content = path.read_text(encoding='utf-8')
    content = replace_once(content, 'range(1, 5)', 'range(1, 4)')
    content = replace_once(content, 'if number == 4: break', 'if number == 3:\n\t\t\tawait _earning_followup(game, out)\n\t\t\tbreak')
    content = replace_once(content, '"stop": "four releases"', '"stop": "two Game3 earning boundaries"')
    content += '''

# Ordinary legal Game4 activity, censored immediately after two Game3 boundaries.
func _earning_followup(game: Control, out: Dictionary) -> void:
	var run: RunState = game.run_state
	var launch_cycle := run.get_completed_run_cycles()
	var last_cycle := launch_cycle + (2 if launch_cycle % 2 == 0 else 1) + 2
	if not _begin_game(game, "Matched Store Game 4", specialty_id, out):
		_stop(game, out, "predevelopment", "Game4 departure rejected")
		return
	await process_frame
	var project: ProjectState = game.project_state
	active_project = project
	var phase: DesignPhase = game.get("_active_phase")
	if phase.is_initial_priority_planning():
		phase.get("_deal_rng").seed = declared_seed + 1500003
		phase.get("_finalization_rng").seed = declared_seed + 1500004
		if not phase.get_workspace().overlay.commit_draft():
			_stop(game, out, "design", "Game4 initial priorities rejected")
			return
	while run.get_completed_run_cycles() < last_cycle:
		phase_for_choice = phase
		if not _production_hand(phase, project, run, era_policy, "mixed", "design", 4, out):
			_stop(game, out, "design", "first Game4 rejected hand; censored")
			return
'''
    path.write_text(content, encoding='utf-8', newline='\n')
    path = PROJECT / 'analysis/near_neutral_reconstruction.gd'
    content = (OLD / 'counterfactual.gd').read_text()
    content = replace_once(content, 'for no_loss in [false,true]:', 'for no_loss in [false]:')
    path.write_text(content, encoding='utf-8', newline='\n')
    (PROJECT / 'design-logs/task32-v1').mkdir(parents=True)
    (HERE / 'branch.patch').write_bytes(git('diff'))
    (HERE / 'branch-status.txt').write_bytes(git('status', '--short'))
    paths = [p for folder in ['scripts', 'scenes', 'data', 'analysis'] for p in (PROJECT / folder).rglob('*') if p.is_file()]
    paths += [PROJECT / 'project.godot']
    manifest = dict(head=prior['head'], branch=prior['branch'], project=str(PROJECT), previous_manifest_sha256=digest(OLD / 'source.json'), plan_sha256=digest(HERE / 'PLAN.md'), files={str(p.relative_to(PROJECT)): digest(p) for p in paths})
    (HERE / 'source.json').write_text(json.dumps(manifest, indent=2))
    for name in ['task29_routes_v1.gd', 'task32_routes_v1.gd', 'fanbase_quarter_capture.gd', 'near_neutral_reconstruction.gd']:
        shutil.copy2(PROJECT / 'analysis' / name, HERE / name)
    print('Prepared', len(paths), 'hashed files; route has not run', flush=True)

def run(name, args):
    env = os.environ.copy()
    profile = Path(tempfile.mkdtemp(prefix='profile-', dir=ROOT))
    for key in ['APPDATA', 'LOCALAPPDATA']:
        path = profile / key
        path.mkdir()
        env[key] = str(path)
    cmd = [GODOT, '--headless', '--path', str(PROJECT), *args]
    result = subprocess.run(cmd, env=env, capture_output=True, timeout=240)
    output = result.stdout + result.stderr
    (HERE / (name+'.log')).write_bytes(output)
    errors = [s for s in output.decode(errors='replace').splitlines() if ('ERROR:' in s or 'FAIL:' in s) and 'root certificate store' not in s]
    (HERE / (name+'.command.json')).write_text(json.dumps(dict(command=cmd, profile=str(profile), exit=result.returncode, errors=errors), indent=2))
    print(name, result.returncode, errors, flush=True)
    assert result.returncode == 0 and not errors

for name in sys.argv[1:]:
    if name == 'prepare':
        prepare()
    elif name == 'import':
        run(name, ['--editor', '--import', '--quit'])
    elif name == 'verify_studio_fanbase':
        run(name, ['--script', 'res://scripts/debug/verify_studio_fanbase.gd'])
    elif name == 'attempt':
        # Exclusive marker enforces the one-attempt allowance even on failure.
        with (HERE / 'attempt-started.txt').open('x') as marker:
            marker.write('Exactly one 4/4/4 continuation dispatched; do not rerun.\n')
        run(name, ['--script', 'res://analysis/fanbase_quarter_capture.gd', '--', '--policy=ordinary', '--band=early', '--seed=1104', '--specialty=action', '--contracts=available', '--alignment=0', '--neon=0', '--weak=continuation-v2'])
        raw = (PROJECT / 'design-logs/task32-v1/route_early_ordinary_1104_available_0_0.json').read_bytes()
        (HERE / 'attempt.json.gz').write_bytes(gzip.compress(raw))
        (ROOT / 'attempt.json').write_bytes(raw)
        data = json.loads(raw)
        print(data['valid'], [(x['cycle'], x['final_review']) for x in data['releases']], data['stop'], flush=True)
    elif name == 'reconstruction':
        run(name, ['--script', 'res://analysis/near_neutral_reconstruction.gd', '--', str(ROOT / 'attempt.json'), str(HERE / 'reconstruction.json')])
    else:
        raise ValueError(name)
