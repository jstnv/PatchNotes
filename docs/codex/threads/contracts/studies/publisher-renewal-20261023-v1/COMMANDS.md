# Exact commands and checker provenance

Run from the repository root using Python `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` and Godot `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`. Each linked JSON records the complete argv. Each bundle retains process command JSON, frozen project, isolated profile, source/runner hashes, input, logs, results and replay artifacts. No output was reused.

| Invocation | Result | Exact command / evidence |
| --- | --- | --- |
| baseline | PASS runner; checkpoint acceptance FAIL | [argv](baseline-command.json) / [bundle](../../sims/publisher-renewal-baseline-20261023-v1/run-report.json) |
| baseline-replay | FAILED setup | [argv](baseline-replay-command.json) / [bundle](../../sims/publisher-renewal-baseline-replay-20261023-v1/run-report.json) |
| prefix | INCOMPLETE interrupted | [argv](prefix-command.json) / [bundle](../../sims/publisher-renewal-prefix-20261023-v1/run-report.json) |
| baseline-replay2 | PASS runner; reproduces failed-save baseline | [argv](baseline-replay2-command.json) / [bundle](../../sims/publisher-renewal-baseline-replay2-20261023-v1/run-report.json) |
| prefix2 | PASS runner | [argv](prefix2-command.json) / [bundle](../../sims/publisher-renewal-prefix2-20261023-v1/run-report.json) |
| commission | FAILED setup | [argv](commission-command.json) / [bundle](../../sims/publisher-renewal-commission-20261023-v1/run-report.json) |
| commission2 | PASS runner | [argv](commission2-command.json) / [bundle](../../sims/publisher-renewal-commission2-20261023-v1/run-report.json) |
| support | PASS runner | [argv](support-command.json) / [bundle](../../sims/publisher-renewal-support-20261023-v1/run-report.json) |
| repeat | PASS runner | [argv](repeat-command.json) / [bundle](../../sims/publisher-renewal-repeat-20261023-v1/run-report.json) |
| cold | PASS runner | [argv](cold-command.json) / [bundle](../../sims/publisher-renewal-cold-20261023-v1/run-report.json) |
| repeat-replay | PASS runner | [argv](repeat-replay-command.json) / [bundle](../../sims/publisher-renewal-repeat-replay-20261023-v1/run-report.json) |
| recovery | PASS runner | [argv](recovery-command.json) / [bundle](../../sims/publisher-renewal-recovery-20261023-v1/run-report.json) |
| third | PASS runner | [argv](third-command.json) / [bundle](../../sims/publisher-renewal-third-20261023-v1/run-report.json) |
| third-replay | PASS runner | [argv](third-replay-command.json) / [bundle](../../sims/publisher-renewal-third-replay-20261023-v1/run-report.json) |

Four focused calls used `checks.py <stage> <case> <deal-count>`: prefix2/sports-1112-two-full-briefs-r20/0; support/sports-1112-support/1; repeat/second-support/2; third/third-support/3. Each `*-audit/audit.command.json` records actual executable, script, paths, isolated environment and180s bound. Outputs are17/0,32/0,43/0 and74/0. The final checker adds the cold-session investigation only when deal-count is3; all shared assertions are unchanged.

The original checker path was edited to add that diagnostic after the first three checks. Their exact file hashes were not captured at invocation. [Earlier checker reconstruction](audit-pre-diagnostic-reconstructed.gd) is reconstructed from that sole code addition, not a newly executed or originally hash-pinned file. [Final checker snapshot](audit-final.gd) is byte-identical to the final74-check execution source; its command still names audit.gd. Do not label earlier checker files immutable original captures. Candidate gameplay bytes remained unchanged across all successful new runs and audits.

Variant creation commands were `tools/simulator_variant.py create --id publisher-support-renewal-v1 --owner contracts --from-variant docs/codex/threads/contracts/simulators/publisher-progression-support-market-v1 --output docs/codex/threads/contracts/simulators/publisher-support-renewal-v1`, then the equivalent v2 command with v1 as parent. Both returned exit0 and retain protected base/creation/integrity/ancestry records. `implement.py` failed in v1; `implement_v2.py` restored only owned changes from the historical parent and applied explicit UTF-8. `scoped-delta.patch` records the resulting five paths against that parent.

Final aggregate command: `python analyze.py`,95 checks/0 failures. Raw session digest mismatches remain explicitly recorded; durable envelopes/RNG and the final diagnostic prove their scope. All14 campaign/replay invocations and four focused invocations are accounted for. No further simulation is authorized by this study's exhausted ceiling.
