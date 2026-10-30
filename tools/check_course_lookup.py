import json,re,collections
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
read=lambda p:json.loads((ROOT/p).read_text(encoding='utf8'))
entries=read('modules/review/content/glossary.json')+read('content/approximation_glossary.json')
aliases=sorted({a for e in entries for a in e['aliases']},key=len,reverse=True)
pattern=re.compile(r'(?<![a-z\u0400-\u04ff])(?:'+ '|'.join(map(re.escape,aliases))+r')(?![a-z\u0400-\u04ff])')
sources=[]
for file in ['content/courses.json','modules/review/content/topics.json']:
 for c in read(file):
  for g in c['groups']:
   for b in g['beats']:
    sources.append((b['id'],b['words']['ru']))
for q in read('modules/review/content/reading.json'):
 sources += [(q['id']+':question',q['question_ru']),(q['id']+':answer',q['answer']['ru'])]
missing=collections.defaultdict(list)
for key,text in sources:
 plain=text.lower().replace('\u0301','').replace('\u0300','')
 stripped=pattern.sub(lambda m:' '*len(m.group()),plain)
 for m in re.finditer('[а-яё]+',stripped):
  missing[m.group()].append({'id':key,'text':text})
out=ROOT/'qa/repair-20261023/lookup-remaining.json';out.write_text(json.dumps(missing,ensure_ascii=False,indent=2),encoding='utf8')
print(len(missing),'unmatched tokens');print(' | '.join(sorted(missing)))
