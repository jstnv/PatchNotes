"""Source-fenced maintained checks with separate profiles and one paired Continue."""
import argparse, json, socket, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
import simulate as sim

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--project', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--group', choices=['fresh', 'legacy'], required=True)
    a = p.parse_args()
    a.output = a.output.resolve()
    a.output.mkdir(parents=True, exist_ok=False)
    project = a.project.resolve()
    before = sim.source_hashes(project)
    sim.write_json(a.output / 'source-manifest.json', before)
    godot = sim.resolve_godot('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe')
    names = (['verify_rival_gameplay_activation', 'verify_rival_gameplay_cold_continue'] if a.group == 'fresh' else
             ['verify_market_density_trial', 'verify_market_release_index', 'verify_rival_feature_exhaustion',
              'verify_rival_synergy', 'verify_rival_trial_activation', 'verify_studio_roster_versions',
              'verify_legacy_world', 'verify_market_browser', 'verify_historical_market'])
    results = []
    for name in names:
        folder = a.output / name
        folder.mkdir()
        env = sim.isolated_environment(a.output / 'paired-profile' if a.group == 'fresh' else folder / 'profile')
        with socket.socket() as slot:
            slot.bind(('127.0.0.1', 0))
            env['PN_CHECKPOINT_TEST_PORT'] = str(slot.getsockname()[1])
        env['PN_CARD_FRAME_OUTPUT'] = (folder / 'report.json').as_posix()
        command = [str(godot), '--headless', '--audio-driver', 'Dummy', '--path', str(project),
                   '--script', 'res://scripts/debug/' + name + '.gd', '--quit-after', '100000']
        code = None
        try:
            with (folder / 'godot.log').open('wb') as log:
                code = subprocess.run(command, env=env, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=180).returncode
        except subprocess.TimeoutExpired:
            pass
        lines = (folder / 'godot.log').read_text(encoding='utf-8', errors='replace').splitlines()
        errors = [line for line in lines if line.startswith(('ERROR:', 'SCRIPT ERROR:'))]
        row = {'name': name, 'exit': code, 'ok': code == 0 and not errors, 'errors': errors,
               'argv': command, 'probe_sha256': sim.sha(project / 'scripts/debug' / (name + '.gd')),
               'log_sha256': sim.sha(folder / 'godot.log')}
        results.append(row)
        sim.write_json(folder / 'result.json', row)
        print(json.dumps(row), flush=True)
        if not row['ok'] and a.group == 'fresh':
            break
    sim.check_snapshot(project, before)
    result = {'ok': all(row['ok'] for row in results) and len(results) == len(names),
              'results': results, 'source_unchanged': True, 'runner_sha256': sim.sha(Path(__file__))}
    sim.write_json(a.output / 'result.json', result)
    return 0 if result['ok'] else 1

if __name__ == '__main__':
    sys.exit(main())
