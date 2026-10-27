"""Read-only exact-cost and known-rent runway audit of retained v15 worlds."""

import json
import math
from collections import defaultdict
from pathlib import Path

THREAD = Path(__file__).resolve().parent
SIMS = THREAD / "sims"
OUT = SIMS / "rival-runway-shadow-audit-20261024-v15.json"
SOURCE = SIMS / "rival-qa-frequency-smoke-20261024-v15" / "project"
HORIZON = 56


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def fee(card):
    return (int(card["primary_value"]) + int(card["secondary_value"])
            + 2 * int(card["scope"])) * 1000


def dues(start, productive, rent):
    return ((start + productive) // 2 - start // 2) * rent


def ceil4(value):
    return (value + 3) // 4


def analyze(seed, arm, definitions):
    folder = SIMS / f"rival-qa-frequency-{seed}-{arm}-20261024-v15"
    report = read(folder / "world-report.json")
    saved = read(folder / "world-report.json.checkpoint.json")
    release_by_project = {item["release_id"]: item for item in report["rival_release_details"]}
    supply = {}
    for release in report["rival_release_details"]:
        supply.setdefault(release["studio_id"], release["owned_features"])
        assert supply[release["studio_id"]] == release["owned_features"]
    finance = {item["id"]: item["run"]["run"]["studio_finance"] for item in saved["world"]["studios"]}
    assert supply.keys() == finance.keys()
    assert all(int(f["monthly_rent_cents"]) == 50000 and not f["employees"]
               and not f["bank_loans"] and not f["education"] for f in finance.values())
    assert all(all(feature in definitions and definitions[feature]["type"] == "feature"
                   for feature in features) for features in supply.values())
    assert not any(choice["action"] in ("admit_research", "research", "starter_purchase")
                   for choice in report["rival_choices"])
    actions = defaultdict(list)
    for studio, ledger in finance.items():
        for entry in ledger["actions"]:
            actions[studio].append(entry)
    progress = {(item["studio_id"], int(item["cycle"])): item
                for item in report["rival_progress"]}
    assert len(progress) == len(report["rival_progress"])
    # The harness also records a post-boundary *preview* of the next policy
    # choice. Drive this audit from committed finance actions and join the
    # contemporaneous policy observation by studio/cycle/price, not sequence.
    starts = defaultdict(list)
    plays = defaultdict(list)
    for studio, ledger in actions.items():
        for action in sorted(ledger, key=lambda entry: int(entry["cycle"])):
            kind = action["kind"]
            if kind not in ("development", "feature_play", "beta_income"):
                continue
            cycle = int(action["cycle"])
            candidates = [choice for choice in report["rival_choices"]
                          if choice["studio_id"] == studio and int(choice["cycle"]) == cycle - 1]
            if kind == "development":
                matching = [choice for choice in candidates
                            if choice["action"] == "begin_development"
                            and int(choice["cash_cents"]) == int(action["cash_before"])]
                assert matching, (seed, arm, studio, cycle, kind)
                starts[studio].append((action["source_id"], matching[0]))
                continue
            matching = []
            for choice in candidates:
                if choice["request"] != "play" or choice["project_id"] != action["source_id"]:
                    continue
                if (choice["phase"] == "beta") != (kind == "beta_income"):
                    continue
                cards = {int(item["token"]): item for item in choice["candidates"]}
                selected = [cards[int(token)] for token in choice["selected_tokens"]]
                direct = sum(fee(item) for item in selected if item["type"] == "feature")
                if kind == "feature_play" and -direct != int(action["direct_delta"]):
                    continue
                matching.append(choice)
            assert matching, (seed, arm, studio, cycle, kind, action["source_id"])
            plays[action["source_id"]].append(matching[0])
    projects = []
    for studio, records in starts.items():
        ids = supply[studio]
        phases = {phase: [feature for feature in ids if definitions[feature]["phase"] == phase]
                  for phase in ("design", "alpha")}
        assert sum(map(len, phases.values())) == len(ids)
        phase_price = {phase: sum(fee(definitions[feature]) for feature in phase_ids)
                       for phase, phase_ids in phases.items()}
        full_price = sum(phase_price.values())
        minimum_feature_hands = sum(ceil4(len(phase_ids)) for phase_ids in phases.values())
        for ordinal, (project, start) in enumerate(records, 1):
            assert project == f"{studio}:project:{ordinal}"
            start_cycle = int(start["cycle"])
            begin_ledger = [entry for entry in actions[studio] if entry["kind"] == "development"
                            and entry["source_id"] == project and int(entry["cycle"]) == start_cycle + 1]
            assert len(begin_ledger) == 1, (seed, arm, project, start_cycle,
                [(entry["kind"], entry["source_id"], entry["cycle"]) for entry in actions[studio]
                 if entry["kind"] == "development"])
            assert int(begin_ledger[0]["cash_before"]) == int(start["cash_cents"])
            assert (studio, start_cycle + 1) in progress
            committed = sorted(plays[project], key=lambda item: int(item["sequence"]))
            played_ids = {"design": set(), "alpha": set()}
            spend = {"design": 0, "alpha": 0}
            counts = {"design": 0, "alpha": 0, "beta": 0}
            hand_meter = []
            for choice in committed:
                phase = choice["phase"]
                assert phase in counts
                cycle = int(choice["cycle"]) + 1
                actual = [entry for entry in actions[studio] if int(entry["cycle"]) == cycle
                          and entry["source_id"] == project and entry["kind"] in ("feature_play", "beta_income")]
                assert len(actual) == 1, (seed, arm, project, cycle, phase)
                cards = {int(item["token"]): item for item in choice["candidates"]}
                selected = [cards[int(token)] for token in choice["selected_tokens"]]
                assert len(selected) == 4
                selected_features = [item for item in selected if item["type"] == "feature"]
                direct = sum(fee(item) for item in selected_features)
                if phase in played_ids:
                    assert actual[0]["kind"] == "feature_play"
                    assert int(actual[0]["direct_delta"]) == -direct, (
                        seed, arm, project, cycle, [card["definition"] for card in selected_features],
                        direct, actual[0]["direct_delta"])
                    for card in selected_features:
                        feature = card["definition"]
                        assert feature in phases[phase] and feature not in played_ids[phase]
                        played_ids[phase].add(feature)
                    spend[phase] += direct
                else:
                    assert not selected_features
                    assert actual[0]["kind"] == "beta_income"
                counts[phase] += 1
                after = progress[(studio, cycle)]
                next_phase = after["phase"]
                assert next_phase in ("design", "alpha", "beta", "studio")
                if next_phase != "studio":
                    remaining_phases = ("design", "alpha") if next_phase == "design" else (
                        ("alpha",) if next_phase == "alpha" else ())
                    remaining = {name: [feature for feature in phases[name]
                                        if feature not in played_ids[name]]
                                 for name in remaining_phases}
                    remaining_fee = sum(fee(definitions[feature]) for features in remaining.values()
                                        for feature in features)
                    remaining_hands = sum(ceil4(len(features)) for features in remaining.values())
                    remaining_hands += max(0, 2 - counts["beta"])
                    margin = int(after["cash_cents"]) - remaining_fee - dues(
                        cycle, remaining_hands, 50000)
                else:
                    remaining = {}
                    remaining_fee = remaining_hands = 0
                    margin = int(after["cash_cents"])
                hand_meter.append({"cycle": cycle, "phase_played": phase,
                    "phase_after": next_phase, "played_design": len(played_ids["design"]),
                    "played_alpha": len(played_ids["alpha"]),
                    "spent_design_cents": spend["design"],
                    "spent_alpha_cents": spend["alpha"],
                    "remaining_quote_cents": remaining_fee,
                    "remaining_hands_min": remaining_hands,
                    "cash_cents": int(after["cash_cents"]),
                    "no_future_income_margin_cents": margin})
            lower_horizon = 1 + minimum_feature_hands + 2
            start_cash = int(start["cash_cents"])
            release = release_by_project.get(project)
            observed_duration = int(release["cycle"]) - start_cycle if release else None
            actual_ledger_spend = sum(-int(entry["direct_delta"]) for entry in actions[studio]
                if entry["kind"] == "feature_play" and entry["source_id"] == project)
            assert actual_ledger_spend == sum(spend.values())
            if release:
                assert counts["beta"] == 2
                assert observed_duration == 1 + sum(counts.values())
            projects.append({"id": project, "studio": studio, "ordinal": ordinal,
                "start_cycle": start_cycle, "start_cash_cents": start_cash,
                "released": release is not None, "release_cycle": int(release["cycle"]) if release else None,
                "observed_duration_cycles": observed_duration,
                "supply_count": {phase: len(ids) for phase, ids in phases.items()},
                "pool_price_cents": phase_price, "pool_total_cents": full_price,
                "feature_hands_min": minimum_feature_hands,
                "start_horizon_min": lower_horizon,
                "start_rent_min_cents": dues(start_cycle, lower_horizon, 50000),
                "start_no_future_income_margin_cents": start_cash - full_price - dues(start_cycle, lower_horizon, 50000),
                "observed_duration_rent_cents": dues(start_cycle, observed_duration, 50000) if release else None,
                "observed_horizon_no_future_income_margin_cents": start_cash - full_price
                    - dues(start_cycle, observed_duration, 50000) if release else None,
                "hands": counts, "played": {phase: len(ids) for phase, ids in played_ids.items()},
                "spent_cents": spend, "hand_meter": hand_meter})
    completed = [item for item in projects if item["released"]]
    assert len(completed) == len(release_by_project)
    return {"source": report["source_identity"], "seed": seed, "arm": arm,
            "projects": projects, "completed_count": len(completed),
            "start_count": len(projects),
            "negative_lower_bound_starts": sum(item["start_no_future_income_margin_cents"] < 0 for item in projects),
            "negative_lower_bound_completed": sum(item["start_no_future_income_margin_cents"] < 0 for item in completed),
            "negative_observed_horizon_completed": sum(item["observed_horizon_no_future_income_margin_cents"] < 0 for item in completed),
            "all_features_played_completed": sum(sum(item["played"].values()) == sum(item["supply_count"].values()) for item in completed),
            "longer_than_feature_hand_lower_bound": sum(sum(item["hands"][phase] for phase in ("design", "alpha"))
                > item["feature_hands_min"] for item in completed),
            "post_hand_negative_count": sum(item["no_future_income_margin_cents"] < 0
                for project in projects for item in project["hand_meter"] if item["phase_after"] != "studio")}


def main():
    if OUT.exists():
        raise SystemExit(f"Refusing overwrite: {OUT}")
    definitions = {item["id"]: item for item in read(SOURCE / "data/card_ledger.json")}
    worlds = {seed: {arm: analyze(seed, arm, definitions) for arm in "BC"}
              for seed in ("4417", "4418")}
    summary = {seed: {arm: {key: value for key, value in world.items()
                if key not in ("projects", "source")} for arm, world in arms.items()}
                for seed, arms in worlds.items()}
    OUT.write_text(json.dumps({"source_card_ledger": str(SOURCE / "data/card_ledger.json"),
        "worlds": worlds, "summary": summary}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))


if __name__ == "__main__":
    main()
