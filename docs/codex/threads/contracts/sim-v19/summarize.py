"""Read-only exact-cent category reconciliation for audited v19 pairs."""

import argparse
import collections
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
if args.output.exists():
    raise RuntimeError("Refusing to overwrite category reconciliation")
audit = json.loads((HERE / "audit-summary-v2.json").read_text(encoding="utf-8"))
if not audit["passed"]:
    raise RuntimeError("Independent audit has not passed")


def categories(arm):
    transactions = arm["endpoints"]["97"]["finance"]["transactions"]
    result = collections.Counter()
    for transaction in transactions:
        result[transaction["kind"]] += transaction["cash_delta_cents"]
    if sum(result.values()) != arm["endpoints"]["97"]["cash_cents"]:
        raise AssertionError("Journal categories do not reconcile to cash")
    return result


results = []
for specialty in ("adventure", "role_playing", "strategy", "simulation"):
    buy = json.loads((HERE / f"{specialty}-buy_chain/native-route.json").read_text(encoding="utf-8"))
    no_buy = json.loads((HERE / f"{specialty}-no_buy/native-route.json").read_text(encoding="utf-8"))
    left, right = categories(buy), categories(no_buy)
    delta = {kind: left[kind] - right[kind] for kind in sorted(set(left) | set(right))}
    expected = buy["endpoints"]["97"]["cash_cents"] - no_buy["endpoints"]["97"]["cash_cents"]
    if sum(delta.values()) != expected:
        raise AssertionError("Paired categories do not reconcile")
    results.append({"specialty": specialty, "cash_delta_cents": expected,
                    "components_cents": {k: v for k, v in delta.items() if v}})

args.output.write_text(json.dumps({"passed": True, "source_audit": "audit-summary-v2.json",
                                   "pairs": results}, indent=2), encoding="utf-8")
print(json.dumps({"passed": True, "pairs": len(results)}, indent=2))
