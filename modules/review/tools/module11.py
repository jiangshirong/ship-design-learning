"""Module 11 original tests, subject routing and continuous teaching content."""
import copy,json,re,zipfile,hashlib,xml.etree.ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
COURSE=ROOT.parents[2]
def bi(zh,ru):return dict(zh=zh,ru=ru)
def norm(s):return s.lower().replace('\u0301','').replace('ё','е')
ROWS=[
('Зави́сит ли фо́рма ми́дель-шпанго́ута от коэффицие́нта полноты́ β?','舯剖面的形状是否与丰满系数β有关？','有关，但同一个β可以对应不同形状。','Да. Но при одно́м β фо́рма мо́жет быть ра́зной.'),
('С како́й це́лью у тихохо́дных судо́в применя́ют прямы́е и́ли во́гнутые ватерли́нии в носово́й оконе́чности?','低速船为什么在艏端采用直线或凹形水线？','减小兴波阻力。','Для уме́ньшения волново́го сопротивле́ния.'),
('Каку́ю фо́рму шпанго́утов применя́ют для носово́й оконе́чности кру́пных тихохо́дных судо́в и почему́?','大型低速船的艏部采用什么横剖面形状，为什么？','适度U形，用于减小波浪中的附加阻力。','Уме́ренно U-обра́зную, для уме́ньшения сопротивле́ния на волне́нии.'),
('Носово́й бульб применя́ют для того́, что́бы:','采用球鼻艏是为了什么？','减小兴波阻力。','Уме́ньшить волново́е сопротивле́ние.'),
('Како́й вид кормы́ применя́ется для улучше́ния взаимоде́йствия ко́рпуса и гребно́го винта́?','采用哪一种艉型来改善船体与螺旋桨的相互作用？','开放式艉部。','Откры́тая корма́.'),
('Для чего́ применя́ется носова́я надстро́йка — бак?','艏部上层建筑——艏楼——有什么用途？','减少甲板上浪和溅水。','Для уме́ньшения залива́ния и забры́згивания па́лубы.'),
('Каковы́ мо́гут быть после́дствия примене́ния чрезме́рного разва́ла шпанго́утов в надво́дной ча́сти в носу́?','艏部水线上方横剖面的外飘过大，可能有什么后果？','可能发生强烈的波浪冲击。','Возмо́жны си́льные уда́ры волн.'),
('Мо́жно ли испо́льзовать аффи́нное преобразова́ние теорети́ческого чертежа́, е́сли:','在什么条件下可以使用型线图的仿射变换？','若丰满系数保持不变。','Е́сли коэффицие́нты полноты́ не изменя́ются.'),
]
CONDITIONS={
2:bi('原题写“低速船”；讲义将直线或略凹艏水线用于较高速船，此处按讲义解释目的。','В вопро́се — тихохо́дные суда́; в те́ксте мо́дуля — быстрохо́дные. Отве́т дан по те́ксту мо́дуля.'),
4:bi('减阻效果取决于球鼻艏形状与航速、吃水的匹配。','Результа́т зави́сит от фо́рмы бу́льба, ско́рости и оса́дки.'),
}
BASE=dict(topic='hullform',qid='M11Q01',phase='overview',progress=0.,bilge=0.,waterline=0.,bow_v=0.,bulb=0.,closed_stern=0.,flare=0.,scale_l=1.,scale_b=1.,scale_t=1.,lines=0.,station=0.,draft=10.88,wave=0.,forecastle=0.,sheer=0.,superstructure=0.)

def apply(courses,formulas,bank,readings):
    path=COURSE/'7a/Modul_11-тест.docx'
    with zipfile.ZipFile(path) as z:
        ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
        ps=[''.join(p.itertext()).strip() for p in ET.fromstring(z.read('word/document.xml')).findall('.//w:p',ns)]
    raw={int(m[1]):m[2] for p in ps if (m:=re.match(r'(\d+)\.\s*(.*)',p))}
    for n,(ru,zh,azh,aru) in enumerate(ROWS,1):
        qid=f'M11Q{n:02}'
        # Punctuation-only normalization: preserve the original em dash spelling in source.
        assert norm(re.sub(r'\s*[-—]\s*','-',ru))==norm(re.sub(r'\s*[-—]\s*','-',raw[n])),(n,raw[n],ru)
        bank.append(dict(id=qid,number=n,title_zh=zh,question_original=raw[n],question_ru=ru,sources=[f'7a-{n}']))
        readings[qid]=dict(id=qid,number=n,question_ru=ru,translation=zh,answer=bi(azh,aru),sources=[f'7a-{n}'],source=dict(question=f'7a/Modul_11-тест.docx #{n}',module='7a/Modul_11. ТЧ.docx',boundary='Original question retained; lecture heading says Module 12.'))
        if n in CONDITIONS:readings[qid]['condition']=CONDITIONS[n]
    c=dict(id='hullform',title=bi('船体型线与阻力','О́бводы и сопротивле́ние'),goal=bi('看懂船体线条怎样表示形状，以及艏艉形状为什么影响阻力。','Поймём ли́нии ко́рпуса и влия́ние фо́рмы на сопротивле́ние.'),initial=BASE.copy(),questions=[f'M11Q{i:02}' for i in [1,2,3,4,5,8]],groups=[],question_targets={},characters_per_second=25,foundation_end='M11:foundation_end')
    def group(course,qid,title,rows):
        state={**BASE,'topic':course['id'],'qid':qid}
        beats=[]
        for key,phase,zh,ru,patch,action,tex in rows:
            state.update(patch or {});state['phase']=phase
            b=dict(id=f'M11:{qid}:{key}',text=zh,words=bi(zh,ru),start_params=copy.deepcopy(state),camera='overview',anchor='ship')
            if qid in readings and 'condition' in readings[qid] and key in ['use','conditions','answer']:b['condition']=readings[qid]['condition']
            if action:b['action']=dict(params=action,duration=3.);state.update(action)
            if tex:
                formulas[b['id']]={lang:[dict(tex=t,linear=t) for t in tex] for lang in ['zh','ru']}
                if key in ['formula','conditions']:
                    rule={'kind':'formula','teacher_reference':'7a/Modul_11. ТЧ.docx'}
                    b.update(source_rule=rule,source_rows={str(i):rule for i in (range(len(tex)) if key=='conditions' else [0])},source_phrase=copy.deepcopy(b['words']))
            beats.append(b)
        if qid in readings:
            r=readings[qid]
            b=dict(id=f'M11:{qid}:answer',text=r['answer']['zh'],words=r['answer'],start_params=copy.deepcopy(state),anchor='ship',recap=bi(r['translation']+'\n'+r['answer']['zh'],r['question_ru']+'\n'+r['answer']['ru']))
            if qid in CONDITIONS: b['condition']=CONDITIONS[qid]
            if 'condition' in r:b['condition']=r['condition']
            beats.append(b);course['question_targets'][qid]=beats[0]['id']
        course['groups'].append(dict(id=qid,title=bi(title,title),beats=beats))
        return beats
    bs=group(c,'foundation','先认识型线',[
      ('goal','overview',c['goal']['zh'],c['goal']['ru'],{},None,None),
      ('waterline','lines','水平面与船壳相交，得到水线。','Горизонта́льная пло́скость пересека́ет ко́рпус: получа́ем ватерли́нию.',{},dict(lines=1.),None),
      ('sections','lines','横剖线表示船壳轮廓；它不是一根实际肋骨。','Теорети́ческий шпанго́ут — ли́ния ко́рпуса, а не дета́ль набо́ра.',{},dict(station=1.),None),
      ('end','drawing','把同一船壳向三个方向投影，得到型线图。','Прое́кции ко́рпуса в трёх направле́ниях образу́ют теорети́ческий чертёж.',{},None,None)])
    bs[-1]['id']=c['foundation_end']
    group(c,'M11Q01','舯剖面与β',[
      ('object','midship','固定船宽和吃水，先看船中的水下横剖面。','Фикси́руем шири́ну и оса́дку; рассмо́трим ми́дель-шпанго́ут.',dict(lines=0.,station=1.),None,None),
      ('area','midship','舭部更圆，水下横剖面面积随之减小。','При закругле́нии скулы́ пло́щадь сече́ния уменьша́ется.',{},dict(bilge=1.),None),
      ('formula','midship','β是水下横剖面面积与参考矩形面积的比。','β — отноше́ние пло́щади сече́ния к пло́щади прямоуго́льника.',{},None,[r'\beta=\frac{A_M}{BT}',r'A_M=@m11_area@\,\mathrm{m^2}',r'\beta=@m11_beta@']),
      ('limits','midship','β只描述面积比例，不能唯一确定整个剖面。','β задаёт отноше́ние площаде́й, но не всю фо́рму сече́ния.',{},None,None)])
    group(c,'M11Q02','艏部水线',[
      ('convex','waterline','从上方看：凸形水线使艏部较丰满。','Ви́дим све́рху: вы́пуклая ватерли́ния даёт бо́лее по́лный нос.',dict(lines=1.,bilge=0.),None,None),
      ('straight','waterline','把艏部水线变直，观察入口形状的变化。','Вы́прямим носову́ю ватерли́нию.',{},dict(waterline=.5),None),
      ('concave','waterline','再变成略凹形，使艏部水线更尖削。','Сде́лаем ватерли́нию сле́гка во́гнутой.',{},dict(waterline=1.),None),
      ('use','waterline','讲义用直线或略凹水线减小较高速船的兴波阻力。','Для быстрохо́дных судо́в э́та фо́рма уменьша́ет волново́е сопротивле́ние.',{},None,None)])
    group(c,'M11Q03','U形与V形',[
      ('V','bowsection','取相同的艏部位置，先看较尖的V形剖面。','В одно́м носово́м сече́нии рассмо́трим V-обра́зную фо́рму.',dict(waterline=0.,bow_v=1.,station=1.),None,None),
      ('U','bowsection','换为适度U形；变化的是实际船壳。','Перейдём к уме́ренно U-обра́зной фо́рме ко́рпуса.',{},dict(bow_v=0.),None),
      ('reason','bowsection','大型船在波浪中，V形艏剖面可能产生较大的附加阻力。','У кру́пных судо́в V-обра́зная фо́рма мо́жет увеличи́ть сопротивле́ние на волне́нии.',{},None,None)])
    group(c,'M11Q04','球鼻艏',[
      ('grow','bulb','在水下艏端形成球鼻艏，观察它与船壳的连接。','Пока́жем носово́й бульб и его́ соедине́ние с ко́рпусом.',dict(station=0.),dict(bulb=1.),None),
      ('waves','bulb','球鼻艏改变艏部波系，匹配时可减小兴波阻力。','Бульб меня́ет носовы́е во́лны и мо́жет уме́ньшить волново́е сопротивле́ние.',{},dict(wave=1.),None)])
    group(c,'M11Q05','艉部与螺旋桨',[
      ('closed','stern','先看封闭式艉部：舵下方有连接船体的支承。','В закры́той корме́ есть ни́жняя опо́ра руля́.',dict(closed_stern=1.,bulb=1.,wave=0.),None,None),
      ('open','stern','移去下部支承，形成开放式艉部。','Уберём ни́жнюю опо́ру: получа́ем откры́тую корму́.',{},dict(closed_stern=0.,bulb=1.),None),
      ('flow','stern','课程采用开放式艉部，以改善船体与螺旋桨的相互作用。','Откры́тая корма́ улучша́ет взаимоде́йствие ко́рпуса и гребно́го винта́.',{},dict(wave=1.),None)])
    group(c,'M11Q08','型线仿射变换',[
      ('prototype','affine','从母型型线出发，只按各方向的比例改变坐标。','Изменя́ем координа́ты прототи́па по направле́ниям.',dict(lines=1.,wave=0.,bulb=1.),None,None),
      ('length','affine','沿纵向伸长；同一组横剖线之间的距离一起改变。','Увели́чим длину́ и расстоя́ния ме́жду сече́ниями.',{},dict(scale_l=1.08),[r'x=l x_0',r'l=\frac{L}{L_0}']),
      ('width','affine','再增大船宽；横向坐标按同一比例改变。','Увели́чим шири́ну: изменя́ются попере́чные координа́ты.',{},dict(scale_b=1.12),[r'y=b y_0',r'b=\frac{B}{B_0}']),
      ('draft','affine','最后改变竖向尺度；水线的高度间隔随之改变。','Изме́ним вертика́льный масшта́б и расстоя́ния ме́жду ватерли́ниями.',{},dict(scale_t=1.10),[r'z=t z_0',r't=\frac{T}{T_0}']),
      ('conditions','affine','尺寸与体积改变，但δ、α、β保持不变。','Разме́ры и объём меня́ются; δ, α, β не изменя́ются.',{},None,[r'V=lbtV_0',r'\delta=\delta_0',r'\alpha=\alpha_0',r'\beta=\beta_0'])])
    # Russian stage captions are concise, not Chinese placeholders.
    ru_titles=['Осно́вы','Ми́дель и β','Носовы́е ватерли́нии','U и V','Носово́й бульб','Корма́ и винт','Преобразова́ние']
    for g,ru in zip(c['groups'],ru_titles):g['title']['ru']=ru
    courses.insert(next(i for i,x in enumerate(courses) if x['id']=='cargo')+1,c)
    free=next(x for x in courses if x['id']=='freeboard')
    group(free,'M11Q06','艏楼的作用',[
      ('before','bow_waves','设置艏楼前，迎浪可能越过甲板。','Встре́чная волна́ мо́жет залива́ть па́лубу.',dict(forecastle=0.,draft=8.),None,None),
      ('protect','bow_waves','升高艏楼甲板，减少上浪和溅水。','Бак уменьша́ет залива́ние и забры́згивание па́лубы.',{},dict(forecastle=1.),None)])
    group(free,'M11Q07','艏部外飘',[
      ('locate','flare','外飘指水线上方的舷侧向外张开。','Разва́л — расшире́ние бо́рта вы́ше ватерли́нии.',dict(forecastle=0.,flare=0.,draft=8.),None,None),
      ('excess','flare','只加大艏部水线上方的外飘，水下形状保持不变。','Увели́чим развал вы́ше воды́, не меня́я подво́дную часть.',{},dict(flare=1.),None),
      ('impact','flare','过度外飘可能在迎斜浪时受到强烈冲击。','Чрезме́рный развал мо́жет вызыва́ть си́льные уда́ры волн.',{},None,None)])
    for g,ru in zip(free['groups'][-2:],['Назначе́ние ба́ка','Разва́л носовы́х шпанго́утов']):g['title']['ru']=ru
    # Insert after the existing bow-height alternatives, preserving every old ID.
    free['questions'] += ['M11Q06','M11Q07']
    for course in [c,free]:
        for qid in course['questions']:
            q=next(q for q in bank if q['id']==qid)
            q.update(topic=course['id'],target=course['question_targets'][qid])
            readings[qid].update(topic=course['id'],target=q['target'])
    sources=dict(test=str(path.relative_to(COURSE)),test_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),lecture='7a/Modul_11. ТЧ.docx',discrepancies=['Test title: Module 11; lecture heading: Module 12.','7a-2 says slow ships; lecture assigns straight/slightly concave bow waterlines to faster ships.','7a-8 is an open-ended conditional question; the answer supplies the condition.'],boundary='Hull variants are qualitative instructional geometry, not certified T2 lines or CFD results. Bulb waves are qualitative interference, not a resistance calculation.')
    sources['bulb_supplement']={'title':'US Naval Academy, EN400 Chapter 7, Resistance and Powering of Ships, §7.6.3','url':'https://www.usna.edu/NAOE/_files/documents/Courses/EN400/02.07_Chapter_7.pdf','use':'Supplementary conceptual explanation of bow-wave interference and operating-speed matching; not a teacher-supplied calculation rule.'}
    (ROOT/'content/module11_sources.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2),encoding='utf-8')

def glossary():
    p=ROOT/'content/glossary.json';entries=json.loads(p.read_text(encoding='utf-8'))
    entries=[e for e in entries if e['id']!='m11_скола']
    rows='''
ми́дель-шпанго́ут|мидель-шпангоута;мидель-шпангоут|舯剖面；船中横剖面
коэффицие́нт полноты́|коэффициента полноты;коэффициенты полноты|丰满系数
фо́рма|форма;форму;формы;формой|形状
шпанго́ут|шпангоута;шпангоутов;шпангоут;шпангоуты|肋骨；型线图中的横剖线
скула́|скулы;скула|舭部；船底与舷侧的过渡部分
зави́сеть|зависит;зависеть|取决于
применя́ть|применяют;применять;применения|采用；应用
применя́ться|применяется;применяться|被采用；应用于
вид|вид;вида|类型；种类
тихохо́дный|тихоходных;тихоходный;тихоходные|低速的
быстрохо́дный|быстроходные;быстроходных|高速的
прямо́й|прямые;прямой;прямая|直的
во́гнутый|вогнутые;вогнутой;вогнутый|凹形的
вы́пуклый|выпуклая;выпуклые|凸形的
ватерли́ния|ватерлинии;ватерлинию;ватерлиния|水线
носова́я оконе́чность|носовой оконечности;носовую оконечность|艏端；艏部
оконе́чность|оконечности;оконечность|船体端部
кру́пный|крупных;крупный;крупные|大型的
уме́ренно|умеренно|适度地
U-обра́зный|u-образную;u-образная;u-образный|U形的
V-обра́зный|v-образную;v-образная;v-образный|V形的
носова́я надстро́йка|носовая надстройка;носовой надстройки|艏部上层建筑
носово́й|носовой;носовых;носовая|艏部的
носово́й бульб|носовой бульб;носового бульба|球鼻艏
бульб|бульб;бульба|球鼻艏的球鼻部分
волново́е сопротивле́ние|волновое сопротивление;волнового сопротивления|兴波阻力
сопротивле́ние|сопротивление;сопротивления|阻力
волне́ние|волнении;волнение;волнения|波浪；海面波动
волна́|волн;волны;волна;волной|波浪
корма́|кормы;корма;корме|船艉
откры́тая корма́|открытая корма;открытой кормы|开放式艉部
гребно́й винт|гребного винта;гребной винт|螺旋桨
взаимоде́йствие|взаимодействия;взаимодействие|相互作用
улучше́ние|улучшения;улучшение|改善
залива́ние|заливания;заливание|甲板上浪；海水漫上甲板
забры́згивание|забрызгивания;забрызгивание|溅水；浪花飞溅
чрезме́рный|чрезмерного;чрезмерный|过度的
разва́л|развала;развал|外飘；舷侧向外张开
надво́дный|надводной;надводный|水面以上的
после́дствие|последствия;последствие|后果
уда́р|удары;ударов;удар|冲击
си́льный|сильные;сильный|强烈的
аффи́нное преобразова́ние|аффинное преобразование;аффинного преобразования|仿射变换
преобразова́ние|преобразование;преобразования|变换
теорети́ческий чертёж|теоретического чертежа;теоретический чертёж|型线图
изменя́ться|изменяются;изменяться|发生改变
уме́ньшение|уменьшения;уменьшение|减小
па́луба|палубы;палубу;палуба|甲板
разли́чный|разной;разные;различный|不同的
полуширота́|полуширота|半宽水线图；型线图的水平投影
ско́рость|скорости;скорость|航速
уда́р волн|удары волн;ударов волн|波浪冲击
'''
    for line in rows.strip().splitlines():
        ru,als,zh=line.split('|');aliases=[norm(a) for a in als.split(';')]
        old=next((x for x in entries if norm(x['ru'])==norm(ru)),None)
        if old:
            old['aliases']=list(dict.fromkeys(old['aliases']+aliases))
            if old['id'].startswith('m11_'):old.update(ru=ru,zh=zh,meaning=zh)
        else:entries.append(dict(id='m11_'+norm(ru).replace(' ','_'),ru=ru,zh=zh,meaning=zh,aliases=aliases,study=True))
    for e in entries:
        if e['id']=='m11_применять':e['aliases']=[a for a in e['aliases'] if a!='применяется']
    # No changes to established IDs, definitions or excluded basic vocabulary.
    p.write_text(json.dumps(entries,ensure_ascii=False,indent=2),encoding='utf-8')
