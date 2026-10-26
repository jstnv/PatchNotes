# G4 benefit-choice bundle audit

Bundle: `C:\Users\64jus\OneDrive\Documents\GitHub\PatchNotes\docs\codex\threads\ai-competitors\sims\g4-benefit-choice-20261018-v1`
Frozen source: `20c89b3748c9d57026e6dea7d12c83ef140a59371da9a4fe89e2a503b1175d69`
Audit complete: **False**

| Group | Mode | Status | Review | Core | Scope | Bugs | Launch cash | Fans | Actual units | Settled cents | Policy/obs μs |
|---|---|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| action-4417 | reference | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| action-4417 | cheapest_quote | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| action-4417 | benefit_quote | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| action-90210 | reference | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| action-90210 | cheapest_quote | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| action-90210 | benefit_quote | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| adventure-4417 | reference | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| adventure-4417 | cheapest_quote | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| adventure-4417 | benefit_quote | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| adventure-90210 | reference | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| adventure-90210 | cheapest_quote | invalid_policy | — | — | — | — | — | — | — | — | 0 |
| adventure-90210 | benefit_quote | invalid_policy | — | — | — | — | — | — | — | — | 0 |

## Integrity and coverage

- action-4417: initial full state/RNG equal = True; issues = none
  - Benefit minus reference: Review None, launch cash cents None, actual units None
  - Benefit minus cheapest_quote: Review None, launch cash cents None, actual units None
- action-90210: initial full state/RNG equal = True; issues = none
  - Benefit minus reference: Review None, launch cash cents None, actual units None
  - Benefit minus cheapest_quote: Review None, launch cash cents None, actual units None
- adventure-4417: initial full state/RNG equal = True; issues = none
  - Benefit minus reference: Review None, launch cash cents None, actual units None
  - Benefit minus cheapest_quote: Review None, launch cash cents None, actual units None
- adventure-90210: initial full state/RNG equal = True; issues = none
  - Benefit minus reference: Review None, launch cash cents None, actual units None
  - Benefit minus cheapest_quote: Review None, launch cash cents None, actual units None
- action-4417-reference: Case did not complete legally
- action-4417-cheapest: Case did not complete legally
- action-4417-benefit: Case did not complete legally
- action-90210-reference: Case did not complete legally
- action-90210-cheapest: Case did not complete legally
- action-90210-benefit: Case did not complete legally
- adventure-4417-reference: Case did not complete legally
- adventure-4417-cheapest: Case did not complete legally
- adventure-4417-benefit: Case did not complete legally
- adventure-90210-reference: Case did not complete legally
- adventure-90210-cheapest: Case did not complete legally
- adventure-90210-benefit: Case did not complete legally
- Bundle: Run report is not successful; retained partial evidence follows

## Limits

- A matching digest and telemetry hash are file-consistency checks; fresh-process replay remains separate.
- The Variant tape is retained but not decoded by this helper.
- Feature-play finance rows aggregate by month; selected quote costs are checked against next cash and their aggregate, not a per-hand receipt field.
- Actual sales fields exclude projected units and gross.
- The first release ends the case, so later monthly sales need the declared Studio continuation.
