from pathlib import Path
import hashlib,json,sys
HERE=Path(__file__).resolve().parent
def show_reminder(history,standing_bp):
    return history['available'] and history['count']>=2 and 0<=standing_bp<10000
cases=[('two_zeros_below_cap',dict(available=True,count=2),0,True),('three_zeros_near_cap',dict(available=True,count=3),9950,True),('two_zeros_at_cap',dict(available=True,count=2),10000,False),('unknown_history',dict(available=False,count=None),0,False),('one_zero',dict(available=True,count=1),0,False)]
rows=[]
for name,history,standing,expected in cases:
    before=json.dumps(history,sort_keys=True);actual=show_reminder(history,standing);assert actual==expected and json.dumps(history,sort_keys=True)==before
    rows.append(dict(name=name,standing_bp=standing,history=history,show_reminder=actual))
p=HERE/'cap-reminder-v1.json';assert not p.exists()
p.write_text(json.dumps(dict(status='PASS',constructed_cases=rows,command=[sys.executable,str(Path(__file__).resolve())],script_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),scope='Presentation guard only; no runtime or reward change.'),indent=2)+'\n',encoding='utf-8')
print('PASS: five constructed cap/reminder display cases')
