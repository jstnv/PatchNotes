"""Read-only visible Beta offer/selection census for the v9 legal 13-cycle route."""

import json
from pathlib import Path

SIMS = Path(__file__).resolve().parent / "sims"
OUT = SIMS / "rival-beta-offer-audit-20261024-v9-v2.json"


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    if OUT.exists():
        raise SystemExit(f"refusing overwrite: {OUT}")
    rows = {}
    for seed in ("4417", "4418"):
        folder = SIMS / f"rival-core-review-audit-{seed}-B-20261024-v9"
        report = read(folder / "world-report.json")
        by_hand = {}
        for choice in report["rival_choices"]:
            if choice["phase"] != "beta" or choice["request"] != "play":
                continue
            key = (choice["project_id"], choice["hand_revision"])
            if key in by_hand:
                assert by_hand[key]["selected_tokens"] == choice["selected_tokens"]
                continue
            cards = choice["candidates"]
            selected = [c for c in cards if c["token"] in choice["selected_tokens"]]
            assert len(selected) == 4
            by_hand[key] = {
                "studio_id": choice["studio_id"], "project_id": choice["project_id"],
                "cycle": choice["cycle"], "hand_revision": choice["hand_revision"],
                "selected_tokens": choice["selected_tokens"],
                "offered_search": sum(c["qa_operation"] == "search" for c in cards),
                "offered_debug": sum(c["qa_operation"] == "debug" for c in cards),
                "chosen_search": sum(c["qa_operation"] == "search" for c in selected),
                "chosen_debug": sum(c["qa_operation"] == "debug" for c in selected),
                "chosen_categories": [c["beta_category"] for c in selected],
            }
        hands = sorted(by_hand.values(), key=lambda x: (x["project_id"], x["hand_revision"]))
        releases = {x["release_id"]: x for x in report["rival_release_details"]}
        rows[seed] = {
            "hands": hands,
            "hand_count": len(hands),
            "no_visible_search": sum(x["offered_search"] == 0 for x in hands),
            "visible_both_search_and_debug": sum(x["offered_search"] > 0 and x["offered_debug"] > 0 for x in hands),
            "chosen_search": sum(x["chosen_search"] > 0 for x in hands),
            "chosen_both_search_and_debug": sum(x["chosen_search"] > 0 and x["chosen_debug"] > 0 for x in hands),
            "remaining_bugs": {key: int(value["remaining_bugs"]) for key, value in releases.items()},
        }
    assert all(row["hand_count"] == 16 for row in rows.values())
    OUT.write_text(json.dumps(rows, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({seed: {k: v for k, v in row.items() if k not in ("hands", "remaining_bugs")} for seed, row in rows.items()}, sort_keys=True))


if __name__ == "__main__":
    main()
