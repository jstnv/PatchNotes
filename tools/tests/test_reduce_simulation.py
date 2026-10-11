import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('reducer', Path(__file__).resolve().parents[1] / 'reduce_simulation.py')
reducer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(reducer)


class ReductionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.bundle = self.root / 'bundle'
        project = self.bundle / 'project'
        project.mkdir(parents=True)
        (project / 'project.godot').write_text('config_version=5')
        debug = project / 'scripts/debug'
        debug.mkdir(parents=True)
        for name in reducer.REQUIRED: (debug / name).write_text('extends RefCounted')
        self.case = self.bundle / 'cases/example'
        self.case.mkdir(parents=True)
        for name, value in [('result.json', {'replayable': True}), ('case.variant.json', {}), ('replay.tape.json', {})]:
            reducer.simulate.write_json(self.case / name, value)
        reducer.simulate.write_json(self.bundle / 'snapshot-manifest.json', reducer.simulate.source_hashes(project))
        reducer.simulate.write_json(self.bundle / 'run-report.json', {'format': reducer.simulate.FORMAT, 'mode': 'run', 'ok': False})

    def tearDown(self): self.temp.cleanup()

    def args(self, output):
        return ['--bundle', str(self.bundle), '--case', 'example', '--kind', 'rejection', '--output', str(output)]

    def test_existing_destination_untouched(self):
        output = self.root / 'existing'
        (output / 'inputs').mkdir(parents=True)
        (output / '.gdignore').touch()
        (output / 'sentinel').write_bytes(b'original')
        before = {str(p): p.read_bytes() for p in output.rglob('*') if p.is_file()}
        self.assertEqual(reducer.main(self.args(output)), 1)
        self.assertEqual(before, {str(p): p.read_bytes() for p in output.rglob('*') if p.is_file()})

    def test_output_within_bundle_never_created(self):
        output = self.bundle / 'nested'
        self.assertEqual(reducer.main(self.args(output)), 1)
        self.assertFalse(output.exists())

    def test_linked_input_output_rejected_before_resolution(self):
        output = self.root / 'new'
        for linked in [self.bundle, output.parent]:
            with self.subTest(linked=linked), patch.object(Path, 'is_symlink', lambda path: path == linked):
                with self.assertRaisesRegex(ValueError, 'Linked'):
                    reducer.main(self.args(output))
            self.assertFalse(output.exists())

    def test_linked_tape_rejected_before_copy(self):
        output = self.root / 'new'
        linked = self.case / 'replay.tape.json'
        with patch.object(Path, 'is_symlink', lambda path: path == linked):
            with self.assertRaisesRegex(ValueError, 'Linked'):
                reducer.prepare(self.bundle, 'example', output)
        self.assertFalse(output.exists())

    def test_snapshot_and_artifacts_copied_without_changes(self):
        output = self.root / 'new'; output.mkdir()
        previous, hashes = reducer.prepare(self.bundle, 'example', output)
        self.assertTrue(previous['replayable'])
        self.assertEqual(len(hashes), 3)
        self.assertEqual(reducer.simulate.source_hashes(output / 'project'), reducer.simulate.source_hashes(self.bundle / 'project'))

    def test_source_tampering_rejected(self):
        (self.bundle / 'project/project.godot').write_text('changed')
        with self.assertRaisesRegex(RuntimeError, 'snapshot'): reducer.prepare(self.bundle, 'example', self.root / 'new')

    def test_old_bundle_reports_missing_support(self):
        path = self.bundle / 'project/scripts/debug/campaign_reduce_cli.gd'
        path.unlink()
        reducer.simulate.write_json(self.bundle / 'snapshot-manifest.json', reducer.simulate.source_hashes(self.bundle / 'project'))
        with self.assertRaisesRegex(ValueError, 'predates'): reducer.prepare(self.bundle, 'example', self.root / 'new')

    def test_nonreplayable_case_rejected(self):
        reducer.simulate.write_json(self.case / 'result.json', {'replayable': False})
        with self.assertRaisesRegex(ValueError, 'replayable'): reducer.prepare(self.bundle, 'example', self.root / 'new')

    def test_invalid_case_and_bounds_rejected(self):
        with self.assertRaisesRegex(ValueError, 'case ID'): reducer.prepare(self.bundle, '../escape', self.root / 'new')
        with self.assertRaisesRegex(ValueError, 'bound'): reducer.main(self.args(self.root / 'new') + ['--max-commands', '0'])

    def test_artifact_edit_during_copy_rejected(self):
        original = reducer.shutil.copy2
        def copy(source, destination):
            result = original(source, destination)
            if Path(source).name == 'replay.tape.json': Path(source).write_text('changed')
            return result
        output = self.root / 'new'; output.mkdir()
        with patch.object(reducer.shutil, 'copy2', side_effect=copy):
            with self.assertRaisesRegex(RuntimeError, 'evidence changed'): reducer.prepare(self.bundle, 'example', output)


if __name__ == '__main__': unittest.main()
