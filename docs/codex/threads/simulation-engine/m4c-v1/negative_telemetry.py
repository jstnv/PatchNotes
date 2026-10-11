"""Semantic negative fixture: one altered cash sample, no source/save edits."""
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('simulation_runner', ROOT / 'tools/simulate.py')
runner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runner)
GODOT = Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')


def main():
    output = HERE / 'store-negative-telemetry-01'
    output.mkdir(exist_ok=False)
    bundle = HERE / 'store-4417-01'
    config = runner.read_json(HERE / 'store-4417-input.json')
    case = bundle / 'cases' / config['cases'][0]['case_id']
    original = case / 'telemetry.json'
    measured = runner.read_json(original)
    before = measured['samples'][1]['cash_cents']
    measured['samples'][1]['cash_cents'] = str(int(before) + 1)
    bad = output / 'telemetry-one-cent-wrong.json'
    runner.write_json(bad, measured)
    # Use an already imported PRIVATE replay snapshot and a new private profile.
    # Direct CLI deliberately reaches semantic checking past Python hash fences.
    project = HERE / 'store-4417-research_now-replay-01/project'
    manifest = runner.source_hashes(project)
    environment = runner.isolated_environment(output / 'profile')
    command = [str(GODOT), '--headless', '--path', str(project), '--script', 'res://scripts/debug/campaign_replay_cli.gd', '--', '--case=' + str(case / 'case.variant.json'), '--tape=' + str(case / 'replay.tape.json'), '--telemetry=' + str(bad), '--output=' + str(output / 'replay-report.json')]
    caught = ''
    try:
        runner.run_process('negative-telemetry', command, output, environment, 240)
    except RuntimeError as error:
        caught = str(error)
    runner.check_snapshot(project, manifest)
    result = runner.read_json(output / 'replay-report.json')
    command_result = runner.read_json(output / 'negative-telemetry.command.json')
    assert command_result['exit'] == 1 and not command_result['errors'], command_result
    assert result['ok'] is False and result['telemetry_verified'] is False
    assert result['error'] == 'Telemetry sample differs at step 1', result
    assert runner.sha(original) == runner.read_json(case / 'result.json')['telemetry_sha256']
    audit = {'ok': True, 'expected_exit': 1, 'actual_exit': command_result['exit'], 'expected_error': result['error'], 'caught_expected_failure': caught, 'mutated_sample': 1, 'field': 'cash_cents', 'original_value': before, 'altered_value': measured['samples'][1]['cash_cents'], 'unchanged_sample_state_digest': measured['samples'][1]['state_digest'], 'original_telemetry_sha256': runner.sha(original), 'negative_telemetry_sha256': runner.sha(bad), 'original_bundle_unchanged': True, 'private_source_unchanged': True, 'scope': 'Direct frozen-project CLI intentionally bypasses artifact hash validation only for this negative fixture, so semantic replay must detect the incorrect value.'}
    runner.write_json(output / 'negative-audit.json', audit)
    print(json.dumps(audit, indent=2))


if __name__ == '__main__':
    main()
