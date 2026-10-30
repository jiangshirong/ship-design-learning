"""Add actual answer word forms without changing existing word IDs or grades."""
import json,re
from pathlib import Path
import pymorphy3
from reasoned_lexicon import ROWS
ROOT=Path(__file__).resolve().parents[1];C=ROOT/'modules/review/content'
def norm(s):return s.lower().replace('\u0301','').replace('ё','е')
def read(p):return json.loads(p.read_text(encoding='utf8'))
def build():
    morph=pymorphy3.MorphAnalyzer();base=[]
    for path in [C/'glossary.json',ROOT/'content/approximation_glossary.json',C/'exam12/glossary.json']:base+=read(path)
    aliases={norm(a):e for e in base for a in e['aliases']}
    lemmas={norm(e['ru']):e for e in base}
    additions={}
    for line in ROWS.strip().splitlines():
        fields=line.split('|');ru,zh=fields[:2];key=norm(ru)
        e=lemmas.get(key,{'id':'answer_v2_'+key.replace(' ','_'),'ru':ru,'zh':zh,'meaning':zh,'aliases':[ru.lower().replace('\u0301','')],'study':len(fields)<3 or fields[2]!='0'})
        additions[key]=dict(e,aliases=list(e['aliases']))
    corrections={'боков':'боковой','кос':'косой','неудалять':'неудаляемый','плав':'на плаву','приблизить':'приближенный','потерянный':'потерять','предусмотренный':'предусмотреть','обвод':'обводы'}
    # Retain definitions and IDs when editing answers stops using a word.
    # Study membership is still selected from the active question/answer text.
    output={e['id']:dict(e,aliases=list(e['aliases'])) for e in additions.values()};missing={};audit=[]
    forms=set()
    for bank in [C,C/'exam12']:
        for q in read(bank/'reading.json'):
            if q.get('kind')=='figure' or q['id'].startswith('P13_'):continue
            for text in [q['question_ru'],q['answer']['ru']]:forms.update(re.findall('[а-яё]+',text.lower().replace('\u0301','')))
    for w in sorted(forms):
        if norm(w) in aliases:continue
        parses=morph.parse(w);key=corrections.get(norm(parses[0].normal_form),norm(parses[0].normal_form))
        if key in additions:e=additions[key]
        else:
            matches=[lemmas[norm(p.normal_form)] for p in parses if norm(p.normal_form) in lemmas]
            if not matches:missing[w]=key;continue
            e=matches[0]
        if e['id'] not in output:output[e['id']]=dict(e,aliases=list(e['aliases']))
        output[e['id']]['aliases']=list(dict.fromkeys(output[e['id']]['aliases']+[w]))
        audit.append({'form':w,'lemma':e['ru'],'id':e['id']})
    target=C/'reasoned_glossary.json';target.write_text(json.dumps(list(output.values()),ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    (ROOT/'qa/reasoned-lexical-results.json').write_text(json.dumps({'missing':missing,'forms':audit},ensure_ascii=False,indent=2),encoding='utf8')
    print('Glossary additions/alias extensions:',len(output),'missing:',missing)
    return missing
if __name__=='__main__':build()
