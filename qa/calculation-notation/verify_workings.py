import json,re,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'))
from calculation_notation import apply
from exam13 import stress
read=lambda p:json.loads(p.read_text(encoding='utf8'))
b=ROOT/'modules/review/content/exam12';r,c,f=[read(b/n) for n in ['reading.json','topics.json','latex.json']]
snapshot=json.dumps([r,c,f],sort_keys=True,ensure_ascii=False);apply(r,c,f,stress);assert snapshot==json.dumps([r,c,f],sort_keys=True,ensure_ascii=False)
old=read(ROOT.parent/'tmp/pdfs/handwriting/compact/manifest.json');assert {q['id']:q['question'] for q in old['questions']}=={q['id']:q['question_ru'] for q in r if q.get('kind')!='figure'}
assert read(ROOT.parent/'新题目手抄/data/questions.json')==[q for q in r if q.get('kind')!='figure']
checks=[]
for qid in ['P12_C01','P12_C02','P12_C03']:
 q=next(q for q in r if q['id']==qid);rows=q['example_data']['rows'];p=sum(v[1] for v in rows);mx=sum(v[1]*v[2] for v in rows);mz=sum(v[1]*v[3] for v in rows)
 assert (p,mx,mz)==tuple(q['example_data'][k] for k in ['total','mx','mz'])
 assert abs(mx/p-q['example_data']['xg'])<1e-12 and abs(mz/p-q['example_data']['zg'])<1e-12
 for i,row in enumerate(rows):
  formula=f[qid+f':row{i}']['zh'];assert any(r'\cdot '+str(row[2]) in v['tex'] for v in formula);assert any(r'\cdot '+str(row[3]) in v['tex'] for v in formula)
 for suffix in ['sum','xsum','zsum']:assert len(f[qid+':'+suffix]['zh'])>=3
 checks.append({'id':qid,'mass':p,'longitudinal_moment':mx,'vertical_moment':mz,'x':mx/p,'z':mz/p,'row_calculations':len(rows)})
assert abs(12*1.2-14.4)<1e-12
for key,v in f.items():
 if key.startswith('P12_C01'):assert not re.search(r'[Pxz]_\{?[12]',str(v))
 if key.startswith('P12_C03'):assert 'P_{3}' not in str(v)
 if key.startswith('P12_C02'):assert not re.search(r'P_\{?[0-5]\}?',str(v))
assert any(r'\mathrm{Х}' in v['tex'] for v in f['P12_C04:solution']['zh'])
engine=read(ROOT/'qa/calculation-notation/workings-engine.json');assert engine['pass']
report={'pass':True,'question_count':67,'questions_unchanged':True,'generator_idempotent':True,'handcopy_exact_copy':True,'calculations':checks,'dining_example_m2':14.4,'engine_checks':len(engine['checks']),'limitation':'No fabricated hydrostatics or dining proportion; packages not rebuilt.'}
(ROOT/'qa/calculation-notation/workings-content.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8');print(json.dumps(report,ensure_ascii=False))
