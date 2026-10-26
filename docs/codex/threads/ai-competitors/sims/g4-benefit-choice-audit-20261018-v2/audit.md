# G4 benefit-choice bundle audit

Bundle: `C:\Users\64jus\OneDrive\Documents\GitHub\PatchNotes\docs\codex\threads\ai-competitors\sims\g4-benefit-choice-20261018-v2`
Frozen source: `b9ac377ff491cee4ae4d9a3ddf0881daf6a978cb069409ab970afa5b3c8903b5`
Audit complete: **True**

| Group | Mode | Status | Review | Core | Scope | Bugs | Launch cash | Fans | Actual units | Settled cents | Policy/obs μs |
|---|---|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| action-4417 | reference | completed | 2.1 | [22, 8, 22, 16] | 25/30 | 4 | 419000 | 20 | 229 | 0 | 61943 |
| action-4417 | cheapest_quote | completed | 0.4 | [15, 4, 19, 7] | 14/30 | 1 | 472000 | 20 | 43 | 0 | 70245 |
| action-4417 | benefit_quote | completed | 2.1 | [21, 9, 21, 17] | 25/30 | 4 | 419000 | 20 | 229 | 0 | 67665 |
| action-90210 | reference | completed | 2.3 | [14, 11, 27, 10] | 23/30 | 1 | 429000 | 20 | 253 | 0 | 59619 |
| action-90210 | cheapest_quote | completed | 0.9 | [11, 15, 14, 4] | 13/30 | 0 | 477000 | 20 | 99 | 0 | 135096 |
| action-90210 | benefit_quote | completed | 2.3 | [14, 10, 27, 11] | 23/30 | 1 | 429000 | 20 | 253 | 0 | 61703 |
| adventure-4417 | reference | completed | 1.3 | [16, 6, 12, 22] | 20/30 | 3 | 445000 | 20 | 142 | 0 | 58347 |
| adventure-4417 | cheapest_quote | completed | 0.0 | [16, 7, 4, 9] | 8/30 | 0 | 501000 | 20 | 0 | 0 | 64604 |
| adventure-4417 | benefit_quote | completed | 1.4 | [16, 8, 12, 20] | 20/30 | 3 | 445000 | 20 | 153 | 0 | 63637 |
| adventure-90210 | reference | completed | 2.0 | [12, 8, 15, 22] | 21/30 | 1 | 440000 | 20 | 220 | 0 | 61657 |
| adventure-90210 | cheapest_quote | completed | 0.6 | [11, 9, 10, 7] | 9/30 | 0 | 496000 | 20 | 66 | 0 | 66529 |
| adventure-90210 | benefit_quote | completed | 2.0 | [12, 10, 14, 21] | 20/30 | 1 | 444000 | 20 | 220 | 0 | 60538 |

## Integrity and coverage

- action-4417: initial full state/RNG equal = True; issues = none
  - Benefit minus reference: Review 0.0, launch cash cents 0, actual units 0
  - Benefit minus cheapest_quote: Review 1.7, launch cash cents -53000, actual units 186
- action-90210: initial full state/RNG equal = True; issues = none
  - Benefit minus reference: Review 0.0, launch cash cents 0, actual units 0
  - Benefit minus cheapest_quote: Review 1.4, launch cash cents -48000, actual units 154
- adventure-4417: initial full state/RNG equal = True; issues = none
  - Benefit minus reference: Review 0.1, launch cash cents 0, actual units 11
  - Benefit minus cheapest_quote: Review 1.4, launch cash cents -56000, actual units 153
- adventure-90210: initial full state/RNG equal = True; issues = none
  - Benefit minus reference: Review 0.0, launch cash cents 4000, actual units 0
  - Benefit minus cheapest_quote: Review 1.4, launch cash cents -52000, actual units 154

## Limits

- A matching digest and telemetry hash are file-consistency checks; fresh-process replay remains separate.
- The Variant tape is retained but not decoded by this helper.
- Feature-play finance rows aggregate by month; selected quote costs are checked against next cash and their aggregate, not a per-hand receipt field.
- Actual sales fields exclude projected units and gross.
- The first release ends the case, so later monthly sales need the declared Studio continuation.
