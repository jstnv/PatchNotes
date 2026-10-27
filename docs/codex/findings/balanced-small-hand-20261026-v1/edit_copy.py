from pathlib import Path
out=Path(__file__).resolve().parent;root=out.parents[3]
def edit(name,pairs):
 p=root/'patch-notes'/name;data=p.read_bytes();nl='\r\n' if b'\r\n' in data else '\n';s=data.decode().replace('\r\n','\n')
 for a,b in pairs:
  assert a in s,(name,a);s=s.replace(a,b)
 p.write_bytes(s.replace('\n',nl).encode())

edit('scripts/market/rival_world_checkpoint.gd',[
 ('## New grants change prospectively;', '## Positive one-point Balanced allowance is prospective; saved state stays exact.\nconst BALANCED_SMALL_HAND_PREDECESSORS := ["9d30a157bfbcdec10be0de7120979ca282c137b23d327bb5b4e24fe2842c6cac"]\n## New grants change prospectively;'),
 ('predecessor_source in BALANCED_BOOST_PREDECESSORS', 'predecessor_source in BALANCED_SMALL_HAND_PREDECESSORS or predecessor_source in BALANCED_BOOST_PREDECESSORS')])
edit('scripts/debug/verify_balanced_boost_parity.gd',[
 ('[[2,2,2,2], [5,5,5,6], [17,20,20,23]]','[[2,2,2,2], [2,2,3,2], [5,5,5,6], [17,20,20,23]]')])

edit('scripts/ui/how_to_play_content.gd',[
 ('qualifies when each of its four unmodified Core gains is within ±15% of the hand\'s four-category average.',
  'qualifies when all four categories contribute and either the highest and lowest gains differ by at most 1 point, or each gain is within ±15% of the hand\'s four-category average. For example, 2/2/3/2 qualifies.')])
edit('scripts/ui/guided_production_tutorial.gd',[
 ('A Feature plus four category gains within ±15% of their average triggers Balanced Production.',
  'Balanced Production needs a Feature and positive gains in all four categories: highest minus lowest at most 1 point, or each gain within ±15% of the average.')])
edit('scripts/ui/gameplay_hud.gd',[
 ('A Feature and hand Core gains within ±15% of their average boost the hand Core total ×1.25,',
  'With a Feature, positive hand Core gains qualify if highest minus lowest is at most 1 point, or each is within ±15% of the average. Boost the Core total ×1.25,')])
edit('scripts/ui/tutorial_overlay.gd',[
 ('when its four Core gains are within ±15% of their average.',
  'when all four categories contribute and either highest minus lowest is at most 1 point, or each gain is within ±15% of the average.'),
 ('if its four Core gains are within ±15% of their average.',
  'if all four categories contribute and either highest minus lowest is at most 1 point, or each gain is within ±15% of the average.')])
edit('scripts/ui/phase_workspace.gd',[
 ('or use a Feature and hand gains within ±15% of their average to share the hand total evenly.',
  'or use a Feature and positive gains in every category: highest minus lowest at most 1 point, or each within ±15% of the average. Balanced boosts total Core ×1.25, rounds down, then shares it evenly.'),
 ('keep this hand’s four Core gains within ±15% of their average for Balanced Production.',
  'give every category positive Core: highest minus lowest at most 1 point, or each gain within ±15% of the average, for Balanced Production.'),
 ('This hand includes a Feature and all four hand Core gains are within ±15% of their average.',
  'This hand includes a Feature and positive Core in every category, with a spread of at most 1 point or every gain within ±15% of the average.')])
