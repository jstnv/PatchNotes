# Banking restart acceptance follow-up — 2026-10-07

Branch `main`, HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`, shared uncommitted implementation. This bounded follow-up closes the two missing Banking restart cases identified in the user's screenshot. No runtime or economic rules changed.

## Results

Seven fresh Godot 4.7.1 processes (`setup`, `unsaved`, `rollback`, `arrears`, `partial`, `recovered`, `check`) all exited 0, with no script/assertion errors. The Windows root-certificate-store warning is recorded and excluded from the gameplay error scan. [Exact commands and results](banking-restart-gaps-v1/process-results.json); adjacent per-process logs retain assertions.

- Setup uses a frozen release accounting fixture and four native productive actions to establish actual settled-sales history. This is not a legal played balance route.
- Through the real Gameplay scene, Continue enters Studio, native departure enters Design, and the Bank UI preview/confirmation accepts a $500 loan. Memory receives exactly $500; the finalized checkpoint path and payload remain unchanged. That process exits without returning to Studio.
- The next process validates/hydrates every checkpoint field against the previous canonical payload SHA. Continue restores the exact finance/credit journal, cycle 4 and no active project or loan. A fresh quote accepts one $500 loan in the restored timeline, using a 120-month term to retain debt during declining-sales setup.
- Native sales/debt actions reach cycle 10. A journaled fixture expense leaves cash plus the next native settlement equal to rent plus $1. Native settlement pays rent, then $1 bank interest and zero bank principal, creating a late partial bank bill. No bill, loan or credit counters are edited.
- After restart, a native $1 receipt increases paid interest to $2 while preserving original due cycle, total accrued interest and the complete credit state. Automatic Studio publication is followed by another process restore.
- The next process recovers the bill's remaining balance through a native receipt. Original due and late history remain; credit is unchanged. A final process confirms the fully recovered late bill and complete persisted state survive.

Full-field equality is checked on detached hydration before scene entry because Studio guidance can acknowledge a tutorial. Scene Continue separately must preserve the exact finance/credit journal. The unsaved scenario records the actual predeparture checkpoint after any pending Studio acknowledgment flush.

## Reproduction and boundaries

Run `docs/codex/findings/banking-restart-gaps-v1/process_gate.py` with the bundled Python runtime. It creates a new isolated APPDATA/LOCALAPPDATA profile and serially launches `res://scripts/debug/banking_restart_gap_probe.gd`. Exact absolute executable, project and profile paths are in the result JSON. The test reserves port 47412 in place of the production writer lease, avoiding interference with the user's open game. Production port 62741 and writer behavior are unchanged; this is not a test of competing production writers.

Initial harness iterations corrected a GDScript type annotation, compared detached state before tutorial acknowledgment, and compared total interest across all monthly rows (a zero-cycle receipt opens a new reporting row). No gameplay defect was found or patched. The final complete sequence above passed from a fresh profile.

Task10 remains open for its broader A01–A12 matrix. Task11's actual exported Bank → exit → Continue → installment → payoff interaction remains unverified; this headless source-scene evidence does not replace it. The earlier Computer Use app-approval timeout remains the recorded export-interaction blocker; no new export interaction was attempted in this follow-up. No commit, push or release-readiness claim.
