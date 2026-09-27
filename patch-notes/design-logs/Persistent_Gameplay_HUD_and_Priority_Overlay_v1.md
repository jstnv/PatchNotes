# Persistent gameplay HUD and priority overlay

Implemented 2026-09-24. Additive presentation milestone; historical redraw,
priority, calendar, and gameplay logs remain authoritative and unchanged.

Gameplay remains the persistent run shell. Its new GameplayHUD presenter binds
the existing ProjectState and RunState references and public signals. Header and
footer instances survive phase transitions. Gameplay.gd only binds the presenter
when orchestrating a phase change. No authoritative values are copied into HUD
state, and no Hidden Bugs are presented.

Runtime hierarchy:

    Gameplay
      Background
      GameplayHUD
        PersistentHeader (Employees, scores, Scope, permitted Bugs, Change Priorities)
        PersistentFooter (Cash, Date, Cycle, Next Bill)
      PhaseRoot
        DesignPhase / AlphaPhase / BetaPhase
          Workspace
            Regions
              PlayedHand / SelectionSummary
              BacklogTitle
              CandidateScroll / HandContainer / existing CardViews
              ContextAndPhase
                ActionRow
                PhasePanel (objective, progress, Begin and transition)
              Feedback
          PriorityOverlay (CanvasLayer)
            ModalBlocker
              PriorityDialog / Content
                vertical priority panel, allocation status, feedback, Commit, Cancel
          PhaseLayout (hidden legacy containers and retained status labels)

PhaseWorkspace composes the same regions for all three phases by moving existing
controls, never candidate CardViews. The Played Hand summary lists selected card
names and one-based backlog slots in selection order. This preserves duplicate
instance identity and creates no extra playable cards. Long summaries and
feedback are elided with full text available in tooltips.

The ordinary HUD no longer exposes sliders or Commit Priorities. Existing
priority controls become vertical inside a centered, dimmed, full-screen input
blocking modal. Tab stays within the modal; Escape and Cancel both discard
staged edits and restore committed values. Outside clicks cannot dismiss it.
Normal gameplay input routes also reject while the modal is open and after their
phase has left the tree.

Opening, editing, Cancel, and Escape are cycle-free. Invalid and unchanged
commits remain open and change no gameplay state. A valid changed commit uses
the existing phase-local priority allocation and commit method: exactly one
project cycle, one run-calendar cycle, and normal redraw restoration once.
Visible candidates, slot order, and selection remain intact; only future deals
read the new committed distribution.

The existing priority commit boundary requires active development. Accordingly,
Change Priorities is available after Begin; planning APIs and phase eligibility
remain unchanged. Design/Alpha retain four categories and Beta three. Every
category retains 5–50 bounds, steps of five, and a required total of 100.

Design and Alpha Play controls are labeled Implement; Beta retains Play Hand.
Redraw displays the shared allowance directly as Redraw (N/4). Transition buttons
live in the phase panel and retain their existing rules. Cut is omitted because
there is no implemented Cut behavior. Employees and Next Bill are explicitly
nonfunctional placeholders; no employee state or bill timing is invented.

The shared workspace_theme.tres resource supplies charcoal panels, burgundy
accents, cream text, amber interactions, cyan focus/status accents, and visibly
disabled controls. Card hover styling stays translucent so it cannot obscure
existing card text. No raster artwork or card data changed.

Files in this milestone:

- scenes/gameplay.tscn and scripts/gameplay.gd: persistent presenter binding.
- scripts/ui/gameplay_hud.gd, phase_workspace.gd, priority_overlay.gd: shared views.
- resources/ui/workspace_theme.tres: reusable styling.
- scenes/phases/design_phase.tscn, alpha_phase.tscn, beta_phase.tscn and matching
  scripts/phases scripts: presentation wiring, vertical controls, modal guards,
  public selection/presentation accessors, and budget label.
- scenes/cards/card_view.tscn: input-button theme variation only.
- scripts/debug/verify_gameplay_hud_overlay.gd: focused behavior and identity tests.
- scripts/debug/verify_design_phase.gd, verify_alpha_phase.gd,
  verify_gameplay_transition.gd: updated presentation type/label/path expectations.
- scripts/debug/capture_gameplay_hud.gd: reproducible 1152x648 capture harness.

Validation: all 26 verifiers passed, including Design, Alpha, Beta, QA, atomic
redraw, priorities, Host Playtest, state/finance, transitions, calendar, launch
results, and automatic Studio entry. Headless editor import/parsing, main-scene
launch, and git diff --check passed. The focused HUD test additionally verifies
modal input/focus blocking, all staging/commit/cancel cycle rules, exact state
identity across transitions, no stale-control mutations, layout bounds, and
current-pool/selection preservation.

Visual inspection used Godot 4.7.1 Compatibility rendering at 1152x648. Design,
Alpha, Beta, and all three modal variants fit; controls are reachable, card
overflow remains horizontal, numeric values and category labels are legible,
and the dimmed backdrop clearly separates the modal. Six captures are preserved
in hud-screenshots/. Existing root-certificate-store diagnostics, missing-art
fallback warnings, and deliberate negative-path test errors remain unrelated.

Deferred: employee runtime data, Next Bill timing, Cut, physical Played Hand card
movement/animation, final art, and further responsive layout polish.
