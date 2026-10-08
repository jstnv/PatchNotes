# Current-source wage comparison

Read [findings](../../../findings/2026-10-07-employees-wage-comparison-v1.md) and [predeclared plan/extensions](PLAN.md). Live wage remains $10. Candidate runs occur only in the isolated Downloads project recorded in `source.json`.

## Reproduction

Use the Python/Godot paths in `run.py`. `prepare.py` freezes the current runtime, substitutes only the isolated hire-quote wage, and installs the saved transitive harness dependencies. It refuses to overwrite an existing snapshot. To reproduce elsewhere, change its destination deliberately and retain the source manifest; a changed runtime requires a new study version.

Run `prepare.py`, `run.py --import`, `run.py`, `run.py --extension`, `run.py --coverage`, `fixed.py`, then `audit.py`. Each native invocation uses fresh APPDATA/LOCALAPPDATA. Successful cached case records are reused; use a new evidence folder for a fresh full replay.

- `source.json`: HEAD and main/isolated runtime hashes.
- `harness/`, `harness-source.json`: exact transitive analysis source, including declared extensions. Ordinary/primary behavior is unchanged by the conditional extensions.
- `*.command.json`, matching logs and compressed route JSON: 180 native cases; report files separate135 primary/strata,20 frugal22 and25 final coverage cases.
- `fixed.json.gz`:48 conditional native journal sensitivities, including censored failures;12 baseline reconstructions exactly match captured source journals.
- `audit.py`, `audit.json`:38,347 independent checks, per-route metrics and action-signature comparisons.
- `boundaries.json.gz`: per-route/per-cycle cash, credit, arrears, per-title sales and monthly finance rows. Full native records retain individual transactions/bills/employee events.
- `import-final.log`: fresh-profile import; root-certificate-store warning is environmental.

The source is local uncommitted work atop main b84d1a5. This folder is analysis evidence, not wage approval or release certification. The 22-cycle release feasibility gap and intentionally tiny second project in actual Bank coverage are disclosed in findings.
