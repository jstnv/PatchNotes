"""Focused read-only checks for the provisional QA Analyst counterfactual."""
from __future__ import annotations

import gzip
import json
import math
import unittest
from collections import defaultdict
from pathlib import Path

import qa_analyst_counterfactual_v1 as qa


class QACounterfactualTests(unittest.TestCase):
    def test_search_bonus_is_once_and_needs_hidden_remainder(self):
        actions = [["search_for_bugs"], ["search_for_bugs"]]
        ordinary = qa.replay(20, actions, "none")
        rewarded = qa.replay(20, actions, "search")
        self.assertEqual(rewarded["extra_discoveries"], 1)
        self.assertEqual(rewarded["discoveries"], ordinary["discoveries"] + 1)
        self.assertEqual(qa.replay(1, actions, "search")["extra_discoveries"], 0)
        self.assertEqual(qa.replay(0, actions, "search")["remaining"], 0)

    def test_debug_requires_later_hand_and_known_bug(self):
        self.assertEqual(qa.replay(20, [["search_for_bugs", "search_for_bugs", "debug"]], "debug")["extra_fixes"], 0)
        actions = [["search_for_bugs"], ["search_for_bugs"], ["debug"], ["debug"]]
        rewarded = qa.replay(20, actions, "debug")
        self.assertTrue(rewarded["challenge_complete"])
        self.assertEqual(rewarded["extra_fixes"], 1)
        self.assertEqual(qa.replay(20, [["debug"]], "debug")["remaining"], 20)

    def test_first_bonus_can_prevent_second_productive_search(self):
        actions = [["search_for_bugs"], ["search_for_bugs"], ["debug"]]
        self.assertEqual(qa.replay(3, actions, "none")["productive_searches"], 2)
        combined = qa.replay(3, actions, "both")
        self.assertEqual(combined["productive_searches"], 1)
        self.assertFalse(combined["challenge_complete"])
        self.assertEqual(combined["extra_fixes"], 0)

    def test_all_marketing_uses_current_specialization(self):
        ids = ["sign_flippers", "posters", "press_release", "press_interview"]
        raw = sum(qa.base.BY_ID[id]["beta_value"] for id in ids)
        result = qa.replay(0, [ids], "none")
        self.assertEqual(result["marketing"], math.floor(raw * 1.5))
        self.assertEqual(result["marketing_special_hands"], 1)

    def test_saved_pairs_and_exact_revenue(self):
        path = Path(__file__).resolve().parents[1] / "design-logs/qa_analyst_counterfactual_v1_results.json.gz"
        with gzip.open(path, "rt", encoding="utf-8") as stream:
            report = json.load(stream)
        self.assertEqual(report["seed"], 260926)
        self.assertEqual(len(report["rows"]), 36000)
        groups = defaultdict(list)
        for row in report["rows"]:
            key = (row["cohort"], row["sample"], row["priority"], row["budget"], row["action_policy"])
            groups[key].append(row)
            self.assertEqual(row["net_cents"], row["units"] * 999 * 70 // 100)
            self.assertEqual(row["net_cents_delta"], row["net_cents"] - row["base_net_cents"])
            self.assertEqual(row["review_delta"], round(row["review"] - row["base_review"], 1))
            self.assertGreaterEqual(row["remaining"], 0)
            self.assertLessEqual(row["extra_discoveries"], 1)
            self.assertLessEqual(row["extra_fixes"], 1)
        self.assertEqual(len(groups), 9000)
        for paired in groups.values():
            self.assertEqual({r["perk"] for r in paired}, set(qa.PERKS))
            self.assertEqual(len({json.dumps(r["draws"]) for r in paired}), 1)
            self.assertEqual(len({json.dumps(r["actions"]) for r in paired}), 1)
            self.assertEqual(len({r["marketing"] for r in paired}), 1)


if __name__ == "__main__":
    unittest.main()
