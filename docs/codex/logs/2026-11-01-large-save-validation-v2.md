# Large-save follow-up and Windows rebuild — 2026-11-01

User: fix remaining large-save delay, then rebuild EXE/ZIP without routine input.

Started and finished on `main`, HEAD `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`; existing shared edits and `.codex-godot-temp` preserved. No commit/push/publication. Final tracked dirty count before these already-dirty status records was 66; the package intentionally includes the current shared runtime. [Exact evidence, changes and limits](../findings/large-save-20261101-v2/README.md).

Production delta: `scripts/fanbase/studio_fanbase.gd`, `scripts/finance/studio_finance_ledger.gd`, new `scripts/finance/journal_key.gd`, and one exact predecessor addition in `scripts/market/rival_world_checkpoint.gd`. The source-pinned pre-task copies and full per-turn diff are retained. No balance, financial rules, RNG, schema, worker priority or Studio-only Continue change.

Diagnosis: Fanbase validation repeatedly reconstructed the full historical prefix; finance's successful byte proofs missed equivalent codec-reordered dictionaries. Added bounded successful detached replay proofs and a finance-only strict recursive alias check. Invalid inputs continue through complete validation; complete final state comparisons remain. Native/synthetic code paths were not weakened to obtain timing improvements.

Checks/evidence (complete argument lists and profiles are retained in the corresponding `result.json` / `command.json` receipts):

- `python docs/codex/findings/large-save-20261101-v2/suite.py`: 24 invocations, 21 PASS, three existing FAIL. Custom results: Fanbase90/0, finance36/0, boundaries249/0, predecessor11/0, coalescing38/0. Every fenced run reports unchanged source.
- `python .../baseline_control.py`: restore the exact nine pre-task production files in an isolated project; all three existing failing suites produce identical error lists. `baseline-failure-comparison.json` asserts equality. These failures remain open.
- `python .../run.py --project <baseline-control> --script <export_profile.gd> --output <baseline-native96> --fixture <current-world/fixture.json> --native --fence --timeout 240`, followed by the same command against `<source>` into `<final-local-native96>`: both PASS, full final player/world equality except source stamp. Search+Accept8,129→5,018ms; full worker publication remains2.4–3.1s. First-hand CPU257→270ms. Slower earlier native receipts retained, not generalized into a performance guarantee.
- `python .../build.py`: clean import and Windows release export0/no errors, pinned editor version/template hashes, all asset import settings copied, source fence unchanged. GUI editor used because the old console path was absent.
- `python .../inspect_pack.py`:311 original PCK entries verified, all payload hashes/exclusions/exact scripts/data, six native icon images.
- `python .../export_accept.py`, then `--resume` after correcting the external fixture's two inference errors: six acceptance cases PASS. Default native EXE startup and exact original-pack native flow/old-save/cold Continue covered. Release templates do not implement `--script`; that failed harness attempt is retained.
- `python .../template_accept.py` prepares the isolated boot fixture; release `--main-pack` is disallowed and its rejection is retained. `python .../template_run.py` uses normal adjacent-pack discovery beside a byte-identical release EXE: native cold Continue4,460ms,0 errors, exact player/world, unchanged save bytes/no duplicate settlement, Studio-only boundary. Original runtime payloads/identity match; bootstrap config/UID/test resources are explicitly separate and not packaged.
- Computer Use app approval timed out at window-state acquisition: native pointer checks NOT RUN. No user approval question or alternate OS-input route; private-profile test process closed. Other windows/player profiles left alone.
- `python .../package.py`: ZIP CRC and all member SHA-256 comparisons PASS; exported EXE/PCK and canonical source fence still match. [Download and checksums](../findings/large-save-20261101-v2/delivery.json).

Final runtime `5d27b061021aac5944f855395ab011b9f3de844e4145f17c857bdac88f2f01eb`; genuine predecessor `b496434dc8095aefd67d498de3f9f98c2992abaa5d531bbd36ff7017ec9a2547` is admitted only through existing modern-field guards. Independent read-only review reports no blocking concern after matching the249-check manifest.

Remaining: nonzero full durable-save cost, larger-history/device performance, native pointer acceptance, three baseline verifier/layout failures and the two prior historical Contract/commission fixture incompatibilities. No whole-release acceptance, instant-save, commit or push claim.
