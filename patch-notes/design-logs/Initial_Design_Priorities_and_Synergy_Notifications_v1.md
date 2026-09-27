# Initial Design priorities and synergy notifications

Implemented 2026-09-25 at the user's request. This supersedes the previous HUD
milestone's restriction that Design priority editing requires Begin Design.

Design, Alpha, and Beta now open an Initialize Priorities menu on phase entry.
The menu is the complete entry step: it shows the phase's sliders, has no Cancel
action, and its Begin Design / Begin Alpha / Begin Beta button accepts any valid
allocation, including the unchanged default. Beginning commits the allocation,
deals the first candidate pool, and closes the menu with zero cycle or redraw
cost. There is no separate prephase confirmation screen.

Priority initialization uses an opaque surface so inactive gameplay header,
backlog, and phase actions are not shown behind it. The persistent bottom status
HUD remains visible for cash, date, cycle, and bill context. Later Change
Priorities overlays remain translucent because the full workspace provides useful
context after the phase has begun.

After a phase begins, Change Priorities retains the staged Commit/Cancel flow and
the existing one-cycle commit cost.

Successful Design/Alpha Specialization and Balanced Production, Beta QA
Specialization and Balanced Operations, and Design Perfect Production now show
an amber/cyan in-game banner with the existing bonus. It is nonblocking, lasts
four seconds, and resets its timer on another hit. In Gameplay the presenter is
shell-owned so finalization notifications survive phase transitions. Standalone
phase scenes retain their own presenter. Failed actions do not show a new hit.
No synergy formulas, eligibility, effects, or cycle costs changed.

Validation: all 26 existing verifiers passed; focused assertions cover initial
staging, Cancel, invalid/unchanged rejection, free initial commit, existing active
commit cost, actual synergy notifications, failed-action suppression, timeout,
and Perfect Production persistence across the Design-to-Alpha transition.
Import/parsing, main-scene headless launch, and git diff --check passed.
Final affected verifiers were rerun after persistent notification wiring.

Visually inspected at 1152x648; captures are in hud-screenshots/
design_initial_priorities.png and design_synergy.png. Existing certificate-store
and missing-artwork diagnostics remain unchanged.
