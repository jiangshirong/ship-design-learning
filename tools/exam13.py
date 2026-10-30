"""Append 13a reading-only questions. Existing cards, IDs and animations survive."""
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as E
import json,re
from functools import lru_cache
from exam13_data import ROWS,SOURCES,FORMULAS
from focused_new_answers import get_answers
from apply_reasoned_answers import accent_map
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'modules/review/content/exam12'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
def originals():
    with ZipFile(ROOT.parent/'13a/问题.docx') as z:root=E.fromstring(z.read('word/document.xml'))
    out={}
    for para in root.findall('.//{http://schemas.openxmlformats.org/wordprocessingml/2006/main}p'):
        text=''.join(n.text or '' for n in para.iter() if n.tag.rsplit('}',1)[-1]=='t')
        m=re.match(r'^(\d+)\.\s*(.+)',text)
        if m:out[int(m[1])]=m[2]
    assert set(out)==set(range(1,31)),'Expected original 13a questions 1–30'
    return out
@lru_cache(maxsize=1)
def accents():
    accents=accent_map()
    extra=ROOT/'tools/exam13_stress.json'
    if extra.exists():accents.update(read(extra))
    # ё is a spelling refinement; retain the verbatim teacher text separately.
    accents['порожнем']='порожнём'
    return accents
def stress(text):
    word_accents=accents()
    def replace(m):
        w=m[0];v=word_accents.get(w.lower().replace('\u0301',''),w)
        return v[0].upper()+v[1:] if w[0].isupper() else v
    return re.sub('[А-Яа-яЁё\u0301]+',replace,text).replace('D_1','D₁')
def append(entries,courses,formulas,audit):
    # Idempotent, including source numbering and the non-animated topic.
    entries[:]=[e for e in entries if not e['id'].startswith('P13_')]
    courses[:]=[c for c in courses if c['id']!='P13_approximation']
    audit[:]=[a for a in audit if not a['id'].startswith('P13_')]
    for course in courses:course['questions']=[q for q in course['questions'] if not q.startswith('P13_')]
    courses.insert(1,{'id':'P13_approximation','title':{'zh':'近似计算与迭代修正','ru':stress('Приближения и уточнение проекта')},'goal':{'zh':'理解为什么从排水量起步，以及质量、功率和尺度为什么需要反复校核。','ru':stress('Поймём, зачем уточнять массу, мощность и размеры.')},'questions':[],'groups':[],'question_targets':{},'animation_available':False})
    byid={c['id']:c for c in courses};questions=originals()
    for row in ROWS.strip().splitlines():
        number,topic,zh,ru,answer_zh=row.split('|');n=int(number);qid=f'P13_Q{n:02}';original=questions[n]
        focused=get_answers()[qid];ru=focused['ru'];answer_zh=focused['zh']
        entry={'id':qid,'kind':'theory','sources':[f'13a-{n}'],'question_original':original,'question_ru':stress(original),'translation':zh,'answer':{'zh':answer_zh,'ru':stress(ru)},'topic':topic,'animation_available':False,'source':'13a/问题.docx','source_aliases':[{'label':f'13a-{n}','original':original}],'answer_version':'13a-reasoned-2026-10-28','answer_sources':SOURCES[topic]}
        if n in FORMULAS:
            entry['formula_id']=qid+':formulas'
            formulas[entry['formula_id']]={lang:[{'tex':t,'linear':t} for t in FORMULAS[n]] for lang in ['zh','ru']}
        entries.append(entry);byid[topic]['questions'].append(qid)
        audit.append({'id':qid,'source':'13a/问题.docx','teacher_materials':SOURCES[topic],'original':original,'answer':entry['answer'],'answer_version':'13a-reasoned-2026-10-28','animation':None})
    from merge_duplicate_questions import apply as merge_duplicates
    merge_duplicates(entries,courses,audit)
    assert len([e for e in entries if e['id'].startswith('P13_')])==29
    return entries,courses,formulas,audit
def build():
    entries=read(OUT/'reading.json');courses=read(OUT/'topics.json');formulas=read(OUT/'latex.json');source=read(OUT/'source_map.json')
    append(entries,courses,formulas,source['questions'])
    source['teacher_question_count']=len([q for q in entries if q.get('kind')!='figure'])
    source['source_question_count']=67
    source['duplicate_aliases']={'P13_Q30':'P12_T03'}
    source['question_files']={'12p/题目.docx':36,'12p/pictures_for_exam.docx':1,'13a/问题.docx':30}
    write(OUT/'reading.json',entries);write(OUT/'topics.json',courses);write(OUT/'latex.json',formulas);write(OUT/'source_map.json',source);write(OUT/'question_bank.json',[{'id':e['id'],**({'legacy_ids':e['legacy_ids']} if e.get('legacy_ids') else {})} for e in entries])
    print('13a appended: 30 reading-only questions; new bank:',len(entries),'entries')
    from exam13_lexicon import build as build_words
    build_words()
if __name__=='__main__':build()
