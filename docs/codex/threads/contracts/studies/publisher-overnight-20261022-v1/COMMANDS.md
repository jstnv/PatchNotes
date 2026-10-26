# Exact executed study commands

2026-10-22. Run from the repository root. Aliases below stand for the exact executables/variant passed on each command. All six run and five replay invocations returned0; three run cases nevertheless failed the required ending-checkpoint acceptance. The original output folders must be retained; reproductions require fresh output paths. This record is not a script to rerun over existing evidence.

```powershell
$pnPython = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$pnVariant = 'docs/codex/threads/contracts/simulators/publisher-progression-support-market-v1'
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/prepare.py
& $pnPython tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/publisher-support-1112-pair-20261022-v1 --case sports-1112-support --output docs/codex/threads/contracts/sims/publisher-overnight-baseline-replay-20261022-v1 --timeout 360 --godot $pnGodot
& $pnPython tools/simulate.py run --variant $pnVariant --config docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/weak-pairs.json --output docs/codex/threads/contracts/sims/publisher-overnight-weak-pairs-20261022-v1 --timeout 360 --godot $pnGodot
& $pnPython tools/simulate.py run --variant $pnVariant --config docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/renewal.json --output docs/codex/threads/contracts/sims/publisher-overnight-renewal-20261022-v1 --timeout 360 --godot $pnGodot
& $pnPython tools/simulate.py run --variant $pnVariant --config docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/recovery.json --output docs/codex/threads/contracts/sims/publisher-overnight-recovery-20261022-v1 --timeout 360 --godot $pnGodot
& $pnPython tools/simulate.py run --variant $pnVariant --config docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/renewal-reduced.json --output docs/codex/threads/contracts/sims/publisher-overnight-renewal-reduced-20261022-v1 --timeout 360 --godot $pnGodot
& $pnPython tools/simulate.py run --variant $pnVariant --config docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/revival.json --output docs/codex/threads/contracts/sims/publisher-overnight-revival-20261022-v1 --timeout 360 --godot $pnGodot
& $pnPython tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/publisher-overnight-renewal-reduced-20261022-v1 --case second-support-minimal --output docs/codex/threads/contracts/sims/publisher-overnight-renewal-reduced-replay-20261022-v1 --timeout 360 --godot $pnGodot
& $pnPython tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/publisher-overnight-weak-pairs-20261022-v1 --case weak2-support --output docs/codex/threads/contracts/sims/publisher-overnight-weak-replay-20261022-v1 --timeout 360 --godot $pnGodot
& $pnPython tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/publisher-overnight-revival-20261022-v1 --case post-cutoff-revival --output docs/codex/threads/contracts/sims/publisher-overnight-revival-replay-20261022-v1 --timeout 360 --godot $pnGodot
& $pnPython tools/simulate.py run --variant $pnVariant --config docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/recovery-renewal.json --output docs/codex/threads/contracts/sims/publisher-overnight-recovery-renewal-20261022-v1 --timeout 360 --godot $pnGodot
& $pnPython tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/publisher-overnight-recovery-20261022-v1 --case miss-recovery-commission --output docs/codex/threads/contracts/sims/publisher-overnight-recovery-replay-20261022-v1 --timeout 360 --godot $pnGodot
```

Input generation and audits also executed with the same Python:

```powershell
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/followup_prepare.py
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/prepare_recovery_renewal.py
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/renewal_model.py renewal-model.json
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/renewal_model.py renewal-model-replay.json
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/audit.py audit-v1.json
```

Inputs were prepared before their dependent runs. Independent pairs of processes were allowed concurrently; no shared mutable project/profile was used. Each run bundle retains original input hashes, exact Godot command JSON, exit/timeout logs, source manifests, runner snapshot, and isolated profile. No seed, budget or output was silently replaced. The minimal failure reduction and campaign revival were declared in PLAN.md before execution.
