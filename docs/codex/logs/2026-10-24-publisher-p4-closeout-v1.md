# SideStreet P4 implementation and acceptance — 2026-10-24

**COMPLETE locally at the approved bounded ACTIVE/TRIAL scope.** Dirty shared `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; existing edits and `.codex-godot-temp` preserved. No commit, push or release-readiness claim.

## Order, authority and changes

The latest user Contract-layout correction completed first: final-size initial hands and wrapped tooltips, with unchanged rules/RNG. The user's game was then closed normally, preserving eight original generations. [Actual P2/P3 EXE acceptance](../findings/sidestreet-p2-p3-20261024-exe-v1/README.md) completed before P4 implementation, satisfying the [explicit dependency and trial approval](../threads/contracts/PUBLISHER-P4-ADOPTION-2026-10-24-v1.md).

P4 now provides frozen Investment-funded Support, one-time productive Begin cash and launch Marketing, Studio ownership with title-only cumulative recoup, sixth-earning-cycle assessment and P1-ordinal renewal. Finance excludes funding from operating profit/Bank income. Strict chronological current/active-rival saves reconstruct the full history; frozen named predecessors initialize empty Support without awards. UI and simulator commands share the authority seam. Continue remains Studio-only; Bank rules and default rival policy are unchanged.

[All 34 project-file changes and hashes](../findings/publisher-p4-20261024-v1/adoption-delta.json): Support authority and five frozen predecessor validators; RunState/Begin/Campaign, awareness, finance, P1/commission facts, typed checkpoint/world migration, Gameplay/Studio/Publisher/predevelopment/Finance/Market/monthly-sales/guide presentation, six maintained historical-projection verifiers and the new Support verifier. The historical packet was inspected, not transplanted. [Predecessor provenance](../findings/publisher-p4-20261024-v1/predecessor-source.json).

Final editor identity `22f504d07fd73970dda3d8746e0cf23ca741afc1436acd5ff3f1630787933036`; actual compiled-PCK identity `6fffe610efd5a29e99f6b6359091f470f56f182814179328c91f6c8ffb5b92cc`. [Full source/evidence fences](../findings/publisher-p4-20261024-v1/verification.json).

## Exact checks/results

| Check | Result |
| --- | --- |
| Fresh maintained matrix |177 suites PASS at c5b37bac…; only final timing words/display spacing in two presentation files differ. Independent review verifies exactly those substitutions; six final-source affected suites pass. |
| Support arithmetic |173/0: I15/I25/cap packages, positive ages23/24/25, cumulative floor/cap, both settlement alignments, criteria misses and nonoperating funding. |
| Legal campaign |241 commands from a fresh game through success → repeat miss → full commission → third Support; seven exact saved boundaries. Both editor and actual PCK record and independent-process replay pass. Every persisted field/RNG matches across all seven editor/PCK boundaries without normalization. |
| Targeted atomic rejection |36/0 after RED-proven partial metadata restore and live supported identity/Scope rejection defects were fixed. |
| Corruption/write/constructed edges |92/0 in source and PCK: malformed repeated histories, exact active DTO, last-valid disk preservation, prepared authority changes, duplicate starts and coherent funded recovery. Cap100 and expense/Bank-journal cases are explicitly constructed, not played campaigns. |
| Named migration |63/0 in source and PCK: four actual prior populated editor/compiled worlds plus earned P2/P3 EXE generation; unknown/joint/rival revision mismatches reject. Store-allocated generation10 is explicitly retained when comparing capture's proposed sequence1. |
| Original player slot |Read-only latest original generation126, cycle14, player/world validation PASS, no Support backfill and unchanged bytes. |
| Populated Founder/rival isolation |19/0 in source and PCK, with a declared legal test policy/Bank bridge. Default rival policy is unchanged. |
| Native scenes |54/0 and24 full live/headless comparisons in each source/PCK run, at1152×648 and1280×720: quote/Back, funding, Marketing, result/availability and strict disk Continue. |
| Actual release EXE |Quote/Back preserves seed generation bytes. One first-four hand per phase, deliberately weak Review0.3 launch, then one older owned-title campaign. Both saved boundaries match all reference gameplay/finance/rights/sales/RNG fields; only seen tutorial topics/pending publisher notifications differ. Raw net$125.87 splits into$25.17 recoup and$100.70 Studio earned/paid. Finance renders$700 nonoperating funding. |
| Actual cold EXEs |Both supported-size Main Menu Continues preserve every earned saved field/RNG exactly. Three actual EXEs exit0; eight original player generations remain byte-exact; production writer62741 released. |
| Build |Clean import/export,371-entry audited PCK, every payload MD5/runtime file check and headless/graphical startups PASS. EXE SHA256 `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`; PCK SHA256 `f56f6f8aafddd375e0ae92b81dd0bdd18e00457a4677ea75908511d004e23855`. |

## Reproduction and retained failures

Use the [findings README and runners](../findings/publisher-p4-20261024-v1/README.md). Bulky immutable projects, profiles, tapes, builds and exact `*.command.json` receipts are outside OneDrive under `C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1/`; their hashes are retained in the compact findings manifest. The checked-in runner files record the exact local Python/Godot paths and arguments. Representative executed commands:

```text
python -X utf8 docs/codex/findings/overnight-20261024-v1/all_checks.py --output <Temp>/regression-v2
python -X utf8 docs/codex/findings/publisher-p4-20261024-v1/check.py p4-route-v4 --route
python -X utf8 docs/codex/findings/publisher-p4-20261024-v1/replay.py <Temp>/p4-route-v4
python -X utf8 docs/codex/findings/publisher-p4-20261024-v1/build.py
python -X utf8 docs/codex/findings/publisher-p4-20261024-v1/compiled.py p4-compiled-route-v1
python -X utf8 docs/codex/findings/publisher-p4-20261024-v1/replay.py <Temp>/p4-compiled-route-v1 --compiled --output-leaf fresh-process-v2
python -X utf8 docs/codex/findings/publisher-p4-20261024-v1/audit_actual.py
python -X utf8 docs/codex/findings/publisher-p4-20261024-v1/finalize.py
```

The first matrix's nine failures were maintained comparisons missing explicitly empty new fields; raw traces, pinned digests and historical fixtures were retained. Other retained failures include genuine rejection RED cases, a fixture signal-closure cleanup cycle, failed legal world budgets/policies, the unnormalized generation comparison, a misspelled verifier selection, and an attempted debug CLI excluded from the package. The last two are harness selection failures, not game failures. External compiled test inheritance/bootstrap is separately pinned; all gameplay executes from the audited PCK. Existing missing-art warnings and six ObjectDB shutdown instances remain; no new runtime ERROR in passing runs. Default `git diff --check` flags CRLF in existing verifier text; the explicit `git -c core.whitespace=cr-at-eol diff --check` check passes without normalizing shared files.

## Remaining limits

Final documentation checks:22 local closeout links exist, all findings-runner Python files parse, and the scoped CRLF-aware whitespace check passes. Final branch/HEAD remain `main`/`0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; `.codex-godot-temp` remains present.

Human comprehension, target-device/audio/license and clean-machine acceptance remain separate. Trial terms are not final balance locks. Cap100/overdue recovery are constructed checks; the direct EXE route is intentionally weak and does not replace the separate scripted full-success/repeat witness. Broader publishers/tiers/P5, the Crown candidate and default rival Support policy remain OPEN. No implementation work in this approved P4 slice remains queued.
