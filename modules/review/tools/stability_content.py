import json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
groups=[];formulas={}
BASE=dict(route='base',morph=0,heel=0,zg=8.7,required=1,clock=0,show='hull',plot='',compare=False)
def group(id,zh,ru):
    groups.append(dict(id=id,title=dict(zh=zh,ru=ru),beats=[]))
def beat(id,zh,ru,*,start=None,end=None,show=None,camera='front',anchor='G',formula=None,controls=None,condition=None,duration=3):
    b=dict(id='ST:'+id,text=zh,words=dict(zh=zh,ru=ru),camera=camera,anchor=anchor,controls=controls or [],start_params=start or {})
    if show is not None:b['start_params']['show']=show
    if condition:b['condition']=dict(zh=condition[0],ru=condition[1])
    if end:b['action']=dict(params=end,duration=duration)
    if formula:
        formulas[b['id']]={lang:[dict(tex=f,linear=f) for f in formula] for lang in ['zh','ru']}
    groups[-1]['beats'].append(b)
def begin(q,zh,ru,**state):
    beat(q+':goal',zh,ru,start={**BASE,**state},camera='overview',anchor='ship')
def answer(q,zh,ru):beat(q+':answer',zh,ru,controls=['heel','zg'] if q not in ['Q20','Q21'] else ['zg'])

group('foundation','基础','Осно́вы')
beat('goal','看懂船为什么能扶正，以及船型和重心怎样改变扶正能力与横摇。','Поймём, почему́ су́дно выпрямля́ется и как фо́рма и центр масс влия́ют на осто́йчивость и ка́чку.',start=BASE.copy(),camera='overview',anchor='ship')
beat('heel','左右倾斜叫横倾；水面始终水平。','Накло́н на борт называ́ется кре́ном. Пове́рхность воды́ горизонта́льна.',end={'heel':6},anchor='water')
beat('G','G是全船重心，重力从这里竖直向下。','G — центр масс всего́ су́дна. Си́ла тя́жести напра́влена вертика́льно вниз.',show='G')
beat('volume','现在看整个水下部分，而不只是一个横剖面。','Сейча́с ви́дим всю подво́дную часть, а не одно́ сече́ние.',show='wet',camera='overview',anchor='C')
beat('C','C是水下体积的中心，叫浮心；浮力通过C竖直向上。','C — центр подво́дного объёма. Си́ла плаву́чести напра́влена че́рез C вертика́льно вверх.',show='forces',anchor='C')
beat('Cmove','倾斜后，一侧浸入、另一侧露出，浮心随水下体积的分布移动。','При кре́не оди́н борт погружа́ется, друго́й выхо́дит из воды́. Центр C перемеща́ется.',end={'heel':-6},anchor='C')
beat('lines','重力和浮力方向相反，但作用线不再重合。','Си́лы напра́влены в ра́зные сто́роны, а их ли́нии де́йствия не совпада́ют.',end={'heel':8},show='lines',anchor='arm')
beat('arm','两条竖直作用线的水平间距，就是复原力臂。','Горизонта́льное расстоя́ние ме́жду ли́ниями сил — плечо́ восстана́вливающего моме́нта.',show='arm',anchor='arm',formula=[r'l_{\text{ст}}=@st_arm@\,\mathrm{m}'])
beat('restore','这对力使船向直立方向转动；力臂越大，扶正力矩越大。','Э́ти си́лы повора́чивают су́дно к прямо́му положе́нию. Бо́льшее плечо́ даёт бо́льший моме́нт.',end={'heel':2},anchor='arm',formula=[r'M_{\text{rest}}=m g\,l_{\text{ст}}'])
beat('foundation_end','横稳性是抵抗横倾、产生扶正作用的能力；并不等于船不会摇。','Попере́чная осто́йчивость — спосо́бность сопротивля́ться кре́ну и выпрямля́ться. Су́дно при э́том мо́жет кача́ться.',controls=['heel'],anchor='arm')

group('Q17','17 · 船型与稳心','17 · Фо́рма и метаце́нтр')
begin('Q17','船型为什么会改变横稳性？先找出横稳心M。','Почему́ фо́рма влия́ет на осто́йчивость? Снача́ла найдём метаце́нтр M.',show='forces')
beat('Mconstruct','在船体坐标中，微小横倾前后的浮力作用线相交；趋近零倾角时得到M。','В координа́тах су́дна ли́нии си́лы плаву́чести при ма́лом кре́не пересека́ются. При кре́не, стремя́щемся к нулю́, получа́ем M.',show='M',end={'heel':3},anchor='M')
beat('Mheight','M不是铰链。GM这段高度h，衡量小角度下的扶正能力。','M — не шарни́р. Высота́ GM, или h, характеризу́ет осто́йчивость при ма́лом кре́не.',anchor='M',formula=[r'h=z_c+r-z_g',r'h=@st_h@\,\mathrm{m}'])
beat('waterplane','水线面靠两舷的面积，对横稳心半径的贡献更大。','Пло́щадь ватерли́нии у бортов сильне́е влия́ет на попере́чный метацентри́ческий ра́диус.',show='waterplane',camera='top',anchor='water',formula=[r'r=\frac{I_x}{\nabla}',r'I_x=\int_{A_w}y^2\,dA'])
beat('area_inertia','这里的I是水线面的面积惯性矩，单位m⁴，不是船体质量的转动惯量。','Здесь I — моме́нт ине́рции пло́щади ватерли́нии в м⁴, а не моме́нт ине́рции ма́ссы су́дна.',camera='top',anchor='water')
beat('width','保持吃水和G高度，船变窄；水线面改变，M下降。','Сохраня́ем оса́дку и высоту́ G. Уменьша́ем ширину́: ватерли́ния меня́ется, M опуска́ется.',start={'route':'narrow','morph':0,'heel':0},end={'morph':1},show='M',anchor='M',condition=('T、z_g不变','T и z_g постоя́нны'),formula=[r'r=@st_r@\,\mathrm{m}',r'h=@st_h@\,\mathrm{m}'])
beat('shape','恢复船宽；只收窄水下底部，也会改变浮心和M的位置。','Возвраща́ем ширину́. Сужа́ем то́лько ни́жнюю подво́дную часть: C и M то́же меня́ются.',start={'route':'shape','morph':0},end={'morph':1},anchor='M',condition=('B、T、z_g不变','B, T и z_g постоя́нны'))
answer('Q17','会。水下形状通过浮心和横稳心的位置影响横稳性。','Да. Подво́дная фо́рма влия́ет на положе́ние C и метаце́нтра M.')

group('Q16','16 · 重心高度','16 · Высота́ це́нтра масс')
begin('Q16','要满足所需稳性，G最高可以放在哪里？','Как высоко́ мо́жно расположи́ть G, что́бы обеспе́чить ну́жную осто́йчивость?',show='M')
beat('Gup','船型和吃水不变：G升高，M不动，h变小。','Фо́рма и оса́дка не меня́ются: G поднима́ется, M остаётся на ме́сте, h уменьша́ется.',end={'zg':9.5},anchor='G',formula=[r'h=z_c+r-z_g',r'h=@st_h@\,\mathrm{m}'],condition=('船型、T不变','Фо́рма и T постоя́нны'))
beat('limit','要求h至少达到h_min，就得到G允许的最高位置。','Тре́буем h не ме́нее h_min. Так получа́ем наибо́льшую допусти́мую высоту́ G.',show='limit',anchor='limit',formula=[r'h\ge h_{\min}',r'z_g\le z_c+r-h_{\min}',r'z_{g,\max}=@st_allowed@\,\mathrm{m}'])
beat('require','只提高稳性要求，允许上限降低；实际G不会自动移动。','Повыша́ем то́лько тре́бование к осто́йчивости: допусти́мая высота́ снижа́ется, сам G не дви́жется.',end={'required':1.6},anchor='limit',formula=[r'h_{\min}=@st_required@\,\mathrm{m}',r'z_{g,\max}=@st_allowed@\,\mathrm{m}'])
beat('draft','比较更深的吃水：水下体积、C和M改变，允许G高度也随之改变。','При бо́льшей оса́дке меня́ются подво́дный объём, C и M, а с ни́ми — допусти́мая высота́ G.',start={'route':'draft','morph':0},end={'morph':1},anchor='C',condition=('船型、z_g、h_min不变','Фо́рма, z_g и h_min постоя́нны'))
beat('shape_limit','同样的吃水，换一种水下形状，也会改变允许的G高度。','При той же оса́дке друга́я подво́дная фо́рма то́же меня́ет допусти́мую высоту́ G.',start={'route':'shape','morph':0},end={'morph':1},anchor='limit')
answer('Q16','允许重心高度取决于水下形状、吃水和所需稳性。','От подво́дной фо́рмы, оса́дки и необходи́мой осто́йчивости.')

group('Q18','18 · 稳性消失角','18 · У́гол зака́та')
begin('Q18','降低G后，船能保持扶正作用的倾角范围会怎样变化？','Как измени́тся диапазо́н положи́тельной осто́йчивости, е́сли опусти́ть G?',show='arm')
beat('curve','每个倾角对应一个力臂；把它们连起来，就是静稳性曲线。','Ка́ждому углу́ кре́на соотве́тствует плечо́. Соединя́ем то́чки — получа́ем диагра́мму стати́ческой осто́йчивости.',start={'plot':'curve','sweep':True},end={'heel':55},anchor='arm',duration=5)
beat('zero','力臂从正值降到零，这个角就是稳性消失角；不是直立时的零点。','Плечо́ па́дает от положи́тельного значе́ния до нуля́. Э́то у́гол зака́та, а не нулево́й крен.',end={'heel':105},anchor='arm',duration=5)
beat('negative','继续倾斜，力臂变负，这对力转而使船继续倾覆。','При да́льнейшем кре́не плечо́ отрица́тельно: си́лы уже́ повора́чивают су́дно к опроки́дыванию.',end={'heel':120},anchor='arm')
beat('lower_G','船型和排水量不变，降低G；同一个倾角下，复原力臂增大。','Фо́рма и водоизмеще́ние постоя́нны. Опуска́ем G: при том же кре́не плечо́ увели́чивается.',start={'heel':45,'sweep':False,'compare':True},end={'zg':7.7},anchor='G',condition=('船型、排水量不变；无进水','Фо́рма и водоизмеще́ние постоя́нны; без затопле́ния'),formula=[r'l_{\mathrm{new}}=l_{\mathrm{old}}-\Delta z_g\sin\theta'])
beat('zero_shift','新的正力臂延续到更大倾角，所以稳性消失角增大。','Положи́тельное плечо́ сохраня́ется до бо́льшего кре́на. У́гол зака́та увели́чивается.',show='arm',anchor='arm',formula=[r'\theta_{\text{зак}}=@st_zero@^\circ'],controls=['heel','zg'])
answer('Q18','降低重心，稳性消失角增大。','При пониже́нии це́нтра масс у́гол зака́та увели́чится.')

group('Q19','最大力臂','Наибо́льшее плечо́')
begin('Q19','重心高度不变，降低型深，最大扶正力臂会怎样变？','Высота́ G постоя́нна. Как изме́нится наибо́льшее плечо́ при уменьше́нии высоты́ бо́рта?',show='arm')
beat('peak','曲线最高点给出最大力臂；它对应一个具体倾角。','Са́мая высо́кая то́чка криво́й даёт наибо́льшее плечо́ при определённом кре́не.',start={'plot':'peak'},end={'heel':40},anchor='arm',formula=[r'l_{\max}=@st_peak@\,\mathrm{m}'])
beat('deck','先看甲板边缘：船倾斜后，低的一侧逐渐接近水面。','Посмо́трим на кро́мку па́лубы: при кре́не оди́н борт приближа́ется к воде́.',anchor='deck',end={'heel':25})
beat('lower_H','保持B、T和G，降低型深；甲板边缘更早浸水。','Сохраня́ем B, T и G. Уменьша́ем высоту́ бо́рта: кро́мка па́лубы ра́ньше вхо́дит в во́ду.',start={'route':'lower','morph':0,'compare':True},end={'morph':1},anchor='deck',condition=('B、T、z_g不变','B, T и z_g постоя́нны'))
beat('peak_lower','初始水下形状未变，但大角度扶正能力减弱，峰值下降。','Нача́льная подво́дная фо́рма та же, но при больши́х угла́х плечо́ ме́ньше. Ма́ксимум снижа́ется.',anchor='arm',formula=[r'l_{\max}=@st_peak@\,\mathrm{m}',r'h=@st_h@\,\mathrm{m}'])
beat('peak_G','再单独降低G：力臂曲线抬高，最大力臂增大。','Тепе́рь отде́льно опуска́ем G: плечи́ и их ма́ксимум увели́чиваются.',start={'route':'base','morph':0,'zg':8.7},end={'zg':7.7},anchor='G',condition=('船型、排水量不变','Фо́рма и водоизмеще́ние постоя́нны'))
answer('Q19','题目保持G高度不变；减小型深，最大静复原力臂减小。','При неизме́нной высоте́ G уменьше́ние высоты́ бо́рта уменьша́ет ма́ксимум плеча́.')

group('Q20','20 · 横摇周期','20 · Пери́од ка́чки')
begin('Q20','船变窄后摇得快还是慢？先认清一次完整横摇。','Су́дно ста́ло у́же: ка́чка бы́стрее или медле́ннее? Снача́ла уви́дим по́лное колеба́ние.',show='roll')
beat('cycle','从右侧极限到左侧，再回到右侧，才是一个周期。','От пра́вого кра́йнего положе́ния к ле́вому и обра́тно — оди́н пери́од.',start={'plot':'time','clock':0},end={'clock':12},show='roll',anchor='deck',duration=12)
beat('period_formula','扶正能力和质量分布共同决定周期；这里固定等效回转半径。','Пери́од зави́сит от осто́йчивости и распределе́ния масс. Здесь эффекти́вный ра́диус ине́рции постоя́нен.',formula=[r'\tau=\frac{2\pi k_{\mathrm{eff}}}{\sqrt{g h}}',r'\tau=@st_period@\,\mathrm{s}'],condition=('k_eff固定；自由小角度横摇','k_eff постоя́нен; свобо́дная ка́чка при ма́лых угла́х'))
beat('roll_G','只升高G，h减小；在相同条件下，横摇周期变长。','Поднима́ем G: h уменьша́ется. При тех же усло́виях пери́од станови́тся бо́льше.',start={'compare':True,'clock':0},end={'zg':9.2,'clock':14},anchor='G',duration=14)
beat('roll_B','恢复G，再减小船宽；本例h降低，周期增长。','Возвраща́ем G и уменьша́ем ширину́. В э́том приме́ре h снижа́ется, пери́од растёт.',start={'route':'narrow','morph':0,'zg':8.7,'clock':0},end={'morph':1,'clock':16},anchor='deck',duration=16,formula=[r'h=@st_h@\,\mathrm{m}',r'\tau=@st_period@\,\mathrm{s}'])
beat('roll_compare','两船使用同一时钟和相同初始摇幅；右船完成一周期更慢。','О́бщее вре́мя и одина́ковая нача́льная амплиту́да. Пра́вое су́дно заверша́ет колеба́ние медле́ннее.',start={'clock':0},end={'clock':20},anchor='deck',duration=20,controls=['zg'])
answer('Q20','按上述固定条件，船变窄后周期增大；只给B和G还不能唯一确定周期。','При э́тих усло́виях пери́од увели́чится. Одни́х B и G недоста́точно для то́чного отве́та.')

group('Q21','21 · 横摇过急','21 · Ре́зкая ка́чка')
begin('Q21','为什么客船的横稳性也不能过大？看摇动的急缓，不只看角度。','Почему́ осто́йчивость пассажи́рского су́дна не должна́ быть сли́шком большо́й? Смо́трим не то́лько на у́гол.',show='roll',plot='time')
beat('stiff','降低G，提高h：扶正作用更强，周期更短。','Опуска́ем G и повыша́ем h: восстана́вливающий моме́нт сильне́е, пери́од коро́че.',start={'zg':9.7296,'compare':True,'reference_zg':9.7296,'clock':0},end={'zg':6.7296,'clock':16},anchor='G',duration=16,condition=('同初始摇幅、同k_eff','Одина́ковые нача́льная амплиту́да и k_eff'))
beat('acceleration','盯住同一处甲板：摇幅相同，急促横摇带来的加速度更大。','Следи́м за то́чкой на па́лубе: амплиту́да та же, но при ре́зкой ка́чке ускоре́ние бо́льше.',start={'clock':0},end={'clock':16},anchor='deck',duration=16,formula=[r'\ddot\theta=-\frac{g h}{k_{\mathrm{eff}}^2}\theta',r'|\ddot\theta|_{\max}=@st_accel@\,\mathrm{rad/s^2}'],controls=['zg'])
beat('comfort','较大的加速度影响乘客舒适性；稳性充足不等于越大越好。','Большо́е ускоре́ние ухудша́ет самочу́вствие пассажи́ров. Осто́йчивость должна́ быть доста́точной, но не избы́точной.',anchor='deck')
answer('Q21','横稳性过大，横摇会过于急促；并非摇幅必然增大。','Бортова́я ка́чка бу́дет сли́шком ре́зкой. Э́то не означа́ет обяза́тельного ро́ста амплиту́ды.')

lesson=dict(id='stability',initial=BASE,groups=groups,characters_per_second=27,busy_policy='finish')
# Targets follow the generated closed envelope, never an invented curve angle.
hydro=json.loads((ROOT/'content/stability_hydro.json').read_text())
reference=hydro['routes']['base'][0]
curve=[(a,r[2]-8.7*math.sin(math.radians(a))) for a,r in zip(hydro['angles'],reference['hydro'])]
peak=max(curve,key=lambda p:p[1])[0]
zero=next(a+(b-a)*v/(v-w) for (a,v),(b,w) in zip(curve,curve[1:]) if v>0 and w<=0)
period=2*math.pi*8/math.sqrt(9.81*(reference['km']-8.7))
for g in groups:
 for b in g['beats']:
  if b['id']=='ST:curve':b['action']['params']['heel']=30
  if b['id']=='ST:zero':b['action']['params']['heel']=zero
  if b['id']=='ST:negative':b['action']['params']['heel']=zero+18
  if b['id']=='ST:peak':b['action']['params']['heel']=peak
  if b['id']=='ST:waterplane':b['start_params']['heel']=0
  if b['id']=='ST:Mconstruct':
   b['text']='船稍微倾斜，新的浮力作用线与原线相交。';b['words']={'zh':b['text'],'ru':'Су́дно сле́гка наклоня́ется. Но́вая ли́ния си́лы плаву́чести пересека́ет пре́жнюю.'};b['start_params']['show']='M_guides'
  if b['id']=='ST:cycle':b['action']['params']['clock']=period;b['action']['duration']=period
  if b['id'] in ['ST:roll_G','ST:roll_B','ST:stiff']:
   b['action']['params'].pop('clock',None);b['action']['duration']=3
  if b['id']=='ST:stiff':
   b['start_params']['zg']=reference['km']-1;b['start_params']['reference_zg']=reference['km']-1;b['action']['params']['zg']=reference['km']-4
  if b['id']=='ST:Q19:answer':
   b['start_params']={};b.pop('action',None);b['controls']=[]
   b['text']='固定重心，减小型深使最大力臂减小；固定船型，降低重心则使它增大。'
   b['words']={'zh':b['text'],'ru':'При постоя́нном G уменьше́ние высоты́ бо́рта уменьша́ет ма́ксимум плеча́; при той же фо́рме сниже́ние G увеличи́вает его́.'}
 # Give G comparison a fixed-parameter playback before the separate width comparison.
 if g['id']=='Q20':
  i=next(i for i,b in enumerate(g['beats']) if b['id']=='ST:roll_G')
  g['beats'].insert(i+1,dict(id='ST:roll_G_play',text='在相同时间里，高G的船完成的往返更少。',words=dict(zh='在相同时间里，高G的船完成的往返更少。',ru='За одно́ и то же вре́мя су́дно с бо́лее высо́ким G де́лает ме́ньше колеба́ний.'),camera='front',anchor='deck',controls=[],start_params={'clock':0},action={'params':{'clock':18},'duration':18}))
 if g['id']=='Q17':
  g['beats'].insert(1,dict(id='ST:M_axis',text='把正浮时的浮力作用线留在船体上，作为比较。',words=dict(zh='把正浮时的浮力作用线留在船体上，作为比较。',ru='Сохраня́ем в координа́тах су́дна ли́нию си́лы плаву́чести при нулево́м кре́не.'),camera='front',anchor='C',controls=[],start_params={'show':'M_guides'}))
  g['beats'].insert(3,dict(id='ST:M_limit',text='让横倾趋近0°，交点趋近的M，叫初始横稳心。',words=dict(zh='让横倾趋近0°，交点趋近的M，叫初始横稳心。',ru='Крен стре́мится к нулю́. Пре́дел положе́ния то́чки пересече́ния M — нача́льный попере́чный метаце́нтр.'),camera='front',anchor='M',controls=[],start_params={'show':'M_definition'},action={'params':{'heel':.2},'duration':3}))
  next(b for b in g['beats'] if b['id']=='ST:Mheight')['start_params']['show']='M'
  formulas['ST:Mheight']={lang:[{'tex':r'h=GM','linear':'h = GM'},{'tex':r'h=@st_h@\,\mathrm{m}','linear':'h = @st_h@ m'}] for lang in ['zh','ru']}
  i=next(i for i,b in enumerate(g['beats']) if b['id']=='ST:waterplane')
  g['beats'][i:i]=[
   dict(id='ST:radius',text='C到M的距离叫横稳心半径r；z_c是浮心距基线的高度。',words=dict(zh='C到M的距离叫横稳心半径r；z_c是浮心距基线的高度。',ru='Расстоя́ние CM — попере́чный метацентри́ческий ра́диус r. z_c — высота́ це́нтра C от основно́й ли́нии.'),camera='front',anchor='M',controls=[],start_params={'show':'radius'}),
   dict(id='ST:waterplane_definition',text='水面在船体上切出的平面，就是水线面。',words=dict(zh='水面在船体上切出的平面，就是水线面。',ru='Сече́ние ко́рпуса пло́скостью воды́ — пло́щадь ватерли́нии.'),camera='top',anchor='water',controls=[],start_params={'show':'waterplane','heel':0}),
   dict(id='ST:displaced_volume',text='∇是排水体积，也就是刚才看到的整个水下体积。',words=dict(zh='∇是排水体积，也就是刚才看到的整个水下体积。',ru='∇ — объёмное водоизмеще́ние, весь подво́дный объём ко́рпуса.'),camera='overview',anchor='C',controls=[],start_params={'show':'wet'})]
  formulas['ST:radius']={lang:[{'tex':r'r=CM','linear':'r = CM'},{'tex':r'h=z_c+r-z_g','linear':'h = z_c + r - z_g'}] for lang in ['zh','ru']}
 if g['id']=='foundation':
  i=next(i for i,b in enumerate(g['beats']) if b['id']=='ST:G')+1
  g['beats'].insert(i,dict(id='ST:baseline',text='基线是船体高度的零点；重心高度从这里量到G。',words=dict(zh='基线是船体高度的零点；重心高度从这里量到G。',ru='Осно́вная ли́ния — нулево́й у́ровень высо́т. От неё измеря́ем высоту́ G.'),camera='front',anchor='baseline',controls=[],start_params={'show':'baseline'}))
(ROOT/'content/stability_course.json').write_text(json.dumps(lesson,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'content/stability_latex.json').write_text(json.dumps(formulas,ensure_ascii=False,indent=2),encoding='utf-8')
print('Stability beats',sum(len(g['beats']) for g in groups))
