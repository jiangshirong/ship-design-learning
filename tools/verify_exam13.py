"""13a source/lookup/progress acceptance. Never writes user data."""
import json,re,hashlib,copy
from pathlib import Path
from exam13 import originals,append,OUT,ROOT
from focused_new_answers import get_answers
read=lambda p:json.loads(p.read_text(encoding='utf8'))
rows=read(OUT/'reading.json');courses=read(OUT/'topics.json');formulas=read(OUT/'latex.json');source=read(OUT/'source_map.json');before=read(ROOT/'qa/exam13/before.json')
checks=[]
def check(ok,label):checks.append({'check':label,'pass':bool(ok)})
def norm(s):return s.replace('\u0301','').replace('ё','е').replace('Ё','Е').replace('D₁','D_1')
new=[q for q in rows if q['id'].startswith('P13_')];old=[q for q in rows if not q['id'].startswith('P13_')];orig=originals()
check(len(new)==29 and len(old)==43 and len(courses)==8,'29张新增独立题＋43原条目；8专题')
check(len({q['id'] for q in rows})==72,'所有稳定ID唯一')
check(len([q for q in rows if q.get('kind')!='figure'])==66,'新入口合计66道有题干问答')
for q in new:
    n=int(q['id'][-2:]);check(q['question_original']==orig[n] and norm(q['question_ru'])==norm(orig[n]),'原题及来源编号准确 '+q['id'])
    check(q['sources']==[f'13a-{n}'] and q['animation_available'] is False,'明确来源且无动画入口 '+q['id'])
    check(sum(q['id'] in c['questions'] for c in courses)==1,'只归属一个知识专题 '+q['id'])
    check(all((ROOT.parent/p).exists() for p in q['answer_sources']),'核对教师资料存在 '+q['id'])
    check(norm(q['answer']['ru'])==norm(get_answers()[q['id']]['ru']) and q['answer']['zh']==get_answers()[q['id']]['zh'],'使用逻辑完整的要点稿 '+q['id'])
for q in old:
    original=before['new_existing'][q['id']]
    check({k:v for k,v in q.items() if k not in (['answer','sources','source_aliases','legacy_ids'] if q['id']=='P12_T03' else ['answer'])}=={k:v for k,v in original.items() if k not in (['answer','sources','source_aliases','legacy_ids'] if q['id']=='P12_T03' else ['answer'])},'原题/示例/识图/题目ID保留 '+q['id'])
    if q.get('kind')=='figure':check(q==original,'识图不改写 '+q['id'])
missing_stress=set()
for q in rows:
    for text in [q['question_ru'],q['answer']['ru']]:
        for word in re.findall('[А-Яа-яЁё\u0301]+',text):
            if word not in ['СЭУ','КПД'] and len(re.findall('[аеёиоуыэюя]',word.lower()))>1 and '\u0301' not in word and 'ё' not in word.lower():missing_stress.add(word)
check(not missing_stress,'新题库全部问答重音覆盖')
gloss=[]
for p in [ROOT/'modules/review/content/glossary.json',ROOT/'content/approximation_glossary.json',OUT/'glossary.json',ROOT/'modules/review/content/reasoned_glossary.json',OUT/'glossary13.json']:gloss+=read(p)
aliases=sorted({a for e in gloss for a in e['aliases']},key=len,reverse=True)
matcher=re.compile(r'(?<![a-zа-яё])(?:'+'|'.join(map(re.escape,aliases))+r')(?![a-zа-яё])')
missing=set()
for q in rows:
    if q.get('kind')=='figure':continue
    for text in [q['question_ru'],q['answer']['ru']]:
        text=text.lower().replace('\u0301','');covered=set()
        for m in matcher.finditer(text):covered.update(range(m.start(),m.end()))
        for m in re.finditer('[а-яё]+',text):
            if not set(range(m.start(),m.end()))<=covered and m[0] not in ['зап']:missing.add(m[0])
check(not missing,'全部66题问答实际拼写的查词覆盖')
live_changed=[]
for category in ['protected_files','progress','exe']:
    for path,digest in before[category].items():
        same=Path(path).exists() and hashlib.sha256(Path(path).read_bytes()).hexdigest()==digest
        if not same and category=='progress' and Path(path).name=='exam12-reading.json':
            # Observed pre-existing user process 25348 (started 08:36:11).
            # Its reading selection changed at 08:38:09 during the user's feedback.
            # Never restore the earlier hash over live learning activity.
            state=read(Path(path));ids={q['id'] for q in rows}
            valid=state.get('selected') in ids and all(k in ids and v in ['known','review'] for k,v in state.get('marks',{}).items())
            check(valid,'用户运行中的阅读记录仍有效，保留其最新位置')
            live_changed.append({'path':path,'selected':state.get('selected'),'reason':'Pre-existing user app updated this reading record while work was in progress. No tool writes to this file.'})
        else:check(same,category+'保持 '+Path(path).name)
saved=json.dumps([rows,courses,formulas,source['questions']],sort_keys=True,ensure_ascii=False)
append(rows,courses,formulas,source['questions'])
check(saved==json.dumps([rows,courses,formulas,source['questions']],sort_keys=True,ensure_ascii=False),'重复构建不重复加题，不改变既有动画步骤')
check(get_answers()['P12_T17']['zh']=='一艘母型通常不能满足新船的全部要求，借来的方案仍需协调、调整并通过计算验证。','母型回答保留原因和后果，去掉铺垫总结')
report={'pass':all(c['pass'] for c in checks),'checks':checks,'missing_stress':sorted(missing_stress),'missing_meaning':sorted(missing),'live_user_progress':live_changed}
(ROOT/'qa/exam13/content-results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
lines=['# 13a 新增题目与答案','', '来源：13a/问题.docx，共30道。原文件只说“图片明天发”，本轮不补造图片题。按知识体系加入“新题目复习”，不新增模型或动画。','', '回答保留结论、因果及决定结论的条件，删除铺垫和重复总结。教师材料用于核对，以下是据此编写的解释，不标为老师提供的标准答案。','']
for c in courses:
    selected=[q for q in new if q['topic']==c['id']]
    if not selected:continue
    lines+=['## '+c['title']['zh'],'']
    for q in selected:
        lines+=['### '+q['sources'][0],'',q['question_ru'],'',q['translation'],'',q['answer']['ru'],'',q['answer']['zh'],'','核对资料：'+'；'.join(q['answer_sources']),'']
lines+=['## 关键边界','', '- 诺曼系数解释的是重新设计中的连带变化；大于1依赖本课程的质量导数条件，不套用于已建船实际装货。','- 改分舱能调整可用空间分配，不能凭空补足不足的总容积。','- 15%为本课程选机方法给定值；修正排水量后仍需复核功率。','- 载况中的永久压载与水压载分开；前者已计入空船。','- 横剖面积曲线用于水下船体的体积与浮心，容积曲线还需要舱室内部边界。','- 新增题没有“看动画”按钮；现有题的动画入口继续可用。','',f"内容检查：{sum(c['pass'] for c in checks)}/{len(checks)}通过。实际窗口检查见 qa/exam13/ui-results.json。"]
(ROOT/'docs/13a题目与答案.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
lines=['# 新题目复习：66题答案','', '12p共37题、13a新增29题，13a-30与12p-3共用一题；6组无题干识图项不作问答。','']
for c in courses:
    lines+=['## '+c['title']['zh'],'']
    for q in read(OUT/'reading.json'):
        if q['topic']==c['id'] and q.get('kind')!='figure':lines+=['### '+' / '.join(q['sources']),'',q['question_ru'],'',q['translation'],'',q['answer']['ru'],'',q['answer']['zh'],'']
(ROOT/'docs/新题目答案汇总.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(json.dumps({'pass':report['pass'],'checks':len(checks),'missing_stress':sorted(missing_stress),'missing_meaning':sorted(missing),'failed':[c for c in checks if not c['pass']]},ensure_ascii=False))
raise SystemExit(0 if report['pass'] else 1)
