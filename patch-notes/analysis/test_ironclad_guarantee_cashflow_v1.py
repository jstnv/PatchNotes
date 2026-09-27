"""Focused invariants for the read-only Ironclad guarantee experiment."""
import unittest

from ironclad_guarantee_cashflow_v1 import BONUSES, CAP, reward, run_path


class GuaranteeTrialTest(unittest.TestCase):
    def row(self, *, cycles=1, units=0, numerator=48, initial=1000):
        return {"initial_cash": initial, "alignment": 0, "game1_play_spend": 0,
                "game1_cycles": cycles, "units": units, "contract": {"numerator": numerator},
                "reserve_id": "test", "game2_play_spend": 0, "game2_cycles": 0}

    def test_exact_rewards_and_cap(self):
        for bonus in BONUSES:
            self.assertEqual(reward(0, bonus), (bonus, 0))
            self.assertEqual(sum(reward(96, bonus)), CAP)
            self.assertEqual(sum(reward(48, bonus)), bonus + (CAP - bonus) // 2)
            self.assertLessEqual(sum(reward(95, bonus)), CAP)
        self.assertEqual(sum(reward(48, 40000)), 140000)

    def test_acceptance_free_and_hand_payout_once(self):
        p = run_path(self.row(), 40000, 0, 0)
        c = p["checkpoints"]
        self.assertEqual(c["after_upfront_cents"] - c["before_acceptance_cents"], 40000)
        self.assertEqual(p["upfront_cents"] + p["remainder_cents"], 140000)
        self.assertEqual(c["after_hand_1_cents"], c["after_upfront_cents"] - 7500)
        self.assertEqual(c["after_hand_2_cents"], c["after_hand_1_cents"] + 100000)

    def test_one_cycle_hire_and_same_boundary_net(self):
        p = run_path(self.row(units=100), 0, 1, 0)
        self.assertEqual(p["checkpoints"]["studio_entry_cents"], 100000)
        boundary = next(b for b in p["boundaries"] if b["stage"] == "Hire")
        self.assertEqual(boundary["cycle"], 2)
        self.assertEqual(boundary["sales_cents"], (100 // 2) * 999 * 70 // 100)
        self.assertEqual(boundary["bill_cents"], 7500)
        self.assertEqual(boundary["payroll_cents"], 10000)
        self.assertEqual(boundary["after_cents"], boundary["before_cents"] +
                         boundary["sales_cents"] - boundary["bill_cents"] - boundary["payroll_cents"])

    def test_first_shortfall_and_delayed_payroll_sensitivity(self):
        row = self.row(initial=100, cycles=1, numerator=0)
        same = run_path(row, 0, 1, 0, hire_boundary="same")
        delayed = run_path(row, 0, 1, 0, hire_boundary="next")
        self.assertEqual(same["first_shortfall"]["stage"], "Hire month boundary")
        self.assertEqual(same["first_shortfall"]["shortfall_cents"], 7500)
        self.assertEqual(delayed["first_shortfall"]["stage"], "Contract hand 2 month boundary")


if __name__ == "__main__":
    unittest.main()
