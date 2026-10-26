# P1 Publisher relationship foundation

2026-10-23. User authorized proceeding with the proposed structural investigation and private prototype. **PROPOSED implementation specification; no gameplay awards or numeric balance approval.**

## Approach

Use a per-Studio typed event ledger, reconstructed through code-owned event resolution. A totals-only map would be smaller but cannot prove duplicate handling or reconstruct awards. Adopting the entire earlier commission/support candidate would couple this foundation to unapproved terms and known save defects. Select the ledger-only approach for this private prototype.

Studio ownership uses the existing stable bank/run ID, independently of Founder/operator identity. The five publisher IDs come from current Contract definitions. New and migrated Studios start with an empty history and zero standing. No current Contract, challenge, notification, release or Founder transition issues an award. Reputation and Investment remain separate integer hundredths with a candidate representational range 0..10000; this representation does not authorize amounts, gates or decline/decay rules.

## Data and commands

`PublisherRelationships`: pure schema, construction, reconstruction and append planning. Record version, owner and ordered events; derive balances, do not persist a second mutable balance cache. Events carry contiguous ordinal, stable event ID, source ID, publisher ID, event kind, productive cycle, requested and actually credited values for both measures. Event IDs cannot be reused with different terms. Source/kind identity is unique within one Studio, including across publishers. Exact retries are successful no-ops. Different publishers and different Studios remain isolated.

`PublisherRelationshipRules`: code-owned resolver for facts already committed by an approved producer. P1 has **zero enabled producers**. Unknown events and forged nonzero histories reject. A future producer must freeze terms and validate source provenance before this resolver can return an expected event; amounts never come from a save or UI command. Fixture resolvers are confined to the verifier and passed explicitly to the pure ledger, never registered in runtime.

`RunState`: stores the ledger, returns detached relationship observations, and exposes a guarded internal commit seam. Resolve before mutation; validate the old ledger, identity and current cycle; plan completely; replace once; then notify observers. Hold the reentry guard through notification. No cash, cycle or RNG effects. A read must not create a record. Guard checkpoint mutation and productive/launch transactions; future awards inside those transactions need an explicitly coordinated adoption, not an unsafe generic call.

`StudioCheckpoint` and schema: encode the typed ledger and validate all events using the production resolver. Introduce a named rules revision. An exact frozen preceding schema/validator verifies predecessor data before zero initialization; unknown or malformed shapes reject. Preserve the original payload and RNG. Existing pre-market migration must still initialize the new empty ledger. Simulation envelope source compatibility remains strict; generate fresh legal campaigns for each revision rather than rewrite an old envelope.

## Acceptance and limits

Pure fixtures: credit isolation, integer bounds, clipped credits at cap, zero actual credit retained as an event, exact retry, collision rejection, reordered/duplicate/forged/wrong-owner/future-cycle histories and detached results. Fixture successes are structural coverage, not actual gameplay rewards.

Runtime: empty-ledger new Studio, exact native codec roundtrip and fresh-process hydrate, predecessor zero migration without changes to other fields, malformed histories rejected, saved state preserved after rejected mutation, Studio-only envelope guard. Two legal ordinary two-release campaigns must retain cash/sales/Contracts/Features/Fans/RNG compared with identical baseline recipes, ignoring only the documented additive ledger and revision metadata. Separate fresh replay of one baseline and one candidate route. Test current Contract definitions and challenge behavior against the frozen candidate. Full native disk coordinator/world migration and export acceptance must be reported at actual coverage, never inferred from headless codec checks.

P2-P4 integration, enabled awards, relationship UI, commissions, support, fees and renewal remain outside P1. The independent-client cash Brief remains a separate prior commitment.
