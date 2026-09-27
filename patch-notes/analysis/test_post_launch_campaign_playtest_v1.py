"""Focused invariants for the read-only campaign model."""
import unittest

import post_launch_campaign_playtest_v1 as model


class CampaignPlaytestTests(unittest.TestCase):
    def setUp(self):
        self.row = {
            "alignment": 0, "initial_cash": 5500, "game1_play_spend": 0,
            "game1_cycles": 0, "market_bp": 10_000,
            "contract": {"payout_cents": 240_000},
            "game2_cycles": 2, "game2_play_spend": 0,
            "review": 2.0, "marketing": 0,
        }

    def test_locked_month_one_is_preserved_and_matched(self):
        self.assertEqual(model.month_one_units(70, 100, 10_000), 750)
        self.assertEqual(model.month_one_units(40, 325, 10_000), 750)
        self.assertEqual(model.net_cents(750), 524_475)
        path = model.simulate(self.row, 70, 100, "none_single")
        self.assertEqual(path["boundaries"][0]["cash_cents"],
                         550_000 + 240_000 + 524_475 - 17_500)
        self.assertEqual(path["boundaries"][0]["earned_cumulative_cents"],
                         path["boundaries"][0]["settled_cumulative_cents"])

    def test_second_half_alignment_settles_only_earned_sales(self):
        self.row["alignment"] = 1
        path = model.simulate(self.row, 70, 100, "none_single")
        first_half_net = model.net_cents(750 // 2)
        self.assertEqual(path["boundaries"][0]["cash_cents"],
                         550_000 + first_half_net - 17_500)
        self.assertEqual(path["boundaries"][0]["settled_this_boundary_cents"],
                         first_half_net)

    def test_campaign_delta_is_sales_increment_less_exact_spend(self):
        control = model.simulate(self.row, 70, 100, "none_single")
        campaign = model.simulate(self.row, 70, 100, "single")
        self.assertEqual(control["boundaries"][0]["cash_cents"],
                         campaign["boundaries"][0]["cash_cents"])
        control_total = sum(x["calculated_units"] for x in control["first_release_monthly"].values())
        campaign_total = sum(x["calculated_units"] for x in campaign["first_release_monthly"].values())
        expected = model.net_cents(campaign_total) - model.net_cents(control_total) - 10_000
        self.assertEqual(campaign["boundaries"][-1]["cash_cents"]
                         - control["boundaries"][-1]["cash_cents"], expected)
        self.assertEqual(campaign["campaign_accepted"], 1)

    def test_dormant_revival_and_saturating_repeats(self):
        weak = model.first_dormant_month(20, 100, 10_000)
        typical = model.first_dormant_month(70, 100, 10_000)
        strong = model.first_dormant_month(90, 100, 10_000)
        self.assertLess(weak, typical)
        self.assertLess(typical, strong)
        for review, month in ((20, weak), (70, typical), (90, strong)):
            self.assertEqual(model.later_units(review, 100, 10_000, month)[0], 0)
            self.assertGreater(model.later_units(review, 100, 10_000, month, 0)[0], 0)
        self.assertGreater(model.net_cents(model.later_units(90, 100, 10_000, strong, 1)[0]), 10_000)
        self.assertLess(model.net_cents(model.later_units(90, 100, 10_000, strong, 2)[0]), 10_000)

    def test_unaffordable_campaign_does_not_spend_or_boost(self):
        self.row["initial_cash"] = 0
        self.row["contract"]["payout_cents"] = 0
        control = model.simulate(self.row, 0, 100, "none_single")
        campaign = model.simulate(self.row, 0, 100, "single")
        self.assertEqual(campaign["campaign_accepted"], 0)
        self.assertEqual(campaign["campaign_spend_cents"], 0)
        self.assertEqual([b["cash_cents"] for b in control["boundaries"]],
                         [b["cash_cents"] for b in campaign["boundaries"]])


if __name__ == "__main__":
    unittest.main()
