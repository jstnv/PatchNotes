"""Standard-library isolation/provenance checks; no Godot or player saves."""
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("simulate", Path(__file__).resolve().parents[1] / "simulate.py")
simulate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(simulate)


class SimulatorRunnerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.project = self.root / "source"
        self.project.mkdir()
        (self.project / "project.godot").write_text("config_version=5\n", encoding="utf-8")
        for name in ("scripts/rule.gd", "data/cards.json", "assets/font.ttf.import", ".godot/cache.bin", ".codex-godot-temp/keep.gd", "design-logs/keep.md", "analysis/keep.gd"):
            path = self.project / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("retained source", encoding="utf-8")

    def tearDown(self):
        self.temporary.cleanup()

    def test_snapshot_excludes_cache_analysis_and_preserves_import_settings(self):
        manifest = simulate.copy_snapshot(self.project, self.root / "copy")
        self.assertEqual(set(manifest), {"project.godot", "scripts/rule.gd", "data/cards.json", "assets/font.ttf.import"})
        self.assertTrue((self.project / ".codex-godot-temp/keep.gd").is_file())
        simulate.check_snapshot(self.root / "copy", manifest)

    def test_snapshot_detects_concurrent_source_edit(self):
        original = simulate.shutil.copy2
        def copy_then_edit(source, target):
            result = original(source, target)
            Path(source).write_text("another thread edited", encoding="utf-8")
            return result
        with patch.object(simulate.shutil, "copy2", side_effect=copy_then_edit):
            with self.assertRaisesRegex(RuntimeError, "Source changed"):
                simulate.copy_snapshot(self.project, self.root / "copy")

    def test_snapshot_detects_missing_or_added_source(self):
        manifest = simulate.source_hashes(self.project)
        (self.project / "scripts/new.gd").write_text("extends RefCounted", encoding="utf-8")
        with self.assertRaises(RuntimeError):
            simulate.check_snapshot(self.project, manifest)

    def test_destinations_are_exclusive(self):
        simulate.copy_snapshot(self.project, self.root / "copy")
        with self.assertRaises(FileExistsError):
            simulate.copy_snapshot(self.project, self.root / "copy")

    def test_profile_isolated_and_old_experiment_environment_removed(self):
        with patch.dict(os.environ, {"PN_CAMPAIGN_RECIPE": "old-player-recipe", "APPDATA": "real-player"}):
            environment = simulate.isolated_environment(self.root / "profile")
        self.assertNotIn("PN_CAMPAIGN_RECIPE", environment)
        for key in ("APPDATA", "LOCALAPPDATA", "HOME", "USERPROFILE", "XDG_DATA_HOME", "TMP"):
            self.assertTrue(Path(environment[key]).is_relative_to(self.root / "profile"))
            self.assertTrue(Path(environment[key]).is_dir())
        second = simulate.isolated_environment(self.root / "second")
        self.assertNotEqual(environment["APPDATA"], second["APPDATA"])

    def config(self, policy_script="res://scripts/rule.gd"):
        return {"schema_version": "1", "policy": {"script": policy_script, "id": "explicit-test", "version": "1"}, "cases": [{"case_id": "example", "policy": {"config": {"setting": 7}}}]}

    def materialize(self, config):
        path = self.root / "experiment.json"
        simulate.write_json(path, config)
        return simulate.materialize_experiment(path, self.project, self.root / "inputs")

    def test_policy_identity_is_actual_snapshot_hash(self):
        config = self.materialize(self.config())
        self.assertEqual(config["policy"]["source_identity"], simulate.sha(self.project / "scripts/rule.gd"))
        self.assertEqual(config["cases"][0]["policy"]["source_identity"], config["policy"]["source_identity"])

    def test_policy_declared_wrong_hash_rejected(self):
        config = self.config()
        config["cases"][0]["policy"]["source_identity"] = "wrong"
        with self.assertRaisesRegex(ValueError, "hash"):
            self.materialize(config)

    def test_policy_not_selected_implicitly(self):
        with self.assertRaises(ValueError):
            self.materialize({"schema_version": "1", "cases": []})

    def test_external_policy_copied_only_into_frozen_debug_folder(self):
        policy = self.root / "my-policy.gd"
        policy.write_text("extends RefCounted\n", encoding="utf-8")
        config = self.materialize(self.config("my-policy.gd"))
        self.assertEqual(config["policy"]["script"], "res://scripts/debug/experiment_policy/supplied_policy.gd")
        self.assertEqual(simulate.sha(policy), simulate.sha(self.project / config["policy"]["script"][6:]))

    def test_unsafe_resource_paths_rejected(self):
        for value in ("../secret", "a/../b", "C:/secret", "/absolute", "a\\b", "./file"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                simulate.safe_relative(value)

    def test_nonfinite_json_rejected(self):
        path = self.root / "bad.json"
        path.write_text('{"number":NaN}', encoding="utf-8")
        with self.assertRaises(ValueError):
            simulate.read_json(path)

    def test_timeout_preserves_command_and_log(self):
        output = self.root / "timed-out"
        output.mkdir()
        with self.assertRaisesRegex(RuntimeError, "timeout"):
            simulate.run_process("timeout", [sys.executable, "-u", "-c", "import time; print('before timeout', flush=True); time.sleep(5)"], output, os.environ.copy(), 0.3)
        self.assertEqual(json.loads((output / "timeout.command.json").read_text())["exit"], "timeout")
        self.assertIn("before timeout", (output / "timeout.log").read_text())

    def test_nonzero_exit_and_runtime_errors_are_retained(self):
        output = self.root / "failed"
        output.mkdir()
        with self.assertRaises(RuntimeError):
            simulate.run_process("bad", [sys.executable, "-c", "print('SCRIPT ERROR: fixture'); exit(0)"], output, os.environ.copy(), 3)
        self.assertEqual(json.loads((output / "bad.command.json").read_text())["errors"], ["SCRIPT ERROR: fixture"])

    def test_output_within_source_rejected_before_creation(self):
        with self.assertRaises(ValueError):
            simulate.main(["run", "--repo", str(self.root), "--config", "missing.json", "--output", str(self.root / "patch-notes/unsafe")])
        self.assertFalse((self.root / "patch-notes/unsafe").exists())


if __name__ == "__main__":
    unittest.main()
