# Exact command families and retained invocations

Working directory: `C:\Users\64jus\OneDrive\Documents\GitHub\PatchNotes`.

```powershell
$py='C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$godot='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe'
$study='docs/codex/threads/contracts/studies/crown-cash-20261028-v1'
$variant='docs/codex/threads/contracts/simulators/crown-cash-20261029-v3'
& $py -X utf8 tools/simulate.py run --repo "$study/frozen-reference" --variant $variant --config "$study/access-config.json" --output "$study/runs/access-v5" --timeout 900 --godot $godot
& $py -X utf8 tools/simulate.py run --repo "$study/frozen-reference" --variant $variant --config "$study/scope-access-config.json" --output "$study/runs/scope-access-v1" --timeout 900 --godot $godot
# Later immutable-reference invocations suppress discovery of the unrelated parent Git worktree.
$env:GIT_CEILING_DIRECTORIES=(Join-Path $PWD $study)
& $py -X utf8 tools/simulate.py run --repo "$study/frozen-reference" --variant $variant --config "$study/payroll-fixture-config-v2.json" --output "$study/runs/payroll-fixtures-v2" --timeout 900 --godot $godot
& $py -X utf8 tools/simulate.py run --repo "$study/frozen-reference" --variant $variant --config "$study/cold-config.json" --output "$study/runs/cold-studio-v1" --timeout 900 --godot $godot
& $py -X utf8 tools/simulate.py replay --bundle "$study/runs/payroll-fixtures-v2" --case final-source-formula-payroll-fresh-release --output "$study/runs/fresh-replay-v1" --timeout 900 --godot $godot
& $py -X utf8 tools/reduce_simulation.py --bundle "$study/runs/scope-access-v1" --case access-action-4417 --kind rejection --output "$study/runs/scope-failure-reduced-v1" --timeout 900 --max-commands 450 --godot $godot
& $py -X utf8 tools/reduce_simulation.py --bundle "$study/runs/baseline-regenerated-v1" --case baseline-action-4417 --kind rejection --output "$study/runs/baseline-reduced-v2" --timeout 900 --max-commands 450 --godot $godot
& $py -X utf8 "$study/branches.py" "$study/runs/scope-access-v1"
& $py -X utf8 "$study/audit_access.py"
& $py -X utf8 "$study/payroll_ceiling.py"
```

These paths name already-existing evidence; do not overwrite or reuse them. Reproduction requires new output directories. Every run also retains exact engine argv in `import.command.json`/`experiment.command.json`, original request and materialized policy/hash in `inputs/`, source manifests and actual process status. Replay/reduction folders retain their own exact argv and confirmations.

Creation sequence: `simulator_variant.py create --id crown-cash-baseline-20261028-v1 --owner contracts --output docs/codex/threads/contracts/simulators/crown-cash-baseline-20261028-v1`; subsequent `create --from-variant` forks named crown-cash-20261028-v1, crown-cash-20261028-v2, crown-cash-20261029-v3. Original base and creation manifests/integrity record each source. `reconcile.py`, `prepare_baseline.py`, `add_crown_cash.py`, their explicit repair records and parent versions preserve the development history; these one-shot mutation scripts are historical construction records, not idempotent commands to rerun against sealed candidates.

Earlier failure/retry details and the lost Downloads outputs are listed in the preregistration. `baseline-config.json` regenerated the old policy with variant crown-cash-baseline-20261028-v1 and the ordinary repo default. `access-v3` used candidatev2; `access-v4` candidatev3 but rejected live canonical drift. Final preserved access/fixture runs use candidatev3. The repaired external payroll policy has explicit version2; version1's parse failure is retained. No successful cash career is implied by an engine exit0 on the synthetic fixtures.
