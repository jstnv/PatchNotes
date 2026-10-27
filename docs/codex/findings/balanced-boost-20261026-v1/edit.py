from pathlib import Path
root = Path(__file__).resolve().parents[4]

def edit(name, replacements):
    path = root / 'patch-notes' / name
    data = path.read_bytes()
    nl = b'\r\n' if b'\r\n' in data else b'\n'
    text = data.decode().replace('\r\n', '\n')
    for before, after in replacements:
        assert before in text, (name, before)
        text = text.replace(before, after)
    path.write_bytes(text.replace('\n', nl.decode()).encode())

edit('scripts/cards/balanced_production.gd', [
    ('\tvar result: Dictionary[ProjectState.CoreScore, int] = {}',
     '\t# Apply the 25% bonus once to the hand total; discard fractional points.\n\t@warning_ignore("integer_division")\n\ttotal += total / 4\n\tvar result: Dictionary[ProjectState.CoreScore, int] = {}')])

edit('scripts/market/rival_world_checkpoint.gd', [
    ('## New grants change prospectively;', '## Balanced 1.25 reward is prospective: retain historical scores and RNG.\nconst BALANCED_BOOST_PREDECESSORS := ["1c28c28f1f82b53cfb76f246f66562d476ffeb23d1ca152cd455108a693c5b4e"]\n## New grants change prospectively;'),
    ('predecessor_source in CARD_POP_PREDECESSORS', 'predecessor_source in BALANCED_BOOST_PREDECESSORS or predecessor_source in CARD_POP_PREDECESSORS')])

for phase in ['design', 'alpha']:
    edit(f'scripts/phases/{phase}_phase.gd', [('Hand total shared across four categories', '1.25× Core total shared across four categories')])

edit('scripts/debug/verify_design_phase.gd', [
    ('\t\tvar sum := 0\n\t\tfor category', '\t\t@warning_ignore("integer_division")\n\t\tvar boosted := total * 5 / 4\n\t\tvar sum := 0\n\t\tfor category'),
    ('5 + (1 if category < total % 4 else 0)', 'int(boosted / 4) + (1 if category < boosted % 4 else 0)'),
    ('sum == total, "Redistribution conserves every whole point"', 'sum == boosted, "Redistribution retains the whole-point 1.25 bonus"'),
    ('{graphics: 6, sound: 5, technology: 5, design: 5}', '{graphics: 7, sound: 7, technology: 6, design: 6}'),
    ('Balanced hand total21 redistributes6/5/5/5 without a multiplier', 'Balanced hand total21 boosts to26 and redistributes7/7/6/6'),
    ('[9, 8, 10, 11, 4]', '[10, 10, 11, 12, 4]'),
    ('ProjectState.CoreScore.GRAPHICS: 2,\n\t\tProjectState.CoreScore.SOUND: 2,', 'ProjectState.CoreScore.GRAPHICS: 3,\n\t\tProjectState.CoreScore.SOUND: 3,'),
    ('each +2 aggregate remains +2 after nearest rounding', 'eight raw points become10, split3/3/2/2'),
    ('[2, 2, 2, 2, 1]', '[3, 3, 2, 2, 1]'),
    ('text == "Graphics: 2"', 'text == "Graphics: 3"'),
    ('text == "Sound: 2"', 'text == "Sound: 3"')])

edit('scripts/debug/verify_alpha_phase.gd', [
    ('{graphics: 6, sound: 5, technology: 5, design: 5}', '{graphics: 7, sound: 7, technology: 6, design: 6}'),
    ('before equal total-preserving redistribution', 'before boosting the total1.25 and splitting whole points'),
    ('qualifying.score_additions[design] == 5 and qualifying.score_additions[technology] == 5', 'qualifying.score_additions[design] == 6 and qualifying.score_additions[technology] == 6'),
    ('Graphics +6, Sound +5, Technology +5, Design +5', 'Graphics +7, Sound +7, Technology +6, Design +6'),
    ('expected_additions[category] = 2', 'expected_additions[category] = 3 if category < 2 else 2')])

edit('scripts/debug/verify_soundtrack_sync.gd', [
    ('+= 6 if i == 0 else 5', '+= 7 if i < 2 else 6'),
    ('== 106 and shared[0].values[&"design"] == 6', '== 107 and shared[0].values[&"design"] == 7'),
    ('Balanced applies signed transfer once after cards play', 'Balanced applies boosted split once after cards play')])

edit('scripts/debug/verify_guided_tutorial_model.gd', [
    ('balanced.scores=={0:2,1:2,2:2,3:2}', 'balanced.scores=={0:3,1:3,2:2,3:2}'),
    ('Balanced shares original total without changing Scope', 'Balanced boosts eight to ten, shares whole points and keeps Scope')])

edit('scripts/debug/verify_production_extraction.gd', [
    ('\tassert(JSON.parse_string(JSON.stringify(results)) == expected, "Pre-extraction production parity failed")',
     '\t# Preserve the frozen extraction fixture; only its explicitly superseded\n\t# Balanced reward changes. Trigger flags and every other field stay exact.\n\tfor row in expected:\n\t\tif row.balanced_production:\n\t\t\tvar total := 0\n\t\t\tfor value in row.score_additions.values(): total += int(value)\n\t\t\t@warning_ignore("integer_division")\n\t\t\tvar boosted := total * 5 / 4\n\t\t\tfor category in range(4):\n\t\t\t\t@warning_ignore("integer_division")\n\t\t\t\trow.score_additions[str(category)] = boosted / 4 + (1 if category < boosted % 4 else 0)\n\tassert(JSON.parse_string(JSON.stringify(results)) == expected, "Production fixture with approved 1.25 Balanced delta failed")'),
    ('production characterization:', 'production characterization with Balanced 1.25 delta:')])

edit('scripts/ui/how_to_play_content.gd', [
    ('Balanced Production redistributes an even hand.', 'Balanced Production boosts and redistributes an even hand.'),
    ('The original hand total is divided evenly across the four categories. Whole-point remainders go Graphics, Sound, Technology, Design: 21 points becomes 6/5/5/5. No extra points are created.',
     'Multiply the hand Core total by 1.25, round down to whole points, then divide evenly across the four categories. Spare points go Graphics, Sound, Technology, Design: 21 points becomes 26, split 7/7/6/6.')])
edit('scripts/ui/phase_workspace.gd', [
    ('their original total is shared evenly.', 'their Core total gets ×1.25, rounded down to whole points, then shared evenly.')])
edit('scripts/ui/gameplay_hud.gd', [
    ('share the original hand total evenly after playing.', 'boost the hand Core total ×1.25, round down, then share it evenly after playing.')])
edit('scripts/ui/tutorial_overlay.gd', [
    ('After playing, its total is shared evenly;', 'After playing, its Core total gets ×1.25, rounds down to whole points and is shared evenly;'),
    ('It redistributes the original hand total evenly,', 'It multiplies the hand Core total by1.25, rounds down to whole points and redistributes evenly,')])
edit('scripts/ui/guided_production_tutorial.gd', [
    ('The original total is shared evenly; it does not create extra points. These eight points already divide into two per category.', 'Multiply the Core total by1.25, round down to whole points, then share evenly. These eight points become ten:3 Graphics,3 Sound,2 Tech,2 Design.'),
    ('Original hand total shared evenly', '1.25× Core total shared evenly')])
