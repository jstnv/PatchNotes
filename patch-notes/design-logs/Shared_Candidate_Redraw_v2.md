# Shared candidate redraw v2

Authority: explicit user ruling, 2026-09-24. This supersedes only the
single-target and one-redraw-per-action clauses in
Shared_Candidate_Redraw_and_Priority_Adjustment_v1.txt in the external design
folder. The historical v1 document remains unchanged.

Design, Alpha, and Beta now expose one phase-level Redraw button. Existing card
clicks toggle hand selection with the same four-card limit and selection order.
The selected hand may exceed the remaining redraw allowance without affecting
Play or Commit availability.

Redraw replaces the complete selected set atomically, costs one redraw per
selected card, and costs zero cycles. It does not resolve effects, exhaust cards,
advance phases, or advance the run calendar. Replacements retain their original
slots and start unselected. Unselected slots retain their original views.

The button is disabled for empty selections, insufficient allowance, ineligible
cards, or unavailable replacements. Budget and selection changes refresh it
immediately. The existing “Redraws: N / 4” status remains beside the button.
Per-card redraw buttons and their signal paths are removed.

Each phase plans the entire operation and prepares all replacement views before
publishing any changes. Finite replacement definitions are reserved across that
plan. Existing phase weighting and eligibility rules are retained; discarded
definitions cannot immediately replace themselves, Passes change type, and Beta
corrective Passes cannot be redrawn. Rejected plans preserve the pool, selection,
lifecycle collections, RNG state, and allowance.

An unavailable Feature replacement rejects the complete action with exactly
“No more Feature cards”. Each selected Feature lacking a replacement shakes;
otherwise valid selected cards do not. When selected Features compete for fewer
finite replacements, reservations follow the existing selection order.

Allowance remains run-owned: starts at four, caps at four, restores one after a
successful cycle, and refreshes to four on successful Design-to-Alpha and
Alpha-to-Beta entry. A successful redraw deducts the entire selected count once
and emits one allowance notification after the pool and selection are committed.

Implementation remains in the phase classes and RunState; Gameplay orchestration
is unchanged by this milestone. No card data or balance rules change.

Verification: verify_atomic_selected_redraw.gd covers all three phases, shared
button behavior, duplicate Pass instances, atomic success/failure, slot retention,
budget and cycle invariants, lifecycle preservation, finite reservation, Feature
feedback, and corrective Beta exclusion. The existing shared redraw/priority
verifier uses the one-selected-card case. The Host Playtest verifier now includes
the already-authoritative priority-commit cycle in its expectations.

Visual reproduction: run scripts/debug/capture_shared_redraw.gd with the
Compatibility renderer at 1152×648. It saves each phase's enabled and disabled
states under the system temporary directory in patchnotes-redraw-visual.

Validation completed on 2026-09-24 with Godot 4.7.1: all 25 verifier scripts
exited successfully, including Design, Alpha, Beta, QA, gameplay transitions,
calendar, and Studio entry. Headless editor import/parsing and main-scene launch
also exited successfully; git diff --check passed. The environment reports a
root-certificate-store error, existing absent artwork uses fallback cards, and
negative-path verifiers deliberately log rejected scenes/snapshot initialization.
No script errors or verifier assertion failures remained.

The six rendered enabled/disabled states were visually inspected at 1152×648.
The shared button is visibly dimmed when disabled and brighter when enabled,
its budget is readable beside it, and phase action controls remain visible.
