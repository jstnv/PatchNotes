# First-run tutorial

Implemented 2026-09-25.

Patch Notes now opens a six-page tutorial before the initial Design priority
initializer. It explains the run objective, phase priorities, four-card hand
selection, the shared redraw budget, production/cycle/lifecycle behavior,
synergy notifications, phase progression, and the Beta Known/Fixed Bug loop.

The tutorial is informational. Opening, navigating, completing, or skipping it
mutates no ProjectState, RunState, phase state, candidate pool, selection, cycle,
cash, or redraw budget. Start Run and Skip Tutorial reveal the already-prepared
Design priority initializer underneath. A Tutorial button in the persistent
bottom HUD reopens the walkthrough from page one.

The tutorial and priority initialization retain the bottom HUD at 1152×648. The
tutorial uses an opaque background to conceal the underlying initializer, the
shared workspace theme, keyboard focus, Back/Next navigation, Escape-to-close,
and a final Start Run action.

The tutorial copy follows the current Google Drive authority, “Patch Notes —
Implementation Discoveries and Locked Rules,” and introduces no new mechanics or
balance rules.
