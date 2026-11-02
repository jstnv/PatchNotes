# PATCH NOTES — Launch Engine Progression Tree & Update Starting Scope

**Thread:** Engine System Development  
**Task:** Gameplay Integration / UI Activation / Balance Adjustment  
**Mode:** Implementation authorized

## Objective

Make the existing proprietary Engine Skill Tree fully accessible and functional during normal gameplay, while increasing starting proprietary engine capacity from 20 to 25 Scope.

Do not rebuild the existing Skill Tree. Inspect and activate the Generation I and II systems already implemented in Phase 3B.

## 1. Update Scope Progression

Set proprietary engine capacity to:

| Progression | Maximum Scope |
|---|---|
| Starting engine | 25 |
| Generation I complete | 30 |
| Generation II complete | 35 |
| Generation III complete | 40 |
| Generation IV complete | 45 |

Preserve automatic +5 Scope milestones.

Existing proprietary engines should retain their purchased nodes and challenge progress. Apply the revised capacity consistently without resetting progression.

Do not modify the 30-Scope project requirement.

## 2. Launch the Engine Skill Tree

Make the Engine Progression Tree accessible through:

**Studio Management → Engines → Select Proprietary Engine → Skill Tree**

The player must be able to:

- View all four technology branches.
- See the four pre-unlocked foundation technologies.
- View active challenges and their progress.
- See node requirements and purchase prices.
- Purchase nodes after completing their challenges.
- Receive technology benefits immediately.
- Unlock automatic Scope Expansion milestones.
- Continue advancing individual branches independently.

Generation I and II must be fully playable.

Generation III and IV should remain visibly unavailable until their mechanics are designed and implemented. Do not create placeholder purchases or fake progression.

## 3. Challenge Tracking

Verify that challenges advance during normal game development.

Rules:

- Challenges are automatically active and free.
- Only Feature activations using the corresponding proprietary engine count.
- Count printed primary and secondary Core contributions.
- Passes and synergy retriggers do not contribute.
- Progress persists across phases and games.
- Each engine maintains independent progression.
- Purchasing a node starts its successor challenge at zero.
- Individual branches do not have generation-wide progression gates.

Ensure the UI updates immediately when challenge progress changes.

## 4. Technology Effects

Verify that purchased nodes immediately activate their existing gameplay effects.

**Generation I**
- Category-specific Pass Budget efficiency bonuses.

**Generation II**
- Graphics and Sound Pass effectiveness bonuses.
- Technology and Design bug-pressure reduction.

Preserve the implemented values and stacking rules.

Do not modify the existing Pass Budget baseline or scoring formulas.

## 5. Scope Expansion

When all four nodes in a generation have been purchased:

- Automatically increase engine capacity by 5.
- Update the displayed maximum Scope immediately.
- Show the completed Scope milestone.
- Do not charge additional money.
- Do not consume a development cycle.
- Prevent duplicate milestone rewards.

Verify that a Generation I engine supports 30 Scope and Generation II supports 35 Scope.

## 6. UI and Navigation

Integrate the Skill Tree into the existing Engines interface.

Requirements:

- Accessible only for proprietary engines.
- Public and licensed engines remain non-upgradeable.
- Clear branch progression and node states.
- Visible challenge progress.
- Visible purchase costs.
- Clear next Scope milestone.
- Consistent back navigation.
- No unrelated engine creation controls inside individual engine pages.

Preserve the current Patch Notes folder-based visual style.

## 7. Verification

Test the full player workflow:

1. Create a proprietary engine for $100.
2. Confirm it starts at 25 Scope.
3. Open its Skill Tree.
4. Play Features using that engine.
5. Verify challenge progress.
6. Complete a Generation I challenge.
7. Purchase its node.
8. Verify its gameplay effect.
9. Complete all four Generation I nodes.
10. Verify automatic expansion to 30 Scope.
11. Continue into Generation II.
12. Verify expansion to 35 Scope.
13. Save and reload.
14. Confirm all progress persists.

Also test multiple proprietary engines, Scope enforcement, existing saves, and marketplace regressions.

Run focused and relevant headless Godot verification suites.

## 8. Deliverables

Report:

- Starting Scope adjustment.
- Skill Tree entry point and navigation.
- Challenge tracking verification.
- Node purchasing behavior.
- Immediate technology effects.
- Automatic Scope milestone behavior.
- Save/load compatibility.
- Changed files and test results.
- Remaining limitations.

Do not implement new generations, change marketplace economics, or modify Feature values.

**Completion means a player can progress from a fresh 25-Scope proprietary engine to 35 Scope through actual gameplay, without developer tools or test-only shortcuts.**