"""Audit rewritten answers and protect source questions, progress and release."""
import hashlib,json,re
from pathlib import Path
from apply_reasoned_answers import ROOT,C,read,write,answers,apply
QA=ROOT/'qa/answer-rewrite-20261027'
checks=[]
def check(ok,label):checks.append({'check':label,'pass':bool(ok)})
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
protected=read(QA/'protected-before.json');canonical=answers();all_entries=[]
for bank,expected in [(C,62),(C/'exam12',43)]:
    rows=read(bank/'reading.json');courses=read(bank/'topics.json');all_entries+=rows
    check(len(rows)==expected,'题库数量 '+str(bank.name))
    for r in rows:
        check({k:v for k,v in r.items() if k not in ['answer','condition','answer_version']}==protected['question'][r['id']],'原题/翻译/来源/计算示例未改 '+r['id'])
        if r['id'] not in canonical:continue
        check(r['answer']==canonical[r['id']],'双语答案使用统一编辑稿 '+r['id'])
        check(len(re.split(r'(?<=[.!?])\s+',r['answer']['ru']))>=2,'有结论和解释 '+r['id'])
    before=json.dumps([rows,courses],ensure_ascii=False,sort_keys=True)
    apply(rows,courses)
    check(before==json.dumps([rows,courses],ensure_ascii=False,sort_keys=True),'再次生成答案不重复追加、不改变步骤 '+bank.name)
    for c in courses:
        for g in c['groups']:
            if g['id'] not in canonical:continue
            for b in g['beats']:
                if b['id'].endswith(':answer'):
                    a=canonical[g['id']]
                    check(a['ru'].startswith(b['words']['ru']) and a['zh'].startswith(b['words']['zh']),'动画结论与完整回答相符 '+g['id'])
check({r['id'] for r in all_entries if r.get('kind')!='figure'}==set(canonical),'全部99题，无遗漏或把无题干图片当问答')
missing=[]
for qid,a in canonical.items():
    for w in re.findall('[А-Яа-яЁё\u0301]+',a['ru']):
        if len(re.findall('[аеёиоуыэюя]',w.lower()))>1 and '\u0301' not in w and 'ё' not in w.lower() and w not in ['СЭУ','КПД']:missing.append((qid,w))
check(not missing,'99个俄语回答多音节词重音覆盖')
check(not read(ROOT/'qa/reasoned-lexical-results.json')['missing'],'新增问答词形有原形与中文释义')
gloss=read(C/'reasoned_glossary.json');excluded={'еще','какой','быть','например','сначала','меньше','можно','больше','мочь','нужно'}
check(all(not e.get('study',True) for e in gloss if e['ru'].replace('\u0301','').replace('ё','е') in excluded),'既有基础词排除继续有效')
for k in ['user','exe']:
    for path,digest in protected[k].items():check(Path(path).exists() and sha(path)==digest,('用户进度不变 ' if k=='user' else '现有EXE不变 ')+Path(path).name)
result={'pass':all(c['pass'] for c in checks),'checks':checks,'missing_stress':missing}
write(QA/'results.json',result)
lines=['# 全部题目：有理由的中俄回答','', '本轮重写旧题库62题、新题库37题，共99题。6组无题干图片仍只作识图辅助。题号、原题、题意翻译、计算示例及进度ID保持原样。','',
'回答是依照教师讲义整理的解释，不标为教师提供的标准答案。先给结论，再说明依据；必要时直接写清适用条件。讲解中的结论句同步，完整理由放在题卡中，避免把长段文字塞进船模对话框。','']
for bank,label in [(C,'原题目复习'),(C/'exam12','新题目复习 · 12p')]:
    rows={r['id']:r for r in read(bank/'reading.json')};lines+=['## '+label,'']
    for course in read(bank/'topics.json'):
        lines+=['### '+course['title']['zh'],'']
        for qid in course['questions']:
            if qid not in canonical:continue
            r=rows[qid];lines+=['#### '+' / '.join(r['sources'])+' · '+qid,'',r['question_ru'],'',r['translation'],'','**回答**', '',r['answer']['ru'],'',r['answer']['zh'],'']
            source=r.get('source',{})
            if isinstance(source,dict):source=source.get('module',source.get('question',''))
            if source:lines+=['核对资料：'+str(source),'']
lines+=['## 重要边界与核对依据','',
'- 母型与设计：Modul_1 的任务、设计阶段及母型方法部分。母型提供经过验证的数据和方案，但仍须协调不同要求、修改和校核；不能仅答“要求不同”。',
'- 载荷：Modul_2 的质量分类、质量矩与系数。区别实际可变载荷和船舶标称能力；分别说明纵向矩与竖向矩。',
'- 舱容：Modul_5 区别理论、实际和不同货物的计容口径；不能将货物积载因数与船提供的单位舱容混淆。',
'- 稳性：Modul_6、9 区别初稳性与大倾角稳性；横摇比较注明惯性条件；h/B的评价结合船型和载况。',
'- 事故：Modul_7、10 分别核对浮性与稳性。Modul_10 原段落30指出距船端约四分之一船长处的舱室同时带来下沉与纵倾，段落37说明宽舱损失水线面惯性矩的影响。',
'- 船型、阻力、布置：Modul_8、11、12。对球鼻艏、艏尖舱、加宽等绝对表述给出适用条件。生活区回答区分讲义中的功能/卫生约束与对其作用的解释，不补造规范条款。',
'- 草图设计题维持该题选择“草图设计”的口径，同时保留讲义中技术设计仍须校核的事实；资料缺少正式选择题答案键，不宣称只在一个阶段检查稳性。',
'- 7a艏水线题与讲义的低速/较高速适用对象矛盾仍在答案中显式说明。9p弗劳德数分档保留定义基准条件。油船推进系数题为有条件的船体/推进器匹配解释，不视作所有油船必然高于所有干货船。',
'- 计算4：原题及已核对模块未明确就餐人数比例，保留座位数条件，不自行选全员或半员。',
'- 重音补充核查：[Грамота：пониженный](https://gramota.ru/meta/ponizhennyy)，采用 пони́женную。','',
'## 自动核验','',f"- 通过：{sum(c['pass'] for c in checks)}/{len(checks)}。",'- 检查题目和示例保持、99题覆盖、动画结论一致、重音和新增词形、重复执行、真实用户记录及现有EXE。', '- 实际窗口交互与截图另见 qa/exam12-results.json 和 qa/exam12-reasoned-prototype-minimum.png。']
(ROOT/'docs/全部题目答案重写与依据.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(json.dumps({'pass':result['pass'],'checks':len(checks),'failed':[c for c in checks if not c['pass']]},ensure_ascii=False))
raise SystemExit(0 if result['pass'] else 1)
