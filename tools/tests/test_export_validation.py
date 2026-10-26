"""Reject broken exports even when Godot exits zero or PCK hashes match."""
import hashlib
import importlib.util
import json
from pathlib import Path
import runpy
import shutil
import struct
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
HELPERS = ROOT / 'docs/codex/findings/export-queue-v3'
spec = importlib.util.spec_from_file_location('export_validation', HELPERS / 'export.py')
exporter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(exporter)


class ExportValidationTests(unittest.TestCase):
    def test_private_writable_temp_per_build(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            paths = []
            for name in ['first', 'second']:
                workspace = base / name
                workspace.mkdir()
                env = exporter.isolated_export_environment(workspace)
                self.assertEqual(env['TMP'], env['TEMP'])
                self.assertEqual(env['TMP'], env['TMPDIR'])
                destination = Path(env['TMP']) / 'tmpproject.binary'
                destination.write_bytes(b'ECFG')
                paths.append(destination)
            self.assertNotEqual(*paths)
            self.assertTrue(all(path.read_bytes() == b'ECFG' for path in paths))

    def test_zero_exit_export_error_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary, patch.object(exporter, 'OUT', Path(temporary)):
            result = subprocess.CompletedProcess(['godot'], 0, b'ERROR: Safe save failed.\n', b'')
            with patch.object(exporter.subprocess, 'run', return_value=result):
                with self.assertRaises(RuntimeError):
                    exporter.run('bad', ['godot'], {}, temporary)
            report = json.loads((Path(temporary) / 'bad.command.json').read_text())
            self.assertEqual(report['exit'], 0)
            self.assertEqual(report['errors'], ['ERROR: Safe save failed.'])

    def test_successful_command(self):
        with tempfile.TemporaryDirectory() as temporary, patch.object(exporter, 'OUT', Path(temporary)):
            result = subprocess.CompletedProcess(['godot'], 0, b'Export complete.\n', b'')
            with patch.object(exporter.subprocess, 'run', return_value=result):
                self.assertEqual(exporter.run('good', ['godot'], {}, temporary)['errors'], [])

    def inspect_payload(self, payload):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            (folder / 'demo').mkdir()
            name = b'project.binary\0'
            offset = 40 + 4 + 4 + len(name) + 16 + 16 + 4
            header = struct.pack('<6I2Q', 0x43504447, 4, 4, 7, 1, 2, 0, 40)
            entry = struct.pack('<II', 1, len(name)) + name + struct.pack('<QQ', offset, len(payload))
            entry += hashlib.md5(payload).digest() + struct.pack('<I', 0)
            (folder / 'demo/Patch Notes Demo.pck').write_bytes(header + entry + payload)
            (folder / 'build-manifest.json').write_text(json.dumps({'workspace': str(folder), 'included': {}}))
            shutil.copy2(HELPERS / 'inspect.py', folder / 'inspect.py')
            runpy.run_path(str(folder / 'inspect.py'), run_name='__main__')

    def test_empty_config_rejected_despite_valid_md5(self):
        with self.assertRaisesRegex(AssertionError, 'project.binary header'):
            self.inspect_payload(b'')

    def test_wrong_config_signature_rejected(self):
        with self.assertRaisesRegex(AssertionError, 'project.binary header'):
            self.inspect_payload(b'WRONG123')

    def test_config_header_accepted(self):
        self.inspect_payload(b'ECFG\0\0\0\0')


if __name__ == '__main__':
    unittest.main()
