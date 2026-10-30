from run import *
sys.path.insert(0,str(ROOT/'tools'))
import simulator_variant as v
before=load(HERE/'source-before.json');canonical=v.sim.source_hashes(ROOT/'patch-notes');candidate=v.sim.source_hashes(VAR/'project')
out=dict(canonical_identity=v.identity(canonical),candidate_identity=v.identity(candidate),canonical_delta=v.delta(before['canonical'],canonical),candidate_delta=v.delta(before['candidate'],candidate),canonical=canonical)
write(HERE/'source-at-publication.json',out)
print(json.dumps({k:val for k,val in out.items() if k!='canonical'},indent=2))
