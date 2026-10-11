"""Materialize predeclared v4 SideStreet extension and access probes."""

import hashlib
import json
from pathlib import Path


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "prefix-v3-run-01" / "cases" / "sports-1104-prefix" / "studio_checkpoint.json"
TARGET = HERE / "study-v4.json"

raw = SOURCE.read_bytes()
checkpoint = json.loads(raw)
assert checkpoint["kind"] == "campaign_studio"
run = checkpoint["studio_payload"]["run"]
assert run["ironclad_completion_committed"] is True
assert len(run["released_games"]) == 2
assert len(run["sidestreet_entitlements"]) >= 1
assert any(
    entry["value"]["publisher_id"] in ("crown_quill", "neon_circuit")
    for entry in run["publisher_offers"]
)


def development(genre: str, first: bool) -> dict:
    return {
        "genre": genre,
        "theme": "fantasy",
        "name_prefix": "SideStreet Screen",
        "selection": "features_first",
        "hands": {"design": 3 if first else 5, "alpha": 4 if first else 6, "beta": 4 if first else 6},
    }


def pair_case(arm: str) -> dict:
    return {
        "schema_version": "1",
        "case_id": f"sports-1104-{arm}-v4",
        "initial": {"checkpoint": checkpoint},
        "max_commands": 220,
        "target_release_count": 4,
        "telemetry": True,
        "study": {
            "pair_id": "sidestreet-sports-1104-v4",
            "arm": arm,
            "prefix_case": "sports-1104-prefix",
            "prefix_checkpoint_sha256": hashlib.sha256(raw).hexdigest(),
        },
        "policy": {
            "config": {
                "mode": "pair",
                "arm": arm,
                "development_first": development("sports", True),
                "development_later": development("sports", False),
            }
        },
    }


def prefix_case(genre: str, seed: str, first_slow: bool, starters: list[str]) -> dict:
    return {
        "schema_version": "1",
        "case_id": f"{genre}-{seed}-prefix-v4",
        "initial": {
            "recipe": {
                "schema_version": 1,
                "studio_id": f"contracts-sidestreet-v4-{genre}-{seed}",
                "studio_name": f"SideStreet v4 {genre} {seed}",
                "specialty": genre,
                "traits": [],
                "seed": seed,
            }
        },
        "max_commands": 180,
        "target_release_count": 2,
        "telemetry": True,
        "policy": {
            "config": {
                "mode": "prefix",
                "starter_ids": starters,
                "development_first": development(genre, not first_slow),
                "development_later": development(genre, False),
            }
        },
    }


config = {
    "schema_version": "1",
    "policy": {"script": "sidestreet_policy_v4.gd", "id": "contracts-sidestreet-postsettlement", "version": "4"},
    "cases": [
        pair_case("take"),
        pair_case("skip"),
        prefix_case("sports", "4417", True, ["sprites", "general_combat", "levels"]),
        prefix_case("adventure", "1104", False, ["enemies", "menu_system", "music"]),
    ],
}

assert not TARGET.exists(), f"Refusing to overwrite {TARGET}"
TARGET.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"output": str(TARGET), "checkpoint_sha256": hashlib.sha256(raw).hexdigest(), "cases": [c["case_id"] for c in config["cases"]]}))
