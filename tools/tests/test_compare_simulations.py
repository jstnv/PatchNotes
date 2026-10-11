"""Boundary semantics and evidence validation for paired simulation reports."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location("compare_simulations", Path(__file__).resolve().parents[1] / "compare_simulations.py")
compare = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(compare)
simulate = compare.simulate


def digest(value):
    return hashlib.sha256(str(value).encode()).hexdigest()


class ComparisonTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.bundle = self.root / "bundle"
        self.project = self.bundle / "project"
        (self.project / "scripts/debug").mkdir(parents=True)
        (self.project / "project.godot").write_text("config_version=5\n", encoding="utf-8")
        (self.project / "scripts/rules.gd").write_text("extends RefCounted\n", encoding="utf-8")
        (self.project / "scripts/debug/policy.gd").write_text("extends RefCounted\n", encoding="utf-8")
        (self.bundle / "runner.py").write_text("# retained runner", encoding="utf-8")
        self.manifest = simulate.source_hashes(self.project)
        self.source = compare.mechanics_identity(self.manifest)
        self.policy = {"script": "res://scripts/debug/policy.gd", "id": "test", "version": "1", "source_identity": simulate.sha(self.project / "scripts/debug/policy.gd")}
        self.cases = {}
        self.results = {}
        self.telemetry = {}
        for name in ("left", "right"):
            self.cases[name] = {"schema_version": "1", "case_id": name, "initial": {"recipe": {"seed": "9223372036854775800"}}, "max_commands": 4, "target_release_count": 1, "telemetry": True, "study": {"pair_id": "paired-example", "arm": name}, "policy": {**{key: self.policy[key] for key in ("id", "version", "source_identity")}, "config": {"arm": name}}}
            self.telemetry[name] = {"schema_version": "1", "sampling": compare.SAMPLING, "source_identity": self.source, "initial_state": digest("initial"), "final_state": digest(name + "-4"), "samples": self.samples(name)}
            self.results[name] = {"schema_version": "1", "case_id": name, "ok": True, "status": "completed", "error": "", "replayable": True, "source_identity": self.source, "engine_version": "4.7.1-stable (official)", "rng_algorithm": "pcg32", "initial_state": digest("initial"), "final_state": digest(name + "-4"), "initial_rng": {"review": {"state": {"integer": "-9223372036854775807"}}}, "initial_run_cycle": 0, "final_run_cycle": 2 if name == "left" else 3, "initial_release_count": 0, "final_release_count": 1, "commands": 4, "accepted_commands": 4, "max_commands": 4, "target_release_count": 1, "policy": self.cases[name]["policy"], "study": self.cases[name]["study"], "artifacts": {"telemetry": "telemetry.json"}}
        self.save()

    def tearDown(self):
        self.temporary.cleanup()

    def samples(self, name):
        # Same-cycle final command after Launch must not replace the first
        # post-launch sample in the release-milestone comparison.
        cycles = [0, 0, 1, 2, 2] if name == "left" else [0, 0, 2, 3, 3]
        cash = ["10000", "9000", "8000", "12000", "11500"] if name == "left" else ["10000", "10000", "7000", "11000", "10500"]
        rows = []
        for index in range(5):
            released = index >= 3
            row = {"step": index, "sequence": index, "run_cycle": cycles[index], "cash_cents": cash[index], "fans": str(0 if not released else 10 + index), "overdue_cents": "100" if index == 2 else "0", "finance_available": True, "financially_blocked": index == 2, "phase": "studio", "in_studio": True, "release_count": int(released), "releases": [{"id": "release-1", "release_cycle": cycles[3], "review": 4.1 if name == "left" else 4.3}] if released else [], "owned_features": [], "research_queue": [], "command_type": "" if index == 0 else "launch" if index == 3 else "advance", "request": {} if index == 0 else {"type": "launch" if index == 3 else "advance", "payload": {}}, "accepted": None if index == 0 else True, "error": "", "state_digest": digest("initial") if index == 0 else digest(name + "-" + str(index)), "transaction_count": index, "transactions_observed": 0 if index == 0 else 1, "transaction_cash_low_cents": cash[index] if index != 2 else "6000"}
            rows.append(row)
        return rows

    def save(self):
        simulate.write_json(self.bundle / "snapshot-manifest.json", self.manifest)
        simulate.write_json(self.bundle / "inputs/requested.json", {"study": "fixture"})
        config = {"schema_version": "1", "policy": self.policy, "cases": list(self.cases.values())}
        simulate.write_json(self.bundle / "inputs/experiment.json", config)
        for name in self.cases:
            destination = self.bundle / "cases" / name
            simulate.write_json(destination / "case.json", self.cases[name])
            simulate.write_json(destination / "telemetry.json", self.telemetry[name])
            self.results[name]["telemetry_sha256"] = simulate.sha(destination / "telemetry.json")
            simulate.write_json(destination / "result.json", self.results[name])
        simulate.write_json(self.bundle / "experiment-report.json", {"results": list(self.results.values()), "ok": all(row["ok"] for row in self.results.values())})
        report = {"format": simulate.FORMAT, "mode": "run", "ok": all(row["ok"] for row in self.results.values()), "policy": self.policy, "godot_version": "4.7.1.stable.official.fixture", "godot_sha256": digest("binary"), "runner_sha256": simulate.sha(self.bundle / "runner.py"), "frozen_source_identity": hashlib.sha256(json.dumps(self.manifest, sort_keys=True).encode()).hexdigest(), "input_hashes": {name: simulate.sha(self.bundle / "inputs" / name) for name in ("experiment.json", "requested.json")}}
        simulate.write_json(self.bundle / "run-report.json", report)

    def run_report(self):
        return compare.compare(self.bundle, "left", "right")

    def truncate(self, name, count, status):
        samples = self.telemetry[name]["samples"][:count + 1]
        self.telemetry[name]["samples"] = samples
        last = samples[-1]
        self.telemetry[name]["final_state"] = last["state_digest"]
        self.results[name].update(ok=False, status=status, error="bounded test", commands=count, accepted_commands=count, final_state=last["state_digest"], final_run_cycle=last["run_cycle"], final_release_count=last["release_count"])

    def test_calendar_uses_last_zero_cycle_boundary_without_interpolation(self):
        report = self.run_report()
        self.assertEqual([row["run_cycle"] for row in report["matched_calendar"]], [0, 2])
        first, second = report["matched_calendar"]
        self.assertEqual((first["left"]["step"], first["right"]["step"]), (1, 1))
        self.assertEqual((second["left"]["step"], second["right"]["step"]), (4, 2))
        self.assertEqual(second["delta_right_minus_left"]["cash_cents"], "-4500")
        self.assertNotIn("endpoint_delta", report)

    def test_release_uses_first_post_launch_and_decimal_review_delta(self):
        report = self.run_report()
        row = report["matched_release_milestones"][0]
        self.assertEqual((row["left"]["sample"]["step"], row["right"]["sample"]["step"]), (3, 3))
        self.assertEqual(row["left"]["sample"]["cash_cents"], "12000")
        self.assertEqual(row["delta_right_minus_left"]["review"], "0.2")
        self.assertEqual(row["delta_right_minus_left"]["release_cycle"], 1)

    def test_int64_and_cent_values_never_use_float_money(self):
        self.telemetry["left"]["samples"][1]["cash_cents"] = "9223372036854775807"
        self.telemetry["right"]["samples"][1]["cash_cents"] = "9223372036854775806"
        self.save()
        row = self.run_report()["matched_calendar"][0]
        self.assertEqual(row["delta_right_minus_left"]["cash_cents"], "-1")
        self.assertEqual(compare.money("9223372036854775807"), "$92233720368547758.07")
        self.assertEqual(compare.money("-1"), "-$0.01")

    def test_cash_lows_different_ledger_and_boundary_scopes(self):
        left = self.run_report()["left"]
        self.assertEqual(left["command_boundary_cash_low_cents"], "8000")
        self.assertEqual(left["transaction_cash_low_cents"], "6000")
        self.assertEqual(left["first_financially_blocked_sample"]["step"], 2)
        self.assertEqual(left["sampled_arrears_peak"]["overdue_cents"], "100")

    def test_incomplete_malformed_retained_without_inventing_missing_release(self):
        self.truncate("right", 2, "malformed_policy_decision")
        self.save()
        report = self.run_report()
        self.assertFalse(report["overall_run_ok"])
        self.assertFalse(report["both_cases_completed"])
        self.assertTrue(report["right"]["censored"])
        self.assertEqual(report["right"]["rejection_observation"], "none observed")
        self.assertEqual(report["matched_release_milestones"], [])
        self.assertEqual(report["right"]["unreached_release_count"], 1)
        self.assertIn("not evidence of a financial blocker", compare.markdown(report))

    def test_rejected_action_retains_request_and_unchanged_state(self):
        self.truncate("right", 2, "rejected_policy_action")
        samples = self.telemetry["right"]["samples"]
        samples[-1] = copy.deepcopy(samples[-2])
        samples[-1].update(step=2, accepted=False, command_type="research", request={"type": "research", "payload": {"feature_id": "test"}}, error="Insufficient cash")
        self.results["right"].update(accepted_commands=1, final_state=samples[-1]["state_digest"], final_run_cycle=samples[-1]["run_cycle"])
        self.telemetry["right"]["final_state"] = samples[-1]["state_digest"]
        self.save()
        rejected = self.run_report()["right"]["first_rejected_action"]
        self.assertEqual(rejected["request"]["payload"]["feature_id"], "test")
        self.assertEqual(rejected["step"], 2)

    def test_initial_releases_separate_from_new_milestones(self):
        old = {"id": "old", "release_cycle": 0, "review": 5.0}
        for name in self.cases:
            self.cases[name]["target_release_count"] = 2
            self.results[name].update(initial_release_count=1, final_release_count=2, target_release_count=2)
            for sample in self.telemetry[name]["samples"]:
                sample["releases"].insert(0, old)
                sample["release_count"] += 1
        self.save()
        report = self.run_report()
        self.assertEqual(report["initial_common_releases"], [old])
        self.assertEqual([row["release_ordinal"] for row in report["matched_release_milestones"]], [2])

    def test_unavailable_finance_is_null_not_zero(self):
        for name in self.cases:
            for sample in self.telemetry[name]["samples"]:
                sample.update(finance_available=False, overdue_cents=None, transaction_cash_low_cents=None, financially_blocked=None, transaction_count=-1, transactions_observed=0)
        self.save()
        report = self.run_report()
        self.assertIsNone(report["left"]["sampled_arrears_peak"])
        self.assertIsNone(report["matched_calendar"][0]["delta_right_minus_left"]["overdue_cents"])

    def test_pair_mismatch_rejected(self):
        for field, value in (("engine_version", "different"), ("rng_algorithm", "different"), ("initial_rng", {"other": "seed"}), ("max_commands", 5), ("target_release_count", 2)):
            with self.subTest(field=field):
                original = copy.deepcopy(self.results["right"])
                self.results["right"][field] = value
                self.save()
                with self.assertRaises(ValueError):
                    self.run_report()
                self.results["right"] = original

    def test_wrong_pair_or_duplicate_arm_rejected(self):
        for field, value in (("pair_id", "other"), ("arm", "left")):
            with self.subTest(field=field):
                original = self.cases["right"]["study"][field]
                self.cases["right"]["study"][field] = value
                self.save()
                with self.assertRaises(ValueError):
                    self.run_report()
                self.cases["right"]["study"][field] = original

    def test_source_input_telemetry_runner_tampering_rejected(self):
        for relative in ("project/scripts/rules.gd", "inputs/experiment.json", "cases/left/telemetry.json", "runner.py"):
            with self.subTest(path=relative):
                path = self.bundle / relative
                original = path.read_bytes()
                path.write_bytes(original + b" ")
                with self.assertRaises((ValueError, RuntimeError)):
                    self.run_report()
                path.write_bytes(original)

    def test_result_consistency_and_missing_artifact_rejected(self):
        path = self.bundle / "cases/left/result.json"
        value = simulate.read_json(path)
        value["commands"] = 3
        simulate.write_json(path, value)
        with self.assertRaisesRegex(ValueError, "experiment report"):
            self.run_report()
        self.save()
        (self.bundle / "cases/left/telemetry.json").unlink()
        with self.assertRaisesRegex(ValueError, "Missing artifact"):
            self.run_report()

    def test_rehashed_invalid_telemetry_still_rejected(self):
        operations = [lambda row: row.update(step=7), lambda row: row.update(cash_cents=1), lambda row: row.update(cash_cents="9223372036854775808"), lambda row: row.update(release_count=9), lambda row: row.update(state_digest="bad"), lambda row: row.update(request={"type": "other"}), lambda row: row.update(overdue_cents=None)]
        for mutate in operations:
            original = copy.deepcopy(self.telemetry["right"])
            mutate(self.telemetry["right"]["samples"][2])
            self.save()
            with self.assertRaises(ValueError):
                self.run_report()
            self.telemetry["right"] = original

    def test_command_bound_is_censored_at_actual_bound(self):
        for name in self.cases:
            self.cases[name]["max_commands"] = 2
            self.results[name]["max_commands"] = 2
            self.truncate(name, 2, "command_bound")
        self.save()
        report = self.run_report()
        self.assertTrue(report["left"]["censored"])
        self.assertEqual(report["left"]["first_rejected_action"], None)

    def test_cli_output_is_exclusive_and_outside_bundle(self):
        output = self.root / "comparison"
        arguments = ["--bundle", str(self.bundle), "--left", "left", "--right", "right", "--output", str(output)]
        self.assertEqual(compare.main(arguments), 0)
        initial = (output / "comparison.json").read_bytes()
        self.assertEqual(compare.main(arguments), 1)
        self.assertEqual((output / "comparison.json").read_bytes(), initial)
        self.assertEqual(compare.main(arguments[:-1] + [str(self.bundle / "nested")]), 1)
        self.assertFalse((self.bundle / "nested").exists())


if __name__ == "__main__":
    unittest.main()
