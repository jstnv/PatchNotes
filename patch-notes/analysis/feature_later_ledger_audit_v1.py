"""Audit authored 1981–83 Department cards against current two-Core schema.

Run: python -B analysis/feature_later_ledger_audit_v1.py [path-to-ledger.docx]
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

from docx import Document

OUT = Path(__file__).resolve().parents[1] / "design-logs"
DEFAULT = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\Cards\DEPARTMENT SYSTEM LEDGER.docx")
LANES = {
    "Character Development": "Story & World", "Branching Story": "Story & World",
    "Branching Dialogue": "Story & World", "Turn-Based Combat": "Gameplay",
    "Character Classes": "Gameplay", "Boss Battles": "Gameplay",
    "Multiple Levels": "Story & World", "Sub-Areas": "Story & World",
    "Branching Paths": "Story & World", "Background Music": "Audio",
    "Recorded Instruments": "Audio", "Recorded Sound Effects": "Audio",
    "Ambient Sound": "Audio",
}
PILOT_BASE_CENTS = {"Background Music": 95000, "Sub-Areas": 170000,
                    "Boss Battles": 280000, "Character Classes": 170000}


def main():
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT
    paragraphs = [p.text.strip() for p in Document(path).paragraphs]
    anchor = next(i for i,p in enumerate(paragraphs) if p.startswith("1981") and "1983" in p)
    tail = paragraphs[anchor+1:]
    rows = []
    for name,lane in LANES.items():
        positions = [i for i,p in enumerate(tail) if p == name]
        assert len(positions) == 1, (name, positions)
        i = positions[0]
        block = []
        for line in tail[i+1:]:
            if not line:
                break
            block.append(line)
        joined = "\n".join(block)
        raw = dict((key.lower(),int(value)) for value,key in re.findall(
            r"\+(\d+)\s+(Graphics|Sound|Technology|Design)",joined))
        scope = re.search(r"Scope:\s*(\d+)",joined)
        requirement = re.search(r"Requirements?:\s*([^\n]+)",joined)
        assert scope and requirement and raw, (name,block)
        parents = [x.strip() for x in requirement.group(1).split("+")]
        row = {"name":name,"era":"1981–1983","phase":"alpha","lane":lane,
               "parents":parents,"core":raw,"scope":int(scope.group(1)),
               "printed_core_total":sum(raw.values()),
               "pilot_base_price_cents":PILOT_BASE_CENTS.get(name),
               "two_core_card_data_supported":len(raw)<=2,
               "current_single_parent_store_gate_supported":len(parents)<=1,
               "combined_parent_familiarity_supported":len(parents)<=1}
        rows.append(row)
    assert len(rows)==13
    assert sum(x["scope"] for x in rows)==28
    total={k:sum(x["core"].get(k,0) for x in rows) for k in ("graphics","sound","technology","design")}
    assert total=={"graphics":9,"sound":23,"technology":18,"design":31},total
    assert next(x for x in rows if x["name"]=="Branching Dialogue")["parents"]==["Dialogue","Branching Nodes"]
    assert next(x for x in rows if x["name"]=="Boss Battles")["core"]=={"graphics":3,"sound":3,"technology":3}
    result={"source_sha256":hashlib.sha256(path.read_bytes()).hexdigest(),
            "source_path":str(path),"source_revision":"ba616515ed1b039fd0da7cf03f73288fd7ccd8e4",
            "authored_count":len(rows),"scope_total":sum(x["scope"] for x in rows),
            "core_totals":total,"lane_counts":{lane:sum(x["lane"]==lane for x in rows) for lane in sorted(set(LANES.values()))},
            "one_parent_count":sum(len(x["parents"])==1 for x in rows),
            "two_parent_count":sum(len(x["parents"])==2 for x in rows),
            "three_core_count":sum(len(x["core"])==3 for x in rows),"cards":rows}
    (OUT/"feature_later_ledger_audit_v1.json").write_text(json.dumps(result,indent=2))
    print("authored",len(rows),"scope",result["scope_total"],"core",total,
          "two_parent",result["two_parent_count"],"three_core",result["three_core_count"])


if __name__=="__main__":
    main()
