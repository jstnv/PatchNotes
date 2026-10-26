# Crown selected-hand preview — source and evidence finding

2026-10-25. **Documentation and evidence extraction COMPLETE; presentation proposal OPEN.** [Design](CROWN-PREVIEW-DESIGN-2026-10-25-v1.md) · [handoff](CROWN-PREVIEW-HANDOFF-2026-10-25-v1.md). No new campaign, policy, runtime query, GUI, save schema or reward change was implemented.

## Current evidence and source

Read current `CURRENT_STATE.md`, `TODO.md`, repository README, `design/publishers-contracts.md`, recent CB2b handoff/findings and current Contract source. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree; branch/HEAD/status/diff inventory is retained in [study folder](studies/crown-preview-20261025-v1/head.txt). Current high-level logs record paper-icon packaging and previously deferred broader UI overhaul; this proposal is a scoped design, not an authorization to resume that overhaul. Preserve current UI and unrelated edits.

Verified source observations:

- `patch-notes/scripts/phases/contract_phase.gd`, `_refresh_all` and `_refresh_actions`: displays committed/presented scores and challenge description; obtains the selected hand plan for validity and productive-cycle affordability. There is no selected-hand Crown Brief Reputation explanation here.
- `patch-notes/scripts/contracts/contract_state.gd`, `plan_hand`: computes score/Scope additions with four-card specialization, but only fills completion/reward fields when the hand completes the Contract. A first-hand display cannot treat its zero settlement fields as a zero score-value quote.
- `patch-notes/scripts/contracts/publisher_relationship_brief.gd`: existing canonical relationship helper is SideStreet-specific and requires completion. It is not a Crown preview API. Canonical `contract_definitions.gd` contains SideStreet Brief, not the private Crown Brief definition.
- `patch-notes/scripts/simulation/contract_session.gd`: its challenge preview describes the current state; it is not a final hidden-draw forecast or selected-hand Reputation calculation.
- `_show_completion` waits for the shared hand presentation and renders committed results; the proposed preview must preserve this sequencing. Existing legality controls and redraws are not changed by this specification.

The four inspected canonical implementation files are hashed in [evidence.json](studies/crown-preview-20261025-v1/evidence.json). These are source observations, not executed current-UI acceptance. Historical “not implemented” wording in older design sections is superseded by newer authority/source where applicable; Crown's private status remains distinct from implemented cash Contracts and SideStreet.

## Evidence method and fixed scope

Question: can the selected-card explanation use exact score values while avoiding an implied first-hand guarantee? Read all six Briefs from the two completed **mean** CB2b routes, seeds 4521/4522; extract both hand selections (12 total), and compare their final quotes with the six recorded settlement results. Do not count identical downside trajectories as extra independent examples.

No new simulation was useful for this question: it concerns interpreting already-recorded values. No commands were submitted to a campaign, no new seeds/budgets or starting conditions introduced, and no actual future cards used to choose a move. Existing legal starting conditions and source limits are inherited from [CB2b](CROWN-TWOHAND-FINDINGS-2026-10-25-v1.md). These are wealthy Action/no-Trait routes, not broad player accessibility evidence.

Frozen canonical baseline: `0ac7ab3da4ac7499a56a5eb9bfd0690422157e73910516ebffc77b40e12c163b`.

Frozen private candidate: `f3e470f5e7f2f22eb1af8e3fdabe5d72457421ae3115f4020395c5467abdb3ad`.

Executed mechanics identity: `4b817896b436bc0770640a0422cfc8757e76fdf33375adce26c96572a805f18a`.

The two original experiment logs are hash-checked against the sealed CB2b evidence manifest. Their absolute paths and hashes, all selected tokens/definitions, current standing, projected scores and requested/credited values are retained in `evidence.json`. This preserves the exact old source; no claim that those campaigns were run against today's canonical UI.

## Recorded legal examples

| Route / Brief | First-hand score value | Recorded final award | Why it matters |
|---|---:|---:|---|
| Action 4521 / 1 | 5.00 | 0.00 | A positive interim estimate can be lost before settlement |
| Action 4521 / 2 | 2.42 | 7.50 | Low interim value is not necessarily a bad final result |
| Action 4521 / 3 | 2.42 | 5.00 | Completion and balance must remain separate |
| Action 4522 / 1 | 0.00 | 2.50 | Zero interim value does not prevent partial progression |
| Action 4522 / 2 | 7.50 | 10.00 | Full final result is attainable; its preview must match settlement |
| Action 4522 / 3 | 2.50 | 0.00 | More final Scope alone does not rescue dominant Cores |

For Action 4521 / Brief 1, first-hand Scope 5, Cores 6/2/4/2 produce completion 63.63%, balance 50.00%, provisional +5.00. Final Scope 10, Cores 10/3/8/8 produce completion 90.90% but balance 0%, therefore +0.00. This supports explaining the limiting factor and never adding first-hand value to standing.

For Action 4522 / Brief 2, the final selected hand projects Scope 6→9 and Cores 7/4/5/5→7/8/8/9, both grades 100%, and +10.00 Reputation, moving standing 2.50→12.50. The design wireframe uses these exact recorded values, not a constructed legal-play claim.

## Constructed display boundaries

Eight isolated arithmetic examples cover full score; half-point over tolerance; completed work with zero balance; incomplete but balanced work; R99 clipping; full grade at R100; excess Scope with no penalty; and empty balanced scores with zero completion. They are explicitly **not** legal hands, live cap acceptance, migration evidence or new balance approval.

Notable examples: all Cores 3 / Scope 9 gives 81.81% completion and requested +8.18; at R99 only +1.00 can be credited. All Cores 4 / Scope 12 still earns the same maximum as Scope 9. All Cores 0 / Scope 0 has balance 100% but completion 0%, so earns nothing. Runtime implementation must call shared authoritative evaluation rather than copying this explanatory Python arithmetic into UI code.

## Checks, commands and limitations

Exact extraction command from repository root:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/threads/contracts/studies/crown-preview-20261025-v1/extract.py
```

**PASS: 16 assertions** — two archived log hashes, six final grade/request/standing comparisons, eight constructed arithmetic cases. Twelve previews extracted; zero new campaign runs. Script and inputs are local; it only reads source/evidence and writes this thread's study records. The current-session generic Git line-ending warnings were informational; no source/config modification was made in response.

**NOT RUN:** preview purity in a runtime implementation, invalid/stale request rejection, actual UI layout/keyboard/motion, current-export parity, human comprehension, current-world migration/active-rival/cap settlement. Those are future acceptance tasks in the handoff. No numerical change is recommended; the display examples do not make Crown ready for activation.

Recommendation: use exact selected-hand projection with provisional first-hand and final conditional award labels; show completion and balance separately with the limiting factor. Keep future-draw expected values in research. Human understanding and explicit Crown pilot approval remain the design blockers to implementation/adoption, alongside prior structural gates.
