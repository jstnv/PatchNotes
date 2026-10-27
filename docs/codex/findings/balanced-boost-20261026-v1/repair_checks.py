from pathlib import Path
root = Path(__file__).resolve().parents[4]
def edit(name, pairs):
    p=root/'patch-notes/scripts/debug'/name
    data=p.read_bytes(); nl='\r\n' if b'\r\n' in data else '\n'
    s=data.decode().replace('\r\n','\n')
    for a,b in pairs:
        assert a in s,(name,a)
        s=s.replace(a,b)
    p.write_bytes(s.replace('\n',nl).encode())
for name in ['verify_design_phase.gd','verify_alpha_phase.gd']:
    edit(name,[('slider.max_value == 50.0','slider.max_value == 75.0'),
               ('10-50 bounds','10-75 bounds'),
               ('value >= 5 and value <= 50','value >= 10 and value <= 75')])
edit('verify_design_phase.gd',[('var boosted := total * 5 / 4','var boosted: int = int(total) * 5 / 4')])
edit('verify_production_extraction.gd',[
    ('\tassert(JSON.parse_string(JSON.stringify(results)) == expected, "Production fixture with approved 1.25 Balanced delta failed")\n',''),
    ('\tprint("PASS: production characterization', '\tif JSON.parse_string(JSON.stringify(results)) != expected:\n\t\tpush_error("FAIL: Production fixture with approved 1.25 Balanced delta failed")\n\t\tquit(1)\n\t\treturn\n\tprint("PASS: production characterization')])
