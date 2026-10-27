"""Run the documented isolated world runner with the bundle's private shadow harness."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import sys


def main() -> None:
    owner = Path(__file__).resolve().parent
    runner_path = owner / "six-hand-phase-study-20261023-v1" / "run_world.py"
    spec = importlib.util.spec_from_file_location("rival_world_runner", runner_path)
    if spec is None or spec.loader is None:
        raise SystemExit("Cannot load isolated world runner")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    args = module.parse_args()
    bundle = args.bundle.resolve(strict=True)
    harness = bundle / "project" / "scripts" / "debug" / "rival_beta_shadow_world_study.gd"
    if not harness.is_file():
        raise SystemExit("Frozen bundle lacks its private Beta shadow harness")
    module.HARNESS = harness
    module.main()


if __name__ == "__main__":
    main()
