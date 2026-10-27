"""Publish the completed bounded study without replacing unrelated queue edits."""
from pathlib import Path
import json

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
summary = json.loads((OUT / "summary.json").read_text(encoding="utf-8"))
assert summary["completed"] == summary["planned_cases"] == 8
cases = summary["cases"]
assert all(c["status"] == "PASS" for c in cases)
assert (OUT / "README.md").is_file()
audit = json.loads((OUT / "review-arithmetic-final-v1.json").read_text(encoding="utf-8"))
assert audit["checks"] == 1728 and not audit["errors"] and not audit["input_errors"]
assert len(audit["cases"]) == 8 and all(c["failures"] == 0 for c in audit["cases"])
assert all(max(c["actual_reviews"]) < 5 and c["rival_strong_releases"] == 0 for c in cases)
assert all(not any(c["settled_gain_targets"].values()) for c in cases)
commands = sum(c["commands"] for c in cases)
releases = sum(c["player_releases"] for c in cases)
cycles = sum(c["cycle"] for c in cases)
records = sum(c["checks"] for c in cases)
replays = sum(c["replay_checks"] for c in cases)


def replace_line(relative, prefix, replacement):
    path = ROOT / relative
    raw = path.read_bytes()
    newline = "\r\n" if b"\r\n" in raw else "\n"
    lines = raw.decode("utf-8").splitlines()
    matches = [i for i, line in enumerate(lines) if line.startswith(prefix)]
    assert len(matches) == 1, (relative, prefix, matches)
    lines[matches[0]] = replacement
    path.write_bytes((newline.join(lines) + newline).encode("utf-8"))


def insert_after_title(relative, paragraph):
    path = ROOT / relative
    raw = path.read_bytes()
    newline = "\r\n" if b"\r\n" in raw else "\n"
    text = raw.decode("utf-8")
    assert paragraph not in text
    title_end = text.index(newline + newline) + len(newline + newline)
    text = text[:title_end] + paragraph + newline + newline + text[title_end:]
    path.write_bytes(text.encode("utf-8"))


totals = f"Eight six-release records and eight exact fresh replays pass across {commands} legal commands, {releases} player releases and {cycles} productive cycles ({records:,} record and {replays:,} replay assertions)."
limits = "This fixed-input study does not establish alternate full campaigns, final balance, positive Fan-gain exposure, a strong incumbent release or a population performance budget. Literal 180-second whole-process plan overruns are disclosed; successful command loops and the separate 210-second process guard are distinguished. Bank rules and all trial values are unchanged."
replace_line("docs/codex/TODO.md", "    **2026-10-19 item 22 post-adoption design work", "    **2026-10-22 item 22 post-adoption exposure and challenge diagnosis — COMPLETE bounded READ-ONLY; leaderboard DESIGN/OPEN.** " + totals + " [Finding, exact attribution, timings and limitations](findings/market-exposure-20261022-v1/README.md) · [independent arithmetic review](findings/market-exposure-20261022-v1/REVIEW.md) · [session log](logs/2026-10-22-market-exposure-v1.md). Same-input counterfactuals distinguish rival pressure from own-title crowding: Action targets rise, Puzzle/War provides disjoint controls, and Fantasy routes exercise Theme overlap. " + limits + " The [October19 work order](threads/ai-competitors/2026-10-19-market-followup-work-order-v1.md) remains authority. Leaderboard metric/eligibility/period/ties/update/ownership/placement, rival Store/Core planning, entrants, news and final challenge targets need separate decisions. Direct release-EXE mouse acceptance remains BLOCKED. No additional gameplay, commit or push follows from the study.")
insert_after_title("docs/codex/CURRENT_STATE.md", "**2026-10-22 longer market exposure — COMPLETE bounded READ-ONLY:** " + totals + " [Findings and source boundaries](findings/market-exposure-20261022-v1/README.md). Rival pressure is measurable in overlapping routes; Puzzle/War controls show no rival effect. The fixed incumbent cohort remains low-quality and narrow in Genre/Theme, so final challenge, richer policies and leaderboard rules remain OPEN. Bank and market rules were unchanged; direct release-EXE input remains separately BLOCKED.")
insert_after_title("docs/codex/threads/ai-competitors/README.md", "**2026-10-22 post-adoption exposure and challenge diagnosis COMPLETE at bounded read-only scope.** " + totals + " [Source-pinned finding](../../findings/market-exposure-20261022-v1/README.md) and [independent review](../../findings/market-exposure-20261022-v1/REVIEW.md) separate rival/own-title crowding and frozen-target effects. Fixed incumbent Genres/Theme and low Review limit exposure; no strong-incumbent or positive Fan-gain case is observed. Final coefficients, new policies, population budgets and leaderboard rules remain OPEN. All gameplay and Bank rules are unchanged.")
replace_line("docs/codex/logs/2026-10-22-market-adoption-v1.md", "The October19 fixed-coefficient market-exposure work order is being executed", "The October19 fixed-coefficient market-exposure work order is complete at its predeclared bounded scope: " + totals + " See the [read-only finding](../findings/market-exposure-20261022-v1/README.md) and [separate session log](2026-10-22-market-exposure-v1.md) for attribution, timing deviations and limits. The [remaining queue audit](../findings/market-adoption-20261018-v1/QUEUE-REVIEW.md) found no additional unstarted approved task; [final integrity check](../findings/market-adoption-20261018-v1/final-integrity-20261022.json) confirms all 301 export inputs still match and Bank files remain unchanged. Leaderboard rules, new rival policy, Store planning, entrants, news and final coefficients remain OPEN.")
log = ROOT / "docs/codex/logs/2026-10-22-market-exposure-v1.md"
with log.open("x", encoding="utf-8") as stream:
    stream.write("# Market exposure study closeout — 2026-10-22\n\n"
        "User direction: finish other executable TODO work while leaving Bank rules unchanged. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared edits and `.codex-godot-temp` preserved. No commit or push.\n\n"
        "Mechanics identity `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536` is unchanged across all runs. " + totals + "\n\n"
        "Four fixed Genre/Theme recipes at two seeds each use ordinary new-game factory state and current incumbent policies. Exact Review, sales, cents and settled Fan targets are compared at factual inputs. Independent arithmetic and fresh-process replay checks are retained in the [finding](../findings/market-exposure-20261022-v1/README.md) and [review](../findings/market-exposure-20261022-v1/REVIEW.md). Exact commands, source/harness hashes, timings, save/memory observations and failed setup output remain in that folder.\n\n"
        "The initial command-zero parse failure was repaired in the harness and retained. " + limits + " The existing six-instance ObjectDB shutdown warning is retained rather than counted as a clean warning-free run.\n\n"
        "Changed only the study's reports/harnesses plus TODO item22, CURRENT_STATE, AI thread index and the adoption log. No canonical gameplay change was made for this read-only follow-up. Queue review found no further unstarted approved work. Leaderboard design, policies/entrants, final tuning and human/device acceptance remain OPEN or deferred; direct release-EXE mouse Continue remains BLOCKED by the captured-window mismatch.\n")
print(json.dumps({"status": "updated", "commands": commands, "releases": releases, "cycles": cycles, "record_checks": records, "replay_checks": replays}))
