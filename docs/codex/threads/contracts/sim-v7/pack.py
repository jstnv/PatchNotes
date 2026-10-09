"""Archive raw native traces after verifying byte-for-byte roundtrip."""

import hashlib
from pathlib import Path
import zipfile

HERE = Path(__file__).resolve().parent
NAMES = ["crown-lease-chain.json"]
ARCHIVE = HERE / "native-traces.zip"


def main():
    if ARCHIVE.exists():
        raise RuntimeError(f"Refusing to overwrite {ARCHIVE}")
    for name in NAMES:
        if not (HERE / name).is_file():
            raise RuntimeError(f"Missing {name}")
    with zipfile.ZipFile(ARCHIVE, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in NAMES:
            archive.write(HERE / name, arcname=name)
    with zipfile.ZipFile(ARCHIVE) as archive:
        if archive.testzip() is not None:
            raise RuntimeError("ZIP integrity failed")
        for name in NAMES:
            source = hashlib.sha256((HERE / name).read_bytes()).digest()
            copied = hashlib.sha256(archive.read(name)).digest()
            if source != copied:
                raise RuntimeError(f"ZIP hash mismatch for {name}")
    for name in NAMES:
        (HERE / name).unlink()
    print(f"Packed {len(NAMES)} verified traces into {ARCHIVE.name} ({ARCHIVE.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
