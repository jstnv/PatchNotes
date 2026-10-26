# New queue implementation and review — 2026-10-17

## Authority and source

User: complete the new internal TODO tasks without waiting for input. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty checkout preserved. No commit, push, player-save edit or `.codex-godot-temp` cleanup. [Intake](intake.json), [original source](baseline-source.json), [final source](final-source.json), [exact project delta](source-delta.json), [session log](../../logs/2026-10-17-new-queue-implementation-v1.md).

Adoption authority: [Market Index](../../threads/ai-competitors/handoffs/market-index-foundation-v1/HANDOFF.md), [Founder ledger](../../threads/founder-legacy-ownership/handoffs/victory-ledger-v1/HANDOFF.md), [Alpha pack](../../threads/feature-pools/handoffs/first-authored-alpha-shop-pack-v1/HANDOFF.md). The Founder candidate's seven file pins reconcile exactly before integration. The Alpha handoff's prior-catalog hash is malformed; [audit](handoff-pin-audit.json) retains it and verifies the actual intake catalog SHA plus all four printed rows against the authored catalog. No shortened hash is represented as a verified SHA-256.

Final gameplay replay identity: `f8f130c6a3e6b7d27710e11a56b445ea6c73d9dbc26ca26a8501ca2cf7ca32de`. Debug-only verifier changes are separately pinned. Query-only code lives under `queries/`, outside the gameplay identity; simulator manifests, release-gate source checks and exported package audits explicitly include it.

## Implemented

### Four Alpha Store cards — ACTIVE/TRIAL

Turn-Based Combat, Character Classes, Character Development and Branching Dialogue now have their approved ordered scores, Scope 2, finite Alpha lifecycle, departments and named parents. Each uses the approved $1,700 base / $0 later-card play fee: $850 admission and nominal $850 final Research installment, with existing earned familiarity/Resourceful adjustments. Owned parents use AND semantics; queued parents do not count. Completion adds future-project supply only. The prior eleven later Features and Primitive/specialty/Contract supply are unchanged.

The expanded Store reserves space for each whole branch; Character Classes and Difficulty Levels previously overlapped. Map navigation tests now drag across the actual canvas origin. All four details and card faces were rendered at 1152×648 and 1280×720. Ten captures are retained in [visuals-v2](visuals-v2/); inspected examples include [Character Classes](visuals-v2/store-1152-character_classes.png), [Branching Dialogue](visuals-v2/store-1280-branching_dialogue.png), [Turn-Based Combat](visuals-v2/store-1280-turn_based_combat.png) and [four card faces](visuals-v2/cards-1152.png). No abbreviated catalog fields remain in the 55-card text-fit check. Fallback artwork is intentional; final art and human comprehension remain separate.

### Neutral release index — read-only foundation

`queries/market_release_index.gd::query(world)` derives ordered real releases from the player, current rivals and continuing former-player owners. Rows carry stable IDs, title/Genre/Theme/date, frozen Review/Core availability and actual earned units/entitlement/settled cents. It excludes archives and previews. Malformed required records fail the whole query with a reason; absent/malformed optional Cores produce `cores_available=false`, never invented zeros. Results are owned copies.

The query leaves all owner states, RNG and world-checkpoint bytes unchanged. It introduces no active Review/sales effect, UI, monthly snapshot or load gate. A six-release test includes actual legal releases, cold restore and operator transfer. **Older missing-Core save migration is not claimed:** the existing Studio codec rejects that malformed historical fixture. Optional-Core behavior was tested on a readable runtime owner after a valid player-only restore. Actual supported prior-source world migration is tested separately below.

### Founder victory ledger — structural foundation

Explicit Founder worlds now carry a versioned claim ledger. The ten-subsidiary evaluator counts distinct direct/indirect majority-controlled subsidiaries beneath founder-majority roots; roots and exact-50% interests do not count. A qualifying ownership settlement publishes cash, cap tables and its permanent once-only claim together. No cash, shares, IP, forced ending or other victory route is added. Version-one data stays readable and activates the ledger on the next successful ownership transaction.

Integration hardens integer versions and historical claim proofs. It also fixes Studio operator handoff after a rival launch: a finalized registered Beta project can remain for inspection; an active project still blocks handoff. The actual ten-subsidiary commit test is an explicitly constructed eleven-Studio in-memory fixture, with a real consented $10 purchase and observer checks. **The eight-rival checkpoint cap still makes this victory unreachable in a saved normal campaign.** The test confirms the larger fixture cannot be saved; it is not a playable career proof.

### Compatibility and maintained test tooling

The exact prior eleven-node catalog revision and pre-ledger Founder source are recognized through narrow compatibility paths. Actual old-source player and active-rival/Founder checkpoints restore with cash, RNG, hands, history and project supply unchanged; only source/content revision metadata changes. Unknown source/catalog identities still reject. No already-active project receives the new cards.

The release gate now orders artifact-producing tests before cold consumers, adds Alpha/index cold passes, clears inherited test-mode flags, includes `queries/` in provenance, and verifies a pinned old-source fixture under `tools/fixtures/`. The UI verifier skips GPU capture under headless execution while retaining layout checks. The fixture is copied byte-for-byte from the original-source run, with its provenance/hash alongside it.

## Checks and actual scope

| Evidence | Result |
|---|---|
| [Final focused run](final-checks-v1/results.json) | 13 suites pass: Store navigation/copy 52; card fit 1,841; Alpha priorities; migration 8; Alpha pack 174; Alpha cold 28; index 151; index cold 4; Founder 13; world 30; Founder cold 6; Gameplay 10 |
| [Rendered Store checks](visuals-v2/results.json) | Radial map and 58 UI assertions pass; ten captures. This older run's navigation failure is retained and superseded by final-checks-v1 |
| [Atomic victory settlement](victory-commit-v3/results.json) | 17/17; real purchase, observer consistency, duplicate rejection, exact codec and forged-proof rejection; no larger-roster save claim |
| [Parent/research regression](alpha-v3/results.json) | Two-parent 65 plus research/integration pass; its old Store node-count failure is retained and corrected later |
| [Fresh campaign](fresh-campaign-v1/run-report.json) | Action/4417, Adventure/4471, Strategy/4714: two releases each, 36 accepted commands each, cycle 14 |
| Fresh replays | [Action](fresh-replay-action-4417/run-report.json), [Adventure](fresh-replay-adventure-4471/run-report.json), [Strategy](fresh-replay-strategy-4714/run-report.json): 108/108 exact command outcomes |
| [Python tooling](python-final-v2.log) | 32 tests pass: release gate 11, simulator 15, export validation 6 |
| [Maintained gate integration](maintained-gate-jobs-v1/summary.json) | Eight affected jobs /459 assertions pass; all original source hashes unchanged, six import-generated UID sidecars independently validated |
| [Build](build-v1/build-manifest.json) / [package](build-v1/pack-manifest-verified.json) / [startup](build-v1/headless-startup.command.json) | Clean import/export/startup exit 0; 301 package entries, all payload checksums valid, no missing/unexpected files; exported query included |
| [Private AI variety](AI-VARIETY.md) | Two fresh 20-cycle processes pass 213/213 each with identical observations/state/RNG, four actual rival releases; representative 18-command player replay exact |

The Alpha mechanics suite explicitly funds its fixtures to isolate acquisition/scoring behavior. It is not an affordability or balance study. The three fresh-start campaigns have ordinary initial funds and no injected cash, but do not claim to acquire all four cards. The prior publisher/Bank graphical acceptance retains its older binary boundary; this pass is not a new full publisher matrix or whole-release approval. The focused gate integration and its exact jobs are recorded in [maintained-gate-jobs-v1](maintained-gate-jobs-v1/).

EXE SHA-256: `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`; PCK: `87a0a11922a1201aaf2e4bba64b6935f2c19d67dd2ad05779ad28837be7bc3ff`. [Closeout audit](closeout-audit.json) checks current canonical export inputs against this build and compares both private AI runs.

## Retained failures and repairs

- Early index attempts exposed snapshot omission, test-fixture timing/type problems, invalid missing-Core save assumptions and the real post-launch handoff bug. All attempts remain in their versioned folders.
- Alpha v1 needed explicit starter confirmation; v2 passed an untyped Array into a typed fee API and reached its external timeout. The fixture was corrected and given a finite internal timer. Later Store count/drag assertions were updated for the expanded map.
- The rendered pass exposed real branch overlap and measured popup bounds before tweens completed; both were corrected and recaptured.
- The first exported package inspector rejected the new `queries/` root. Its allowlist now audits that root; the original failed inspector and successful v2 are both retained.
- AI variety run v1 rejected concurrent canonical debug-source drift during capture. Run v2 used a fresh output folder and passed the provenance fence. No fence or saved identity was bypassed.
- Victory verifier v1 had an inferred-type parse error; v2 retained an observer reference cycle. V3 disconnects the observer and passes. Some inherited world/rival probes still emit the existing six-ObjectDB-instance exit warning; no `ERROR`/script errors occur in the accepted runs.
- Initial combined Python invocation named a nonexistent `test_export` module. Corrected `test_export_validation` invocation passes all 32; the first log remains.
- All eight maintained-gate jobs pass459 assertions. The wrapper's final strict source comparison then rejected six Godot import-generated UID sidecars. [Independent follow-up audit](maintained-gate-jobs-v1/summary.json) confirms every original hash unchanged and validates only `.gd.uid` additions. The original wrapper is retained as `gate_jobs-original.py`; the reusable wrapper now handles these additions explicitly.

## Review disposition and remaining work

[Design review](DESIGN-REVIEW.md) completes the bounded Handoffs 013/014 review with an explicit first-pack deferral and concrete recommended typed entitlement/frozen-project migration contracts. Current Genre/Theme options and +2 Passes stay unchanged. Contract challenge integration is reviewed, but publisher mappings, targets/fades, bonus caps and rounding remain unapproved. No $100/+4 candidate is adopted.

Active market pressure still needs the separate private transaction/project-standard/per-age-month-ledger prototype and numeric/migration decisions before any canonical handoff. The variety result closes the old bounded timeout follow-up only; it does not complete that active-effects work or broader AI policy/Genre-choice coverage. Founder route UI, saved-population expansion, annual awards, market denominator, Innovation Path and comeback rules retain their explicit design/dependency gates. Human quote/Store understanding, audible/device timing, final art, clean-machine acceptance and final tuning are not automated completions.
