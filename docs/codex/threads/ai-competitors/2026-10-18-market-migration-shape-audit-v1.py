"""Compare retained old and v10 encoded checkpoint record shapes, without edits."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent / "sims"
OLD = ROOT / "market-migration-old-fixtures-20261018-v1/profile/APPDATA/Godot/app_userdata/Patch Notes/market-legacy-cycle-10.json"
NEW = ROOT / "market-transaction-provenance-focused-20261018-v10/profile/APPDATA/Godot/app_userdata/Patch Notes/market-transaction-cold.json"


def shape_diff(a, b, path=""):
    if isinstance(a, dict) and isinstance(b, dict):
        ak, bk = set(a), set(b)
        if ak != bk:
            print(path, "only_old=", sorted(ak-bk), "only_new=", sorted(bk-ak))
        for key in sorted(ak & bk):
            shape_diff(a[key], b[key], path + "." + key)
    elif isinstance(a, list) and isinstance(b, list):
        if a and b:
            shape_diff(a[0], b[0], path + "[0]")
    elif type(a) is not type(b):
        print(path, "type_old=", type(a).__name__, "type_new=", type(b).__name__)


def main():
    old = json.loads(OLD.read_text())
    new = json.loads(NEW.read_text())
    shape_diff(old["player"], new["player"], "player")
    shape_diff(old["world"]["studios"][0]["run"], new["world"]["studios"][0]["run"], "rival0")
    shape_diff(old["world"]["studios"][1]["run"], new["world"]["studios"][1]["run"], "rival1")


if __name__ == "__main__":
    main()
