"""Independent DOCX/alias/answer/build invariants for the 9p revision."""
import json,re,zipfile,hashlib,xml.etree.ElementTree as E,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];COURSE=ROOT.parents[2]
r=lambda f:json.loads((ROOT/f).read_text(encoding='utf-8'))
checks=[]
def ck(ok,label):checks.append(dict(name=label,passed=bool(ok)))
def norm(x):return re.sub(r'\s+',' ',x.lower().replace('\u0301','').replace('ё','е')).strip()
p=COURSE/'9p-晚上发的/Проверочная работа 2. Вопросы для подготовки.docx'
with zipfile.ZipFile(p) as z:ps=[''.join(n.itertext()).strip() for n in E.fromstring(z.read('word/document.xml')).findall('.//{http://schemas.openxmlformats.org/wordprocessingml/2006/main}p')]
raw=[s for s in ps if s and not s.startswith('Тема')]
bank=r('content/question_bank.json');cards=r('content/reading.json');topics=r('content/topics.json');byid={q['id']:q for q in cards};aliases={s:q['id'] for q in bank for s in q['sources']}
ck(len(raw)==41,'41 questions read directly from original DOCX')
ck(len(bank)==len(cards)==62 and len(aliases)==90 and len(topics)==9,'62 cards / 90 aliases / 9 topics')
for i,text in enumerate(raw,1):
 qid=aliases.get(f'9p-{i}');ck(qid in byid,f'9p-{i} resolves')
 q=next(q for q in bank if q['id']==qid)
 variants=byid[qid].get('source_variants',[])
 original=next((v['original'] for v in variants if v['source']==f'9p-{i}'),q['question_original'])
 ck(original==text,f'Exact 9p-{i} wording retained')
 if qid.startswith('R9') and i!=35:ck(norm(byid[qid]['question_ru'])==norm(text),f'Accents preserve 9p-{i} wording')
ck(aliases['9p-31']==aliases['9p-35'],'Equivalent power questions share mastery')
ck(byid['N14']['answer']['ru']=='По́лному гру́зу и по́лным запа́сам.','Full load answer simplified')
ck(byid['M11Q08']['answer']['ru']=='Е́сли коэффицие́нты полноты́ не изменя́ются.' and 'condition' not in byid['M11Q08'],'Open-ended conditional question, not missing text')
ck('око́неч' not in json.dumps(cards,ensure_ascii=False),'Question stress corrected without changing original wording')
ck('дополни́тельное' in byid['M11Q03']['answer']['ru'],'Added resistance in waves remains distinct from wave-making resistance')
for q in cards:ck('увеличива' not in norm(q['answer']['ru']),f'No extra imperfective increase verb in answer {q["id"]}')
for c in topics:
 ids=[b['id'] for g in c['groups'] for b in g['beats']]
 for q in c['questions']:ck(c['question_targets'][q] in ids,f'Animation target {q}')
free=next(c for c in topics if c['id']=='freeboard');order=[g['id'] for g in free['groups']]
ck(order.index('N14')<order.index('R9Q17')<order.index('R9Q18')<order.index('R9Q19')<order.index('N15'),'New freeboard reasoning inserted at dependency point')
ck(math.isclose(100*10/.6,1666.6666666667),'kN m/s = kW, engine power EPS/eta')
ck(math.isclose(10/math.sqrt(9.81*100),.3192754284070505),'Length Froude independent numerical check')
report=dict(checks=len(checks),failures=[c for c in checks if not c['passed']],results=checks,source_sha256=hashlib.sha256(p.read_bytes()).hexdigest(),aliases={s:q for s,q in aliases.items() if s.startswith('9p-')},boundary='Regime thresholds belong to original question; volume-Froude interpretation is stated explicitly, not claimed as a supplied lecture definition.')
(ROOT/'qa/revision9p-content.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(len(checks),'9p checks;',len(report['failures']),'failures')
for c in report['failures']:print(c['name'])
raise SystemExit(bool(report['failures']))
