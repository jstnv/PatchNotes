# Large-save validation repair and Windows package — 2026-11-01

Implemented locally and rebuilt **Patch Notes v0.03 — Save Fix**. This repairs repeated validation work; it does not promise instant full-world saves or whole-release acceptance.

[Download Windows ZIP](<release/Patch Notes v0.03 - Save Fix.zip>) · [Package hashes and integrity](delivery.json) · [Build/source manifest](build-manifest.json) · [Dated session log](../../logs/2026-11-01-large-save-validation-v2.md)

## Source and changes

Branch `main`, HEAD `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`, shared dirty checkout. Existing edits and `.codex-godot-temp` preserved. No commit, push or Drive publication. The package contains the current runtime checkout, including the pre-existing Engine/Awards work; this task's delta is separately captured in [turn-production.diff](turn-production.diff).

- [StudioFanbase](../../../../patch-notes/scripts/fanbase/studio_fanbase.gd): successful replay prefixes can resume only when exact typed replay inputs, source/rule context and cutoff match. Full supplied sales validation and final rebuilt-state equality remain mandatory. Future campaigns/factors are excluded only from an earlier prefix's drivers. The cache retains detached values, is mutex protected, and is bounded to 18 entries / 32 MiB of serialized proof material.
- [StudioFinanceLedger](../../../../patch-notes/scripts/finance/studio_finance_ledger.gd) and new [JournalKey](../../../../patch-notes/scripts/finance/journal_key.gd): successful journal proofs survive dictionary insertion-order changes introduced by the typed checkpoint codec. The complete recursive comparison preserves scalar/container types, array order and float bits. Non-String keys, typed containers and unknown values use the full validator. Count 128 / serialized 32 MiB bounds include detached proof snapshots; oversized snapshots retain the existing byte-only proof path.
- [RivalWorldCheckpoint](../../../../patch-notes/scripts/market/rival_world_checkpoint.gd): add only genuine predecessor `b496434dc8095aefd67d498de3f9f98c2992abaa5d531bbd36ff7017ec9a2547`. Existing annual-ledger, Pass Budget and frozen engine ID/capacity guards remain. The file's pre-existing CRLF format is preserved.

Final runtime identity: `5d27b061021aac5944f855395ab011b9f3de844e4145f17c857bdac88f2f01eb`. Canonical, clean-project and original exported-pack identities agree. No gameplay values, finance/sales rules, RNG algorithms, save schema, worker priority, rendering cap, visibility or pause behavior changed.

## Measured behavior

[Matched serial native comparison](matched-native-comparison.json): same genuine eight-rival cycle-96 fixture, legal actions and RNG; isolated local projects outside OneDrive. The baseline restores the exact pre-task production files and reports runtime `b496…`; the optimized project is the exported source copy.

| Native action | Before | After |
| --- | ---: | ---: |
| Search | 214 ms | 274 ms |
| Immediate Accept, including latest-save barrier | 7,915 ms | 4,744 ms |
| Search + Accept | 8,129 ms | 5,018 ms |
| First hand CPU call | 257 ms | 270 ms |

The entire final player is identical; the entire rival world is identical except its executing-source stamp. This includes finance, history, market records, calendar, projects and RNG. Both runs retain three successful worker publications and no active-Contract checkpoint. Full publications still take roughly 2.4–3.1 s in this pair, and durable departure remains measurable.

Focused final-source measurements: Fanbase full replay **99,524 µs**, warm proof **2,974 µs**; finance full replay **41,655 µs**, insertion-order-only proof **9,522 µs**. These are bounded samples, not device or future-save guarantees. Earlier canonical/native-pack runs were slower (14.815 s / 12.451 s Accept); retained receipts show the variation. They are not concealed or presented as controlled improvements. An unrelated existing DEBUG game was left untouched.

## Verification

All receipts include exit/error scanning and production-source fences where applicable. [Suite results](suite-results.json), [baseline control](baseline-control.json), [identical failure comparison](baseline-failure-comparison.json).

- **90/90** Fanbase reference/current checks, including every genuine actor and later productive/month-boundary steps.
- **36/36** finance proof/reference checks.
- **249/249** boundary checks: same-cycle awards/launch ordering; odd legacy calendar closure; valid historical and future campaigns/factors; detached mutation; concurrent validations; count/byte eviction; typed/StringName/malformed finance fallbacks.
- **11/11** cold genuine predecessor checks, including rejection of missing/invalid annual, budget, engine, capacity, source, RNG and calendar state.
- **38/38** coalescing, failure/Retry, replacement, latest-state and teardown checks.
- **21 of 24** broader/current check invocations pass, including Bank accounting, finance proofs, Fanbase, annual awards, codec/store/runtime, background publication, campaigns and Engine workflow/Continue.
- **Three existing suites FAIL identically on the exact pre-fix production control:** `verify_finance_observation` (47 aggregate/hiring assertions; its retained legacy aggregate predates the current Employee interface); `verify_bank_integration` (one 1152×648 fit assertion); `verify_campaign_latency` (one reopening-refresh assertion). These are not closed or counted as passes. The two historical Contract/commission fixture incompatibilities recorded in [v1](../contract-latency-20261101-v1/README.md) are also not closed or rerun unchanged here.

Independent read-only code review found no blocking concern after inspecting the 249-check receipt and matching production hashes. Review is separate from executable/device acceptance.

## Executable and archive acceptance

- Godot **4.7.1.stable.official.a13da4feb**; installed release/debug template SHA-256 values match the previously verified pinned templates. The old console executable path was absent; the installed GUI editor built the package successfully. All asset import settings were retained in the clean project. Canonical sources were unchanged during export.
- Original PCK: **311 entries**, every payload MD5 valid; runtime scripts/JSON match the copied source; debug/evidence/cache materials excluded. All **six** source paper-icon images are present in the PE. Font and engine licenses are packaged.
- Unmodified EXE + shipped PCK: native default-startup smoke exits 0 with no error markers.
- Original PCK under the full Godot runner: old-save negatives, complete native cycle-96 Contract flow and exact state comparison pass. Independent cold Continue takes 5,636 ms in this sample and preserves save bytes without repeated settlements. [Six-case receipt](export-acceptance.json).
- Actual release executable: independent cold Continue passes in **4,460 ms** using an isolated bootstrap pack beside a byte-identical EXE. Only `project.binary` / UID cache differ among original pack entries; three test-bootstrap entries are added. Every original runtime payload and runtime identity matches. Complete player/world equality, no rewrite/duplicate settlement and Studio-only Continue pass. The bootstrap is **not shipped**. [Explicit test boundary and receipt](template-acceptance.json).
- Native pointer acceptance: **NOT RUN**. Computer Use's app-approval step timed out. No routine user confirmation was requested; no alternate OS-input automation was used. The private-profile test EXE was closed; unrelated windows/player saves were preserved.
- ZIP: CRC for every member and SHA-256 equality against every packaged original pass. EXE/PCK hashes still match the export, and canonical source hashes still match the build manifest. [Delivery receipt](delivery.json).

Retained setup/failed trials include the initial failing performance tests, the discarded sorted-key prototype, unsupported release `--script` attempt, the corrected external-script inference errors and unsupported release `--main-pack` attempt. The release template disables those CLI facilities; its adjacent-pack bootstrap test supplies the permitted software-testing route.

Larger histories/populations, sustained device frame rate, native pointer/menu acceptance, missing artwork, the existing broad fixture/layout failures and whole-release acceptance remain separate follow-ups. This package is not a claim that those gates passed.
