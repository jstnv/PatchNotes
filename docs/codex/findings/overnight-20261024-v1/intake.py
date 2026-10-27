"""Read-only current-source/packet inventory. Never adopt the historical P4 delta."""
from pathlib import Path
import hashlib, importlib.util, json, socket, subprocess
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent

def load(path):return json.loads(path.read_text(encoding='utf8'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    spec=importlib.util.spec_from_file_location('variant',ROOT/'tools/simulator_variant.py')
    variant=importlib.util.module_from_spec(spec);spec.loader.exec_module(variant)
    packet=ROOT/'docs/codex/threads/contracts/handoffs/publisher-support-renewal-20261023-v1'
    seals=load(packet/'handoff-integrity.json')
    assert all(sha(packet/name)==digest for name,digest in seals.items())
    before=load(packet/'base-manifest.json');candidate=load(packet/'candidate-manifest.json')
    variant.verify_archive(packet/'base-source.zip',before)
    variant.verify_archive(packet/'candidate-source.zip',candidate)
    current=variant.sim.source_hashes(ROOT/'patch-notes')
    handoff=load(packet/'handoff.json')
    changes=[]
    for row in handoff['changes']:
        path=row['path'];now=current.get(path)
        changes.append({**row,'current_sha256':now,'status':'already_identical' if now==row['after_sha256'] else 'clean_reference_delta' if now==row['before_sha256'] else 'conflict_reconcile_required'})
    writer_free=True
    with socket.socket() as sock:
        try:sock.bind(('127.0.0.1',62741))
        except OSError:writer_free=False
    snapshot=ROOT/'docs/codex/threads/contracts/simulators/publisher-p4-current-preflight-v1'
    metadata,base,project,integrity=variant.load_variant(snapshot)
    creation=load(snapshot/'creation-manifest.json')
    assert variant.identity(creation)=='06587dea359014f9d0cc502814d49fb5dd45f2d424b87d0e3fce380099d10218'
    status=subprocess.check_output(['git','status','--porcelain=v1','--untracked-files=no'],cwd=ROOT).decode('utf8',errors='replace')
    report={'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'tracked_dirty_paths':len(status.splitlines()),'source_identity':variant.identity(current),'canonical_runtime_source':current,'historical_packet_seals_verified':len(seals),'archives_verified':2,'historical_candidate_identity':handoff['candidate_identity'],'historical_changes':len(changes),'current_overlap':changes,'production_writer_available':writer_free,'p4_current_snapshot':str(snapshot),'snapshot_creation_identity':variant.identity(creation),'candidate_changed_paths':variant.delta(creation,project),'p4_approval':'APPROVED bounded trial','p4_activation':'BLOCKED by explicit P2/P3 acceptance dependency; no support implementation/adoption claimed','computer_access':'Read-only capture of the existing game timed out waiting for app approval; no input/quit/kill sent','commit_or_push':False,'release_ready':False}
    variant.sim.write_json(HERE/'intake.json',report)
    print(json.dumps({k:v for k,v in report.items() if k not in {'canonical_runtime_source','current_overlap','candidate_changed_paths'}}))
    print(json.dumps({'overlap':{kind:sum(row['status']==kind for row in changes) for kind in ['already_identical','clean_reference_delta','conflict_reconcile_required']},'conflicts':[row['path'] for row in changes if row['status']=='conflict_reconcile_required']}))

if __name__=='__main__':main()
