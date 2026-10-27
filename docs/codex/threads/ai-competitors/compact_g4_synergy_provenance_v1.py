"""Losslessly compress this study's large duplicate Git provenance capture."""

import argparse
import gzip
import hashlib
import shutil
from pathlib import Path


def digest(path: Path, compressed: bool) -> str:
    hasher = hashlib.sha256()
    opener = gzip.open if compressed else open
    with opener(path, "rb") as stream:
        while block := stream.read(1024 * 1024):
            hasher.update(block)
    return hasher.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", type=Path, required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[4]
    file = args.file.resolve(strict=True)
    allowed = repo / "docs" / "codex" / "threads" / "ai-competitors" / "sims"
    if allowed.resolve() not in file.parents or not file.parent.name.startswith("g4-synergy-20261018-") or file.name != "git-provenance.json":
        raise SystemExit("Only this study's run provenance may be compacted")
    target = file.with_suffix(file.suffix + ".gz")
    if target.exists():
        raise SystemExit(f"Refusing to overwrite {target}")
    before = digest(file, False)
    with file.open("rb") as source, gzip.open(target, "wb", compresslevel=9) as output:
        shutil.copyfileobj(source, output, length=1024 * 1024)
    after = digest(target, True)
    if before != after:
        target.unlink()
        raise SystemExit("Compressed provenance failed SHA-256 verification")
    original_size = file.stat().st_size
    compressed_size = target.stat().st_size
    file.unlink()
    print(f"{file.name}: {original_size} bytes -> {compressed_size} bytes; SHA-256 {before}")


if __name__ == "__main__":
    main()
