"""Canonical reasoned answers, applied last by BOTH question-bank builders.

Only course resources are touched, never user progress or release packages.
"""
import copy,json,re
from pathlib import Path
from reasoned_answers_data import raw_answers
from reasoned_stress import WORDS
ROOT=Path(__file__).resolve().parents[1]
C=ROOT/'modules/review/content'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,value):p.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
def norm(s):return s.lower().replace('\u0301','')
def accent_map():
    accents={}
    for p in sorted(C.rglob('*.json'))+[ROOT/'content/approximation_glossary.json']:
        for w in re.findall('[А-Яа-яЁё\u0301]+',p.read_text(encoding='utf8')):
            if '\u0301' in w or 'ё' in w.lower():accents.setdefault(norm(w),w.lower())
    for w in WORDS.split():accents[norm(w)]=w
    extra=ROOT/'tools/exam13_stress.json'
    if extra.exists():accents.update(read(extra))
    return accents
def answers():
    accents=accent_map()
    def stress(m):
        w=m[0];v=accents.get(norm(w),w)
        if w.isupper():return v.upper()
        return v[0].upper()+v[1:] if w[0].isupper() else v
    return {k:{'ru':re.sub('[А-Яа-яЁё\u0301]+',stress,a['ru']),'zh':a['zh']} for k,a in raw_answers().items()}
def first_sentence(s,lang):
    if lang=='zh':
        parts=re.split(r'(?<=[。！？])',s)
        return ''.join(parts[:2]) if len(parts[0])<=3 else parts[0]
    parts=re.split(r'(?<=[.!?])\s+(?=[А-ЯЁ])',s)
    return ' '.join(parts[:2]) if parts[0] in ['Да.','Нет.'] else parts[0]
def apply(readings,courses):
    all_answers=answers();byid={r['id']:r for r in readings}
    for r in readings:
        if r['id'] not in all_answers:continue
        r['answer']=copy.deepcopy(all_answers[r['id']])
        r['answer_version']='reasoned-2026-10-27'
        # Conditions now live in the explanation itself, in both languages.
        r.pop('condition',None)
    for c in courses:
        for g in c['groups']:
            r=byid.get(g['id'])
            if not r or r['id'] not in all_answers:continue
            for b in g['beats']:
                if b['id'].endswith(':answer'):
                    # Keep the spatial callout compact. The complete reasoning is
                    # on the reading card; existing spatial explanation beats stay.
                    b['words']={lang:first_sentence(r['answer'][lang],lang) for lang in ['zh','ru']}
                    b['text']=b['words']['zh'];b.pop('condition',None)
                    if 'recap' in b:
                        b['recap']={'zh':r['translation']+'\n'+r['answer']['zh'],'ru':r['question_ru']+'\n'+r['answer']['ru']}
    return readings,courses
def main():
    audit=[]
    for bank in [C,C/'exam12']:
        readings=read(bank/'reading.json');courses=read(bank/'topics.json')
        before={r['id']:copy.deepcopy(r['answer']) for r in readings}
        apply(readings,courses)
        write(bank/'reading.json',readings);write(bank/'topics.json',courses)
        for r in readings:
            if r['id'] in raw_answers():audit.append({'id':r['id'],'before':before[r['id']],'after':r['answer'],'source':r.get('source',{})})
        if (bank/'source_map.json').exists():
            source=read(bank/'source_map.json');index={r['id']:r for r in readings}
            for item in source['questions']:
                item['answer']=index[item['id']]['answer'];item['answer_version']='reasoned-2026-10-27'
            write(bank/'source_map.json',source)
    legacy=read(C/'lessons.json');all_answers=answers()
    for r in legacy:
        if r['id'] in all_answers:r['answer']=all_answers[r['id']]
    write(C/'lessons.json',legacy)
    path=ROOT/'qa/answer-rewrite-20261027';path.mkdir(exist_ok=True)
    # Preserve the original answer but keep the final editorial text current.
    if (path/'changes.json').exists():
        original={r['id']:r['before'] for r in read(path/'changes.json')}
        for r in audit:r['before']=original.get(r['id'],r['before'])
    write(path/'changes.json',audit)
    print('Reasoned answers:',len(audit))
if __name__=='__main__':main()
