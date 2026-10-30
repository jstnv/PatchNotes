from pathlib import Path
import base64,hashlib,json,re,subprocess
out=Path(__file__).resolve().parent;root=out.parents[3]
paths=json.loads((out/'selected-paths.json').read_text(encoding='utf-8'))
patterns=[re.compile(rb'gh[pousr]_[A-Za-z0-9]{36,255}'),re.compile(rb'github_pat_[A-Za-z0-9_]{60,255}'),re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),re.compile(rb'AKIA[0-9A-Z]{16}')]
findings=[];rows=[];encoded_false_positives=[]
for name in paths:
    p=root/name
    assert p.resolve().is_relative_to(root.resolve()),name
    content=p.read_bytes()
    inspected=content
    if name.endswith('.tape.json'):
        envelope=json.loads(content)
        if envelope.get('format')=='patch-notes-development-replay' and isinstance(envelope.get('payload'),str):
            payload=envelope.pop('payload')
            # A pattern in base64 is not a cleartext credential. Inspect the
            # decoded bytes without deserializing or executing any object.
            inspected=json.dumps(envelope).encode()+base64.b64decode(payload,validate=True)
            if any(pattern.search(content) for pattern in patterns) and not any(pattern.search(inspected) for pattern in patterns):encoded_false_positives.append(name)
    if any(pattern.search(inspected) for pattern in patterns):findings.append(name)
    rows.append({'path':name,'bytes':len(content),'sha256':hashlib.sha256(content).hexdigest()})
assert not findings, 'Inspect possible credentials in: '+repr(findings)
(out/'reviewed-files.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
(out/'selection-review.json').write_text(json.dumps({'paths':len(rows),'bytes':sum(row['bytes'] for row in rows),'largest':max(row['bytes'] for row in rows),'high_confidence_secret_matches':findings,'base64_pattern_false_positives_decoded_and_cleared':encoded_false_positives,'outside_workspace_paths':0},indent=2),encoding='utf-8')
print('Reviewed',len(rows),'paths; no high-confidence credential patterns or outside-workspace paths.')
