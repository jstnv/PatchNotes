from pathlib import Path
OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
path = ROOT/'patch-notes/scripts/simulation/campaign_session.gd'
text = path.read_text(encoding='utf-8')
text = text.replace('var releases: Array = []','var _section_clock := Time.get_ticks_usec()\n\tvar releases: Array = []',1)
text = text.replace('var quotes: Array = []','load("res://../docs/codex/findings/research-fix-20261027-v1/profile.gd").add("section:releases",Time.get_ticks_usec()-_section_clock)\n\t_section_clock=Time.get_ticks_usec()\n\tvar quotes: Array = []',1)
needle = '\treturn {"run_id":run._bank_run_id'
index = text.index(needle)
text = text[:index]+'''\tload("res://../docs/codex/findings/research-fix-20261027-v1/profile.gd").add("section:research_quotes",Time.get_ticks_usec()-_section_clock)
\t_section_clock=Time.get_ticks_usec()
\tvar _money := StudioActions.observation(run)
\tload("res://../docs/codex/findings/research-fix-20261027-v1/profile.gd").add("section:studio_actions",Time.get_ticks_usec()-_section_clock)
\t_section_clock=Time.get_ticks_usec()
\tvar _development: Dictionary={} if in_studio or contract != null else development.observation()
\tload("res://../docs/codex/findings/research-fix-20261027-v1/profile.gd").add("section:development",Time.get_ticks_usec()-_section_clock)
'''+text[index:]
text = text.replace('"studio_actions":StudioActions.observation(run)','"studio_actions":_money',1).replace('"development":{} if in_studio or contract != null else development.observation()','"development":_development',1)
path.write_text(text,encoding='utf-8',newline='\n')
