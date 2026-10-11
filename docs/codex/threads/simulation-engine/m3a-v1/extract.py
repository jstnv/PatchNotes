from pathlib import Path
ROOT=Path(__file__).resolve().parents[5]
p=ROOT/'patch-notes/scripts/gameplay.gd'
s=p.read_text(encoding='utf-8')
start=s.index('func _ensure_review_result()')
end=s.index('func _build_checkpoint_controls()',start)
original=s[start:end]
target=ROOT/'patch-notes/scripts/simulation/launch_settlement.gd'
target.write_text(target.read_text(encoding='utf-8')+'\n\n'+original,encoding='utf-8')
wrappers=''
for stage in ['review','awareness','launch_market_context','units_sold','month_one_sales_revenue']:
    wrappers+=f'''func _ensure_{stage}_result() -> bool:
\tvar settlement := LaunchSettlement.new(project_state,run_state,_snapshot_database,_controlled_review_roll)
\tsettlement._review_rng = _review_rng
\tvar ok := settlement._ensure_{stage}_result()
\t_controlled_review_roll = settlement._controlled_review_roll
\treturn ok


'''
s=s[:start]+wrappers+s[end:]
s=s.replace('const REQUIRED_SCOPE := 30','const REQUIRED_SCOPE := 30\nconst LaunchSettlement := preload("res://scripts/simulation/launch_settlement.gd")\nconst BeginProject := preload("res://scripts/simulation/begin_project.gd")')
a=s.index('\tvar has_competitor :=',s.index('func _initialize_project_snapshots'))
b=s.index('\n\nfunc _on_design',a)
s=s[:a]+'''\treturn BeginProject.initialize_snapshots(target,run_state,_snapshot_database,_controlled_snapshot_rolls)
'''+s[b:]
a=s.index('\tvar saved_rng :=',s.index('func _begin_next_project'))
b=s.index('\tproject_state = next',a)
s=s[:a]+'''\tvar prepared: Array[DesignPhase] = []
\tvar readiness := func(next_project: ProjectState) -> bool:
\t\tvar view := DESIGN_PHASE_SCENE.instantiate() as DesignPhase
\t\tif view == null: return false
\t\tview.setup(next_project,run_state)
\t\tview.proceed_to_alpha_requested.connect(_on_design_proceed_to_alpha_requested.bind(view))
\t\tprepared.append(view)
\t\tif checkpoints != null: checkpoints.in_studio = false
\t\treturn true
\tvar result := BeginProject.execute(run_state,_snapshot_database,base_name,genre,theme_id,readiness,_controlled_snapshot_rolls)
\tif not result.ok:
\t\tif checkpoints != null: checkpoints.in_studio = true
\t\tfor view in prepared: view.free()
\t\t_transition_in_progress = false
\t\tsource_studio.show_development_error(result.error)
\t\treturn false
\tvar next: ProjectState = result.project
\tvar design: DesignPhase = prepared[0]
'''+s[b:]
p.write_text(s,encoding='utf-8')
print('Extracted existing stage implementations and Begin Development adapter')
