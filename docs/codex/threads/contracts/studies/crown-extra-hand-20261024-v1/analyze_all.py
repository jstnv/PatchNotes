import contextlib, io, json
from setup import HERE
import analyze, audit_extra, summarize

with contextlib.redirect_stdout(io.StringIO()):
    analyze.main()
    audit_extra.main()
    summarize.main()
a=json.loads((HERE/'summary.json').read_text())
print(json.dumps({k:a[k] for k in ['complete','arms','extra_hand_attempts','extra_hand_accepted','study_assertions','extra_assertions','controls_reproduced']},indent=2))
for pair in a['pairs']:
    print(pair['pair'], 'control', pair['control']['reviews'], 'extra', pair['extra']['reviews'], 'extra hands',pair['additional_hand_count'])
