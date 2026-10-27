"""Independently audit explicit completed exposure reports; never run gameplay.

Example (use a new output name):
  python audit.py --source <mechanical-source-sha256> --output audit-new.json \
      action-war-4417-v2.json action-war-4418-v2.json

Paths are interpreted relative to the caller's working directory. Inputs are
read-only. Output is created exclusively, so existing evidence is never replaced.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys


class ArithmeticAudit:
    def __init__(self) -> None:
        self.checks = 0
        self.errors: list[str] = []

    def check(self, passed: bool, label: str) -> None:
        self.checks += 1
        if not passed:
            self.errors.append(label)

    @staticmethod
    def fixed_review(inputs: dict, standards: list) -> tuple[float, float, float]:
        ratios = [min(1.25, max(0, core / target))
                  for core, target in zip(inputs["cores"], standards)]
        average = sum(ratios) / 4
        deviation = math.sqrt(sum((ratio - average) ** 2 for ratio in ratios) / 4)
        production = min(10, max(0, min(1.25, max(0, average - 0.5 * deviation)) * 8))
        raw = min(10, max(0, production * inputs["scope_completion"]
                         * inputs["bug_multiplier"] + inputs["variance_modifier"]))
        return production, raw, math.floor(raw * 10 + 0.5) / 10

    def review_rows(self, data: dict, label: str) -> None:
        for row in data["review_counterfactuals"]:
            inputs = row["inputs"]
            scope = min(1, max(0, inputs["scope"] / inputs["required_scope"]))
            bugs = min(1, max(0.25, 1 - inputs["remaining_bugs"] / inputs["required_scope"]))
            self.check(abs(inputs["scope_completion"] - scope) < 1e-12, label + " scope")
            self.check(abs(inputs["bug_multiplier"] - bugs) < 1e-12, label + " bugs")
            roll = inputs["variance_roll"]
            variance = (-0.5 if roll < 10 else -0.25 if roll < 30
                        else 0 if roll < 70 else 0.25 if roll < 90 else 0.5)
            self.check(inputs["variance_modifier"] == variance, label + " variance")
            for key, standards in [("actual", "actual_standards"),
                                   ("genre_base_only", "base_standards")]:
                values = self.fixed_review(inputs, row[standards])
                fields = ["production_rating", "unrounded_review", "final_review"]
                self.check(all(abs(values[i] - row[key][field]) < 1e-10
                               for i, field in enumerate(fields)), label + " Review " + key)

    def sales_rows(self, data: dict, label: str) -> None:
        owner = data["recipe"]["studio_id"]
        snapshots = data["snapshots"]
        for row in data["sales_counterfactuals"]:
            factual = row["actual"]
            publication = next(item for item in data["actual_publications"]
                               if item["owner"] == owner and item["release_id"] == row["release_id"])
            metadata = publication["metadata"]
            age_rows = row["age_month_factors"]
            self.check(len(age_rows) == (factual["total_earned_cycles"] + 1) // 2,
                       label + " all earned age months")
            for age_row in age_rows:
                source = snapshots[age_row["actual_snapshot"]]
                counts = [0, 0, 0]
                for fact in source["facts"]:
                    if fact["studio_id"] != owner or fact["release_id"] == row["release_id"]:
                        continue
                    genre = fact["genre"] == metadata["genre"]
                    theme = fact["theme"] == metadata["theme"]
                    if genre and theme:
                        counts[2] += 1
                    elif genre:
                        counts[0] += 1
                    elif theme:
                        counts[1] += 1
                factor = age_row["own_title_only_factor"]
                self.check([factor["genre_only"], factor["theme_only"], factor["pair"]] == counts,
                           label + " exclusive own buckets")
                expected = max(7000, 10000 - 600 * counts[0] - 300 * counts[1] - 1200 * counts[2])
                self.check(factor["factor_bp"] == expected, label + " own factor")
            for key in ["actual", "rival_facts_removed", "all_facts_removed"]:
                record = row[key]
                units = organic = monthly = settled = gain = 0
                for cycle in range(1, record["total_earned_cycles"] + 1):
                    age = (cycle + 1) // 2
                    factor_bp = record["market_factors"][str(age)]["factor_bp"]
                    if cycle <= 2:
                        units = (record["total_units"] * cycle // 2) * factor_bp // 10000
                    else:
                        if cycle % 2:
                            organic = (record["launch_awareness"] * 5000 + 300000 if age == 2
                                       else organic * (2500 + 55 * record["review_tenths"]) // 10000)
                            boost = (100000 // (record["campaign_months"][str(age)] + 1)
                                     if str(age) in record["campaign_months"] else 0)
                            raw = (500 * record["review_tenths"] * (organic + boost)
                                   * record["market_bp"] // (70 * 200 * 10000 * 10000))
                            monthly = raw * factor_bp // 10000
                        units += monthly // 2 if cycle % 2 else monthly - monthly // 2
                    net = units * 999 * 70 // 100
                    if (metadata["release_cycle"] + cycle) % 2 == 0:
                        settled = net
                        quality = min(30, max(0, record["review_tenths"] - 50))
                        gain = max(0, units - row["launch_fans"]) * 8 * quality // 2000
                self.check(units == record["earned_units"], label + " units " + key)
                self.check(units * 999 * 70 // 100 == record["entitlement_cents"],
                           label + " entitlement " + key)
                self.check(settled == record["settled_cents"], label + " settled " + key)
                self.check(gain == row["settled_gain_targets"][key], label + " gain " + key)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, help="Expected exact mechanical source SHA-256")
    parser.add_argument("--output", required=True, type=Path, help="New JSON audit path; must not exist")
    parser.add_argument("reports", nargs="+", type=Path, help="Explicit completed record report paths")
    args = parser.parse_args()
    destination = args.output.resolve()
    inputs = [path.resolve() for path in args.reports]
    if len(set(inputs)) != len(inputs):
        parser.error("Duplicate input reports would double-count coverage.")
    if destination.exists() or destination in inputs:
        parser.error("Output must be a new path distinct from every input.")
    if not destination.parent.is_dir():
        parser.error("Output parent directory must already exist.")
    if len(args.source) != 64 or any(char not in "0123456789abcdef" for char in args.source):
        parser.error("Expected source must be a lowercase SHA-256 identity.")

    audit = ArithmeticAudit()
    cases: list[dict] = []
    input_errors: list[str] = []
    for path in inputs:
        before_checks, before_failures = audit.checks, len(audit.errors)
        case: dict = {"file": path.name, "path": str(path)}
        try:
            raw = path.read_bytes()
            data = json.loads(raw.decode("utf-8-sig"))
            case.update(sha256=hashlib.sha256(raw).hexdigest(), source=data["source_identity"],
                        harness=data["harness_sha256"])
            if (not data.get("completed") or data.get("failures") != 0 or data.get("errors")
                    or data.get("source_drift") or data["source_identity"] != args.source
                    or data.get("starting_source_identity") != args.source):
                raise ValueError("requires a completed error-free record with unchanged expected source")
            if not data.get("review_counterfactuals") or not data.get("sales_counterfactuals"):
                raise ValueError("missing counterfactual rows")
            audit.review_rows(data, path.name)
            audit.sales_rows(data, path.name)
        except (OSError, ValueError, KeyError, TypeError, StopIteration, ZeroDivisionError) as error:
            message = f"{path}: {type(error).__name__}: {error}"
            input_errors.append(message)
            case["input_error"] = message
        case.update(checks=audit.checks - before_checks, failures=len(audit.errors) - before_failures)
        cases.append(case)

    report = {"checker_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "expected_source": args.source, "checks": audit.checks, "errors": audit.errors,
              "input_errors": input_errors, "cases": cases,
              "scope": "Independent Python arithmetic of explicit reports; no gameplay or alternate campaign."}
    try:
        with destination.open("x", encoding="utf-8") as file:
            file.write(json.dumps(report, indent=2) + "\n")
    except FileExistsError:
        parser.error("Output appeared during the audit; existing evidence was preserved.")
    print(json.dumps({"output": str(destination), "checks": audit.checks,
                      "failures": len(audit.errors), "input_errors": len(input_errors),
                      "reports": len(cases)}))
    return 1 if audit.errors or input_errors else 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(main())
