from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
def change(path,old,new):
 p=ROOT/path;b=p.read_bytes();assert old.encode() in b,path;p.write_bytes(b.replace(old.encode(),new.encode(),1))
change('patch-notes/scripts/ui/phase_workspace.gd',
 'func _update_presented_scores(values: Dictionary, deltas: Dictionary) -> void:',
 'func present_employee_plan(distribution: Dictionary) -> bool:\r\n'
 '\tvar accepted := [false]\r\n'
 '\t_present_action("play", func(): accepted[0] = phase.play_hand_with_employee_plan(distribution))\r\n'
 '\treturn accepted[0]\r\n\r\n'
 'func _update_presented_scores(values: Dictionary, deltas: Dictionary) -> void:')
change('patch-notes/scripts/ui/employee_planning_dialog.gd',
 '\tif not phase.play_hand_with_employee_plan(_distribution()):',
 '\tvar distribution := _distribution()\r\n\thide()\r\n'
 '\tif not phase.get_workspace().present_employee_plan(distribution):')
change('patch-notes/scripts/debug/verify_employee_hands.gd',
 '\t\t\t\tcheck(phase.play_hand_with_employee_plan(changed),"Commit bundled "+label+" plan")',
 '\t\t\t\tdialog.open_for(phase)\r\n'
 '\t\t\t\tfor i in range(4): dialog.inputs[i].value = changed[i]\r\n'
 '\t\t\t\tdialog.get_ok_button().pressed.emit()\r\n'
 '\t\t\t\tvar motion: HandPresentation = phase.get_workspace().hand_motion\r\n'
 '\t\t\t\tcheck(not dialog.visible and motion.busy,"Dialog commits bundled "+label+" plan through presentation")')
change('patch-notes/scripts/debug/verify_employee_hands.gd',
 '\t\t\t\treconcile(run)\r\n\t\t\t\tbreak',
 '\t\t\t\tvar frames := 0\r\n'
 '\t\t\t\twhile motion.busy and frames < 600:\r\n'
 '\t\t\t\t\tawait create_timer(0.02).timeout\r\n'
 '\t\t\t\t\tframes += 1\r\n'
 '\t\t\t\tcheck(not motion.busy and run.get_completed_run_cycles()==cycle+1,"Specialist animation finishes without a second gameplay commit")\r\n'
 '\t\t\t\tcheck(motion.trace.filter(func(step):return step.event=="score").size()==4,"Specialist presents four card score events once")\r\n'
 '\t\t\t\tcheck(phase.get_selected_candidate_views().is_empty() and phase.get_workspace().played_hand.text.contains("Select"),"Specialist completion clears stale hand selection text")\r\n'
 '\t\t\t\treconcile(run)\r\n\t\t\t\tbreak')
