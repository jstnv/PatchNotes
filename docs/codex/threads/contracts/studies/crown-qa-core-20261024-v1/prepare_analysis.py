from setup import HERE, PREV

code=(PREV/'analyze.py').read_text(encoding='utf-8')
code=code.replace("'control-'+pair,'extra-'+pair","'control-'+pair,'candidate-'+pair")
code=code.replace("['control','extra']","['control','candidate']")
code=code.replace("'EXTRA '","'FOLLOWUP '").replace('line[6:]','line[9:]').replace("<=300","<=320")
code=code.replace("for field in ['godot','policy','nonimport']", "for field in ['godot','runner','policy','nonimport']")
start=code.index('        from runner_audit import audit\n');end=code.index('    for row in rows:',start)
code=code[:start]+code[end:]
(HERE/'analyze.py').write_text(code,encoding='utf-8')
print('Prepared source/input/telemetry analysis; no historical source-parity override')
