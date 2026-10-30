from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]/'patch-notes/scripts'
p=ROOT/'ui/gameplay_hud.gd';s=p.read_text(encoding='utf-8')
a=s.index('func setup(');b=s.index('func set_phase(',a)
s=s[:a]+s[a:b].replace('(refresh)','(_queue_refresh)')+s[b:]
p.write_text(s,encoding='utf-8',newline='\n')
p=ROOT/'phases/studio_phase.gd';s=p.read_text(encoding='utf-8')
a=s.index('\tif _run_state != null and _run_state.calendar_changed.is_connected(_refresh_summary):',s.index('func setup('))
b=s.index('\t_project_state = project_state',a)
s=s[:a]+'''\tif _run_state != null:
\t\tfor event in [&"calendar_changed",&"sales_changed"]:
\t\t\tif _run_state.is_connected(event,_queue_run_refresh):_run_state.disconnect(event,_queue_run_refresh)
'''+s[b:]
s=s.replace('\t_run_state.calendar_changed.connect(_refresh_summary)\n\t_run_state.calendar_changed.connect(_refresh_rivals)\n\t_run_state.sales_changed.connect(_refresh_summary)','\t_run_state.calendar_changed.connect(_queue_run_refresh)\n\t_run_state.sales_changed.connect(_queue_run_refresh)')
p.write_text(s,encoding='utf-8',newline='\n')
