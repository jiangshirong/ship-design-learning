"""Original question bank and concise answers. No new answers for pending lessons."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def normalize(s):return ' '.join(s.lower().replace('\u0301','').replace('ё','е').split())
def words(s):return re.findall('[а-яё]+',normalize(s))
def build(courses,originals,sections):
    ru=json.loads((ROOT/'content/questions_ru.json').read_text(encoding='utf-8'))
    assert len(ru)==len(originals)==25
    short={
      'Q01':('订船方。','Зака́зчик.'),
      'Q02':('货舱容积不变。','Грузовмести́мость не изменя́ется.'),
      'Q04':('它说明船舶实际怎样建成。','Она́ пока́зывает, как постро́ено су́дно.'),
      'Q05':('这种估算不宜用它，应选尺寸接近的母型。','Нет. Для расчёта ну́жен прототи́п бли́зкого разме́ра.'),
      'Q11':('增大型深。','Увели́чить высоту́ бо́рта.'),
      'Q14':('不能，货物质量已达上限。','Нет. Ма́сса гру́за уже́ на преде́ле.'),
      'Q15':('增大型深。','Увели́чить высоту́ бо́рта.'),
    }
    bank=[]
    for i,(raw,stressed,section) in enumerate(zip(originals,ru,sections),1):
        expected=raw.replace('размерениясудна','размерения судна')
        assert normalize(expected)==normalize(stressed),(i,raw,stressed)
        bank.append(dict(id=f'Q{i:02}',number=i,title_zh=section['study_section'].splitlines()[0],question_original=raw,question_ru=stressed))
    audit=[]
    for course in courses:
        before=course['answer']['ru'];zh,answer=short[course['id']]
        course['answer']={'zh':zh,'ru':answer}
        audit.append(dict(id=course['id'],before=before,after=answer,words_before=len(before.split()),words_after=len(answer.split())))
    # Exact word-form inventory; do not mislabel it a count of dictionary lemmas.
    index={}
    for q in bank:
        for word in set(words(q['question_ru'])):index.setdefault(word,[]).append(q['number'])
    report={'questions':25,'original_text_verified':True,'normalization':'Accents, whitespace, е/ё and the missing space in Q11 only; original wording and incomplete units retained.',
      'distinct_question_word_forms':len(index),'question_word_forms':dict(sorted(index.items())),'answer_changes':audit,
      'answer_forms_not_in_questions':sorted({w for c in courses for w in words(c['answer']['ru']) if w not in index})}
    for name,data in [('content/question_bank.json',bank),('content/lessons.json',courses),('qa/answer-vocabulary-audit.json',report)]:
        (ROOT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    q14=next(c for c in courses if c['id']=='Q14')
    (ROOT/'content/sample.json').write_text(json.dumps(q14,ensure_ascii=False,indent=2),encoding='utf-8')
    print(f'25 original questions verified; {len(index)} distinct Russian word forms; 7 answers shortened.')
