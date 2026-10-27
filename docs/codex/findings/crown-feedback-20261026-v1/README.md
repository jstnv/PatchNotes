# Crown feedback: private implementation evidence

2026-10-26. [Session/results/remaining gates](../../logs/2026-10-26-crown-feedback-v1.md) · [sealed source packet](../../threads/contracts/handoffs/crown-feedback-20261026-v1/HANDOFF.md) · [approved GF2–GF6](../../threads/contracts/CROWN-PREVIEW-HANDOFF-2026-10-25-v4.md).

- `audit.json`: final manifests, canonical preservation, source identities, receipt and capture hashes, exact campaign outcomes and retained failures.
- `reconciliation.json` / normalized `*.patch`: eleven-path sealed-pilot reconciliation onto the current canonical baseline; no wholesale old project copy.
- `run.py LABEL SCRIPT [--native] [--pack=PATH] [--fixture=PATH]`: focused runner, unique isolated profiles/ports/artifact directories. Use the bundled Python runtime; every label must be new. Each `*-run.json` retains the exact executable/arguments, exit/errors and duration.
- `model-final`, `flow-guard-final`, `pack-guard-final`, `cold-final`, `pack-cold-final`: model, live transaction/guard and separate-process typed replay/restore receipts.
- `ui-streak-final-artifacts/ui-captures/` and `pack-streak-final-artifacts/ui-captures/`: both-size normal/final/result/Details/offer captures, actual three-zero history and settled layout bounds. Representative editor and PCK captures visually inspected.
- `final-search`, `final-relationships`, `final-contracts`, `final-world`: maintained current-candidate source-fenced checks.
- `campaign-run-final`: fresh227-command three-release/three-Brief campaign from the exact sealed candidate. `campaign-run-v1` and `campaign-replay-v1`: same executable inputs and outcomes, independent227-step/228-telemetry replay. Only debug harness source changed between run versions; audit verifies that boundary.
- `exports/crown-feedback-private.pck` and `export-run.json`: private compiled test pack, including debug acceptance scripts. This is not a player build.

Raw logs preserve the initial expected red test, UI integration/harness failures, original external-oracle timeout and plain-JSON-tape rejection. Existing player files and canonical executable source are unchanged. The final tests use the existing lossless tape API; no source/integrity fields are rewritten to obtain compatibility.
