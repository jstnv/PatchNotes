from pathlib import Path
out=Path(__file__).resolve().parent;root=out.parents[3]
def edit(name,fn):
 p=root/'patch-notes'/name;data=p.read_bytes();nl='\r\n' if b'\r\n' in data else '\n'
 s=fn(data.decode().replace('\r\n','\n'));p.write_bytes(s.replace('\n',nl).encode())
def hud(s):
 start=s.index('\tfor key: StringName in deltas:',s.index('func _show_presented_scores'))
 end=s.index('\nfunc _refresh_footer()',start)
 s=s[:start]+'\tscoreboard.punch(deltas)\n'+s[end:]
 return s.replace('\t_presented_scores.clear()\n\tfor pulse','\t_presented_scores.clear()\n\tscoreboard.reset_punches()\n\tfor pulse',1)
edit('scripts/ui/gameplay_hud.gd',hud)
def tutorial(s):
 s=s.replace('func _present_scores(values: Dictionary, _deltas: Dictionary)', 'func _present_scores(values: Dictionary, deltas: Dictionary)')
 return s.replace('\t_shown_scores = values.duplicate()\n\t_update_stats()', '\t_shown_scores = values.duplicate()\n\t_update_stats()\n\tstats.punch(deltas)',1)
edit('scripts/ui/guided_production_tutorial.gd',tutorial)
def codec(s):
 s=s.replace('## New grants change prospectively;', '## Floating score presentation only; exact preceding player/world/RNG retained.\nconst SCORE_FLOAT_PREDECESSORS := ["8593779f9afa7deab4ca218fab64118864efe5d763ff088485f8d6ad43be7ab8"]\n## New grants change prospectively;',1)
 return s.replace('predecessor_source in BALANCED_SMALL_HAND_PREDECESSORS','predecessor_source in SCORE_FLOAT_PREDECESSORS or predecessor_source in BALANCED_SMALL_HAND_PREDECESSORS',1)
edit('scripts/market/rival_world_checkpoint.gd',codec)
