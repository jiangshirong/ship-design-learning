"""Independent decimal checks against 6a-Женя.docx, not generated expected outputs."""
from decimal import Decimal as D, ROUND_CEILING, ROUND_FLOOR
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[1];checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)});assert ok,name
L=D('189.13');B=D('26.53');H=D('14.97');T=D('10.85')
check('nominal',D('.002')*L+D('.48')==D('.85826'))
for name,lo,hi,a,expected in [('fore','.05','.08','.6',(16,25)),('aft','.04','.08','.6',(13,25)),('engine','.14','.17','1.7',(16,18))]:
 low=D(lo)*L;high=D(hi)*L;a=D(a)
 check(name+' integer bounds',(int((low/a).to_integral_value(rounding=ROUND_CEILING)),int((high/a).to_integral_value(rounding=ROUND_FLOOR)))==expected)
ns=[0,24,60,85,109,133,157,181,185,221,243]
def pos(n):
 if n<=24:return D(n)*D('.6')
 if n<=61:return D('14.4')+D(n-24)*D('.69')
 if n<=221:return D('39.93')+D(n-61)*D('.85')
 return D('175.93')+D(n-221)*D('.6')
lengths=[pos(b)-pos(a) for a,b in zip(ns,ns[1:])]
check('all ten compartment lengths',lengths==list(map(D,['14.4','24.84','21.09','20.4','20.4','20.4','20.4','3.4','30.6','13.2'])))
check('full length',sum(lengths)==L)
check('cargo length',sum(lengths[1:7])==D('127.53'))
check('transition end',pos(61)==D('39.93') and pos(61)>D('.2')*L)
check('minimum transition',D('.2')*L-D('14.4')==D('23.426'))
for n in [58,60,61]:check('pair conserved '+str(n),(pos(n)-pos(24))+(pos(85)-pos(n))==D('45.93'))
db=D('.0328')*H+D('1.2');minimum=(L-40)/570+D('.04')*B+D('3.5')*T/L
check('double bottom estimate',db==D('1.691016'));check('double bottom adopted',minimum<D('1.70')<=2)
dw=44024-(10840+1041);side=D('.5')+D(dw)/20000
check('deadweight',dw==32143);check('double side',side==D('2.10715') and side<D('2.20')<=D('2.5'))
check('central width',B-2*D('2.2')-2*D('6.65')==D('8.83'))
check('length rule',D('8.85')/B>D('.2') and max(lengths[1:7])<D('.2')*L)
course=json.loads((root/'content/bulkheads.json').read_text(encoding='utf-8'));beats=[b for g in course['groups'] for b in g['beats']]
check('stable IDs unique',len(beats)==len({b['id'] for b in beats}))
check('all bilingual',all(b['words']['zh'] and '\u0301' in b['words']['ru'] for b in beats))
check('source steps complete',all('BH:'+k in {b['id'] for b in beats} for k in ['pump','secondhold','webjoin','dbcheck','dbadopt','deadweight','sideadopt','central','tankcheck','finish']))
topics=json.loads((root/'modules/review/content/topics.json').read_text(encoding='utf-8'))
def groups(x):
 if isinstance(x,dict):
  if x.get('id')=='Q19' and 'beats' in x:yield x
  for v in x.values():yield from groups(v)
 elif isinstance(x,list):
  for v in x:yield from groups(v)
q=next(groups(topics));check('Q19 seven beats',len(q['beats'])==7)
check('Q19 only one hull lowering action',sum(b.get('action',{}).get('params',{}).get('morph')==1 for b in q['beats'])==1)
check('Q19 unnumbered title',q['title']['zh']=='最大力臂');check('Q19 ending no action','action' not in q['beats'][-1])
(root/'qa/bulkheads-numerical.json').write_text(json.dumps({'checks':checks,'frames':ns,'from_bow':[str(pos(n)) for n in ns],'double_bottom_min':str(minimum),'source_sha256':hashlib.sha256((root.parent/'6a/6a-Женя.docx').read_bytes()).hexdigest()},ensure_ascii=False,indent=2),encoding='utf-8')
print(len(checks),'independent checks passed')
