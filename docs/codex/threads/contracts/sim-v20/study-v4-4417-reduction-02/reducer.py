"""Reduce a recorded command failure using legal Studio checkpoints only.

Uses the original frozen source, never player saves or current gameplay. This
finds the shortest reproducing Studio suffix, not a globally minimal program.
"""
from __future__ import annotations

import argparse
import datetime as dt
import importlib.util
import math
from pathlib import Path
import shutil
import sys

SPEC = importlib.util.spec_from_file_location('_simulate_reduction', Path(__file__).with_name('simulate.py'))
simulate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(simulate)
REQUIRED = ['campaign_reduce_cli.gd', 'campaign_failure_reducer.gd', 'campaign_invariants.gd']


def prepare(bundle: Path, case_id: str, output: Path) -> tuple[dict, dict]:
    simulate.reject_links(bundle)
    simulate.reject_links(output)
    if not case_id or len(case_id) > 100 or any(char not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-' for char in case_id):
        raise ValueError('Invalid case ID')
    if output.is_relative_to(bundle):
        raise ValueError('Output must be outside the original bundle')
    report = simulate.read_json(bundle / 'run-report.json')
    if report.get('format') != simulate.FORMAT or report.get('mode') != 'run':
        raise ValueError('Expected a retained simulation run bundle')
    manifest = simulate.read_json(bundle / 'snapshot-manifest.json')
    simulate.check_snapshot(bundle / 'project', manifest)
    for name in REQUIRED:
        if not (bundle / 'project/scripts/debug' / name).is_file():
            raise ValueError('Bundle predates reduction support: ' + name + '; preserve it and rerun the declared case with a current simulator')
    case = bundle / 'cases' / case_id
    for name in ['result.json', 'case.variant.json', 'replay.tape.json']:
        simulate.reject_links(case / name)
    previous = simulate.read_json(case / 'result.json')
    if not previous.get('replayable'):
        raise ValueError('Case has no replayable initial state')
    copied = simulate.copy_snapshot(bundle / 'project', output / 'project')
    if copied != manifest:
        raise RuntimeError('Original frozen source changed during copy')
    inputs = output / 'inputs'
    inputs.mkdir()
    for name in ['case.variant.json', 'replay.tape.json', 'result.json']:
        before = simulate.sha(case / name)
        shutil.copy2(case / name, inputs / name)
        if simulate.sha(case / name) != before or simulate.sha(inputs / name) != before:
            raise RuntimeError('Original evidence changed during copy: ' + name)
    return previous, {path.name: simulate.sha(path) for path in inputs.iterdir()}


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument('--bundle', type=Path, required=True)
    result.add_argument('--case', required=True)
    result.add_argument('--kind', choices=['rejection', 'divergence', 'invariant'], required=True)
    result.add_argument('--output', type=Path, required=True)
    result.add_argument('--godot')
    result.add_argument('--timeout', type=float, default=240)
    result.add_argument('--max-commands', type=int, default=1000)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    if not math.isfinite(args.timeout) or args.timeout <= 0 or not 1 <= args.max_commands <= 10000:
        raise ValueError('Finite positive timeout and command bound 1..10000 required')
    simulate.reject_links(args.bundle)
    simulate.reject_links(args.output)
    bundle, output = args.bundle.resolve(), args.output.resolve()
    report = {'format': 'patch-notes-failure-reduction-v1', 'ok': False, 'bundle': str(bundle),
              'case': args.case, 'kind': args.kind, 'created_utc': dt.datetime.now(dt.timezone.utc).isoformat(),
              'tool_sha256': simulate.sha(Path(__file__)), 'runner_sha256': simulate.sha(Path(__file__).with_name('simulate.py'))}
    created = False
    try:
        if output.is_relative_to(bundle) or output.is_relative_to((simulate.ROOT / 'patch-notes').resolve()):
            raise ValueError('Output must be outside original evidence and the canonical project')
        output.mkdir(parents=True, exist_ok=False)
        created = True
        (output / '.gdignore').touch()
        previous, hashes = prepare(bundle, args.case, output)
        report.update(input_hashes=hashes, original_status=previous.get('status'))
        shutil.copy2(Path(__file__), output / 'reducer.py')
        shutil.copy2(Path(__file__).with_name('simulate.py'), output / 'runner.py')
        environment = simulate.isolated_environment(output / 'profile')
        godot = simulate.resolve_godot(args.godot)
        report['godot_sha256'] = simulate.sha(godot)
        project = output / 'project'
        frozen = simulate.import_project(godot, project, output, environment, args.timeout)
        command = [str(godot), '--headless', '--path', str(project), '--script', 'res://scripts/debug/campaign_reduce_cli.gd', '--']
        shared = ['--kind=' + args.kind, '--max-commands=' + str(args.max_commands)]
        try:
            simulate.run_process('reduce', command + shared + ['--case=' + str(output / 'inputs/case.variant.json'), '--tape=' + str(output / 'inputs/replay.tape.json'), '--result=' + str(output / 'inputs/result.json'), '--output=' + str(output / 'reduced')], output, environment, args.timeout)
            reduced = simulate.read_json(output / 'reduced/reduction.json')
            if not reduced.get('ok'): raise RuntimeError('Failure was not reduced')
            # Reconstruct and reproduce the saved result in another process and
            # profile. No original policy, player save or live session is reused.
            fresh_environment = simulate.isolated_environment(output / 'confirmation-profile')
            simulate.run_process('confirm', command + shared + ['--case=' + str(output / 'reduced/case.variant.json'), '--tape=' + str(output / 'reduced/replay.tape.json'), '--output=' + str(output / 'confirmation')], output, fresh_environment, args.timeout)
            confirmation = simulate.read_json(output / 'confirmation/reduction.json')
            if not confirmation.get('ok') or confirmation.get('signature') != reduced['signature'] or confirmation.get('original_commands') != reduced['reduced_commands']:
                raise RuntimeError('Fresh reduced failure signature differs')
            report.update(ok=True, reduction=reduced, fresh_process_confirmation=True)
        finally:
            simulate.check_snapshot(project, frozen)
    except Exception as error:
        report['ok'] = False
        report['error'] = str(error)
    if created: simulate.write_json(output / 'reduction-run.json', report)
    print(__import__('json').dumps(report, indent=2))
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
