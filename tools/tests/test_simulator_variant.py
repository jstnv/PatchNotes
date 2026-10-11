"""Candidate isolation, ancestry, drift and adoption evidence checks; no Godot."""
import argparse
import importlib.util
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import zipfile

SPEC = importlib.util.spec_from_file_location("simulator_variant", Path(__file__).resolve().parents[1] / "simulator_variant.py")
variant = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(variant)
sim = variant.sim


class VariantTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.repo = self.root / "repo"
        self.project = self.repo / "patch-notes"
        self.project.mkdir(parents=True)
        for name, content in {"project.godot": "config_version=5\n", "scripts/rule.gd": "const VALUE = 1\n", "data/cards.json": "{}\n", "assets/pixel.png": b"\x00\xff\x00", ".codex-godot-temp/retained.gd": "keep", ".godot/cache.bin": "cache"}.items():
            target = self.project / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content if isinstance(content, bytes) else content.encode())
        self.original = sim.source_hashes(self.project)

    def tearDown(self):
        self.temporary.cleanup()

    def create(self, name="thread-v1", parent=None):
        output = self.root / name
        variant.create(argparse.Namespace(repo=self.repo, output=output, id=name, owner="design-thread", from_variant=parent))
        return output

    def edit(self, path):
        (path / "project/scripts/rule.gd").write_text("const VALUE = 2\n", encoding="utf-8")

    def fake_bundle(self, path, name="bundle", ok=True):
        output = self.root / name
        output.mkdir()
        hashes, record = variant.freeze_for_run(path, self.project, output / "project", output)
        sim.write_json(output / "workspace-source-manifest.json", hashes)
        sim.write_json(output / "snapshot-manifest.json", hashes)
        sim.write_json(output / "run-report.json", {"mode": "run", "ok": ok, "variant": record})
        return output

    def handoff(self, path, bundle, name="handoff"):
        output = self.root / name
        decision = self.root / "decision.md"
        decision.write_text("Constructed tooling fixture only; not design approval.\n", encoding="utf-8")
        result = variant.handoff(argparse.Namespace(repo=self.repo, output=output, variant=path, evidence=[bundle], design_record=decision, summary="Fixture changes for review", acceptance=["Replay fixture route"]))
        return output, result

    def test_creation_isolated_and_canonical_temp_preserved(self):
        path = self.create()
        metadata, base, current, _ = variant.load_variant(path)
        self.assertEqual(self.original, base)
        self.assertEqual(base, current)
        self.assertEqual(metadata["status"], "CANDIDATE")
        self.assertTrue((path / ".gdignore").exists())
        self.assertFalse((path / "project/.codex-godot-temp").exists())
        self.assertTrue((self.project / ".codex-godot-temp/retained.gd").exists())
        self.edit(path)
        self.assertEqual(sim.source_hashes(self.project), self.original)
        self.assertNotEqual(variant.load_variant(path)[2], self.original)

    def test_no_existing_output_overwrite(self):
        self.create()
        with self.assertRaises(FileExistsError):
            self.create()

    def test_output_inside_canonical_or_parent_rejected(self):
        with self.assertRaises(ValueError):
            variant.create(argparse.Namespace(repo=self.repo, output=self.project / "new", id="safe", owner="x", from_variant=None))
        parent = self.create()
        with self.assertRaises(ValueError):
            variant.create(argparse.Namespace(repo=self.repo, output=parent / "new", id="safe", owner="x", from_variant=parent))

    def test_fork_keeps_original_base_and_current_parent_revision(self):
        parent = self.create()
        self.edit(parent)
        child = self.create("thread-v2", parent)
        metadata, base, current, _ = variant.load_variant(child)
        self.assertEqual(base, self.original)
        self.assertEqual(current, variant.load_variant(parent)[2])
        self.assertEqual(metadata["lineage"][0]["id"], "thread-v1")
        self.assertEqual(metadata["creation_identity"], variant.identity(current))
        self.assertNotEqual(metadata["creation_identity"], metadata["base_identity"])

    def test_fork_new_id_required(self):
        parent = self.create()
        with self.assertRaisesRegex(ValueError, "new id"):
            variant.create(argparse.Namespace(repo=self.repo, output=self.root / "other", id="thread-v1", owner="x", from_variant=parent))

    def test_metadata_edit_rejected(self):
        path = self.create()
        (path / "variant.json").write_text("{}", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Protected"):
            variant.load_variant(path)

    def test_changed_baseline_archive_rejected(self):
        path = self.create()
        with zipfile.ZipFile(path / "base-source.zip", "a") as output:
            output.writestr("injected.gd", "changed")
        with self.assertRaisesRegex(ValueError, "Protected"):
            variant.load_variant(path)

    def test_self_consistent_archive_manifest_mismatch_rejected(self):
        path = self.create()
        with zipfile.ZipFile(path / "base-source.zip", "a") as output:
            output.writestr("injected.gd", "changed")
        integrity = sim.read_json(path / "integrity.json")
        integrity["base-source.zip"] = sim.sha(path / "base-source.zip")
        sim.write_json(path / "integrity.json", integrity)
        with self.assertRaisesRegex(ValueError, "inventory"):
            variant.load_variant(path)

    def test_extra_integrity_key_rejected(self):
        path = self.create()
        integrity = sim.read_json(path / "integrity.json")
        integrity["../other"] = "a" * 64
        sim.write_json(path / "integrity.json", integrity)
        with self.assertRaisesRegex(ValueError, "unexpected"):
            variant.load_variant(path)

    def test_invalid_paths_and_case_collisions_rejected(self):
        for name in ("../bad", "data//bad.json", "data/foo. ", "data\\bad.json", "C:/bad"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                variant.valid_manifest({"project.godot": "a" * 64, name: "b" * 64})
        with self.assertRaises(ValueError):
            variant.valid_manifest({"project.godot": "a" * 64, "scripts/Rule.gd": "b" * 64, "scripts/rule.gd": "c" * 64})

    def test_snapshot_records_current_drift_without_changing_candidate(self):
        path = self.create()
        self.edit(path)
        (self.project / "data/cards.json").write_text('{"new":true}', encoding="utf-8")
        output = self.fake_bundle(path)
        record = sim.read_json(output / "variant-provenance.json")
        self.assertTrue(record["baseline_drift"])
        self.assertEqual([item["path"] for item in record["delta"]], ["scripts/rule.gd"])
        self.assertEqual([item["path"] for item in record["canonical_delta"]], ["data/cards.json"])
        self.assertNotEqual(record["candidate_identity"], record["canonical_identity"])

    def test_frozen_run_survives_later_candidate_edits(self):
        path = self.create()
        output = self.fake_bundle(path)
        frozen = sim.source_hashes(output / "project")
        self.edit(path)
        self.assertEqual(sim.source_hashes(output / "project"), frozen)

    def test_concurrent_canonical_change_during_capture_rejected(self):
        path = self.create()
        output = self.root / "run"
        output.mkdir()
        original = sim.copy_snapshot
        def copy_and_edit(source, destination):
            value = original(source, destination)
            (self.project / "scripts/rule.gd").write_text("changed", encoding="utf-8")
            return value
        with patch.object(sim, "copy_snapshot", side_effect=copy_and_edit):
            with self.assertRaisesRegex(RuntimeError, "Canonical source changed"):
                variant.freeze_for_run(path, self.project, output / "project", output)

    def test_handoff_exact_delta_and_no_automatic_adoption(self):
        path = self.create()
        self.edit(path)
        (path / "project/data/cards.json").unlink()
        (path / "project/data/new.json").write_text("[]", encoding="utf-8")
        (path / "project/assets/pixel.png").write_bytes(b"\x00\xfe\x00")
        bundle = self.fake_bundle(path)
        output, result = self.handoff(path, bundle)
        self.assertEqual(result["changes"], 4)
        record = sim.read_json(output / "handoff.json")
        self.assertFalse(record["adopted"])
        self.assertFalse(record["todo_updated"])
        self.assertEqual(record["acceptance"], ["Replay fixture route"])
        self.assertEqual(sim.sha(output / "design-decision.md"), record["design_record"]["sha256"])
        self.assertEqual(sim.source_hashes(self.project), self.original)
        with zipfile.ZipFile(output / "delta-files.zip") as changed:
            self.assertEqual(set(changed.namelist()), {"scripts/rule.gd", "data/new.json", "assets/pixel.png"})
            self.assertEqual(changed.read("assets/pixel.png"), b"\x00\xfe\x00")
        self.assertIn("const VALUE = 2", (output / "source-review.patch").read_text())
        self.assertIn("Binary source changed", (output / "source-review.patch").read_text())
        self.assertEqual(record["evidence"][0]["files"]["run-report.json"], sim.sha(bundle / "run-report.json"))

    def test_stale_evidence_rejected(self):
        path = self.create()
        bundle = self.fake_bundle(path)
        self.edit(path)
        with self.assertRaisesRegex(ValueError, "predates"):
            self.handoff(path, bundle)

    def test_design_record_edit_between_hash_and_copy_rejected(self):
        path = self.create()
        bundle = self.fake_bundle(path)
        original = variant.copy_checked
        def edit_then_copy(source, destination):
            if source.name == "decision.md":
                source.write_text("Changed after the first decision hash", encoding="utf-8")
            return original(source, destination)
        with patch.object(variant, "copy_checked", side_effect=edit_then_copy):
            with self.assertRaisesRegex(RuntimeError, "Design decision changed"):
                self.handoff(path, bundle)

    def test_other_variant_evidence_rejected(self):
        first = self.create()
        other = self.create("other-v1")
        bundle = self.fake_bundle(first)
        with self.assertRaisesRegex(ValueError, "this candidate"):
            self.handoff(other, bundle)

    def test_failed_evidence_retained_honestly(self):
        path = self.create()
        bundle = self.fake_bundle(path, ok=False)
        output, _ = self.handoff(path, bundle)
        self.assertFalse(sim.read_json(output / "handoff.json")["evidence"][0]["ok"])

    def test_handoff_flags_overlap_conflict(self):
        path = self.create()
        self.edit(path)
        bundle = self.fake_bundle(path)
        (self.project / "scripts/rule.gd").write_text("const VALUE = 3\n", encoding="utf-8")
        _, result = self.handoff(path, bundle)
        self.assertTrue(result["baseline_drift"])
        self.assertEqual(result["conflicts"], ["scripts/rule.gd"])

    def test_snapshot_rejects_root_file_and_root_directory_links(self):
        for linked in (self.project / "project.godot", self.project / "scripts"):
            original = Path.is_symlink
            def simulated_link(path):
                return path == linked or original(path)
            with self.subTest(linked=linked), patch.object(Path, "is_symlink", simulated_link):
                with self.assertRaisesRegex(ValueError, "Linked"):
                    sim.source_hashes(self.project)

    def test_runner_accepts_variant_and_rejects_output_inside_it(self):
        path = self.create()
        args = sim.parser().parse_args(["run", "--variant", str(path), "--output", "out", "--config", "in.json"])
        self.assertEqual(args.variant, path)
        with self.assertRaisesRegex(ValueError, "outside the editable variant"):
            sim.main(["run", "--repo", str(self.repo), "--variant", str(path), "--output", str(path / "run"), "--config", "in.json"])

    def test_junction_fallback_for_python_before_312(self):
        with patch.object(Path, "is_junction", None, create=True), patch.object(Path, "is_symlink", return_value=False), patch.object(Path, "lstat", return_value=SimpleNamespace(st_reparse_tag=0xA0000003)):
            with self.assertRaisesRegex(ValueError, "Linked"):
                sim.reject_links(self.project)


if __name__ == "__main__":
    unittest.main()
