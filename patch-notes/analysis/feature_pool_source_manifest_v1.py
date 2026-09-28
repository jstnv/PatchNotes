"""Hash the live Patch Notes source and analysis inputs for the read-only batch."""
from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DESIGN_LEDGER = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\Cards\DEPARTMENT SYSTEM LEDGER.docx")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def main() -> None:
    files = [ROOT / "project.godot", DESIGN_LEDGER]
    for folder, pattern in (("scripts", "*.gd"), ("data", "*.json"),
                            ("scenes", "*.tscn"), ("analysis", "feature_*.py"),
                            ("analysis", "feature_*.gd")):
        files.extend(sorted((ROOT / folder).rglob(pattern)))
    names = {}
    for path in files:
        if path.is_file():
            name = str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path)
            names[name.replace("\\", "/")] = sha256(path)
    git_root = ROOT.parent
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=git_root, text=True).strip()
    status = subprocess.check_output(["git", "status", "--short"], cwd=git_root, text=True).splitlines()
    output = {"head": head, "worktree_dirty": bool(status), "git_status_short": status,
              "file_sha256": names, "note": "Hashes include the current dirty source; untracked trial cards are analysis-only."}
    target = ROOT / "design-logs/feature_pool_source_manifest_v1.json"
    target.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(head, len(names), len(status), target)


if __name__ == "__main__":
    main()
