"""Summarize retained candidate/control careers without changing simulation data."""
import argparse,json,hashlib
from pathlib import Path
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('--careers',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    source=json.loads((a.careers/'batch-report.json').read_text(encoding='utf-8'))
    report={'status':'CANDIDATE EVIDENCE ONLY','canonical_adoption':False,'batch_sha256':sha(a.careers/'batch-report.json'),'case_count':len(source['cases']),'cases':[],'seeds':{}}
    for row in source['cases']:
        folder=a.careers/row['case_id'];path=folder/'prelude.json'
        item=dict(row)
        if path.is_file():
            v=json.loads(path.read_text(encoding='utf-8'));releases=v['releases']
            reviews=[r['review_tenths'] for r in releases]
            receipt=lambda r:r['metadata']['review']
            item.update(reviews_tenths=reviews,release_cycles=[r['cycle'] for r in releases],high_reviews=sum(r>=80 for r in reviews),all_full_scope=all(receipt(r)['scope']>=receipt(r)['required_scope'] for r in releases),all_zero_bugs=all(receipt(r)['remaining_bugs']==0 for r in releases),all_commands_accepted=all(x['accepted'] for x in v['actions']),initial_scope=v['initial']['owned_scope'],initial_cash_cents=v['initial']['cash_cents'],final_cash_cents=v['final_cash_cents'],final_fans=v['final_fans'],phase=v['final_phase'],final_scope=v['final_owned_scope'],future_audio_active=not any(x in v['initial']['future_supply'] for x in ['music','sound_effects','8_bit_music','16_bit_music']),historical_source_checks=v['source_checks'],projection=v.get('projection',{}),result_sha256=sha(path),tape_sha256=sha(folder/'prelude.tape.json') if (folder/'prelude.tape.json').is_file() else None)
            if row['profile']=='candidate' and row['finance']=='trial':
                seed=report['seeds'].setdefault(row['seed'],{'historical_8plus':0,'studios_with_8plus':0,'titles':0,'first_reviews_tenths':[]})
                seed['historical_8plus']+=item['high_reviews'];seed['studios_with_8plus']+=bool(item['high_reviews']);seed['titles']+=len(releases)
                if reviews:seed['first_reviews_tenths'].append(reviews[0])
        report['cases'].append(item)
    report['candidate_72_count']=sum(bool(c.get('reached72')) for c in report['cases'] if c['profile']=='candidate' and c['finance']=='trial')
    report['all_declared_cases_present']=len(report['cases'])==21
    report['limitations']=['Independent pre-start careers, then shared January projection; not an interacting pre-1980 market.','Exact rosters, per-epoch untagged Store access, $25k capital, midpoint standards, fixed specialty Genre, seven Beta hands and flat reserve are OPEN trial controls.','No player Review/challenge, final balance, canonical migration/adoption, historical UI/device or native Research/input performance acceptance.']
    a.output.write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps({'candidate_72_count':report['candidate_72_count'],'cases':len(report['cases']),'seeds':report['seeds']}))
if __name__=='__main__':main()
