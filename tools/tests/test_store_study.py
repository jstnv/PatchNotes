"""Matched-state and evidence-boundary checks; no Godot, UI or player saves."""
import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location("prepare_store_study", TOOLS / "prepare_store_study.py")
study = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(study)
from simulate import source_hashes, write_json, sha


class StoreStudyTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.bundle = self.root / "prefix"
        self.project = self.bundle / "project"
        self.project.mkdir(parents=True)
        (self.project / "project.godot").write_text("config_version=5\n", encoding="utf-8")
        self.policy = self.project / "scripts/simulation/finite_fixture_policy.gd"
        self.policy.parent.mkdir(parents=True)
        self.policy.write_text("extends RefCounted\n", encoding="utf-8")
        write_json(self.project / "data/feature_store_ledger.json", [{"id": "recorded_sounds", "type": "feature", "phase": "design"}])
        write_json(self.project / "data/card_ledger.json", [{"id": "8_bit_sound", "type": "feature", "phase": "design"}])
        write_json(self.bundle / "snapshot-manifest.json", source_hashes(self.project))
        self.case = self.bundle / "cases/example"
        self.development = {"genre": "action", "theme": "fantasy", "name_prefix": "Fixture", "selection": "visible_order", "hands": {"design": 2, "alpha": 2, "beta": 2}}
        self.checkpoint = {"schema_version": "1", "kind": "campaign_studio", "integrity": "engine-validates", "source_identity": "source", "engine_version": "godot", "rng_algorithm": "pcg", "studio_payload": {"rng": {"seed": "9223372036854775800", "state": "-9123456789123456789"}}, "accepted_sequence": "18"}
        self.result = {"case_id": "example", "ok": True, "status": "completed", "outcome": {"in_studio": True, "research_queue": [], "owned_features": ["8_bit_sound"]}, "artifacts": {"studio_checkpoint": "studio_checkpoint.json"}, "final_release_count": 1, "final_state": "exact-final-state", "source_identity": "source", "engine_version": "godot", "rng_algorithm": "pcg"}
        self.experiment = {"schema_version": "1", "policy": {"script": "res://scripts/simulation/finite_fixture_policy.gd", "id": "finite-development-fixture", "version": "1", "source_identity": sha(self.policy)}, "cases": [{"case_id": "example", "policy": {"config": self.development}}]}
        self.save()

    def tearDown(self):
        self.temporary.cleanup()

    def save(self):
        write_json(self.case / "result.json", self.result)
        write_json(self.case / "studio_checkpoint.json", self.checkpoint)
        write_json(self.bundle / "inputs/experiment.json", self.experiment)
        write_json(self.bundle / "run-report.json", {"input_hashes": {"experiment.json": sha(self.bundle / "inputs/experiment.json")}})

    def prepare(self, **changes):
        values = {"bundle": self.bundle, "case_id": "example", "feature": "recorded_sounds", "target_release_count": 2, "max_commands": 100}
        values.update(changes)
        return study.prepare(**values)

    def test_pair_has_identical_detached_checkpoint_rng_and_explicit_policy(self):
        config = self.prepare()
        first, second = config["cases"]
        self.assertEqual(first["initial"], second["initial"])
        self.assertEqual(first["initial"]["checkpoint"], self.checkpoint)
        self.assertEqual(first["study"]["pair_id"], second["study"]["pair_id"])
        self.assertEqual([item["study"]["arm"] for item in config["cases"]], ["research_now", "defer"])
        for case in config["cases"]:
            self.assertTrue(case["telemetry"])
            self.assertEqual(case["max_commands"], 100)
            self.assertEqual(case["target_release_count"], 2)
            self.assertEqual(case["policy"]["config"]["development"], self.development)
            self.assertEqual(case["policy"]["config"]["feature"], "recorded_sounds")
        first["initial"]["checkpoint"]["studio_payload"]["rng"]["state"] = "changed"
        self.assertEqual(second["initial"]["checkpoint"], self.checkpoint)

    def test_stable_pair_identity_changes_when_horizon_or_policy_changes(self):
        first = self.prepare()
        self.assertEqual(first, self.prepare())
        self.assertNotEqual(first["cases"][0]["study"]["pair_id"], self.prepare(target_release_count=3)["cases"][0]["study"]["pair_id"])
        alternate = copy.deepcopy(self.development)
        alternate["hands"]["beta"] = 3
        changed = self.prepare(development_override=alternate)
        self.assertTrue(changed["cases"][0]["study"]["development_config_overridden"])
        self.assertEqual(changed["cases"][1]["policy"]["config"]["development"], alternate)
        self.assertNotEqual(first["cases"][0]["study"]["pair_id"], changed["cases"][0]["study"]["pair_id"])

    def test_unsafe_ids_and_invalid_bounds_rejected(self):
        for changes in ({"case_id": "../other"}, {"feature": "../feature"}, {"max_commands": 0}, {"target_release_count": 1}, {"target_release_count": True}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.prepare(**changes)

    def test_incomplete_prefix_and_unavailable_checkpoint_rejected(self):
        for field, value in (("ok", False), ("status", "command_bound"), ("final_release_count", 0)):
            original = self.result[field]
            self.result[field] = value
            self.save()
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.prepare()
            self.result[field] = original
        self.result["outcome"]["in_studio"] = False
        self.save()
        with self.assertRaisesRegex(ValueError, "Studio"):
            self.prepare()

    def test_existing_queue_owned_and_unknown_targets_rejected(self):
        for feature in ("8_bit_sound", "nonexistent"):
            with self.subTest(feature=feature), self.assertRaises(ValueError):
                self.prepare(feature=feature)
        self.result["outcome"]["research_queue"] = [{"feature_id": "another"}]
        self.save()
        with self.assertRaisesRegex(ValueError, "empty"):
            self.prepare()

    def test_frozen_source_or_input_tampering_rejected(self):
        self.policy.write_text("changed", encoding="utf-8")
        with self.assertRaisesRegex(RuntimeError, "snapshot"):
            self.prepare()
        self.policy.write_text("extends RefCounted\n", encoding="utf-8")
        self.experiment["cases"][0]["policy"]["config"]["hands"]["alpha"] = 3
        write_json(self.bundle / "inputs/experiment.json", self.experiment)
        with self.assertRaisesRegex(ValueError, "input hash"):
            self.prepare()

    def test_checkpoint_identity_mismatch_rejected_without_rewriting(self):
        self.checkpoint["source_identity"] = "old-source"
        self.save()
        before = (self.case / "studio_checkpoint.json").read_bytes()
        with self.assertRaisesRegex(ValueError, "identities"):
            self.prepare()
        self.assertEqual(before, (self.case / "studio_checkpoint.json").read_bytes())

    def test_unknown_prefix_policy_requires_complete_explicit_override(self):
        self.experiment["policy"]["id"] = "custom-policy"
        self.save()
        with self.assertRaisesRegex(ValueError, "development-config"):
            self.prepare()
        self.prepare(development_override=self.development)
        with self.assertRaisesRegex(ValueError, "Development config"):
            self.prepare(development_override={"hands": {"design": 1}})

    def test_new_output_and_evidence_are_never_overwritten(self):
        output = self.root / "study.json"
        argv = ["--bundle", str(self.bundle), "--case", "example", "--feature", "recorded_sounds", "--target-release-count", "2", "--max-commands", "100", "--output", str(output)]
        self.assertEqual(study.main(argv), 0)
        original = output.read_bytes()
        with self.assertRaises(FileExistsError):
            study.main(argv)
        self.assertEqual(original, output.read_bytes())
        argv[-1] = str(self.bundle / "new-input.json")
        with self.assertRaisesRegex(ValueError, "original evidence"):
            study.main(argv)


if __name__ == "__main__":
    unittest.main()
