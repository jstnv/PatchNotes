# Beta Fixed Bugs visibility

Date: 2026-09-25

## Problem

A Beta hand containing both Search for Bugs and Debug already resolved in the
correct order: Search moved Hidden Bugs into Known Bugs, then Debug removed
Known Bugs. When the two effects canceled each other numerically, the persistent
interface could leave the Known Bugs value unchanged, making the successful
Debug effect appear to have been lost.

## Resolution

`ProjectState` now records the cumulative number of Bugs actually fixed. Debug
increments that value by the same clamped amount it removes from Known Bugs.
Beta presents Known and Fixed counts together in the phase status, action panel,
and persistent HUD.

The existing Bug formulas and hand resolution order are unchanged. Hidden Bugs
and total Remaining Bugs remain undisclosed during Beta.

## Regression coverage

The focused mixed-hand case starts with one Hidden Bug and plays Search for Bugs
with Debug. The result is zero Hidden Bugs, zero Known Bugs, one Fixed Bug, and
zero Remaining Bugs. Coverage also checks cumulative and clamped fixing, state
persistence across Beta reconstruction, synchronous UI refresh, and the original
mixed Search/Debug resolution behavior.

All 26 verifier scripts passed. Headless import/parsing, the main-scene headless
launch, and `git diff --check` also passed. Expected missing-artwork warnings and
the Windows root-certificate warning remain environmental.

## Visual check

The Beta workspace was captured and inspected at 1152×648 with the Compatibility
renderer. “Known / Fixed” in the header and “Known: 0 · Fixed: 0” in the phase
action panel are legible, aligned, and do not overlap adjacent controls.
