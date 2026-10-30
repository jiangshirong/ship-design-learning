"""Author the representative Q14 lesson; the 25-question manuscript stays separate."""
import json,re,hashlib,zipfile,xml.etree.ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def write(name,data):
    p=ROOT/name;p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
def pair(zh,ru): return dict(zh=zh,ru=ru)
beats=[];formulas={}
def add(id,zh,ru,phase,rows=(),load=None,duration=2.0,label=None):
    beat=dict(id='Q14:'+id,text=zh,words=pair(zh,ru),phase=phase,lines=list(rows))
    if load is not None:beat['action']=dict(params=dict(loaded=load),duration=duration)
    if label:beat['record_label']=pair(*label)
    formulas[beat['id']]={lang:[dict(tex=t,linear=l) for t,l in rows] for lang in ['zh','ru']}
    beats.append(beat)
add('example','例如：舱容32立方米，最多装16吨；每吨货占1立方米。','Приме́р: трюм — 32 кубоме́тра, преде́л — 16 тонн. То́нна гру́за занима́ет оди́н кубоме́тр.','load',load=16,duration=5)
add('reason','16吨货只占16立方米。质量已到上限，舱里仍有空位。','Уже́ 16 тонн, но за́нято то́лько 16 кубоме́тров. Ме́сто ещё есть.','limit')
lesson=dict(id='Q14',title=pair('14 · 货舱能装满吗？','14 · Мо́жно ли запо́лнить трюм?'),
    summary={'params':{'loaded':16,'height':2},'phase':'limit'},
    initial=dict(loaded=0),characters_per_second=25,busy_policy='finish',
    groups=[dict(id='Q14',title=pair('质量与舱容','Ма́сса и объём'),beats=beats)],
    question=pair('货物每吨占的空间，比船每吨允许载货量对应的舱容小。能把货舱装满吗？','Мо́жно ли запо́лнить трюм, е́сли уде́льная погру́зочная кубату́ра гру́за ме́ньше уде́льной грузовмести́мости су́дна?'),
    answer=pair('不能。先达到质量上限，舱里还会有空位。','Нет. Снача́ла дости́гнем преде́ла по ма́ссе. В трю́ме ещё оста́нется ме́сто.'),
    condition=pair('原题条件：μгр < μс','Усло́вие: μгр < μс'),
    question_speech='Мо́жно ли по́лностью запо́лнить грузовы́е помеще́ния су́дна, е́сли уде́льная погру́зочная кубату́ра гру́за ме́ньше уде́льной грузовмести́мости су́дна?',
    source={'question':'5p/Вопросы для подготовки по первой недели обучения.docx #14','module':'5p/Modul_5. Виды вместимости.docx §4.2',
    'example':'32 m³ capacity, 16 t cargo limit, 1 m³/t stowage factor are authored teaching values, not teacher-given numbers.',
    'geometry':'8 × 2 × 2 m net stowage envelope; each 1 m³ stowage cell contains a rigid pallet/crate unit. Structure outside envelope. No hydrostatic or weight-design inference.'})
write('content/sample.json',lesson);write('content/latex_source.json',formulas)
def short_beat(qid,id,zh,ru,phase,params=None,duration=3):
    result={'id':qid+':'+id,'text':zh,'words':pair(zh,ru),'phase':phase}
    if params:result['action']={'params':params,'duration':duration}
    return result

def course(qid,title,question,answer,initial,summary,beats,source):
    return dict(id=qid,title=pair(*title),question=pair(*question),answer=pair(*answer),
        question_speech=question[1],initial=initial,summary=summary,
        characters_per_second=25,busy_policy='finish',
        groups=[dict(id=qid,title=pair('看原因','Почему́?'),beats=beats)],source=source)

q02=course('Q02',('02 · 什么不会随装卸货改变？','02 · Что не меня́ется при погру́зке?'),
    ('排水量、载重量、货舱容积，哪一个在使用中不变？',
     'Каки́е из перечи́сленных ка́честв су́дна не мо́гут изменя́ться в проце́ссе эксплуата́ции: водоизмеще́ние, дедве́йт, грузовмести́мость?'),
    ('货舱容积不变。货物和储备的质量可以改变。',
     'Грузовмести́мость не меня́ется. Ма́сса гру́за и запа́сов мо́жет меня́ться.'),
    {'loaded':16,'height':2},{'params':{'loaded':8,'height':2},'phase':'capacity'},[
      short_beat('Q02','unload','卸下货物，船上货物的质量减少。','Выгружа́ем груз. Его́ ма́сса уменьша́ется.','unload',{'loaded':8},4),
      short_beat('Q02','capacity','舱壁没有移动，货舱容积仍为32立方米。','Сте́нки трю́ма не сдви́нулись. Его́ объём — всё те же 32 кубоме́тра.','capacity'),
      short_beat('Q02','deadweight','本课的DW指实际载荷，不是额定最大载重量。','Здесь DW — ма́сса гру́за и запа́сов на борту́, а не допусти́мый ма́ксимум.','capacity'),
    ],{'question':'5p/Вопросы для подготовки по первой недели обучения.docx #2',
        'module':['1p/Modul_1.docx §1.1','1p/Modul_2.docx §2.1'],
        'boundary':'Unmodified hull and hold. Course DW means current variable load; rated maximum deadweight does not change with unloading.',
        'example':'32 m³ hold and unloading 16 t to 8 t are authored examples.'})

q11=course('Q11',('11 · 排水体积不变，怎样扩舱？','11 · Как увели́чить вмести́мость при том же V?'),
    ('排水体积V不变，改变哪个主尺度能增加货舱容积？',
     'Каки́е гла́вные размере́ния су́дна ну́жно измени́ть, что́бы увели́чить грузовмести́мость при постоя́нном V?'),
    ('增大型深，让货物有更多空间。','Ну́жно увели́чить высоту́ бо́рта. Так бу́дет бо́льше ме́ста для гру́за.'),
    {'loaded':0,'height':2},{'params':{'loaded':0,'height':3},'phase':'depth_done'},[
      short_beat('Q11','underwater','固定水线以下的船体，排水体积V不变。','Подво́дная часть не меня́ется. Объём V остаётся пре́жним.','underwater'),
      short_beat('Q11','raise','抬高甲板，型深H增大，水线上方空间增加。','Поднима́ем па́лубу. Высота́ бо́рта H растёт. Для гру́за ста́нет бо́льше ме́ста.','raise',{'height':3},2.8),
    ],{'question':'5p/Вопросы для подготовки по первой недели обучения.docx #11',
        'module':'5p/Modul_5. Виды вместимости.docx §4.1, §4.5',
        'boundary':'Geometric design comparison: L, B, T and underwater form fixed. Not an equilibrium simulation after adding structural weight.',
        'geometry':'Cutaway prismatic hull segment; baseline at y=-0.18, fixed waterline at y=1, deck rises from y=2 to y=3. H is baseline to deck. No claim of full-ship hydrostatics.'})

q15=course('Q15',('15 · 设计的货舱不够大，怎么办？','15 · В прое́кте не хвата́ет ме́ста для гру́за'),
    ('设计的单位货舱容积小于要求，应怎样修改？',
     'При проекти́ровании су́дна факти́ческая уде́льная грузовмести́мость оказа́лась ме́ньше, чем тре́буется. Каки́е измене́ния в прое́кт су́дна сле́дует внести́, что́бы испра́вить оши́бку?'),
    ('增加货舱容积，例如增大型深。','Ну́жно увели́чить объём грузовы́х помеще́ний. Наприме́р, увели́чить высоту́ бо́рта.'),
    {'loaded':32,'height':2},{'params':{'loaded':48,'height':3},'phase':'space_done'},[
      short_beat('Q15','shortage','例如要装48吨；舱已满，却只装进32吨。','Ну́жно погрузи́ть 48 тонн. Трюм уже́ по́лон, а гру́за то́лько 32 то́нны.','shortage'),
      short_beat('Q15','raise','载货任务不变，抬高甲板，增加舱容。','Ма́ссу ну́жного гру́за не меня́ем. Поднима́ем па́лубу и увеличи́ваем трюм.','raise',{'height':3},2.8),
      short_beat('Q15','load','舱容增至48立方米，剩下的货也能装下。','Тепе́рь в трю́ме 48 кубоме́тров. Оста́вшийся груз то́же поме́стится.','space_load',{'loaded':48},4),
    ],{'question':'5p/Вопросы для подготовки по первой недели обучения.docx #15',
        'module':'5p/Modul_5. Виды вместимости.docx §4.2, §4.5',
        'example':'Required 48 t of cargo at 1 m³/t. Initial hold 32 m³, enlarged to 48 m³. Authored geometry example; ship weight and stability require separate design checks.',
        'boundary':'Increase capacity while retaining the cargo task; do not claim that reducing the cargo completes the specified task.'})
q01=course('Q01',('01 · 谁提出设计要求？','01 · Кто задаёт тре́бования?'),
    ('未来船舶的使用要求由谁提出：订船方还是设计方？','Кто задаёт эксплуатацио́нные ка́чества бу́дущего су́дна: зака́зчик и́ли проекта́нт?'),
    ('订船方提出要求，设计方据此设计船舶。','Тре́бования задаёт зака́зчик. Проекта́нт по ним проекти́рует су́дно.'),
    {'progress':0},{'params':{'progress':1},'phase':'handoff'},[
      short_beat('Q01','task','订船方先说明：运什么、运多少、跑多快。','Зака́зчик задаёт груз, его́ ма́ссу и ско́рость.','requirements'),
      short_beat('Q01','design','设计方选择尺寸和设备，实现这些要求。','Проекта́нт выбира́ет разме́ры и обору́дование.','handoff',{'progress':1},2.5),
    ],{'question':'5p/Вопросы для подготовки по первой недели обучения.docx #1','module':'1p/Modul_1.docx §1.1–1.2','boundary':'Customer specifies operational requirements; designer participates in justification and selects technical solutions.'})
q04=course('Q04',('04 · 竣工资料有什么用？','04 · Заче́м отчётная документа́ция?'),
    ('已建成船舶的竣工资料有什么用？','Для чего́ нужна́ отчётная документа́ция о постро́енном су́дне?'),
    ('它记录船舶实际建成的样子。','Она́ пока́зывает, как су́дно постро́ено на са́мом де́ле.'),
    {'progress':0},{'params':{'progress':1},'phase':'record'},[
      short_beat('Q04','plan','设计图表示原计划；施工时可能调整。','Прое́кт — э́то план. При постро́йке возмо́жны измене́ния.','plan'),
      short_beat('Q04','record','例如舱壁移了位置，竣工资料就要记录实际位置。','Перегоро́дку сдви́нули. В документа́ции пока́зывают её но́вое ме́сто.','record',{'progress':1},3),
    ],{'question':'5p/Вопросы для подготовки по первой недели обучения.docx #4','module':'1p/Modul_1.docx §1.2','example':'A schematic partition change illustrates as-built documentation; no real ship dimensions or construction authorization implied.'})
q05=course('Q05',('05 · 怎样选母型船？','05 · Как вы́брать прототи́п?'),
    ('载重量10 000吨的油船，适合作为1 000吨油船的母型吗？','Мо́жет ли быть прототи́пом для та́нкера с DW = 1 000 тонн та́нкер с DW = 10 000 тонн?'),
    ('这种估算最好选尺寸接近的油船，这里差别太大。','Для тако́го расчёта лу́чше взять та́нкер бли́зкого разме́ра. Здесь ра́зница сли́шком больша́я.'),
    {'progress':0},{'params':{'progress':1},'phase':'compare'},[
      short_beat('Q05','reference','母型船是已有的参考船，提供设计经验和数据。','Прототи́п — э́то уже́ постро́енное су́дно для сравне́ния.','reference'),
      short_beat('Q05','compare','载重量相差10倍，不能只因都是油船就照搬系数。','Дедве́йт отлича́ется в 10 раз. Нельзя́ про́сто копи́ровать коэффицие́нты.','compare',{'progress':1},3),
      short_beat('Q05','choose','估算用尺寸接近的母型；个别设备方案仍可参考。','Для расчёта берём бли́зкий разме́р. Отде́льные реше́ния мо́жно испо́льзовать.','compare'),
    ],{'question':'5p/Вопросы для подготовки по первой недели обучения.docx #5','module':'1p/Modul_1.docx §1.3','boundary':'Bars encode deadweight only, not ship length. Reject blind coefficient transfer, not all possible technical reference.'})
courses=[q01,q02,q04,q05,q11,lesson,q15]
write('content/lessons.json',courses)
write('qa/formula-values.json',{'loaded':32,'used':32})
write('content/notation_terms.json',{
    'W|гр.факт':'факти́ческая грузовмести́мость\n实际货舱容积', 'P|гр':'груз\n货物',
    '\\mu|гр':'груз\n货物', '\\mu|с':'су́дно\n船舶'})
print('Q14: question and answer visible first; two optional explanation beats.')
manuscript=ROOT.parents[2]/'第一周口试25题_知识点与中俄回答.md'
if manuscript.exists():
    contents=manuscript.read_text(encoding='utf-8')
    sections=re.findall(r'^## (\d\d) ([\s\S]*?)(?=^## |\Z)',contents,re.M)
    assert len(sections)==25
    original=ROOT.parents[2]/'5p/Вопросы для подготовки по первой недели обучения.docx'
    with zipfile.ZipFile(original) as archive: xml=ET.fromstring(archive.read('word/document.xml'))
    ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
    paragraphs=[''.join(t.text or '' for t in p.findall('.//w:t',ns)) for p in xml.findall('.//w:body/w:p',ns)]
    questions=[p.strip() for p in paragraphs if p.strip()][1:]
    assert len(questions)==25
    entries=[]
    for (number,section),original_text in zip(sections,questions):
        question=re.search(r'\*\*老师原题：\*\* (.+)',section)[1]
        assert question==original_text
        answer=re.search(r'^> (.+)',section,re.M)[1]
        assert '**听题词：**' in section and '**要懂：**' in section and '\u0301' in answer
        entries.append({'id':int(number),'question_original':question,'answer_ru':answer,'study_section':section})
    write('content/oral_questions.json',entries)
    for item in courses:
        item['question_original']=questions[int(item['id'][1:])-1]
    write('content/lessons.json',courses)
    write('qa/content-checks.json',{'questions':25,'answers':25,'matches_original_questions':True,'max_answer_words':max(len(e['answer_ru'].split()) for e in entries),'animated_questions':[int(c['id'][1:]) for c in courses],'manuscript_sha256':hashlib.sha256(manuscript.read_bytes()).hexdigest()})
    print('25 questions match the original DOCX, with listening cues and short accented answers.')
    from build_question_bank import build
    build(courses,questions,entries)
    from complete_courses import complete
    complete(courses,json.loads((ROOT/'content/question_bank.json').read_text(encoding='utf-8')))
    import add_complete_vocabulary
    from build_reading import build as build_reading
    build_reading()
