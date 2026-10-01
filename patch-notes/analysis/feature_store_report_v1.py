"""Assemble the completed staged evidence into a standalone New Data Logs TXT."""
from pathlib import Path
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design-logs/feature-store-staged-v1"
LOGS = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\New Data Logs")


def main():
    verification = json.loads((OUT / "final_verification_v1.json").read_text())
    assert verification["passed"], "Final checks must pass before the completion report"
    baseline = json.loads((OUT / "baseline_results.json").read_text())
    stage2 = json.loads((OUT / "stage2_summary_v1.json").read_text())
    stage3 = json.loads((OUT / "stage3_summary_v1.json").read_text())
    guard = json.loads((OUT / "source_preservation_audit_v1.json").read_text())
    assert not guard["changed_preexisting_gameplay_files"]
    parts = [
        "PATCH NOTES — FEATURE STORE STAGED SIMULATION FINDINGS v1",
        "Completed bounded read-only handoff. User dispatch: 'Go ahead and run the sims' after supplying both Feature Store documents. Candidate rules, numerical values and platform/era assumptions remain unapproved. No gameplay or cumulative authority edit; no commit or push.",
        "RESULT AT A GLANCE",
        f"Stage 1: 97 unique catalog nodes audited; 378 actual Godot capability checks and 37 explicit shadow checks, zero unexpected failures. Missing live capabilities are reported as blockers, not passed implementations. Stage 2: {stage2['cases']} accepted policy/shopping routes with bounded Game 3 follow-up across {len(stage2['jobs'])} jobs; {stage2['unique_matched_first_game_routes']} distinct matched first-game policy/seed/Beta/focus fixtures. Repeated arms are not independent seeds. Exact denominators and excluded failed attempts appear below. Stage 3: {stage3['primary_n']} normal bounded routes, one matched ordinary continuation, and six separate stress routes. One normal continuation reached 2026 through actual productive actions.",
        "Most consequential discovery: today's empty-release plus SideStreet route generates positive direct Contract cash every three cycles. All 87 measured segments paid $525–$1,150 (median $850), excluding every sales settlement. This is a legal per-new-release route, not duplicate payout. Bare calendar or release-count era gates also permit deliberate progress without meaningful production. Decide what constitutes qualifying progress before tuning later-era prices.",
        "Recommendations: retain the exact authored printed definitions for future review; revise the planned integration to support all-parent ownership, combined familiarity, tertiary contributions and explicit direct capability eligibility; defer full-catalog and later-era numerical tuning. Individual early-card price/fee recommendations and their matched uncertainty are in Stage 2 below. Nothing is locked by these recommendations.",
        "SOURCE, VERIFICATION AND PRESERVATION",
        f"Source main / HEAD / initially verified GitHub main: {guard['starting_head']}. Current source preserves the five pre-existing tutorial edits recorded in baseline_worktree.diff. The baseline was saved before dependent simulations. {baseline['script_count']}/{baseline['script_count']} existing verification suites and initial Godot editor import passed. Final editor import, Python syntax, source-preservation comparison, independent cash audit and git diff --check passed. Exact commands, outputs and hashes are included in the evidence directory.",
        "No AGENTS.md was found in the repository or inspected relevant parents. The two local DOCX ledgers were checked and copied with hashes; independently newer Drive copies of those DOCX ledgers could not be verified. Current cumulative authority and execution queue were fetched before testing. The 39-versus-40 Primitive Scope discrepancy and two ordered-Core conflicts are preserved below. The .codex-godot-temp directory and unrelated worktree files were not changed.",
        "Evidence is actual headless Godot scene/API/signal execution plus explicitly labeled isolated shadow adapters. Native graphical input and human comprehension were not tested. Fixed hand budgets, controlled Review variance and internal-state-informed QA heuristics make these comparative simulations, not human Review-distribution estimates. The user's later-game Reviews above 9 are separate human evidence, not contradicted by low scripted-policy results.",
        "Accounting keeps acquisition and play costs, Beta Rival rewards, Contract payouts, campaigns and settled sales separate. Earned but unsettled cash cannot fund a purchase. Simultaneous old-game settlement is never assigned to Feature purchase ROI. Exact independent audit findings follow the three stages.",
    ]
    for number in [1, 2, 3]:
        report = OUT / f"stage{number}_findings_v1.md"
        assert report.is_file(), f"Missing completed stage report: {report}"
        parts += [f"STAGE {number} — FULL VERSIONED FINDINGS", report.read_text(encoding="utf-8")]
    parts += ["INDEPENDENT CASH RECONCILIATION", (OUT / "cash_audit_v1.md").read_text(encoding="utf-8")]
    new_analysis = subprocess.check_output(["git", "ls-files", "--others", "--exclude-standard", "analysis/feature_store*"], cwd=ROOT, text=True).splitlines()
    parts += [
        "FILES ADDED BY THIS ANALYSIS",
        "\n".join(str(ROOT / p) for p in new_analysis),
        "Evidence and source snapshots: " + str(OUT),
        "Standalone TXT: " + str(LOGS / "Feature_Store_Staged_Simulation_Findings_v1.txt"),
        "Baseline TXT: " + str(LOGS / "Feature_Store_Staged_Test_Baseline_v1.txt"),
        "Archive: " + str(ROOT / "design-logs/Feature_Store_Staged_Simulation_Evidence_v1.zip"),
        "All newly added files are analysis, test inputs, source snapshots or findings. No pre-existing gameplay file was modified by this task. Exact archive file hashes are in evidence_manifest_v1.json. See REPRODUCE_v1.md and per-job command/result JSON for rerunning every accepted cohort and reproducing failed-attempt exclusions.",
        "REMAINING BOUNDARIES",
        "Resolve the two existing primary-Core order conflicts against current authority before any corrective data edit. Implementing general AND gates, tertiary scoring, capability/platform selection and Store presentation would require a separate authorized milestone. The combined 59-card shadow catalog, unsupported tertiary gameplay and later-era numerical balance remain deferred. No payroll, expenses, employees, traits, platform UI, campaign balance lock, minimum release quality or other proposed system was added. Runtime startup failures were worked around using isolated profiles and preserved in the logs.",
        "Human playtest observations needed: (1) Capture purchases, Genres, priorities, complete hands/redraws and the Review breakdown on a later-game >9 route; (2) note whether new players understand printed primary Core and the two tutorial synergy opportunities; (3) record where Store prerequisite chains or production costs force an unwanted stop; (4) time meaningful progression and ask whether empty-release/Contract grinding feels advantageous; (5) verify the complete visible Store-to-project and release-to-Contract UI path.",
        "Queue disposition: this bounded Feature Store testing deliverable is complete with the stated blocked/deferred arms. Task 17 remains the next independent READY task in the inspected execution queue; its broader lifespan/campaign calibration was not expanded into this handoff. Canonical authority remains unchanged. Drive upload and exact queue revision/readback receipts are maintained separately so this report's simulation results stay immutable.",
    ]
    target = OUT / "Feature_Store_Staged_Simulation_Findings_v1.txt"
    target.write_text("\n\n".join(parts) + "\n", encoding="utf-8")
    LOGS.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(target, LOGS / target.name)
    print(json.dumps({"report": str(target), "local_log": str(LOGS / target.name), "bytes": target.stat().st_size}))


if __name__ == "__main__":
    main()
