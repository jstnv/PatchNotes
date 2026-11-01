# Legacy annual cutoff regression — 2026-10-31

Narrow final-review fix on shared `main`, HEAD `49d769235474a880a73d996499cefa72beec63e5`. Existing dirty work and `.codex-godot-temp` preserved. Owned production delta is only `annual_awards_ledger.gd:first_eligible_year`; added `scripts/debug/verify_annual_awards_legacy_cutoff.gd` and these `legacy-cutoff-*` findings. No commits, pushes, exports or children. Parent explicitly cleared production after its old-source acceptance finished; test-first RED preceded this helper edit.

The supported Clock profile `{version:2,legacy_until:23}` presents raw23 as1980 December Week3. December Week2 is absent from the old two-cycle prefix, so `cycle_at` returns-1. The old helper incorrectly used that absence to retain1980 as first eligible. A real1981 settlement then failed ledger validation because the expected first entry was1980. The same issue exists at later odd December cutovers such as raw47/1981.

The helper now asks Clock for actual year, month and quarter at inception. At/past December Week2 it begins the next year, even if the old cutoff has no raw cycle. Before1980 it still returns1980, preserving rival/prelude behavior. It does not alter settlement, ranking, payouts, schema or migration admission.

## Checks and source

All runs used installed Windows Godot4.7.1, private profiles/free checkpoint ports, and the existing `run_check.py` wrapper with `--fence --timeout 60`. Exact command:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/findings/annual-awards-20261031-v1/run_check.py --script res://scripts/debug/verify_annual_awards_legacy_cutoff.gd --output docs/codex/findings/annual-awards-20261031-v1/legacy-cutoff-green-v1 --fence --timeout 60
```

- `legacy-cutoff-red-v1`: FAIL due to test parse/type inference; retained as harness evidence, not meaningful RED.
- `legacy-cutoff-red-v2`:35 checks/10 failures. Initial modeled Studio lacked a name; retained, superseded by corrected test scaffold.
- `legacy-cutoff-red-v3`: meaningful RED,35 checks/8 failures, exit1. Next-year settlement succeeded, but both cutovers retained the expired year and failed subsequent ledger/typed-roundtrip validation. Entire source unchanged during run.
- `legacy-cutoff-green-v1`: PASS35 checks/0 failures, exit0, no ERROR or SCRIPT ERROR. Entire source unchanged during run. The unchanged regression now accepts actual next-year settlement, validates the result without a missing dead year, repeats settlement inertly, and encodes/decodes a still-valid typed ledger.

The35 checks cover raw23/raw47 odd December cutovers; next-year due-cycle reachability and actual ledger settlement/validation; fresh raw44/45/46; January; December Week1;1977 December; and the1977 prelude reaching1980 January. Each run emitted an engine shutdown warning for10 ObjectDB instances; this focused task does not claim leak-free shutdown.

`legacy-cutoff-source-pins.json` records exact final file bytes, SHA256, newline counts and RED-to-GREEN source delta. Production SHA256: `6f040ad15574b030df7ca60b2b2ece4113720377947d7e42b788b31d26c8e74e`. The only source delta between meaningful RED and GREEN is the production helper file.

## Limits and follow-up

The regression explicitly constructs calendar models and a one-owner/no-release ledger model. It uses the actual Clock, ranking, settle, valid and typed checkpoint codec; it does not fabricate an old checkpoint, claim historical provenance, validate the entire modeled Studio/GlobalWorld, or establish a full legal old-save career. Bounded inspection found genuine old calendar fixtures, but this task did not alter or recapture them. Parent owns final source-fenced legal world, genuine migration, native ceremony and broader maintained checks on the fixed helper. No balance, device or release-readiness claim.
