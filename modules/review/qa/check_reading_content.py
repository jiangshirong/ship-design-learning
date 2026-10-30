"""Independent source, arithmetic and vocabulary checks. No network or user data."""
import json,re,zipfile,xml.etree.ElementTree as ET
from fractions import Fraction as F
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(name):return json.loads((ROOT/name).read_text(encoding='utf-8'))
records=read('content/reading.json');bank=read('content/question_bank.json')
lessons={e['id']:e for e in read('content/lessons.json')}
checks=[]
def check(ok,label):
    checks.append(dict(passed=bool(ok),name=label))
    assert ok,label
with zipfile.ZipFile(ROOT.parents[2]/'5p/Вопросы для подготовки по первой недели обучения.docx') as f:
    doc=ET.fromstring(f.read('word/document.xml'))
ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
paragraphs=[''.join(t.text or '' for t in p.findall('.//w:t',ns)).strip() for p in doc.findall('.//w:body/w:p',ns)]
questions=[p for p in paragraphs if p][1:]
check(len(records)==len(questions)==25,'25 original questions')
for index,(entry,original) in enumerate(zip(records,questions),1):
    check(entry['number']==index and entry['id']==f'Q{index:02}','Stable ID '+str(index))
    check(bank[index-1]['question_original']==original,'Source DOCX exact '+str(index))
    check(entry['question_ru']==bank[index-1]['question_ru'] and '\u0301' in entry['question_ru'],'Accented unabridged question '+str(index))
    check(entry['answer']==lessons[entry['id']]['answer'],'Existing concise bilingual answer '+str(index))
    check(len(re.findall('[。！？]',entry['fact']))<=2 and entry['fact'],'Maximum two fact sentences '+str(index))
    check(entry['translation'] and all(p['ru'] in entry['question_ru'] and p['zh'] for p in entry['phrases']),'Translation and exact phrase pairs '+str(index))
expected={7:{'example':400,'variant':420},8:{'example':5000,'variant':5000},9:{'example':2,'variant':6},10:{'example':1.5,'variant':9}}
for n in [7,8,9,10]:
    for kind,variant in records[n-1]['calculation'].items():
        a=variant['inputs'];q=lambda k:F(str(a[k]))
        if n==7:answer=q('D')*q('p');key='mass_t'
        if n==8:answer=q('P')/q('p');key='power_kw'
        if n==9:
            time=q('R')/q('v');answer=time*q('N')*q('p')/(1000 if a['unit']=='kg' else 1);key='mass_t'
            check(float(time)==variant['outputs']['time_h'],'Nautical mile/knot to hours '+kind)
        if n==10:
            litres=q('n')*q('S')*q('litres_per_day');answer=litres/1000;key='mass_t'
            check(float(litres)==variant['outputs']['volume_l'],'Litres independent total '+kind)
        check(float(answer)==variant['outputs'][key]==expected[n][kind],'Independent fraction arithmetic '+str(n)+kind)
glossary=read('content/glossary.json');ids={e['id']:e for e in glossary}
for key in ['allowed','more','still','which','be','example','first','less']:check(ids[key]['study']==False,'Excluded card '+key)
check(len(ids)==len(glossary),'Unique glossary IDs')
# Check coverage at token level, allowing only grammar/basic words and literal notation.
norm=lambda s:s.replace('\u0301','').lower()
aliases=sorted({a for e in glossary for a in e['aliases']},key=len,reverse=True)
pattern=re.compile(r'(?<![а-яё])(?:'+'|'.join(map(re.escape,aliases))+r')(?![а-яё])')
allowed=set('кто или не в при на с для по и а ли что как к от о из во за его её это но до чем чтобы какие какой если то да нет рк х рсэу т у рсэз гр'.split())
for e in records:
    unmatched=set(re.findall('[а-яё]+',pattern.sub(' ',norm(e['question_ru']+' '+e['answer']['ru']))))-allowed
    check(not unmatched,'Question/answer word coverage '+e['id']+' '+str(sorted(unmatched)))
for n,term in [(20,'无法单独确定'),(24,'没有列出比较对象'),(25,'不普遍成立')]:check(term in records[n-1]['fact'],'Necessary limitation visible '+str(n))
(ROOT/'qa/reading-content-checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),encoding='utf-8')
print(len(checks),'content checks passed; 25 full source questions, 8 independent computations.')
