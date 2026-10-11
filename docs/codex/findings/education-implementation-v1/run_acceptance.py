from run import run,HERE
import sys

directory='--directory='+str(HERE).replace('\\','/')
if sys.argv[1]=='focused':
 for label,script in [('atomic-v1','verify_education_atomicity.gd'),('focused-v4','verify_education_debt.gd'),('edges-v2','verify_education_edges.gd')]:
  if run(label,['--script','res://scripts/debug/'+script,'--',directory]):sys.exit(1)
else:
 groups=[('active-long-v2',['creation','month12','first_partial','partial_continue','recovery','final_due','final_continue','final_recovery','final_check']),('native-payoff-v2',['native_seed','native_rollback','native_payoff','native_check'])]
 for profile,modes in groups:
  for mode in modes:
   if run('restart-'+mode+'-v2',['--script','res://scripts/debug/education_restart_probe.gd','--',directory,'--mode='+mode],profile=profile):sys.exit(1)
