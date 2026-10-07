# Incremental loss verification v1

2026-10-06, America/Los_Angeles. **Result: already satisfied on branch.** Read-only verification of [the approved loss structure](2026-10-06-incremental-loss-decision-v1.md) and [its bounded handoff](handoffs/2026-10-06-incremental-loss-verification-v1.md). No correction task is needed for these cases. Loss rates and exposure estimates remain trial values.

The tested source is `origin/codex/fanbase-on-main` at `bd450a9e4e8d83ece1478cdf5a16526432e36cce`, using the disposable source archive already retained by the prior legal-route capture. Shared checkout `main` remained at `553d1a46f33d59641efa4c2e4ff141f958c1230d` with concurrent documentation/evidence edits preserved. No gameplay file was edited. Source SHA-256: `studio_fanbase.gd` `ac6634b7691d5f5c58267368277ccdd60d20331e41889fbeaadffca414ef8b6a`; `released_game_sales.gd` `4d8418b023557cffae670794c9a881d936a2dcbf0eb457d85438c8bfce014739`; existing `verify_studio_fanbase.gd` `876c89af702832aeef832a04011663efa66aa22225d1d0de4a727dd8df135ade`. These match the branch snapshot before and after execution.

The [constructed domain probe](incremental-loss-v1/driver.gd) ran native `ReleasedGameSales.next_cycle` and `StudioFanbase.plan` against explicitly declared fixture inputs. It passed **202 checks, zero failures**, with Godot 4.7.1 exit 0. The branch's existing RunState-integrated [verifier output](incremental-loss-v1/native-verifier.log) also exited 0 with zero failures. Both logs contain the environment's root-certificate-store diagnostic; neither contains a script error or failed check. These fixtures test accounting invariants, not player balance or natural Review frequency. [Exact trace and check labels](incremental-loss-v1/trace.json), [probe output](incremental-loss-v1/probe.log).

One weak title starts with 10,000 Fans, Review 4.0, Month 1 units 400, launch Awareness 100 and market basis points 10,000. The existing Review-neutral shadow estimates reach; the provisional rate is 15% per Review point below 5. Each monthly loss equals the increase in the rounded cumulative loss target:

| Month | Cumulative estimated reach | Newly estimated reach | Cumulative loss target | Loss this month | Ending Fans |
|---:|---:|---:|---:|---:|---:|
| 1 | 535 | 535 | 80 | 80 | 9,920 |
| 2 | 677 | 142 | 101 | 21 | 9,899 |
| 3 | 752 | 75 | 112 | 11 | 9,888 |
| 4 | 791 | 39 | 118 | 6 | 9,882 |
| 5 | 811 | 20 | 121 | 3 | 9,879 |
| 6 | 821 | 10 | 123 | 2 | 9,877 |
| 7 | 826 | 5 | 123 | 0 | 9,877 |
| 8 | 828 | 2 | 124 | 1 | 9,876 |
| 9 | 829 | 1 | 124 | 0 | 9,876 |
| 10 | 829 | 0 | 124 | 0 | 9,876 |

At every monthly boundary, repeating the callback rejects without changing state. A lossless typed dictionary snapshot reconstructed with `bytes_to_var(var_to_bytes(state))` also rejects that repeated boundary and produces exactly the uninterrupted result for the following cycle. This verifies reconstruction of the domain snapshot; durable disk checkpoint/Continue remains a separate absent runtime feature. The field `loss_exposure_accounted` stores the accounted rounded cumulative loss target; the neutral sales record carries the cumulative estimated reach. Flat reach therefore cannot charge prior exposure again, and rounding may postpone a loss even when reach rises.

The concurrent fixture starts with 10 Fans and two Review 0.0 titles, each with a launch-Fan cap of 10. Their rounded cumulative targets request 7 losses each, or 14 total. The first boundary records **10 starting, 10 lost, 0 gained, 0 ending**. Adding a Review 7.0 title with 1,000 earned Month 1 units produces **10 starting, 10 lost, 79 gained, 79 ending**; gains do not fund extra losses. The next boundary records **79 starting, 0 lost, 16 gained, 95 ending**. Reversing dictionary insertion order gives identical monthly records. A Review 5.0 fixture with 1,000 existing Fans remains at 1,000 with zero gain/loss across both earning months.

The completed [legal-route capture](2026-10-06-current-branch-replay-v1.md) was reviewed without rerunning it. Its +11 Fans at the first 6.1 boundary and +4 next-launch Awareness support a distinct gain-curve decision, but neither curve is selected by these accounting checks. Exact rates, exposure/reserve size, rounding, cross-title audience overlap, fan-to-Awareness tuning and Cult Following remain OPEN.

Reproduction uses the retained source snapshot at `C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-replay-20261006/patch-notes`, with separate writable `APPDATA`/`LOCALAPPDATA` directories for each process:

```powershell
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-replay-20261006/patch-notes' --script 'C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/docs/codex/threads/fanbase/incremental-loss-v1/driver.gd' -- '--output=C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/docs/codex/threads/fanbase/incremental-loss-v1/trace.json'
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-replay-20261006/patch-notes' --script res://scripts/debug/verify_studio_fanbase.gd
```

Driver SHA-256 `858f82279fd99b31f1e31b182e2a906fd16b75685e6371c1139a6f39642c721f`; trace SHA-256 `64de3f4a252d21910eddb88bcfe090d1cca0ce956733463052580abf87ebddd9`. No full suite, human balance check, merge, commit or push was performed.
