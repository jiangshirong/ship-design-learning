"""Continuous comparisons without repeat openings; stable aliases for old saves."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def apply(courses,formulas,bank,readings):
    freeboard=next(c for c in courses if c['id']=='freeboard')
    for g in freeboard['groups']:
        qid=g['id']
        if qid not in ['R9Q17','R9Q18','R9Q19']:continue
        if qid!='R9Q17':
            old=f'R9:{qid}:0';new=f'R9:{qid}:1'
            g['beats']=[b for b in g['beats'] if b['id']!=old]
            freeboard.setdefault('resume_aliases',{})[old]=new
            freeboard['question_targets'][qid]=new
            readings[qid]['target']=new
            next(q for q in bank if q['id']==qid)['target']=new
        for b in g['beats']:
            # The visual uses the same unchanged requirements while the ship sinks.
            b['start_params']['p']=0 if qid=='R9Q17' else (1 if qid=='R9Q18' else 2)
            if b['id'].endswith(':answer'):b['start_params']['p']={'R9Q17':1,'R9Q18':2,'R9Q19':3}[qid]
            elif b.get('action'):b['action']['params']['p']=({'R9Q17':1,'R9Q18':2,'R9Q19':3}[qid] if b['id'].endswith(':1') else 0)
    # Preserve the presentation's final parameter value in every following segment.
    for c in courses:
        if c['id']!='arrangement':continue
        for g in c['groups']:
            if not g['id'].startswith('R9Q'):continue
            prev=0.0
            for b in g['beats']:
                b['start_params']['p']=prev
                if b.get('action'):prev=b['action']['params'].get('p',prev)
                if b['id'].endswith(':answer'):b['start_params']['p']=prev
                if g['id']=='R9Q41' and b['id'].endswith(':1'):
                    b['words']={'zh':'艏部这段封闭的上层建筑，就是艏楼。','ru':'Носова́я закры́тая надстро́йка — бак.'};b['text']=b['words']['zh']
def update_existing():
    def load(n):return json.loads((ROOT/'content'/n).read_text(encoding='utf8'))
    courses=load('topics.json');formulas=load('topics_latex.json');bank=load('question_bank.json');rows=load('reading.json');readings={r['id']:r for r in rows}
    apply(courses,formulas,bank,readings)
    for n,v in [('topics.json',courses),('topics_latex.json',formulas),('question_bank.json',bank),('reading.json',rows)]:
        (ROOT/'content'/n).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
if __name__=='__main__':update_existing()
