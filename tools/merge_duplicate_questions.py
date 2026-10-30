"""Merge only the explicitly confirmed identical 12p-3 / 13a-30 pair."""
import copy
ALIASES={"P13_Q30":"P12_T03"}
def apply(entries,courses,audit=None):
    by={q['id']:q for q in entries};canonical=by['P12_T03'];duplicate=by.get('P13_Q30')
    if duplicate:assert canonical['question_original']==duplicate['question_original']
    canonical['sources']=['12p-3','13a-30'];canonical['legacy_ids']=['P13_Q30']
    aliases=canonical.setdefault('source_aliases',[])
    if not any(a['label']=='13a-30' for a in aliases):aliases.append({'label':'13a-30','original':canonical['question_original'],'source':'13a/问题.docx'})
    entries[:]=[q for q in entries if q['id']!='P13_Q30']
    for c in courses:
        c['questions']=[q for q in c['questions'] if q!='P13_Q30']
        c.get('question_targets',{}).pop('P13_Q30',None)
    if audit is not None:
        audit[:]=[q for q in audit if q['id']!='P13_Q30']
        for q in audit:
            if q['id']=='P12_T03':q['source_aliases']=copy.deepcopy(aliases);q['legacy_ids']=['P13_Q30']
    return entries,courses
if __name__=='__main__':
    import json
    from pathlib import Path
    root=Path(__file__).resolve().parents[1];b=root/'modules/review/content/exam12'
    read=lambda p:json.loads(p.read_text(encoding='utf8'))
    e,c,s=[read(b/n) for n in ['reading.json','topics.json','source_map.json']];apply(e,c,s['questions'])
    s['teacher_question_count']=66;s['source_question_count']=67;s['duplicate_aliases']=ALIASES
    catalog=[{'id':q['id'],**({'legacy_ids':q['legacy_ids']} if q.get('legacy_ids') else {})} for q in e]
    for n,v in [('reading.json',e),('topics.json',c),('source_map.json',s),('question_bank.json',catalog)]:
        (b/n).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('66 independent questions; 67 source numbers; 6 figure auxiliaries.')
