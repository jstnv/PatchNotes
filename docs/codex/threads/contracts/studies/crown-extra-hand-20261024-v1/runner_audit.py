from setup import HERE, RAW, write
import hashlib, difflib

BASE = '65bdf6c5eb4a47af829283a0b07d4b78ad45e8a95139607b96a613d6ffbf9193'
ICON = '3a7db22dd14747bce423f5031f85d92bc8e0aa1d20155e106b6fa3601e57da0b'

def audit(contexts):
    baseline = (RAW/'simulation-4522/runner.py').read_bytes()
    assert hashlib.sha256(baseline).hexdigest() == BASE
    entries=[]
    for context in contexts:
        path=RAW/context['pair']/'runner.py'
        actual=path.read_bytes()
        digest=hashlib.sha256(actual).hexdigest()
        assert digest==context['runner'] and digest in [BASE, ICON]
        normalized=actual if digest==BASE else actual.replace(b'".png", ".ico", ".svg"', b'".png", ".svg"')
        assert normalized==baseline, 'Unexpected runner change'
        entries.append({'pair':context['pair'],'runner_sha256':digest,'identical_except_ico_allowlist':True})
        if digest==ICON:
            (HERE/'runner-ico.diff').write_text(''.join(difflib.unified_diff(baseline.decode().splitlines(True),actual.decode().splitlines(True),fromfile=BASE,tofile=ICON)),encoding='utf-8')
    assert len({c['source'] for c in contexts})==1
    assert len({c['nonimport'] for c in contexts})==1
    result={'status':'PASS','original_audit_failure':'AssertionError: common runner; initial three-batch aggregate audit stopped before writing analysis.json. No runtime failure.', 'amendment':'Accept two explicitly identified host runners only after byte-exact proof that adding .ico to SOURCE_SUFFIXES is the sole delta, with equal frozen mechanics and non-import source manifest identities. No case, seed, policy, gameplay or command bound changed.', 'entries':entries}
    write(HERE/'runner-compatibility.json',result)
    return result
