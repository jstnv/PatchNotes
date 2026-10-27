"""Retained command wrapper from the 2026-10-26 variant creation retry.

Delegates to the standard simulator_variant tool. The variant tool loads its
own simulate module, so this outer small-buffer monkey patch did not change
the variant's hashing behavior. Retained only to reproduce the exact command
used on the successful retry after transient system memory pressure.
"""

from __future__ import annotations

import hashlib
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))
from tools import simulate as sim  # noqa: E402


def small_buffer_sha(path: Path) -> str:
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        while block := stream.read(64 * 1024):
            digest.update(block)
    return digest.hexdigest()


sim.sha = small_buffer_sha
from tools import simulator_variant  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(simulator_variant.main())
