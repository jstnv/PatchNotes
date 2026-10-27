"""Reconcile the sealed private Crown delta onto a new current-source variant."""
from pathlib import Path
import difflib
import hashlib
import json
import subprocess
import zipfile

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
PACKET = ROOT / "docs/codex/threads/contracts/handoffs/crown-search-brief-20261025-v1"
PROJECT = ROOT / "docs/codex/threads/contracts/simulators/crown-feedback-20261026-v1/project"
meta = json.loads((PACKET / "handoff.json").read_text())
assert not (OUT / "reconciliation.json").exists()
records = []
with zipfile.ZipFile(PACKET / "base-source.zip") as base, zipfile.ZipFile(PACKET / "candidate-source.zip") as candidate:
    for change in meta["changes"]:
        name = change["path"]
        if "/debug/" in name:
            continue
        raw = candidate.read(name)
        assert hashlib.sha256(raw).hexdigest() == change["after_sha256"]
        theirs = raw.decode().replace("\r\n", "\n")
        target = PROJECT / name
        ours = target.read_text(encoding="utf-8") if target.exists() else ""
        ancestor = base.read(name).decode().replace("\r\n", "\n") if change["before_sha256"] else ""
        if not ancestor or ours == ancestor:
            merged = theirs
            code = 0
        else:
            files = []
            for label, value in [("ours", ours), ("base", ancestor), ("theirs", theirs)]:
                path = OUT / (name.replace("/", "__") + "." + label)
                path.write_text(value, encoding="utf-8", newline="\n")
                files.append(str(path))
            result = subprocess.run(["git", "merge-file", "-p", *files], cwd=ROOT, capture_output=True)
            code = result.returncode
            assert code in (0, 1), result.stderr
            merged = result.stdout.decode()
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(merged, encoding="utf-8", newline="\n")
        diff = "\n".join(difflib.unified_diff(ours.splitlines(), merged.splitlines(), fromfile="current/"+name, tofile="private/"+name))
        (OUT / (name.replace("/", "__") + ".patch")).write_text(diff, encoding="utf-8")
        records.append({"path": name, "conflict": bool(code), "normalized_diff_lines": len(diff.splitlines())})
(OUT / "reconciliation.json").write_text(json.dumps(records, indent=2)+"\n")
print(json.dumps(records, indent=2))
