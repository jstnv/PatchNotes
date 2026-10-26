# G4 synergy-aware rival choice — predeclared study, 2026-10-18

**Status: DESIGN experiment.** The user wants rivals to pursue synergies more competently. This study tests one phase-local selection change in independent simulators; it does not approve a final AI policy, extra hands, Store shopping, market pressure, or a gameplay edit.

## Question and hypothesis

The ACTIVE/TRIAL rival takes the first four Features by token and does not inspect Design/Alpha primary Core labels or either production synergy. Earlier printed-benefit and cheapest-affordable policies failed as universal choices. H1: ranking the 35 visible four-card combinations by their *actual* specialization or Balanced Production result, then the project's Genre-normalized Core/Scope potential, will choose useful synergies and improve Review over the existing policy without extra hands or a worse cash/arrears outcome. This is a bounded diagnostic; future draws, hidden Bugs and final variance are unknown.

## Source and comparison

At declaration, repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` has a shared dirty worktree. Preserve it and `.codex-godot-temp`. Create `g4-synergy-20261018-v1` from the current authoritative project. First run the unchanged `features_first` fixture from v1. Fork v2 from v1; change only its private `project/scripts/market/rival_trial.gd` for the candidate and add a private debug policy wrapper. Within v2 compare `reference` (the original Feature-first/token order) and `synergy_aware` (the candidate). Verify v2 reference reproduces v1 reference actions and outcomes before interpreting pair differences. No old Studio checkpoint crosses a source-identity revision.

The candidate keeps two legal Design, Alpha and Beta hands, ordinary exits, first-project specialty Genre and Fantasy Theme. Beta stays Feature-first to isolate Design/Alpha Review-relevant production synergies. For each current Design/Alpha deal, enumerate at most 35 four-card sets, reject duplicate finite Feature definitions, and calculate base printed Core, Scope and Feature bug pressure from visible cards. Use the same pure `ProductionHand.calculate` specialization/Balanced Production arithmetic as gameplay. Compare current Genre-normalized projected Review with known Bugs held constant. Select a synergistic hand only when its projected Review strictly exceeds the reference hand and its visible first-Studio Feature play cost does not exceed the reference cost; otherwise play the reference hand. Tie by stable tokens. The legal command/settlement remains authoritative, and any rejected hand is a retained failure. This primitive-only cost screen is a test policy; later Store cards and exact future dues stay OPEN.

## Declared cases and bounds

Fresh legal January Studio recipes: Action, Adventure, Puzzle and Sports specialty/project Genre × seeds `4417` and `90210`, with `family_funding` and `cult_following`, Fantasy Theme, no Store/redraw/Bank actions. Eight recipes × two v2 policies = 16 matched first-release cases. Each has at most 45 commands, absolute one-release target and 240-second process timeout. Run eight v1 reference cases first under the same recipe/bounds.

Continue Action/4417 and Puzzle/4417 from *each arm's own* completed Studio-only checkpoint to an absolute second release, with at most 45 further commands and the same process timeout. Do not substitute another seed if one fails. Replay Action/4417 and Puzzle/4417 candidate first releases and one candidate continuation in fresh processes. Check initial full state/RNG parity within each v2 pair and source/runtime identities; after policies diverge, final RNG need not match.

Count available legal Design/Alpha synergies among the 32 reference decision hands, chosen specialization/Balanced Production, exact committed Core/Scope and Bug results, and the selected hand's Core gain over the same unsynergized cards. Measure first and second Reviews, release cycle, actual earned/settled sales, Fans, cash lows, arrears, selected Feature cost, rejected/idle actions, policy plus observation time, and replay/state integrity. A first-release projected unit count is not actual earned sales.

## Stop and interpretation

Retain every invalid, rejected, incomplete and timed-out case. Stop policy promotion if a matched initial state/RNG differs, v2 reference drifts from v1 reference, a selected play is rejected, ordinary legal exits fail, or fresh-process replay differs. Reduce a reproducible action/invariant failure where applicable. If fewer than four available legal synergies occur across the 32 reference Design/Alpha decisions, call this selection-only panel inconclusive and open draw-priority/redraw design instead of changing seeds. If Reviews are mixed or cash/second-release opportunity worsens materially, keep the exact objective OPEN; do not adopt an unconditional synergy bonus. A passing simulator does not approve balance or establish representative player challenge.

Run through `tools/simulate.py run --variant` into unique folders, then `replay`; use the documented isolated Python/Godot paths. Keep original baselines, ancestry, raw reports and failed runs. Canonical gameplay, market values and TODO remain unchanged during the experiment.
