# HUD and priority overlay milestone — resume checkpoint

Request source: C:/Users/64jus/.codex/attachments/a9206447-204b-4a2a-be44-991b894daf95/Pasted text.txt

User requests persistent Design/Alpha/Beta HUD organization, staged vertical modal
priorities, existing gameplay preservation, all regression checks and 1152x648
visual inspection. Preserve unrelated dirty files and .codex-godot-temp. Do not
create AGENTS/AUTHORITY/CURRENT_MILESTONE/IMPLEMENTATION_RULES/VALIDATION/STATUS.

Starting point: shared atomic redraw milestone complete; all 25 verifiers passed.
Repository was already dirty. Prior work must remain intact.

Plan: persistent shell header/footer presenter; reusable phase workspace presenter
that moves existing scene controls without moving CardViews; Played Hand textual
instance/slot summary; vertical modal reuses phase priority staging/commit system.
Employees and Next Bill are placeholders. Priority commits already require active
development, so Change Priorities is enabled after Begin; retain planning APIs.

Tools:
- Godot: C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe
- Python: C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe
- Always read/write Python text with encoding='utf-8'.
- Set APPDATA and LOCALAPPDATA to TEMP/patchnotes-redraw-validation for Godot.
- Root certificate warning and absent artwork fallbacks are pre-existing.
- Use Compatibility renderer for captures; native Godot viewport capture works.

Current progress: implemented scripts/ui/gameplay_hud.gd, phase_workspace.gd,
priority_overlay.gd and shared resources/ui/workspace_theme.tres. Gameplay shell
binds persistent HUD; phase ready methods compose shared workspace by reparenting
existing controls (never candidate CardViews). Sliders converted to VSlider and
moved into modal. Modal uses existing phase drafts and commit; Cancel resets draft.
All gameplay action routes block while modal is visible or phase detached.
Existing atomic redraw verifier passes; most regression verifiers pass.

Completed: all 26 verifiers passed, including the focused HUD/overlay verifier.
Headless import/parsing and main launch passed. Final focused verification after
theme and presenter cleanup passed. git diff --check passed. No assertion or
script failures remain. Expected negative-path diagnostics and the environment
certificate warning remain documented.

Visually inspected Design, Alpha, Beta and all three modal variants at 1152x648.
Six screenshots are saved in design-logs/hud-screenshots/. The final implementation
and ownership report is Persistent_Gameplay_HUD_and_Priority_Overlay_v1.md.
hud_integrate.py was removed. No outstanding implementation steps remain.
Final checkpoint: 2026-09-25. Changes are local and uncommitted; unrelated dirty
worktree changes and .codex-godot-temp were preserved.

Follow-up completed 2026-09-25: initial Design priority modal is now available
before Begin, with staged/cancelable free initial commits. Existing active commits
still cost one cycle. In-game synergy banners cover Design/Alpha Specialization
and Balanced Production, Beta QA Specialization/Balanced Operations, and Design
Perfect Production. The shared Gameplay presenter survives phase transitions.
All 26 verifiers passed; affected verifiers passed again after final wiring.
1152x648 planning and synergy captures were visually checked and saved.
See Initial_Design_Priorities_and_Synergy_Notifications_v1.md. No remaining steps.

Follow-up completed 2026-09-25: Beta now records and displays cumulative Fixed
Bugs alongside Known Bugs. This makes mixed Search for Bugs + Debug hands visible
even when their net Known Bugs value does not change. Search-before-Debug order,
Bug formulas, and Hidden/Remaining Bug secrecy are unchanged. All 26 verifiers,
headless import, main-scene launch, and `git diff --check` passed. The updated
Beta HUD was visually checked at 1152x648. See Beta_Fixed_Bugs_Visibility_v1.md.

Follow-up completed 2026-09-25: the initial Design priority menu now opens
automatically in the prephase workspace, so its sliders are visible before Begin
Design. It reuses the existing staged/cancelable initial allocation behavior.

Latest follow-up completed 2026-09-25: phase entry priority setup now applies to
Design, Alpha, and Beta and is labeled Initialize Priorities. Entry setup has no
Cancel action; its phase-specific Begin button commits a valid allocation and
immediately starts the phase. Later Change Priorities actions retain Commit,
Cancel, and their one-cycle cost.

The initialization surface is opaque, removing inactive prephase header and
action elements from view while retaining the persistent bottom status HUD.
Active-phase Change Priorities remains translucent.

Follow-up completed 2026-09-25: a six-page first-run tutorial now appears before
the initial Design priorities. It is state-free, can be skipped or completed, and
can be reopened from a Tutorial button in the persistent bottom HUD. See
First_Run_Tutorial_v1.md.

Baseline scripts/scenes backup: TEMP/patchnotes-hud-start.
Regression logs: TEMP/patchnotes-hud-logs. Focused log: TEMP/patchnotes-overlay.log.
