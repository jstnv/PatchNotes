"""Supply only explicit verifier settings after the simulator's PN_ isolation."""
import hashlib,json,sys
from pathlib import Path
import run_current_founder_probe_v1 as probe

isolated=probe.sim.isolated_environment
def environment(profile):
    result=isolated(profile)
    result['PN_CARD_FRAME_OUTPUT']=str(profile.parent/'observation.json')
    result['PN_CHECKPOINT_TEST_PORT']='39248'
    return result
probe.sim.isolated_environment=environment
original_run=probe.subprocess.run
def bounded_run(argv,*args,**kwargs):
    # The legacy runner's60-frame cap can exit0 before animated UI completes.
    # Preserve the real argv in receipts and use its existing wall-time bound.
    if isinstance(argv,list) and '--quit-after' in argv:
        argv[argv.index('--quit-after')+1]='100000'
    return original_run(argv,*args,**kwargs)
probe.subprocess.run=bounded_run
if __name__=='__main__':
    output=Path(sys.argv[sys.argv.index('--output')+1]).resolve()
    probe.main()
    (output/'verifier-settings.json').write_text(json.dumps({'wrapper_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'PN_CARD_FRAME_OUTPUT':str(output/'observation.json'),'PN_CHECKPOINT_TEST_PORT':'39248'}),encoding='utf-8')
