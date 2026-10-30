"""Editorial and dependency-aware scene details for the 12p bank."""
import copy,re,json,zipfile,xml.etree.ElementTree as ET

def enhance(entries,courses,formula,audit,pictures,stress,pair,beat,tex,root):
 by={e['id']:e for e in entries};cs={c['id']:c for c in courses}
 # Full conditions in the Chinese question, without leaking the answer.
 translations={
  'P12_T01':'为什么判断船舶浮态和稳性时，仅知道排水量D还不够？',
  'P12_T03':'为什么根据容积曲线可以求舱室容积和纵向坐标x_c，却不能求竖向坐标z_c？',
  'P12_T07':'为什么高速船不宜采用过于丰满的船体，即使它能提供更多装货空间？',
  'P12_T15':'为新船选择质量系数（例如船体或动力装置质量系数）时，为什么要使用接近母型的数据，而不是所有船舶的平均值？',
  'P12_T16':'为什么题目说球鼻艏只在设计航速和设计吃水下有效？',
  'P12_T20':'用固定排水量法计算事故稳性时，为什么横向初稳性高的变化Δh与有效水线面面积减小有关，而不是与船舶质量改变有关？',
  'P12_T22':'为什么高速船采用球鼻艏，而低速船不采用？',
  'P12_T24':'对于货物积载因数较大的船，为什么增加型深比增加船长或船宽更有利？',
  'P12_T25':'选择主尺度时，为什么不仅要考虑快速性，还要考虑稳性和货舱容积？',
  'P12_T26':'为什么增加船宽会改善初稳性，却使快速性变差？',
  'P12_T32':'为什么干舷较大的船不一定需要增加上层建筑高度？'}
 for k,v in translations.items():by[k]['translation']=v
 # Teacher's distinction is between end-compartment immersion and broad midship waterplane loss.
 by['P12_T18']['answer']=pair('端部进水易产生大纵倾；中部进水易损失较大的水线面惯性矩。',stress('В оконечностях опасен дифферент; в середине — потеря момента инерции ватерлинии.'))
 by['P12_T11']['answer']=pair('因为结构、死水残余和必要的未装满空间占用容积。',stress('Из-за конструкций, остатков и недолива.'))
 by['P12_T23']['answer']['ru']=stress('Оно влияет на дифферент и продольную прочность.')
 by['P12_T21']['answer']=pair('较长的艏楼能保护更多甲板区域。',stress('Более длинный бак защищает большую часть палубы.'))
 for e in entries:e['question_ru']=e['question_ru'].replace(r'\Delta h','Δh')
 by['P12_T20']['answer']=pair('质量不变；进水舱不再提供原有浮力和有效水线面惯性矩。',stress('Масса постоянна; затопленный отсек теряет плавучесть и момент инерции ватерлинии.'))
 cond={
 'P12_T01':'Для дифферента и остойчивости нужны данные о плавучести.',
 'P12_T08':'Малые углы; одинаковые начальная амплитуда и радиус инерции.',
 'P12_T16':'Эффект возможен в диапазоне скоростей и осадок, не только в одной точке.',
 'P12_T18':'Это качественное сравнение; аварийный угол не рассчитывается.',
 'P12_T20':'Воду в открытом отсеке нельзя одновременно добавлять к массе судна.',
 'P12_T21':'Также влияют высота носа, скорость и волнение.',
 'P12_T22':'У некоторых тихоходных судов тоже есть бульб.',
 'P12_T24':'Подводные размеры постоянны; нужны другие проверки.',
 'P12_T26':'Результат зависит от скорости, водоизмещения и формы.',
 'P12_T27':'Нужна проверка больших углов и открытых отверстий.'}
 for id,ru in cond.items():
  if 'condition' in by[id]:by[id]['condition']['ru']=stress(ru)
 # Common foundations are topic-specific, not seven copies of a generic introduction.
 foundations={
 'design':('先把任务要求与母型已有数据分开。','Сначала отделим требования от данных прототипа.','prototype'),
 'loads':('演示坐标：x从艉垂线量起，z从基线量起。','В примере: x от кормового перпендикуляра, z от основной плоскости.','load'),
 'volume':('同一个船体，在图纸上有三个投影。','Один корпус имеет три проекции.','lines'),
 'resistance':('船体排开水，形状和航速共同影响阻力。','Форма и скорость влияют на сопротивление.','resistance'),
 'stability':('G受重力，C受浮力；两条竖直作用线之间形成力臂。','Вес действует через G, сила плавучести — через C.','stability'),
 'reserve':('先找到水线，再区分水上封闭空间与水下部分。','Найдём ватерлинию и закрытый объём выше неё.','reserve'),
 'arrangement':('舱室有用途，通道把它们联系起来。','Помещения связаны проходами.','rooms')}
 for key,(zh,ru,concept) in foundations.items():
  c=cs['P12_'+key];b=c['groups'][0]['beats'][1];b['text']=zh;b['words']=pair(zh,stress(ru));b['start_params']={'concept':concept,'heel':0.,'roof':0.}
  b['action']={'params':{'progress':1.,'roof':1. if key=='arrangement' else 0.,'heel':6. if key=='stability' else 0.},'duration':3.}
  # The introductory target remains explicit; Russian is not a generic substitute.
  c['groups'][0]['beats'][0]['words']['ru']=stress({'design':'Поймём, как использовать прототип для нового проекта.','loads':'Найдём массу и две координаты центра масс.','volume':'Свяжем форму корпуса, чертёж и объём.','resistance':'Поймём влияние формы и скорости на сопротивление.','stability':'Поймём остойчивость, качку и повреждения.','reserve':'Найдём запас плавучести и защиту от воды.','arrangement':'Разместим помещения, оборудование и проходы.'}[key])
 # Keep theory stages readable and give distinct changes appropriate to each question.
 for c in courses:
  for g in c['groups'][1:]:
   id=g['id'];bs=g['beats'];e=by[id]
   if e['kind']=='theory':
    if bs[0]['start_params'].get('concept') in ['rooms','hygiene']:bs[0]['start_params']['roof']=1.
    if bs[0]['start_params'].get('concept') in ['load','longitudinal','tank','double','engine']:bs[0]['start_params']['cut']=1.
    bs[-1]['words']=e['answer'];bs[-1]['text']=e['answer']['zh']
    if e.get('condition'):bs[-1]['condition']=e['condition']
   if id=='P12_T03':bs.insert(2,beat(id+':height','同一个舱室上移，横剖面积不变；容积曲线没有记录这次高度变化。','Переместим отсек вверх: площадь сечения не изменится.',state={'section_height':0.,'scan':.5},target={'section_height':1.}))
   if id=='P12_T04':bs[1]['words']=pair('沿通道联系食品库、厨房和餐厅，布置不能任意割裂这些联系。',stress('Свяжем кладовую, камбуз и столовую проходами.'))
   if id=='P12_T14':bs[0]['start_params'].update(load=1.,cargo_z=3.);bs[1]['action']['params'].update(load=1.,cargo_z=11.)
   if id=='P12_T23':bs[0]['start_params'].update(load=1.,cargo_x=70.);bs[1]['action']['params'].update(load=1.,cargo_x=150.)
   if id=='P12_T18':
    bs[0]['start_params'].update(shift=0.,flood=0.)
    bs[1]['words']=pair('端部进水更易引起纵倾；随后比较中部。',stress('Затопление оконечности опасно большим дифферентом.'));bs[1]['action']={'params':{'cut':1.,'flood':1.,'shift':0.},'duration':3.}
    bs.insert(2,beat(id+':midship','改为中部宽舱：重点检查有效水线面惯性矩的损失。','В середине важна потеря момента инерции ватерлинии.',target={'shift':.5}))
   if id=='P12_T20':bs[0]['start_params'].update(shift=.5);bs[1]['action']['params']['shift']=.5
   if id=='P12_T22':bs[0]['start_params'].update(bulb=1.,speed=1.);bs[1]['action']['params'].update(speed=.35)
   if id=='P12_T27':bs[1]['action']['params']['heel']=100.;bs[1]['action']['duration']=6.
   if id=='P12_T08':bs[1]['action']['duration']=12.;bs[1]['action']['params']['progress']=1.
   if e['kind']=='calculation' and id.startswith('P12_C'):
    e['calculation']={'example':{'question_ru':stress('Учебный пример. Найдите массу и координаты центра масс.' if id!='P12_C04' else 'Учебный пример. Найдите площадь столовой.'),'translation':'独立演示算例，不是老师给定的数值。','steps':['已知：'+('；'.join(f'{r[0]} {r[1]} t，x={r[2]} m，z={r[3]} m' for r in e['example_data']['rows']) if 'example_data' in e else '另定12个座位，每座1.2 m²。'),'分别计算质量和各方向质量矩。' if id!='P12_C04' else '座位数乘每座面积。','单位：质量t，坐标m，质量矩t·m。' if id!='P12_C04' else '单位：m²。',e['condition']['zh']],'formula_id':id+':sum'}}
    e['condition']['ru']=stress('Нужны данные о плавучести.' if id in ['P12_C01','P12_C03'] else ('Груз и расходуемые запасы не входят в массу порожнём.' if id=='P12_C02' else 'Число мест в исходных данных не задано.'))
    bs[-1]['words']=e['condition'];bs[-1]['condition']=e['condition']
    if id=='P12_C02':e['answer']=pair('选船体、船体设备、动力装置、系统、导航设备和永久压载；再求和与重心。',stress('Корпус, оборудование, СЭУ, системы, навигационное вооружение и постоянный балласт.'))
    if 'example_data' in e:
     for k,r in enumerate(e['example_data']['rows']):
      b=next(b for b in bs if b['id']==id+f':row{k}');b['start_params']['row_index']=k
      tex(b['id'],[rf'P_{{{k}}}=@ex_item_mass@\,\mathrm{{t}}',rf'x_{{{k}}}={r[2]}\,\mathrm{{m}},\quad z_{{{k}}}={r[3]}\,\mathrm{{m}}',rf'P_{{{k}}}x_{{{k}}}=@ex_item_mx@\,\mathrm{{t\,m}}',rf'P_{{{k}}}z_{{{k}}}=@ex_item_mz@\,\mathrm{{t\,m}}'])
     for lang in ['zh','ru']:
      if id=='P12_C02':
       for row in formula[id+':sum'][lang]:
        row['tex']=row['tex'].replace('D=',r'P_{\mathrm{пор}}=').replace('x_g',r'x_{\mathrm{пор}}').replace('z_g',r'z_{\mathrm{пор}}');row['linear']=row['tex']
     bs[-2]['start_params']={'load':1.}
     bs[-2]['action']['params']['load']=1.
   if id=='P12_F02':bs.append(beat(id+':raise_g','上移G，同一倾角下的复原力臂减小。','Поднимем G: плечо уменьшается.',state={'image_index':5,'heel':35.},target={'zg':10.2}))
   if id=='P12_F06':
    e['answer']=pair('ЦВ是浮心；艏部相对更丰满时，纵向浮心向艏移。',stress('ЦВ — центр величины. Полнота носа перемещает его вперёд.'))
    e['topic']='P12_resistance'
    bs[-1]['words']=pair('把容积移向艉部，纵向浮心也向艉移动。',stress('Объём в корме перемещает центр величины назад.'))
    for b in bs:
     if 'start_params' in b:b['start_params'].update(concept='lcb',image_index=10,heel=0.,flood=0.,shift=0.)
     if 'action' in b:b['action']['params']={'shift':1.,'progress':1.}
    bs[0]['words']=pair('图中的ЦВ指浮心；比较艏艉丰满程度。',stress('ЦВ — центр величины. Сравним полноту оконечностей.'))
    bs[-1]['action']={'params':{'shift':-1.,'progress':1.},'duration':3.}
   if id=='P12_D01':
    bs[0]['start_params'].update(scale_l=1.,drawing=True)
    bs[1].pop('source_rule',None)
 # Formula reveal follows the physical dependency: total, longitudinal coordinate, height.
 for c in courses:
  for g in c['groups']:
   id=g['id'];bs=g['beats']
   if id.startswith('P12_C') and id!='P12_C04':
    e=by[id];rows=e['example_data'];sumid=id+':sum'
    complete=copy.deepcopy(formula[sumid]);formula[id+':solution']=complete
    e['formula_id']=id+':solution';e['calculation']['example']['formula_id']=id+':solution'
    for lang in ['zh','ru']:
     formula[sumid][lang]=[complete[lang][0]]
    n=next(i for i,b in enumerate(bs) if b['id']==sumid)
    bs[n]['words']=pair('先把各项质量相加，得到总质量。',stress('Сначала суммируем массы.'))
    for axis,offset,zh,ru in [('x',1,'纵向总矩除以总质量，得到纵向重心坐标。','Продольный момент делим на массу.'),('z',2,'竖向总矩除以总质量，得到重心高度。','Вертикальный момент делим на массу.')]:
     bid=id+':'+axis+'sum';formula[bid]={lang:[complete[lang][offset]] for lang in ['zh','ru']}
     bs.insert(n+offset,beat(bid,zh,ru,target={'axis':float(offset)},record='纵向重心' if offset==1 else '重心高度'))
    total='P_{\\mathrm{пор}}' if id=='P12_C02' else 'D'
    symbolic=[total+r'=\sum P_i',r'x_g=\frac{\sum P_ix_i}{'+total+'}',r'z_g=\frac{\sum P_iz_i}{'+total+'}']
    if id=='P12_C02':symbolic=[v.replace('x_g',r'x_{\mathrm{пор}}').replace('z_g',r'z_{\mathrm{пор}}') for v in symbolic]
    tex(id+':goal',symbolic)
    bs[0]['source_rule']={'kind':'formula','teacher_reference':'1p/Modul_2.docx'};bs[0]['source_rows']={str(i):bs[0]['source_rule'] for i in range(3)}
    if id=='P12_C02':
     for b in bs:
      if 'start_params' in b:b['start_params']['concept']='lightship'
     bs.insert(1,beat(id+':select','货物、航次燃油、食品淡水和船员不属于空船质量。','Груз, расходуемые запасы и экипаж не входят в массу порожнём.',target={'cut':1.,'room':3.}))
   if id in ['P12_T01','P12_T14','P12_T23','P12_T03','P12_T08','P12_T20']:
    b=bs[1];b['source_rule']={'kind':'formula','teacher_reference':by[id]['source']};b['source_rows']={str(i):b['source_rule'] for i in range(len(formula.get(b['id'],{}).get('zh',[])))}
   if id=='P12_D01':
    b=bs[1];b['source_rule']={'kind':'given','teacher_reference':'12p/pictures_for_exam.docx'};b['source_rows']={'0':b['source_rule']}
 # Reuse the general equations already revealed in this topic; do not append identical copies.
 for id,rows in [('P12_T14',[r'D=@ex_D@\,\mathrm{t}',r'z_g=@ex_zg@\,\mathrm{m}']),('P12_T23',[r'D=@ex_D@\,\mathrm{t}',r'x_g=@ex_xg@\,\mathrm{m}'])]:
  tex(id+':change',rows)
  for g in cs['P12_loads']['groups']:
   if g['id']==id:
    for b in g['beats']:b.pop('source_rule',None);b.pop('source_rows',None)
 for id in ['P12_C01','P12_C03']:
  formula.pop(id+':goal',None)
  g=next(g for g in cs['P12_loads']['groups'] if g['id']==id)
  g['beats'][0].pop('source_rule',None);g['beats'][0].pop('source_rows',None)
  g['beats'][0]['record_text']=pair(by[id]['sources'][0]+' · 演示算例',stress('Учебный пример '+id[-1]))
 # Images preserve their original labels; F06 is explicitly linked to the matching teacher figure.
 by['P12_F06']['condition']=pair('对应模块11图13：浮心位置与船体形状；没有给定可定量复算的坐标。',stress('Рисунок 13: положение центра величины и форма корпуса.'))
 # Store exact teacher paragraphs as provenance; display only concise necessary conditions.
 keywords={1:['центра','координат'],2:['дифференциальной форме'],3:['аппликат','эпюр','площадей'],4:['ограничения','общего расположения'],5:['запас плавучести'],6:['санитар','пищ'],7:['волнов','быстроход'],8:['качк','верхн'],9:['обратная задача'],10:['водонепроница','остойчив'],11:['вычет'],12:['запас плавучести','непотоп'],13:['машинного отделения','валопровод'],14:['центра масс'],15:['прототип'],16:['бульб'],17:['прототип'],18:['проверка','постоянного'],19:['индивидуальная','индивидуальная','индивидуаль'],20:['постоянного водоизмещения'],21:['бака','бак '],22:['бульб'],23:['центра','продоль'],24:['высоты борта','вместим'],25:['размерений'],26:['ширины','L/B'],27:['диаграмм'],28:['двойн'],29:['общественные','помещения экипажа'],30:['провизион','санитар'],31:['проекц'],32:['надстройк']}
 cache={}
 for item in audit:
  path=root.parent/item['source']
  if not path.exists():item['evidence_status']='source_missing';continue
  if str(path) not in cache:
   with zipfile.ZipFile(path) as z:t=ET.fromstring(z.read('word/document.xml'))
   cache[str(path)]=[''.join(n.text or '' for n in p.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}t')) for p in t.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}p')]
  number=int(item['id'][-2:]);keys=keywords.get(number,[]) if '_T' in item['id'] else ['порожнем','порожнём','столовые']
  item['evidence']=[{'paragraph':i+1,'text':s} for i,s in enumerate(cache[str(path)]) if any(k in s.lower() for k in keys)][:8]
  item['evidence_status']='teacher_method_plus_explanation' if item['evidence'] else 'question_and_geometric_reasoning'
  item['answer']=by[item['id']]['answer'];item['condition']=by[item['id']].get('condition',{})
  item['question_file']='12p/pictures_for_exam.docx' if item['id']=='P12_D01' else '12p/题目.docx'
  item['source_label']=by[item['id']]['sources'][0];item['original']=by[item['id']]['question_original']
 from calculation_notation import apply as apply_question_notation
 apply_question_notation(entries,courses,formula,stress)
 return entries,courses,formula,audit
