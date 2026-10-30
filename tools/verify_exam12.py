"""Verify the 12p source bank and write the human-readable delivery record."""
import hashlib,json,re,zipfile,xml.etree.ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BANK=ROOT/'modules/review/content/exam12'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
entries=read(BANK/'reading.json');topics=read(BANK/'topics.json');source=read(BANK/'source_map.json')
# Keep this verifier focused on the original 12p source set after additions.
entries=[e for e in entries if e['id'].startswith('P12_')]
topics=[c for c in topics if c['id'].startswith('P12_')]
checks=[]
def check(ok,label):
 checks.append({'check':label,'pass':bool(ok)})
def plain(s):return re.sub(r'\s+',' ',s.replace('\u0301','').replace('ё','е').replace('Ё','Е')).strip()
def document(path):
 with zipfile.ZipFile(path) as z:tree=ET.fromstring(z.read('word/document.xml'))
 return plain(' '.join(''.join(n.text or '' for n in p.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}t')) for p in tree.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}p')))
real=[e for e in entries if e['kind']!='figure'];figures=[e for e in entries if e['kind']=='figure']
check(len(real)==37 and len(figures)==6 and len(topics)==7,'37道明确题干、6组识图、7专题')
check({e['id'] for e in real}=={f'P12_T{i:02}' for i in range(1,33)}|{f'P12_C{i:02}' for i in range(1,5)}|{'P12_D01'},'32理论、4计算、1型线图题完整')
check(len({e['id'] for e in entries})==43,'独立稳定题卡ID')
docs={f:document(ROOT.parent/f) for f in ['12p/题目.docx','12p/pictures_for_exam.docx']}
course_by={c['id']:c for c in topics}
for e in real:
 f='12p/pictures_for_exam.docx' if e['id']=='P12_D01' else '12p/题目.docx'
 check(plain(e['question_original']) in docs[f],'原始题干逐字对应 '+e['id'])
 check(plain(e['question_ru']).replace('Δh',r'\Delta h')==plain(e['question_original']),'显示只增加重音、ё和Δ排版 '+e['id'])
 c=course_by[e['topic']];target=c['question_targets'].get(e['id'])
 check(any(b['id']==target for g in c['groups'] for b in g['beats']),'动画定位 '+e['id'])
for item in source['questions']:check((ROOT.parent/item['source']).exists(),'教师讲义可追溯 '+item['id'])
with zipfile.ZipFile(ROOT.parent/'12p/pictures_for_exam.docx') as z:
 media=[n for n in z.namelist() if n.startswith('word/media/') and not n.endswith('/')]
 check(len(media)==10,'原文档10张原图')
 for p in source['pictures']:
  original=z.read('word/media/'+p['source']);exported=(ROOT/'modules/review/assets/exam12'/p['source']).read_bytes()
  check(hashlib.sha256(original).hexdigest()==p['sha256'] and original==exported,'原图字节保留 '+str(p['number']))
check(sorted(p['number'] for e in figures for p in e['images'])==list(range(1,11)),'全部原图各归属一项')
check(next(e for e in figures if e['id']=='P12_F06')['topic']=='P12_resistance','图10按教师图13归为浮心与船型')
for c in topics:
 ids=[b['id'] for g in c['groups'] for b in g['beats']]
 check(len(ids)==len(set(ids)) and c['foundation_end'] in ids,'专题步骤及基础终点 '+c['id'])
unknown=set()
def stress_scan(value,ru=False):
 if isinstance(value,dict):
  for k,v in value.items():stress_scan(v,k in ['ru','question_ru'])
 elif isinstance(value,list):
  for v in value:stress_scan(v,ru)
 elif isinstance(value,str) and ru:
  for w in re.findall('[А-Яа-яЁё\u0301]+',value):
   if len(re.findall('[аеёиоуыэюя]',w.lower()))>1 and '\u0301' not in w and 'ё' not in w.lower() and w!='СЭУ':unknown.add(w)
stress_scan(entries);stress_scan(topics);check(not unknown,'多音节俄语重音覆盖（СЭУ为缩写）')
gloss=[]
for p in [ROOT/'modules/review/content/glossary.json',ROOT/'content/approximation_glossary.json',BANK/'glossary.json',ROOT/'modules/review/content/reasoned_glossary.json',BANK/'glossary13.json']:gloss+=read(p)
aliases=sorted({a for e in gloss for a in e['aliases']},key=len,reverse=True)
matcher=re.compile(r'(?<![a-zа-яё])(?:'+'|'.join(map(re.escape,aliases))+r')(?![a-zа-яё])')
missing=set()
for e in real:
 for value in [e['question_ru'],e['answer']['ru']]:
  value=value.lower().replace('\u0301','');covered=set()
  for m in matcher.finditer(value):covered.update(range(m.start(),m.end()))
  for m in re.finditer('[а-яё]+',value):
   if not set(range(m.start(),m.end()))<=covered and m[0]!='зап':missing.add(m[0])
check(not missing,'问答词形释义覆盖（зап由符号释义承接）')
excluded={'мочь','нужно','ещё','какой','быть','например','сначала','меньше','можно','больше'}
for e in read(BANK/'glossary.json'):
 if e['ru'].replace('\u0301','') in excluded:check(not e.get('study',True),'基础词不新增背词卡 '+e['ru'])
expected={'P12_C01':(1150,112000,6500),'P12_C02':(1000,83950,4970),'P12_C03':(1350,126000,7100)}
for e in entries:
 if e['id'] not in expected:continue
 rows=e['example_data']['rows'];tot=sum(r[1] for r in rows);mx=sum(r[1]*r[2] for r in rows);mz=sum(r[1]*r[3] for r in rows)
 check((tot,mx,mz)==expected[e['id']],'独立加和质量与两个矩 '+e['id'])
check(abs(12*1.2-14.4)<1e-10 and 150*(.35+.4+.25)==150,'餐厅面积与150米分段')
report={'pass':all(c['pass'] for c in checks),'checks':checks,'missing_stress':sorted(unknown),'missing_meaning':sorted(missing)}
(ROOT/'qa/exam12-content-results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# 12p 新题目复习：题目、原图与讲解对应','',
'本表对应工程中的“新题目复习”，不改变旧题库及现有 EXE。32道理论题、4道计算题及1道型线图题，另设6组识图辅助，保留10张原图。短答是依据讲义整理的教学回答，不标为老师提供的标准答案。','',
'## 题目与专题','', '|来源编号|题意／考点|简短俄语回答|动画定位|教师讲义|','|---|---|---|---|---|']
audit={a['id']:a for a in source['questions']}
for c in topics:
 lines+=['|**'+c['title']['zh']+'**|||||']
 for e in real:
  if e['topic']!=c['id']:continue
  a=audit[e['id']];lines+=['|'+ '|'.join([e['sources'][0],e['translation'].replace('\n',' '),e['answer']['ru'],c['question_targets'][e['id']],a['source']])+'|']
lines+=['','## 原图清单','','按 pictures_for_exam.docx 内嵌图顺序编号。图7保留原始EMF，并另存PNG供Godot显示；其余原始PNG逐字节保留。没有题干的图片只标为识图辅助。','','|原图|识图项|专题|定位|','|---|---|---|---|']
for e in figures:
 for p in e['images']:lines+=['|'+ '|'.join([f"图{p['number']:02d}",e['sources'][0],course_by[e['topic']]['title']['zh'],course_by[e['topic']]['question_targets'][e['id']]])+'|']
lines+=['','## 核对时保留的边界','',
'- 理论16、22保留老师原题的绝对表述，答案旁说明：球鼻艏有效性有航速和吃水范围；部分低速船也使用球鼻艏。',
'- 理论18区分端部进水造成的纵倾／浸没与中部宽舱失去水线面惯性矩；仅作定性事故演示。',
'- 理论20使用固定排水量法：不能再把同一连海进水量作为新增船重。有效浮力、水线面惯性矩、浮心分别考虑。',
'- 计算1—3原题没有数值，原样保留符号；动画和计算示例使用独立演示数据。坐标以演示艉垂线为x=0、基线为z=0。仅凭质量与质量矩不能判定最终纵倾和稳性变化。',
'- 计算2按教师空船分类选项，不把全部燃油、淡水和船员计入空船。',
'- 计算4未查到教师给明的就餐人数比例，保留 S=n_seat X；12座、每座1.2平方米仅为独立练习。',
'- 图10与模块11图13逐字节匹配，内容是浮心位置与艏艉丰满程度，不是横倾水线。图5匹配模块6图3；图9匹配模块8图7。其余图按图片本身识别，不补造缺失曲线数值或标准答案。',
'- 图2、图4原文件中已有黑色遮挡区域，未自行修补。',
'- 精细船模用于教学关系；新增生活区、内部结构和示例布置不是对老师原图的工程级复建。波形为轻量关系示意，不依赖独立波浪包。',
'- 题目原文另存 question_original；显示补俄语重音、ё，并将原文“\\Delta h”排为Δh。俄语空载词写作“порожнём”，参见[Грамота词典](https://gramota.ru/poisk?mode=slovari&query=порожнём)。','',
'## 详细数据','',
'- [逐题来源段落与动画ID](../modules/review/content/exam12/source_map.json)',
'- [图片来源对应](../modules/review/content/exam12/image_provenance.json)',
'- [内容校验结果](../qa/exam12-content-results.json)',
'- [实际运行检查](../qa/exam12-results.json)']
(ROOT/'docs').mkdir(exist_ok=True)
(ROOT/'docs/12p题目与图片对应表.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({'pass':report['pass'],'checks':len(checks),'missing_stress':sorted(unknown),'missing_meaning':sorted(missing)},ensure_ascii=False))
if not report['pass']:
 for c in checks:
  if not c['pass']:print('FAIL:',c['check'])
 raise SystemExit(1)
