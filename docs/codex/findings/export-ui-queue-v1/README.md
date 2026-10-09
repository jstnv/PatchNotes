# Actual exported UI acceptance — 2026-10-08

Dedicated profile: `Patch Notes Acceptance 20261008 Queue`. All gameplay actions used real exported controls through Computer Use; checkpoint files were only read/copied afterward. No user save injection. Builds are isolated copies with a custom user directory; official release template and package manifests are in adjacent export-ui-queue-v1 through v4 directories.

| Boundary | Cycle | Cash | Evidence |
|---|---:|---:|---|
| First release |9|$2,530.00|Review5.1, Scope25/30, zero bugs, Awareness106|
| First Continue |9|$2,530.00|Exact unchanged captured Studio|
| Ironclad plus campaign |12|$8,145.84|Two actual positive sales settlements; no loan funding yet|
| $500 loan accepted |12|$8,645.84|12-month quote; first due14; maximum installment$46.67|
| Loan Continue |12|$8,645.84|Exact unchanged captured Studio|
| Two Research completions / installment |14|$7,643.29|8-Color Palette and Colored Text; $46.67 Bank payment|
| Explicit payoff |14|$7,184.96|$458.33 cash; total principal$500 and interest$5 paid|
| Second release |26|$3,742.10|Review4.3, Scope30/30, Awareness127; three undiscovered bugs|

`capture_checkpoint.py LABEL` reads the dedicated profile, checks the envelope hash and preserves both generations, decoded DTO and current runtime log. `audit.py` independently reconciles journal/monthly cash, generation checksums, exact restart identity, loan closure and once-only installments/payoff. Raw action labels/coordinates are in `ui-actions.json` (starts first-game Alpha; earlier creation/Design in the conversation record).

## Build boundaries and defects

First release usedv1. The loan route and second release usedv2. The integrated presentation buildv3 included Dashboard sizing, deferred Store category scrolling, payoff wrapping and corrected Design/Alpha copy. A later log scan found116 error markers in the second-release session: the detached Feature Store still reacted to run signals and tried to access `/root/CardDatabase`. This is a real runtime defect, not a harmless placeholder warning. Buildv4 adds an in-tree guard with a dedicated late-signal regression. The original logs remain unchanged; later verification must establish closure.

Gatev3's94 suites predate these repairs. Gatev4 failed the Store radial test's early observation; the test now waits for the deferred scroll result and retains the same geometry assertions. Gatev5 was stopped when the exported lifecycle defect was found. Gatev6 and final exported continuation provide current acceptance. Approved audio and art completeness remain separate; no clean-machine or release-ready claim.
