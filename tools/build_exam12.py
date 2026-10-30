"""Build only the independent 12p bank; teacher files remain untouched."""
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as E
import json,re,copy,hashlib
R=Path(__file__).resolve().parents[1]; C=R/'modules/review/content'; OUT=C/'exam12'; OUT.mkdir(exist_ok=True)
def write(n,v): (OUT/n).write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf8')
def pair(zh,ru):return dict(zh=zh,ru=ru)
def paras(p):
 with ZipFile(p) as z:r=E.fromstring(z.read('word/document.xml'))
 ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
 return [''.join(t.text or '' for t in x.findall('.//w:t',ns)) for x in r.findall('.//w:p',ns)]
P=paras(R.parent/'12p/题目.docx'); tests=P[P.index('ТЕСТОВЫЕ ВОПРОСЫ')+1:];tests=[re.sub(r'^\d+\.\s*','',s) for s in tests if s.strip()]
# id, title, translation, short Russian answer, Chinese answer, model concept,
# object sentence, relationship sentence, source module.
ROWS=[
(1,'质量与位置','为什么只知道排水量D还不足以判断船舶姿态和稳性？','Нужны координаты центра масс.','还需要重心坐标。','load','先看全船总质量与重心G。','总质量相同，货物位置不同，重心仍会改变。',2),
(2,'近似与母型','为什么微分形式的质量方程要求接近的母型船？','Изменения должны быть малыми.','变化应当足够小。','prototype','母型提供一个已知的设计状态。','微分近似描述附近的变化；差异过大时不能照搬。',3),
(3,'容积曲线','为什么容积曲线能求舱容和纵向坐标，却不能求竖向坐标？','Она показывает объём по длине, но не по высоте.','它表示沿船长的容积分布，没有高度分布。','sections','沿船长截取横剖面，每处得到一个面积。','同样的面积可以处于不同高度，曲线无法区分。',5),
(4,'布置的联系','为什么总布置不是任意拼凑舱室？','Нужно учитывать связи помещений и требования.','需要考虑舱室联系及要求。','rooms','厨房、餐厅和食品库通过通道联系。','移动一个舱室会改变通行与卫生关系。',12),
(5,'储备浮力','什么是储备浮力？','Объём водонепроницаемой части судна выше ватерлинии.','水线上方保持水密的船体及上层建筑容积。','reserve','水线以下的体积支撑当前船重。','水线上方的水密空间提供继续浸入的余量。',7),
(6,'厨房与卫生区','为什么厨房不能紧邻公用卫生设施？','Чтобы не загрязнять пищу.','避免污染食物。','hygiene','分别找到厨房和卫生区。','保持隔离，避免污物流线进入食品区。',12),
(7,'丰满与阻力','为什么高速船不宜过于丰满，即使这能增加货舱空间？','Сильно растёт волновое сопротивление.','兴波阻力会显著增加。','resistance','同尺度下，丰满船体提供更多水下体积。','较高航速下，过于丰满的形状会增加兴波阻力。',8),
(8,'稳性上限','为什么稳性上限与横摇有关，而不只是倾覆安全？','При большой высоте h качка слишком резкая.','初稳性高较大时横摇过于急促。','roll','同初始摇幅下比较两种重心高度。','固定等效回转半径时，初稳性高越大，周期越短。',9),
(9,'逆向设计','为什么船舶设计是逆问题而非正问题？','По требованиям выбирают размеры и форму.','根据要求选择尺度和形状。','inverse','先给出载货、航速及航区要求。','改变尺寸和形状，寻找满足要求的方案。',1),
(10,'浮力不等于不沉性','为什么增加储备浮力本身不能保证不沉性？','Нужны водонепроницаемые отсеки и остойчивость.','还需要水密分舱和足够稳性。','flood','破口让水进入一个舱室。','水密舱壁限制蔓延；剩余浮力和稳性还要校核。',7),
(11,'实际舱容','为什么液舱实际舱容小于理论容积？','Часть объёма занята конструкциями; нужен свободный объём.','结构占据部分空间，且需留出必要余量。','tank','先观察由理论边界围成的液舱。','扣除舱内结构及不能利用的空间，才得到实际舱容。',5),
(12,'干舷与事故','为什么有干舷仍不能保证船不会沉？','Вода может затопить отсеки; возможна потеря остойчивости.','舱室可能进水，也可能失去稳性。','flood','干舷描述甲板边缘高于水线的距离。','它不表示所有开口水密，也不能阻止破舱进水。',7),
(13,'尾机型','为什么机舱通常布置在艉部？','Короче валопровод; больше места для груза.','轴系更短，便于集中布置货舱。','engine','机舱内的主机通过轴系连接艉部螺旋桨。','机舱靠近艉部，轴系缩短，货舱区域更连续。',12),
(14,'总质量不足','为什么不能仅用总质量描述船舶？','Важно и распределение масс.','质量分布也很重要。','load','保持货物质量不变。','将货物上移后，竖向重心升高。',2),
(15,'质量系数','为什么新船质量系数应来自接近的母型，而非所有船的平均值？','Измерители зависят от типа и размеров судна.','质量系数取决于船型和尺度。','prototype','质量系数来自特定船型、尺度和设备。','相同系数不能保证适用于差异很大的船。',3),
(16,'球鼻艏匹配','为什么球鼻艏效果取决于设计航速和吃水？','Нужно благоприятное взаимодействие волн корпуса и бульба.','需要船体波与球鼻艏波适当匹配。','bulb','球鼻艏和船体各自改变附近波形。','航速和浸深改变后，原有的有利匹配可能减弱。',11),
(17,'母型不是答案','为什么母型只能加快设计，不能替代设计？','У нового судна другие требования.','新船的要求不同。','prototype','母型提供已有尺寸、质量和布置。','新任务改变后，仍需重新计算和校核。',1),
(18,'事故校核情景','为什么事故浮性与事故稳性校核要选择不同的进水舱室？','Разные отсеки дают разные осадку, крен и остойчивость.','不同舱室造成的吃水、倾斜和稳性变化不同。','damage','分别观察中部、端部和偏舷舱室进水。','容积、纵向位置和不对称性影响不同；应分别筛选不利情景。',10),
(19,'总布置个性','为什么每艘船的总布置都具有个体特点？','Разные назначение, размеры и оборудование.','用途、尺度和设备不同。','rooms','先确定运输任务、设备和人员需要。','这些条件不同，舱室大小和相互位置也不同。',12),
(20,'固定排水量法','为什么固定排水量法中的横稳心高变化与有效水线面减小有关，而不是船重变化？','Масса постоянна; меняются действующая ватерлиния и центр величины.','质量保持不变；有效水线面和浮心改变。','waterplane','此方法不把自由连通海水作为新增船重。','去掉进水区域的有效浮力后，重新计算浮心和水线面惯性矩。',7),
(21,'艏楼长度','为什么设艏楼，其长度怎样影响甲板上浪？','Бак защищает палубу; длиннее бак — больше защищённая часть.','艏楼保护甲板；艏楼加长会扩大保护范围。','forecastle','抬高艏部甲板，让迎浪更难越过。','延长艏楼，扩大较高甲板覆盖范围；效果还与航速和海况有关。',11),
(22,'球鼻艏与船速','为什么高速船使用球鼻艏，而低速船不使用？','Бульб уменьшает сопротивление при подходящих скорости и осадке.','球鼻艏在合适航速和吃水下减阻。','bulb','先观察球鼻艏的位置和浸深。','原题的绝对说法不普遍成立：部分低速丰满船也采用球鼻艏。',11),
(23,'纵向质量分布','为什么设计时不仅看排水量，还看质量沿船长的分布？','Она влияет на дифферент и продольную прочность.','它影响纵倾和纵向强度。','longitudinal','同样的货物分别放在中部和艏部。','纵向重心及局部载荷改变；还需与沿船长的浮力分布比较。',2),
(24,'增大型深','对积载因数大的货物，为什么常增大型深而非船长或船宽？','Больше вместимость без увеличения длины и ширины.','不增大船长和船宽，也能增加舱容。','depth','这种货物每吨需要较大的空间。','保持水下尺度的比较中，提高甲板可以增加舱容。',5),
(25,'尺度权衡','为什么选择主尺度时要同时考虑快速性、稳性和容积？','Размеры влияют на все эти качества.','尺度同时影响这些性能。','tradeoff','增加船宽会同时改变水线面和舱容。','满足某个要求后，还要复核其他性能。',9),
(26,'船宽的影响','为什么增加船宽有利于初稳性，却可能不利于快速性？','Растут момент инерции ватерлинии и сопротивление.','水线面惯性矩增大，阻力也可能增加。','breadth','在固定比较条件下增加船宽。','水线面惯性矩通常增大；阻力变化需结合航速和船型。',9),
(27,'h不代表全部稳性','为什么只知道稳心高h还不足以评价稳性？','Нужна диаграмма остойчивости на больших углах.','还需要大倾角稳性曲线。','stability','h描述接近正浮时的恢复关系。','大倾角还要看最大力臂、正稳性范围和进水开口。',9),
(28,'双层结构','为什么设置双层底和双舷侧？','Чтобы ограничить затопление при повреждении наружной обшивки.','外板受损时限制进水。','double','剖开外板，找到内底和内舷。','外板破损时，完整的内层结构限制水进入其他舱室。',7),
(29,'休息与进餐','为什么船员休息区与进餐区应当分开？','Для отдыха и соблюдения гигиены.','满足休息与卫生需要。','rooms','分别找到卧室、餐厅及它们的通道。','进餐活动和食品流线不应干扰休息。',12),
(30,'食品库与卫生区','为什么食品库不能紧邻卫生设施？','Чтобы не загрязнять продукты.','避免污染食品。','hygiene','食品库储存准备食用的物资。','隔离卫生设施及其污染源，保持食品流线清洁。',12),
(31,'三投影','为什么型线图使用三个投影而非一个？','Одна проекция не показывает всю форму корпуса.','一个投影不能完整表达船体形状。','lines','从侧面、上方和端部分别观察同一船体。','同一个空间点，在三个投影中相互对应。',11),
(32,'干舷与上层建筑','为什么干舷大的船不一定要增加上层建筑高度？','Высоту надстройки определяют её назначение и требования.','上层建筑高度由其用途和相关要求确定。','reserve','干舷是水线到干舷甲板的高度。','上层建筑在甲板之上，不能把两个高度混为一谈。',10),
]
TOPICS=[('design','设计任务与母型','Проект и прототип',[2,9,15,17,25],'看懂母型提供什么，以及新船为什么仍要重新设计。'),('loads','载荷、重心与船舶姿态','Массы и центр масс',[1,14,23],'算清总质量和两个重心坐标，再判断还缺哪些浮态资料。'),('volume','型线、舱容与容积计算','Форма и вместимость',[3,11,24,31],'把三维形状、图纸和容积计算对应起来。'),('resistance','船型、航速与阻力','Форма и сопротивление',[7,16,22,26],'看懂船型和航速怎样共同影响阻力。'),('stability','稳性、横摇与事故状态','Остойчивость и качка',[8,18,20,27],'区分小角度、横摇、大角度和事故状态的稳性。'),('reserve','储备浮力与防进水结构','Плавучесть и защита',[5,10,12,21,28,32],'看懂哪些空间提供储备浮力，哪些结构限制进水。'),('arrangement','总布置与船员生活区','Общее расположение',[4,6,13,19,29,30],'把舱室用途、通道和卫生关系落实到船内位置。')]
OBJECT_RU={'load':'Смотрим на массу и положение груза.','prototype':'Сравним новое судно с прототипом.','sections':'Покажем площади сечений по длине.','rooms':'Покажем помещения и проходы.','reserve':'Найдём ватерлинию и закрытый объём выше неё.','hygiene':'Найдём пищевые и санитарные помещения.','resistance':'Изменим полноту корпуса при тех же размерах.','roll':'Начальный угол одинаковый; радиус инерции постоянный.','inverse':'Сначала заданы требования, потом выбираем форму.','flood':'Вода поступает через повреждённую обшивку.','tank':'Покажем границы цистерны и конструкции внутри.','engine':'Вал соединяет двигатель и винт.','bulb':'Найдём бульб ниже ватерлинии.','damage':'Сравним положение затопленных отсеков.','waterplane':'В этом методе масса судна постоянна.','forecastle':'Поднимем носовую палубу.','longitudinal':'Переместим груз к носу.','depth':'Поднимем палубу при той же осадке.','tradeoff':'Изменим ширину и проверим другие качества.','breadth':'Увеличим ширину при той же осадке.','stability':'Сначала посмотрим на малый угол крена.','double':'Покажем наружное и внутреннее дно.','lines':'Посмотрим на корпус с трёх сторон.'}
def normalize(s):return s.replace('\u0301','').lower()
accent={}
for path in [C/'reading.json',C/'glossary.json',C/'topics.json']:
 for w in re.findall(r'[А-Яа-яЁё\u0301]+',path.read_text(encoding='utf8')):
  if '\u0301' in w or 'ё' in w.lower():accent.setdefault(normalize(w),w.lower())
manual='запа́са водонепроница́емой постоя́нна постоя́нный повре́ждённую санитарно-гигиени́ческими санитарно-гигиени́ческих помеще́ниями санита́рные пищевы́е загрязня́ть пи́щу проду́кты прохо́ды обрат́ной обра́тной пря́мой малы́ми измене́ния зави́сят длине́ высоте́ э́пюре ёмкости прое́кции прое́кциях прое́кция цилиндри́ческой вста́вки заостре́ние дли́ны ча́стей закры́тый коро́че валопрово́д постоя́нным прове́рим продо́льную про́чность действу́ющей действу́ющая совпа́дение подхо́дящих ра́диус ина́че одина́ковый нача́льный соединя́ет дви́гатель внутре́ннее нару́жное нару́жной ви́дим сравни́м пока́жем подни́мем перемести́м измени́м исхо́дные да́нные демонстрацио́нный приме́р места́ ме́сто ме́ст числе́нность столо́вая столо́вой о́тдыха пита́ния приёма гигие́ны свобо́дный необходи́мый ме́тода положе́ние расче́тной расчётной постоя́нного усреднённые уско́ряет заменя́ет гаранти́рует защищённая сле́дует разде́лять необходи́мо рассчи́тывается но́рме поса́дочное поса́дочных тяжести́ тя́жести при́нят перевози́мый навигацио́нное вооруже́ние прови́зия пре́сная ба́гажом составля́ющие вхо́дят объясни́те по́рожнем сумми́руем вы́числим ну́жны тре́бует недоста́точно непотопля́емости выполне́ния'
extra=OUT/'stress_overrides.json'
for w in manual.split():accent[normalize(w)]=w
if extra.exists():accent.update(json.loads(extra.read_text(encoding='utf8')))
from reasoned_stress import WORDS as REVIEWED_STRESSES
for w in REVIEWED_STRESSES.split():accent[normalize(w)]=w
def stress(s):
 def word(m):
  w=m[0];v=accent.get(normalize(w),w);return v[0].upper()+v[1:] if w[0].isupper() else v
 return re.sub(r'[А-Яа-яЁё\u0301]+',word,s)
CONDITIONS={1:'还需相应浮态的浮心、稳心及纵向浮态资料，才能判断纵倾与初稳性变化。',8:'同初始摇幅、固定等效回转半径；只比较小角度自由横摇。',16:'有效性通常有一定航速和吃水范围，并非仅在一个设计点有效。',18:'定性比较，不输出未经计算的事故倾角或合格结论。',20:'固定排水量法不能同时把同一海水再作为新增船重；还要计入浮心和水线面惯性矩的变化。',21:'效果还与艏部高度、航速和海况有关。',22:'原题前提不是普遍规律：部分大型低速丰满船也采用球鼻艏。',24:'保持水下尺度的比较；仍需复核重心、结构等要求。',26:'阻力变化还与航速、排水量和船型有关，不是无条件单调规律。',27:'还要检查大角度稳性和进水开口。'}
SOURCES={1:'1p/Modul_1.docx',2:'1p/Modul_2.docx',3:'1p/Modul_3.docx',5:'5p/Modul_5. Виды вместимости.docx',7:'5p/Modul_7. Непотопляемость.docx',8:'6a/Modul_8. Ходкость.docx',9:'6p/Modul_9. Обеспечение остойчивости.docx',10:'6p/Modul_10. Обеспечение непотопляемости.docx',11:'7a/Modul_11. ТЧ.docx',12:'9p-晚上发的/Modul_12. Общее расположение.docx'}
BASE={'topic':'exam12','qid':'P12_T01','phase':'overview','concept':'prototype','progress':0.,'load':0.,'cargo_x':112.,'cargo_z':5.,'flood':0.,'room':0.,'heel':0.,'zg':8.7,'scale_l':1.,'scale_b':1.,'scale_t':1.,'bilge':0.,'bulb':0.,'lines':0.,'station':0.,'speed':0.,'roof':0.,'cut':0.,'depth':0.,'forecastle':0.,'scan':0.,'shift':0.,'image_index':0,'axis':0.,'row_index':0,'drawing':False,'section_height':-1.}
TARGETS={'load':{'load':1.,'cargo_z':11.,'cut':1.},'longitudinal':{'load':1.,'cargo_x':150.,'cut':1.},'prototype':{'scale_l':1.15,'scale_b':1.1},'inverse':{'scale_l':1.1,'scale_b':1.1},'tradeoff':{'scale_b':1.2},'sections':{'scan':1.,'station':1.,'cut':1.},'lines':{'lines':1.,'station':1.,'scan':1.},'tank':{'cut':1.,'load':1.},'depth':{'depth':3.,'cut':1.},'resistance':{'bilge':1.,'speed':1.},'bulb':{'bulb':1.,'speed':1.},'breadth':{'scale_b':1.2,'speed':1.},'roll':{'zg':7.5,'heel':12.,'progress':1.},'stability':{'heel':55.},'damage':{'flood':1.,'cut':1.,'shift':1.},'waterplane':{'flood':1.,'cut':1.},'flood':{'flood':1.,'cut':1.},'double':{'cut':1.,'flood':.5},'reserve':{'depth':2.},'forecastle':{'forecastle':1.},'rooms':{'room':1.,'roof':1.,'cut':1.},'hygiene':{'room':2.,'roof':1.,'cut':1.},'engine':{'room':3.,'cut':1.}}
entries=[];courses=[];formula={};audit=[]
def beat(id,zh,ru,state=None,target=None,record=None):
 d={'id':id,'text':zh,'words':pair(zh,stress(ru)),'camera':'topic','anchor':'ship'}
 if state is not None:d['start_params']=state
 if target:d['action']={'params':target,'duration':3.0}
 if record:d['record_text']=pair(record,stress(ru))
 return d
def tex(id,rows):formula[id]={lang:[{'tex':t,'linear':t} for t in rows] for lang in ['zh','ru']}
for key,title,ru,nums,goal in TOPICS:
 cid='P12_'+key
 bs=[beat(cid+':intro',goal,'Поймём связь формы, массы и требований.',dict(BASE,concept=ROWS[nums[0]-1][5])),beat(cid+':foundation_end','先指出对象，再观察一个因素的变化。','Сначала найдём объект, затем изменим один параметр.',target={'progress':1.})]
 c={'id':cid,'title':pair(title,stress(ru)),'goal':pair(goal,stress('Поймём связь формы, массы и требований.')),'initial':BASE.copy(),'groups':[{'id':'foundation','title':pair('基础','Осно́ва'),'beats':bs}],'questions':[],'question_targets':{},'foundation_end':cid+':foundation_end','characters_per_second':28}
 for n in nums:
  _,short,zh,ans,anszh,concept,obj,rel,source=ROWS[n-1];qid=f'P12_T{n:02d}';st=dict(BASE,qid=qid,concept=concept);st['phase']='bulb' if concept=='bulb' else ('drawing' if concept=='lines' else 'overview')
  e={'id':qid,'kind':'theory','sources':[f'理论{n}'],'question_original':tests[n-1],'question_ru':stress(tests[n-1]),'translation':zh,'answer':pair(anszh,stress(ans)),'topic':cid,'source':SOURCES[source]}
  if n in CONDITIONS:e['condition']=pair(CONDITIONS[n],'')
  bs=[beat(qid+':object',obj,OBJECT_RU[concept],st),beat(qid+':change',rel,ans,target=TARGETS[concept]),beat(qid+':answer',anszh,ans)]
  if n in CONDITIONS:bs[-1]['condition']=pair(CONDITIONS[n],'')
  if n==3:tex(bs[1]['id'],[r'W=\int A(x)\,dx',r'x_c=\frac{\int xA(x)\,dx}{W}'])
  if n==8:tex(bs[1]['id'],[r'\tau=\frac{2\pi k_{eff}}{\sqrt{gh}}'])
  if n==20:tex(bs[1]['id'],[r'h=z_c+\frac{I_x}{\nabla}-z_g',r'\Delta h=\Delta z_c+\Delta\!\left(\frac{I_x}{\nabla}\right)-\Delta z_g'])
  if n in [1,14,23]:tex(bs[1]['id'],[r'D=\sum P_i',r'x_g=\frac{\sum P_i x_i}{D}',r'z_g=\frac{\sum P_i z_i}{D}'])
  c['groups'].append({'id':qid,'title':pair(short,stress('Вопрос '+str(n))),'beats':bs});c['questions'].append(qid);c['question_targets'][qid]=bs[0]['id'];entries.append(e);audit.append({'id':qid,'source':SOURCES[source],'original':tests[n-1],'condition':CONDITIONS.get(n,''),'animation':bs[0]['id']})
 courses.append(c)
CALC_TRANSLATIONS=['空船质量和重心已知，加入货物与储备，各项质量和坐标已知。求排水量、纵向与竖向重心，并说明相对空船的纵倾与初稳性变化。','给出船体、船体设备、动力装置、系统、导航设备、永久压载、货物、燃油和油料、带行李的船员、食品与淡水的质量和重心。选出空船组成，求空船质量和重心，并解释排除哪些项。','空船加入两个货舱的货物、燃油和淡水储备，各项质量和坐标已知。求排水量及两个重心坐标，并说明纵倾和初稳性变化。','船员N人，每座面积定额X，餐厅应按多少人计算？求餐厅面积。']
for n,(a,b) in enumerate([(2,4),(6,12),(14,16),(18,20)],1):
 original=re.sub(r'^\d+\.\s*','','\n'.join(s for s in P[a:b] if s.strip())).replace('Вопросы к экзамену','').strip();qid=f'P12_C{n:02d}';c=next(c for c in courses if c['id']=='P12_'+('arrangement' if n==4 else 'loads'))
 ans=pair('质量相加，再分别用纵向和竖向总矩除以总质量。','Суммируем массы; каждый момент делим на общую массу.') if n<4 else pair('座位数乘每座面积；还需明确就餐人数比例。','Число мест умножаем на площадь одного места.')
 condition='还需浮态资料才能判断纵倾和初稳性变化。' if n in [1,3] else ('工作介质和运营储备须按教师空船分类区分。' if n==2 else '原题及已查模块12未明确就餐人数比例，不能认定全员同时就餐。')
 e={'id':qid,'kind':'calculation','sources':[f'计算{n}'],'question_original':original,'question_ru':stress(original),'translation':CALC_TRANSLATIONS[n-1],'answer':pair(ans['zh'],stress(ans['ru'])),'condition':pair(condition,''),'topic':c['id'],'source':SOURCES[2 if n<4 else 12]}
 st=dict(BASE,qid=qid,concept='rooms' if n==4 else 'load',cut=1.)
 bs=[beat(qid+':goal','先列已知量，再按本题要求计算。',ans['ru'],st)]
 rows=[]
 if n in [1,3]:
  rows=[('空船',1000,95,6),('货物1',100,140,4)]
  if n==3:rows.append(('货物2',200,70,3))
  rows.append(('储备',50,60,2))
 elif n==2:rows=[('钢船体',600,95,5),('船体设备',100,90,10),('动力装置',150,35,3),('系统',50,85,5),('导航设备',10,35,18),('永久压载',90,90,1)]
 if rows:
  for k,(name,m,x,z) in enumerate(rows):
   id=qid+f':row{k}';bs.append(beat(id,f'演示算例：{name}{m}吨，纵向{x}米，竖向{z}米。','Учебный пример: считаем массу и два момента.',dict(st,load=k/len(rows),cargo_x=x,cargo_z=z),{'load':(k+1)/len(rows)},name));tex(id,[rf'P_{{{k}}}={m}\,\mathrm{{t}}',rf'P_{{{k}}}x_{{{k}}}={m}\cdot{x}={m*x}\,\mathrm{{t\,m}}',rf'P_{{{k}}}z_{{{k}}}={m}\cdot{z}={m*z}\,\mathrm{{t\,m}}'])
  total=sum(a[1] for a in rows);mx=sum(a[1]*a[2] for a in rows);mz=sum(a[1]*a[3] for a in rows);tex(qid+':sum',[rf'D={total}\,\mathrm{{t}}',rf'x_g=\frac{{{mx}}}{{{total}}}={mx/total:.4f}\,\mathrm{{m}}',rf'z_g=\frac{{{mz}}}{{{total}}}={mz/total:.4f}\,\mathrm{{m}}']);e['example_data']={'rows':rows,'total':total,'mx':mx,'mz':mz,'xg':mx/total,'zg':mz/total}
  bs.append(beat(qid+':sum','分别得到纵向重心和竖向重心。',ans['ru'],target={'load':1.,'progress':1.},record='演示算例汇总'))
 else:
  tex(qid+':sum',[r'S=n_{seat}X',r'n_{seat}=12,\quad X=1.2\,\mathrm{m^2}',r'S=12\cdot1.2=14.4\,\mathrm{m^2}']);bs.append(beat(qid+':sum','演示算例：另行确定12个座位，每座1.2平方米，共14.4平方米。','Учебный пример: 12 мест, площадь 14,4 квадратного метра.',target={'room':1.,'roof':1.,'load':1.},record='演示座位数不是教师规定的就餐比例'))
 bs.append(beat(qid+':answer',condition,'Нужны дополнительные данные.'));bs[-1]['condition']=pair(condition,'');e['formula_id']=qid+':sum'
 entries.append(e);c['questions'].append(qid);c['question_targets'][qid]=bs[0]['id'];c['groups'].append({'id':qid,'title':pair(f'计算{n}',stress('Задача '+str(n))),'beats':bs});audit.append({'id':qid,'source':e['source'],'condition':condition,'animation':bs[0]['id']})
q='P12_D01';c=next(c for c in courses if c['id']=='P12_volume');original=next(s for s in paras(R.parent/'12p/pictures_for_exam.docx') if s.strip())
entries.append({'id':q,'kind':'calculation','sources':['型线图题'],'question_original':original,'question_ru':stress(original),'translation':'定义型线图和平行中体；画出侧面、横剖面、半宽三投影。标出艏35%、艉40%、平行中体25%，船长150米时求三段长度。','answer':pair('型线图以三投影表达船体；平行中体横剖面不变。艏52.5米、艉60米、中体37.5米。',stress('Три проекции показывают форму корпуса. Во вставке сечения одинаковые. Длины: 52,5; 60; 37,5 метра.')),'topic':c['id'],'formula_id':q+':lengths'})
bs=[beat(q+':object','同一船体投影到三个平面。','Три проекции одного корпуса.',dict(BASE,qid=q,concept='lines',phase='drawing'),{'lines':1.,'station':1.}),beat(q+':lengths','150米按题给比例分为52.5、60和37.5米。','Нос 52,5; корма 60; вставка 37,5 метра.',target={'scan':1.,'progress':1.},record='题给长度与比例'),beat(q+':sum','三段相加150米；平行中体横剖面保持相同。','Сумма длин равна 150 метрам.')]
tex(q+':lengths',[r'L=150\,\mathrm m',r'l_{\mathrm{н}}=0.35L=52.5\,\mathrm m',r'l_{\mathrm{к}}=0.40L=60\,\mathrm m',r'l_{\mathrm{ц}}=0.25L=37.5\,\mathrm m',r'52.5+60+37.5=150\,\mathrm m']);bs[1]['source_rule']=True
c['groups'].append({'id':q,'title':pair('型线图题','Три прое́кции'),'beats':bs});c['questions'].append(q);c['question_targets'][q]=bs[0]['id'];audit.append({'id':q,'source':'12p/pictures_for_exam.docx','animation':bs[0]['id']})
image_dir=R/'modules/review/assets/exam12';image_dir.mkdir(exist_ok=True);z=ZipFile(R.parent/'12p/pictures_for_exam.docx');pictures=[]
for i in range(1,11):
 name=f'image{i}.'+('emf' if i==7 else 'png');data=z.read('word/media/'+name);(image_dir/name).write_bytes(data);pictures.append({'number':i,'source':name,'sha256':hashlib.sha256(data).hexdigest(),'path':'res://modules/review/assets/exam12/'+f'image{i}.png'})
figs=[('arrangement',[1],'生活区平面','识别餐厅、通道和相邻舱室。','rooms'),('stability',[2,3,4,5],'稳性曲线','识别初始斜率、最大力臂和正稳性区末端。','stability'),('arrangement',[6,8],'食品储藏与卫生关系','识别食品库、卫生设施和通道；比较污染流线。','hygiene'),('arrangement',[7],'总布置与双层底','把侧视、货舱平面和双层底图对应到三维位置。','double'),('resistance',[9],'阻力组成','比较不同Fr下的阻力比例；这不是本船实测值。','resistance'),('resistance',[10],'浮心与艏艉丰满程度','识别ЦВ（浮心），比较艏艉容积分配与纵向浮心位置。','prototype')]
for i,(topic,nums,title,hint,concept) in enumerate(figs,1):
 qid=f'P12_F{i:02d}';c=next(c for c in courses if c['id']=='P12_'+topic);entries.append({'id':qid,'kind':'figure','sources':['识图'+str(i)],'question_original':'','question_ru':stress('Рассмотрите рисунок.'),'translation':hint,'answer':pair(hint,stress(OBJECT_RU[concept])),'condition':pair('原文件未给具体题干；这是识图辅助，不是老师标准问答。',''),'images':[pictures[n-1] for n in nums],'topic':c['id']})
 bs=[beat(qid+':object',hint,OBJECT_RU[concept],dict(BASE,qid=qid,concept=concept,image_index=nums[0]),TARGETS[concept]),beat(qid+':identify','将图上的区域对应到船上。','Сравним рисунок и корпус.',target={'progress':1.})];c['groups'].append({'id':qid,'title':pair(title,stress('Рисунок '+str(i))),'beats':bs});c['questions'].append(qid);c['question_targets'][qid]=bs[0]['id']
for e in entries:
 if e['kind']!='figure':e['source_aliases']=[{'label':e['sources'][0],'original':e['question_original']}]
from exam12_editorial import enhance
entries,courses,formula,audit=enhance(entries,courses,formula,audit,pictures,stress,pair,beat,tex,R)
from apply_reasoned_answers import apply as apply_reasoned
apply_reasoned(entries,courses)
from exam13 import append as append_exam13
entries,courses,formula,audit=append_exam13(entries,courses,formula,audit)
for item in audit:
 item['answer']=next(e['answer'] for e in entries if e['id']==item['id'])
 item.setdefault('answer_version','reasoned-2026-10-27')
write('reading.json',entries);write('topics.json',courses);write('question_bank.json',[{'id':e['id']} for e in entries]);write('source_map.json',{'questions':audit,'pictures':pictures,'teacher_question_count':67,'figure_items':6,'question_files':{'12p/题目.docx':36,'12p/pictures_for_exam.docx':1,'13a/问题.docx':30}});write('latex.json',formula)
unknown=set()
for e in entries:
 for s in [e['question_ru'],e['answer']['ru']]:
  for w in re.findall(r'[А-Яа-яЁё\u0301]+',s):
   if len(re.findall('[аеёиоуыэюя]',w.lower()))>1 and '\u0301' not in w and 'ё' not in w.lower():unknown.add(w.lower())
write('stress_missing.json',sorted(unknown));print('12p:',len(entries),'items,',len(courses),'topics; missing accents:',len(unknown))
from build_reasoned_lexicon import build as build_answer_words
build_answer_words()
from exam13_lexicon import build as build_exam13_words
build_exam13_words()
