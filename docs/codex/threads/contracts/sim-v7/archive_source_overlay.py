"""Preserve the dirty project overlay needed with the pinned HEAD for replay."""

import hashlib
import json
from pathlib import Path
import zipfile

HERE = Path(__file__).resolve().parent
MANIFEST = json.loads((HERE / "source-manifest.json").read_text(encoding="utf-8"))
COPY = Path(MANIFEST["analysis_copy"])
ARCHIVE = HERE / "dirty-source-overlay.zip"


def main():
    if ARCHIVE.exists():
        raise RuntimeError("Refusing to overwrite existing overlay")
    names = []
    for line in MANIFEST["source_status_at_copy"]:
        path = line[3:].replace("\\", "/")
        if not path.startswith("patch-notes/"):
            raise RuntimeError(f"Unexpected dirty path: {line}")
        names.append(path[len("patch-notes/"):])
    with zipfile.ZipFile(ARCHIVE, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in names:
            if name not in MANIFEST["files"]:
                raise RuntimeError(f"Dirty source missing from manifest: {name}")
            archive.write(COPY / name, arcname=name)
    with zipfile.ZipFile(ARCHIVE) as archive:
        if archive.testzip() is not None or sorted(archive.namelist()) != sorted(names):
            raise RuntimeError("Overlay ZIP integrity failed")
        for name in names:
            digest = hashlib.sha256(archive.read(name)).hexdigest()
            if digest != MANIFEST["files"][name]:
                raise RuntimeError(f"Overlay hash mismatch: {name}")
    print(f"Archived {len(names)} dirty project files: {ARCHIVE.stat().st_size} bytes")


if __name__ == "__main__":
    main()
