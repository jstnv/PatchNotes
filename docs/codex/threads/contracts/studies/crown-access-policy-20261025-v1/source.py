from run import *
sys.path.insert(0,str(ROOT/'tools'))
import simulator_variant as v
canonical=v.sim.source_hashes(ROOT/'patch-notes');candidate=v.sim.source_hashes(VAR/'project');parent=v.sim.source_hashes(THREAD/'simulators/crown-search-access-20261025-v1/project')
out=dict(canonical_identity=v.identity(canonical),candidate_identity=v.identity(candidate),parent_identity=v.identity(parent),canonical_delta=v.delta(parent,canonical),candidate_delta=v.delta(parent,candidate),canonical=canonical,candidate=candidate)
name='source-before.json' if not (HERE/'source-before.json').exists() else 'source-after.json'
write(HERE/name,out)
assert not out['candidate_delta']
print(json.dumps({k:val for k,val in out.items() if k not in ['canonical','candidate']}))
