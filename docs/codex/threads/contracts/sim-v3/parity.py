"""Independent exact current-source replay gate; no advance results inferred."""
from pathlib import Path
import json
from prepare import HERE, REPO, digest

def main():
    results = []
    for mode in ('legacy', 'trait'):
        old = json.loads((HERE.parent/'sim-v1'/f'{mode}-strong-probe.json').read_text())
        new = json.loads((HERE/f'capture-{mode}.json').read_text())
        signature = lambda x: (x.get('phase'),x.get('game'),x.get('success'),x.get('before',{}).get('cycle'),x.get('after',{}).get('cycle'))
        assert list(map(signature, old['actions'])) == list(map(signature, new['actions']))
        fields = ('final_review','scope','awareness','cycle','cash_cents')
        assert [tuple(x.get(k) for k in fields) for x in old['releases']] == [tuple(x.get(k) for k in fields) for x in new['releases']]
        fields = ('cycle','cash_before','direct_delta','kind','sales_earned','settled','productive')
        assert [tuple(x.get(k) for k in fields) for x in old['final']['finance']['actions']] == [tuple(x.get(k) for k in fields) for x in new['final']['finance']['actions']]
        assert old['final_finance_report'] == new['final_finance_report']
        assert new['valid'] and not new['errors'] and not new['discrepancies']
        log = (HERE/f'capture-{mode}.log').read_text()
        assert 'TASK34_TYPED_CAPTURE' in log and 'SCRIPT ERROR' not in log
        assert all('root certificate store' in line for line in log.splitlines() if line.startswith('ERROR:'))
        results.append({'startup':mode,'actions':len(new['actions']),'typed_checks':new['parity_checks'],'parity':True})
    manifest=json.loads((HERE/'source-manifest.json').read_text())
    assert all(digest(REPO/x['path']) == x['sha256'] for x in manifest['files'])
    report={'gate':'34A','passed':True,'source_files_unchanged':len(manifest['files']),'routes':results}
    (HERE/'parity-results.json').write_text(json.dumps(report,indent=2))
    print(json.dumps(report))

if __name__ == '__main__': main()
