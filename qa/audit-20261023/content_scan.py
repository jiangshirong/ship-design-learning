import json,re,collections,hashlib,sys
from pathlib import Path
ROOT=Path('船舶原理学习');OUT=ROOT/'qa/audit-20261023'
read=lambda f:json.loads((ROOT/f).read_text(encoding='utf8'))
courses=read('content/courses.json');topics=read('modules/review/content/topics.json');formula=read('content/latex_source.json');formula.update(read('content/bulkheads_latex.json'));tf=read('modules/review/content/topics_latex.json');tf.update(read('modules/review/content/stability_latex.json'))
result=[];dupes=[];narr=[];lengths=[];inert=[]
for kind,cs,tex in [('home',courses,formula),('topic',topics,tf)]:
 for c in cs:
  beats=[b for g in c['groups'] for b in g['beats']];seen=collections.defaultdict(list);spoken=collections.defaultdict(list)
  for b in beats:
   for row in tex.get(b['id'],{}).get('zh',[]):seen[row['tex']].append(b['id'])
   z=b.get('words',{}).get('zh','');spoken[z].append(b['id'])
   if len(z)>60 or len(b.get('words',{}).get('ru',''))>190:lengths.append(dict(course=c['id'],id=b['id'],zh=z,ru=b.get('words',{}).get('ru','')))
  for s,ids in seen.items():
   ids=list(dict.fromkeys(ids))
   if len(ids)>1:dupes.append(dict(course=c['id'],formula=s,steps=ids))
  for s,ids in spoken.items():
   if len(ids)>1 and len(s)>10:narr.append(dict(course=c['id'],text=s,steps=ids))
  for g in c['groups']:
   run=[]
   for b in g['beats']:
    if not b.get('action'):run.append(b['id'])
    else:
     if len(run)>=3:inert.append(dict(course=c['id'],group=g['id'],steps=run));run=[]
   if len(run)>=3:inert.append(dict(course=c['id'],group=g['id'],steps=run))
  result.append(dict(kind=kind,id=c['id'],title=c['title']['zh'],groups=len(c['groups']),steps=len(beats),opening=beats[0].get('words'),missing_bilingual=[b['id'] for b in beats if not all(b.get('words',{}).get(l) for l in ['zh','ru'])],sources=[b.get('source') for b in beats if b.get('source')][:2]))
report=dict(chapters=result,duplicate_formula_candidates=dupes,duplicate_narration_candidates=narr,long_paragraphs=lengths,static_run_candidates=inert)
(OUT/'content-scan.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({'chapters':len(result),'beats':sum(c['steps'] for c in result),'duplicate_formulas':len(dupes),'duplicate_paragraphs':narr,'long_paragraphs':lengths[:8],'static_runs':inert},ensure_ascii=False,indent=2))
sys.path.insert(0,str(ROOT/'modules/review/tools'))
from audit_lookup import scan
coverage=scan();(OUT/'lookup-coverage.json').write_text(json.dumps(coverage,ensure_ascii=False,indent=2),encoding='utf8')
print('Uncovered lexical forms',len(coverage['missing']));print(json.dumps(coverage['missing'],ensure_ascii=False)[:7000])
