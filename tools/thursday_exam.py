"""Add the 2026-10-29 paper as a reading-only topic; retain verbatim originals."""
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as E
import json,copy
ROOT=Path(__file__).resolve().parents[1];B=ROOT/'modules/review/content/exam12'
MATCHES=[27,8,4,16,10,28,6,14,17,24]
QUESTIONS=[
('Почему расчёт нового судна начинают с составления и решения уравнения масс?','为什么新船计算从建立并求解质量方程开始？'),
('В чём смысл коэффициента Нормана и почему он больше единицы?','诺曼系数表示什么，为什么大于1？'),
('Почему при выборе x_c учитывают тип судна — тихоходное или быстроходное?','选择纵向浮心坐标x_c时，为什么要区分低速船和高速船？'),
('Для чего разработку общего расположения начинают на ранних стадиях?','为什么总布置要在设计早期就开始？'),
('Почему при проектировании рассчитывают несколько вариантов нагрузки (полный груз 100%, 10% запасов, порожнём с балластом)?','为什么设计时要计算满载、10%储备、空船加压载等多个载况？'),
('Для чего строят эпюру ёмкости, если есть теоретический чертёж?','已经有型线图，为什么还要绘制容积曲线？'),
('Почему при несовпадении объёмов сначала перераспределяют объёмы между отсеками?','舱室容积不匹配时，为什么先在各舱之间重新分配容积？'),
('В чём принципиальная разница между измерителями масс и уравнениями через размерения?','质量估算系数法与通过主尺度建立质量公式，原则上有什么区别？'),
('Почему при проверке начальной остойчивости в курсовом проекте недостаточно знать только положение центра масс z_g, а нужно учитывать ещё и форму подводной части корпуса?','课程设计检查初稳性时，为什么只知道重心高度z_g不够，还要考虑水下船体形状？'),
('Почему увеличения надводного борта недостаточно для обеспечения непотопляемости?','为什么只增加干舷，还不足以保证不沉性？')]

def append(entries,courses,audit=None):
 from exam13 import stress
 from focused_new_answers import get_answers
 with ZipFile(ROOT.parent/'23级考试真题/选择题.docx') as z:doc=E.fromstring(z.read('word/document.xml'))
 originals=[''.join(n.text or '' for n in p.iter() if n.tag.rsplit('}',1)[-1]=='t').strip() for p in doc.iter() if p.tag.rsplit('}',1)[-1]=='p']
 originals=[x for x in originals if x];assert len(originals)==10
 entries[:]=[q for q in entries if not q['id'].startswith('THU')];courses[:]=[c for c in courses if c['id']!='THU_20261029']
 topic={'id':'THU_20261029','title':{'zh':'周四真题','ru':stress('Экзамен в четверг')},'goal':{'zh':'复习10月29日选择题对应的知识。','ru':stress('Вопросы экзамена.')},'questions':[],'groups':[],'question_targets':{},'animation_available':False}
 courses.insert(0,topic)
 if audit is not None:audit[:]=[q for q in audit if not q['id'].startswith('THU')]
 answers=get_answers()
 for i,((question,zh),original,n) in enumerate(zip(QUESTIONS,originals,MATCHES),1):
  qid=f'THU{i:02}';old=f'P13_Q{n:02}';a=copy.deepcopy(answers[old])
  if i==2:a={'ru':'Коэффициент Нормана показывает отношение полного изменения водоизмещения к прямому изменению массы. При перепроектировании добавленная масса вызывает увеличение массы корпуса, установки и запасов, поэтому полное изменение больше прямого.','zh':'诺曼系数表示排水量总变化与直接质量变化的比值。重新设计时，直接增加的质量还会引起船体、动力装置和储备的连带增重，所以总变化大于直接变化。'}
  if i==3:a={'ru':'Продольное положение центра величины определяет распределение объёма между носом и кормой и влияет на сопротивление. У тихоходных судов центр величины обычно смещают к носу от миделя, а у быстроходных — к корме, чтобы заострить нос и уменьшить волновое сопротивление.','zh':'纵向浮心位置决定艏艉体积分配，并影响阻力。低速船通常使浮心偏向舯前；高速船通常偏向舯后，以使艏部更尖削、减小兴波阻力。'}
  if i==9:a={'ru':'Начальная остойчивость определяется высотой центра масс относительно метацентра. Положение метацентра зависит от подводной формы и ватерлинии, поэтому при одной высоте центра масс разные корпуса могут иметь разную остойчивость.','zh':'初稳性取决于重心相对横稳心的高度。横稳心的位置取决于水下船型和水线面，因此重心高度相同，船体不同，初稳性仍可能不同。'}
  a={'ru':stress(a['ru']),'zh':a['zh']}
  q={'id':qid,'kind':'theory','sources':[f'周四-{i}'],'question_original':original,'question_ru':stress(question),'translation':zh,'answer':a,'topic':topic['id'],'animation_available':False,'source':'23级考试真题/选择题.docx','source_aliases':[{'label':f'周四-{i}','original':original}],'related_question':old,'editorial_note':'原稿有拼写错误；显示俄文纠正拼写，保留原稿。','answer_sources':['7a/Modul_11. ТЧ.docx'] if i==3 else []}
  entries.append(q);topic['questions'].append(qid)
  if audit is not None:audit.append({'id':qid,'source':q['source'],'original':original,'display_question':q['question_ru'],'answer':a,'related_question':old,'animation':None})
 return entries,courses

def build():
 read=lambda p:json.loads(p.read_text(encoding='utf8'))
 e,c,s=[read(B/n) for n in ['reading.json','topics.json','source_map.json']]
 original_entries=[q for q in e if not q['id'].startswith('THU')]
 original_courses=[t for t in c if t['id']!='THU_20261029']
 s['questions']=[q for q in s['questions'] if not q['id'].startswith('THU')];s['teacher_question_count']=66;s['source_question_count']=67;s['question_files'].pop('23级考试真题/选择题.docx',None)
 target=B.parent/'exams';target.mkdir(exist_ok=True)
 new=[];topics=[];audit=[];append(new,topics,audit)
 def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
 for n,v in [('reading.json',original_entries),('topics.json',original_courses),('source_map.json',s),('question_bank.json',[{'id':q['id'],**({'legacy_ids':q['legacy_ids']} if q.get('legacy_ids') else {})} for q in original_entries])]:write(B/n,v)
 for n,v in [('reading.json',new),('topics.json',topics),('source_map.json',{'questions':audit,'teacher_question_count':10}),('question_bank.json',[{'id':q['id']} for q in new])]:write(target/n,v)
 print('Separate banks: 66 preparation questions; 10 Thursday exam questions.')
if __name__=='__main__':build()
