"""Authored short bilingual teaching beats, backed by course_calculations outputs."""
import json,copy,re,sys
from pathlib import Path
from course_calculations import ROOT,build,rnd
DATA=build();S=DATA['steps'];OLD=json.loads((ROOT/'content/authoring/legacy_courses.json').read_text('utf8'));OLD_BY={c['id']:c for c in OLD}
LATEX=json.loads((ROOT/'content/authoring/legacy_latex_source.json').read_text('utf8'))
INPUT=json.loads((ROOT/'content/confirmed/inputs.json').read_text('utf8'))['cases']
def bi(zh,ru):return dict(zh=zh,ru=ru)
def linear_tex(tex):
    """Copyable linear notation: preserve grouping of fractions and exponents."""
    tex=re.sub(r'\\(?:begin|end)\{gathered\}', '', tex).replace('\\\\',' ')
    pos=0
    def parse(stop=False):
        nonlocal pos
        out=''
        while pos<len(tex):
            ch=tex[pos];pos+=1
            if ch=='}' and stop:return out
            if ch=='{':out+='('+parse(True)+')'
            elif ch=='\\':
                m=re.match(r'[A-Za-z]+',tex[pos:]);command=m[0] if m else tex[pos:pos+1];pos+=len(command)
                if command in ['frac','sqrt','mathrm','text']:
                    degree=''
                    if command=='sqrt' and pos<len(tex) and tex[pos]=='[':
                        end=tex.index(']',pos);degree=tex[pos+1:end];pos=end+1
                    args=[]
                    for _ in range(2 if command=='frac' else 1):
                        if pos<len(tex) and tex[pos]=='{':pos+=1;args.append(parse(True))
                        else:args.append('')
                    out+=f'(({args[0]})/({args[1]}))' if command=='frac' else (f'root({degree or 2},{args[0]})' if command=='sqrt' else args[0])
                else:out+={'cdot':' * ','times':' * ','quad':' ',';':' ', ',':' ','left':'','right':'','approx':' ~= ','le':' <= ','ge':' >= ','longrightarrow':' -> ','propto':' proportional to ','%':'%','sum':'sum','nabla':'volume','Sigma':'sum','delta':'delta','alpha':'alpha','beta':'beta','zeta':'zeta','ell':'ell','rho':'rho','mu':'mu','Delta':'Delta'}.get(command,command)
            else:out+=ch
        return out
    return parse().strip()
def course(id,zh,ru,scene='load'):
    return dict(id=id,title=bi(zh,ru),initial=dict(scene=scene,show_load=False,show_centre=False,dimensions=False,draft=10,cutaway_amount=0,b01_reveal=0,cargo_progress=0,trim_progress=0),groups=[],characters_per_second=28,resume_aliases={})
def group(c,id,zh,ru):
    g=dict(id=id,title=bi(zh,ru),beats=[]);c['groups'].append(g);return g
def beat(g,id,zh,ru,tex=(),label=None,visual='',params=None,action=None,camera='overview',anchor='ship',step=None):
    b=dict(id=id,text=zh,words=bi(zh,ru),lines=list(tex),layout='calculation' if tex else 'model',visual=visual,camera=camera,anchor=anchor,scene_params=params or {})
    b['calculation_step']=step or (g['id'] if re.fullmatch('[BLT][0-9]{2}',g['id']) else '')
    if b['calculation_step']:b['source_ref']='confirmed/steps.json#'+b['calculation_step']
    if label:b['record_label']=label
    if action:
        b['action']=dict(params=action,duration=2.2);b['defer_record']=bool(tex)
        for key in action:
            if key in b['scene_params']:b.setdefault('start_params',{})[key]=b['scene_params'].pop(key)
    LATEX[id]={lang:[dict(linear=linear_tex(t),tex=(re.sub(r'(?<=\d)\.(?=\d)',r'{,}',t) if lang=='ru' else t)) for t in tex] for lang in ['zh','ru']}
    g['beats'].append(b);return b
def num(x,n=2):return f'{x:.{n}f}'
def unit(x,u='t',n=2):return num(x,n)+r'\,\mathrm{'+u+'}'
def intro():
    c=copy.deepcopy(OLD_BY['basics']);c['groups']=c['groups'][:3]
    parts=c['groups'][0]
    beat(parts,'parts:waterline','船体与水面的交线，就是水线。','Ли́ния пересече́ния ко́рпуса с водо́й — ватерли́ния.',params={'part_focus':'','cutaway_amount':0},camera='baseline',anchor='water')
    baseline=c['groups'][1]
    b=beat(baseline,'baseline:plane','基本平面是船底处的高度零基准：z = 0。','Основна́я пло́скость у дни́ща — нулево́й у́ровень высо́т: z = 0.',params={'base_plane':True,'baseline_mode':False,'plane_focus':True,'water':False,'cutaway_amount':0},camera='base_plane',anchor='base_plane')
    baseline['beats'].remove(b);baseline['beats'].insert(0,b)
    baseline['beats'][1]['words']=bi('侧视图中，基本平面看成一条基线，记为 z = 0。','Сбо́ку осно́вная пло́скость ви́дна как осно́вная ли́ния: z = 0.')
    dims=c['groups'][2];drafts=baseline['beats'][2:];baseline['beats']=baseline['beats'][:2]
    dims['beats']=[]
    beat(dims,'dimensions:length','船长 L 沿船的前后方向量。','Длину́ L измеря́ем вдоль су́дна.',params={'dimensions':True,'dimension_kind':'L','dimension_reveal':0,'cutaway_amount':0},action={'dimension_reveal':1},camera='baseline')
    beat(dims,'dimensions:beam','船宽 B 沿左右舷之间量。','Ширину́ B измеря́ем ме́жду борта́ми.',params={'dimensions':True,'dimension_kind':'B','dimension_reveal':0,'cutaway_amount':0},action={'dimension_reveal':1},camera='deck')
    # Scene overlays must not override the animated dimension_reveal parameter.
    for b in dims['beats']:b['start_params']={'dimension_reveal':0}
    dims['beats']+=drafts
    for g in c['groups']:
        for b in g['beats']:LATEX[b['id']]={'zh':[],'ru':[]};b['lines']=[]
    return c
def foundation():
    c=course('foundation','基础题 · 第 5 方案','Зада́чи · Вариа́нт 5');g=group(c,'B01','横剖面丰满系数','Полнота́ миде́ля')
    beat(g,'B01:goal','求船中横剖面有多饱满：先在船中部横切一刀。','Найдём полноту́ миде́ля: разре́жем су́дно поперёк посереди́не.',params={'section_plane':True},action={'b01_reveal':1},camera='cutaway')
    beat(g,'B01:area','水下剖面面积为 45 平方米。','Пло́щадь подво́дного сече́ния — 45 м².',[r'A_M=45\,\mathrm{m}^2'],bi('B01 · 给定剖面积','B01 · За́данная пло́щадь'),visual='section',params={'b01_reveal':1})
    beat(g,'B01:width','船宽 B 是 15 米，标在剖面两侧之间。','Шири́на B ме́жду борта́ми равна́ 15 м.',[r'B=15\,\mathrm m'],visual='section',action={'b01_reveal':2})
    beat(g,'B01:draft','吃水 T 是 5 米，从基线量到水线。','Оса́дка T от осно́вной ли́нии до ватерли́нии равна́ 5 м.',[r'T=5\,\mathrm m'],visual='section',action={'b01_reveal':3})
    beat(g,'B01:rectangle','用 B 和 T 围出参考矩形。','Постро́им опи́санный прямоуго́льник со сторона́ми B и T.',[r'A_{\mathrm{rect}}=B\cdot T',r'=15\cdot5=75\,\mathrm m^2'],visual='section',action={'b01_reveal':4})
    beat(g,'B01:ratio','实际面积除以矩形面积，得到横剖面丰满系数。','Разде́лим пло́щадь сече́ния на пло́щадь прямоуго́льника.',[r'\beta=\frac{A_M}{BT}',r'=\frac{45}{75}=0.60'],visual='section',action={'b01_reveal':5})
    beat(g,'B01:meaning','水下剖面占参考矩形的 60%。','Подво́дное сече́ние занима́ет 60% прямоуго́льника.',[r'\beta\cdot100\%=60\%'],visual='section')
    g=group(c,'B02','还能装多少货','Ско́лько гру́за мо́жно приня́ть')
    beat(g,'B02:goal','第二港还能装多少货？吨数和舱容都不能超限。','Ско́лько гру́за взять во второ́м порту́? Ограни́чены ма́сса и объём.',[r'P_{\max}=15950\,\mathrm t',r'W_{\max}=20640\,\mathrm m^3'],bi('B02 · 两个上限','B02 · Два преде́ла'),visual='cargo_limits',params={'cargo_progress':0})
    beat(g,'B02:given','这些是第一港已装的货物，共 10950 吨。','Э́то груз пе́рвого по́рта: всего́ 10950 т.',[r'P_1=10950\,\mathrm t'])
    beat(g,'B02:factor1','每吨货物占 1.32 立方米，这叫装载因数。','Ка́ждая то́нна занима́ет 1.32 м³: э́то уде́льный погру́зочный объём.',[r'\mu_1=1.32\,\mathrm{m^3/t}'])
    for id,zh,ru,tex,progress in [
        ('mass','先看吨数：载货上限减去已装质量。','Снача́ла ма́сса: вычтем уже́ при́нятый груз из преде́ла.',[r'P_{\mathrm{rest}}=15950-10950',r'=5000\,\mathrm t'],1),
        ('volume1','再看空间：质量乘每吨占用的容积。','Тепе́рь объём: умно́жим ма́ссу на объём одно́й то́нны.',[r'W_1=P_1\mu_1',r'=10950\cdot1.32=14454\,\mathrm m^3'],2),
        ('volume2','从总舱容中扣掉已占空间。','Вычтем за́нятый объём из по́лной вмести́мости.',[r'W_{\mathrm{rest}}=20640-14454',r'=6186\,\mathrm m^3'],3),
        ('bound','剩余空间除以每吨所需空间，得到可装吨数。','Разде́лим свобо́дный объём на объём одно́й то́нны.',[r'P_{2,V}=\frac{W_{\mathrm{rest}}}{\mu_2}',r'=\frac{6186}{1.21}=5112.40\,\mathrm t'],4),
        ('answer','两个上限取较小值：第二港装入 5000 吨。','Берём ме́ньший преде́л: во второ́м порту́ гру́зим 5000 т.',[r'P_2=\min(5000,5112.40)',r'=5000\,\mathrm t'],5),
        ('check','质量先到上限，舱容还剩 136 立方米。','Преде́л по ма́ссе дости́гнут; остаётся 136 м³.',[r'W_{\mathrm{free}}=6186-5000\cdot1.21',r'=136\,\mathrm m^3'],6)]:
        if id=='bound':beat(g,'B02:factor2','第二港的货物，每吨需要 1.21 立方米。','Груз второ́го по́рта занима́ет 1.21 м³ на то́нну.',[r'\mu_2=1.21\,\mathrm{m^3/t}'])
        beat(g,'B02:'+id,zh,ru,tex,action={'cargo_progress':progress,**({'cargo_second_fraction':1} if id=='answer' else {})})
    for b in g['beats']:
        b.update(visual='',camera='cargo_loading',anchor='load')
        b['scene_params'].update(cargo_lesson=True,cargo_phase=b['id'].split(':')[1],cutaway_amount=1,section_plane=False,water=False)
    g=group(c,'B03','艏艉吃水与纵倾','Оса́дка и диффере́нт')
    beat(g,'B03:goal','已知艉吃水 3.5 米，求艏吃水和平均吃水。','Оса́дка кормо́й 3.5 м; найдём оса́дку но́сом и сре́днюю.',[r'T_k=3.5\,\mathrm m'],bi('B03 · 吃水','B03 · Оса́дка'),visual='trim',params={'trim_progress':0})
    beat(g,'B03:bow','艏倾 2.8 米：船头比船尾吃水深 2.8 米。','Диффере́нт на нос 2.8 м: оса́дка но́сом на 2.8 м бо́льше оса́дки кормо́й.',visual='trim',action={'trim_progress':1})['layout']='calculation'
    beat(g,'B03:sign','纵倾用艉减艏；艏更深，所以本题为负。','Диффере́нт — оса́дка кормо́й ми́нус оса́дка но́сом; на нос — отрица́тельный.',[r'd=T_k-T_n=-2.8\,\mathrm m'],visual='trim')
    beat(g,'B03:fore','移项得艏吃水 6.3 米。','Оса́дка но́сом равна́ 6.3 м.',[r'T_n=T_k-d',r'=3.5-(-2.8)=6.3\,\mathrm m'],visual='trim',action={'trim_progress':2})
    beat(g,'B03:mean','本题平均吃水取艏艉吃水的算术平均。','Сре́дняя оса́дка зде́сь — полусу́мма оса́док но́сом и кормо́й.',[r'T_{\mathrm{mean}}=\frac{T_k+T_n}{2}',r'=\frac{3.5+6.3}{2}=4.9\,\mathrm m'],visual='trim',action={'trim_progress':3})
    return c
def finish(courses):
    from teaching_flow import improve
    improve(courses,beat,bi,S)
    from course_notation import apply
    apply(courses,LATEX,linear_tex,ROOT)
    from curriculum_repairs import apply as repair_curriculum
    repair_curriculum(courses,LATEX,linear_tex,ROOT)
    from chapter_refinements import apply as refine_chapters
    refine_chapters(courses,LATEX)
    # Map every old identity to its corresponding new phase, without guessing indices.
    for c in courses:
        old=OLD_BY.get(c['id'],{})
        for g in old.get('groups',[]):
            mapping={'fullness':'B01','cargo':'B02','trim':'B03','load-definition':'L01','load-fuel':'L01','load-ship':'L04','load-centre':'L06','t2-input':'task','t2-supply':'T01','t2-coefficients':'T02','t2-equation':'T03','t2-root':'T04','t2-back':'T05','dim-length':'T08','dim-volume':'T11','dim-equations':'T12','dim-eliminate':'T13','dim-check':'T14'}
            target=next((ng['beats'][0]['id'] for ng in c['groups'] if ng['id']==mapping.get(g['id'],g['id'])),c['groups'][0]['beats'][0]['id'])
            for b in g['beats']:c['resume_aliases'].setdefault(b['id'],target)
        ids={b['id'] for g in c['groups'] for b in g['beats']}
        c['resume_aliases']={k:v for k,v in c['resume_aliases'].items() if k not in ids}
    (ROOT/'content/manifest.json').write_text(json.dumps(dict(schema_version=2,chapters=len(courses),beats=sum(len(g['beats']) for c in courses for g in c['groups']),calculation_steps=list(S),source='已确认作业计算流程',ost_in_curriculum=False,formula_renderer='MathJax SVG / DPITexture',formula_em=30),ensure_ascii=False,indent=2),'utf8')
    (ROOT/'content/courses.json').write_text(json.dumps(courses,ensure_ascii=False,indent=2),'utf8')
    used={b['id'] for c in courses for g in c['groups'] for b in g['beats']}
    (ROOT/'content/latex_source.json').write_text(json.dumps({k:v for k,v in LATEX.items() if k in used or k.startswith('_')},ensure_ascii=False,indent=2),'utf8')
    nodes=[]
    positions=[(420,85),(420,260),(420,435),(420,610),(420,785),(880,785)]
    assignments={'foundation':'1p','load':'1p','mass':'2a','dimensions':'2p'}
    subjects={
        'foundation':bi('独立题目','Незави́симые зада́чи'),
        'load':bi('四货舱多用途船','Многоцеле́вое, 4 трю́ма'),
        'mass':bi('Т2 油船','Та́нкер Т2'),
        'dimensions':bi('Т2 油船','Та́нкер Т2'),
    }
    for c,(x,y) in zip(courses,positions):nodes.append(dict(id=c['id'],course=c['id'],step=c['groups'][0]['beats'][0]['id'],title={lang:title.split('·',1)[0].strip() for lang,title in c['title'].items()},assignment=assignments.get(c['id'],''),subject=subjects.get(c['id'],bi('','')),position=[x,y]))
    edges=[]
    for a,b in zip(nodes[:4],nodes[1:5]):
        x,y=a['position'];xx,yy=b['position'];edges.append({'from':a['id'],'to':b['id'],'kind':'chapter_branch','route':[[x,y+48],[xx,yy-48]]})
    if len(nodes)>5:edges.append({'from':nodes[3]['id'],'to':nodes[5]['id'],'kind':'chapter_branch','route':[[420,658],[420,695],[880,695],[880,737]]})
    (ROOT/'content/knowledge_map.json').write_text(json.dumps(dict(schema_version=2,extent=[1140,870],groups=[],nodes=nodes,edges=edges),ensure_ascii=False,indent=2),'utf8')
    print(len(courses),'chapters',sum(len(g['beats']) for c in courses for g in c['groups']),'beats')
def loads():
    c=course('load','载荷与重心 · 第 5 方案','Нагру́зка и центр тя́жести · Вариа́нт 5');c['initial'].update(show_load=True,focus_only=True,focus=0,water=False,load_vessel=True)
    g=group(c,'L01','油舱质量矩','Моме́нты масс то́плива')
    beat(g,'L01:goal','这艘四货舱船有九个燃油舱，燃油供船自身使用。','У э́того су́дна с четырьмя́ трю́мами де́вять то́пливных та́нков для со́бственных нужд.',params={'show_fuel':True,'focus':0,'fuel_index':0,'focus_only':False,'cutaway_amount':0},action={'cutaway_amount':1},camera='cutaway',anchor='hull')
    beat(g,'L01:positions','按给定重心：1—5号靠近船底，6—9号集中在艉部。','По координа́там це́нтров: та́нки 1–5 у дни́ща, 6–9 — в кормово́й ча́сти.',params={'show_fuel':True,'focus_only':False},camera='cutaway',anchor='load')
    beat(g,'L01:origin','x 从艉垂线向艏量，z 从基本平面向上量。','x отсчи́тываем от кормово́го перпендикуля́ра к но́су, z — от осно́вной пло́скости вверх.',[r'x_i,z_i\quad[\mathrm m]'],bi('L01 · 坐标与质量矩','L01 · Координа́ты и моме́нты'),params={'show_fuel':True,'fuel_index':0,'focus':0,'coordinate_lines':True,'base_plane':True},camera='baseline')
    beat(g,'L01:meaning','质量矩是质量乘坐标，表示该项质量对重心位置的贡献。','Моме́нт ма́ссы — ма́сса, умно́женная на координа́ту; он задаёт вклад в положе́ние це́нтра.',[r'M_{z,i}=P_i\cdot z_i',r'M_{x,i}=P_i\cdot x_i',r'[M]=\mathrm{t\cdot m}'],params={'show_fuel':True,'fuel_index':0},anchor='load')
    for i,r in enumerate(S['L01']['rows']):
        p,z,x=r['mass_t'],r['z_m'],r['x_m'];j=i+1;pa={'show_fuel':True,'fuel_index':i,'focus':i,'focus_only':True,'coordinate_lines':True}
        lines=[fr'P_{{{j}}}={unit(p)}',fr'z_{{{j}}}={unit(z,"m")}',fr'x_{{{j}}}={unit(x,"m")}',fr'P_{{{j}}}z_{{{j}}}={p:g}\cdot{z:g}',fr'={unit(r["moment_z_tm"],r"t\cdot m")}',fr'P_{{{j}}}x_{{{j}}}={p:g}\cdot{x:g}',fr'={unit(r["moment_x_tm"],r"t\cdot m")}',fr'I_{{f,{j}}}={unit(r["free_surface_tm"],r"t\cdot m")}']
        label=bi(f'油舱 {j}',f'Танк {j}')
        if i==0:
            beat(g,'L01:tank1:given','第一油舱给定 250 吨、z = 0.58 米、x = 97 米。','Для пе́рвого та́нка да́ны 250 т, z = 0.58 м, x = 97 м.',lines[:3],label,params=pa,anchor='load')
            beat(g,'L01:tank1:z','250 乘 0.58，得到竖向质量矩 145 吨·米。','250 умно́жить на 0.58 — получа́ем 145 т·м.',lines[3:5],params=pa,anchor='load')
            beat(g,'L01:tank1:x','250 乘 97，得到纵向质量矩 24250 吨·米。','250 умно́жить на 97 — продо́льный моме́нт равен 24250 т·м.',lines[5:7],params=pa,anchor='load')
            beat(g,'L01:free','自由液面矩由原表给定：1号舱为420吨·米，不用再算。','Моме́нт свобо́дной пове́рхности дан в табли́це: для та́нка 1 — 420 т·м.',lines[7:],params=pa,anchor='load')
        else:beat(g,f'L01:tank{j}',f'{j}号舱重心：距艉垂线{x:g}米，高{z:g}米。',f'Центр та́нка {j}: {x:g} м от кормово́го перпендикуля́ра, высота́ {z:g} м.',lines,label,params=pa,anchor='load')
    g=group(c,'L02','燃油合计','Су́ммы для то́плива');r=S['L02']
    for key,symbol,zh,ru in [('P_t',r'\sum P_i','九个油舱质量相加，得到燃油总质量。','Су́мма масс де́вяти та́нков — о́бщая ма́сса то́плива.'),('moment_z_tm',r'\sum P_i z_i','原点一致，竖向质量矩可以逐项相加。','При о́бщем нача́ле отсчёта моме́нты масс мо́жно скла́дывать.'),('moment_x_tm',r'\sum P_i x_i','纵向质量矩同样相加。','Продо́льные моме́нты скла́дываем так же.'),('free_surface_tm',r'\sum I_{f,i}','自由液面矩合计为 1734 吨·米，保留原题结果。','Су́мма моме́нтов свобо́дных пове́рхностей — 1734 т·м.')]:
        vals=[row['mass_t' if key=='P_t' else key] for row in S['L01']['rows']]
        beat(g,'L02:'+key,zh,ru,[symbol+'=', '+'.join(f'{v:g}' for v in vals[:4]),'+'+'+'.join(f'{v:g}' for v in vals[4:]),'='+unit(r[key],'t' if key=='P_t' else r't\cdot m')],bi('L02 · 合计','L02 · Су́ммы') if key=='P_t' else None,params={'show_fuel':True,'focus_only':False})
    g=group(c,'L03','燃油合成重心','Центр тя́жести то́плива')
    for axis,key in [('z','moment_z_tm'),('x','moment_x_tm')]:
        zh,ru = (
            ('P·z 的总和除以燃油总质量，只求重心距基本平面的高度 z。','Су́мму P·z де́лим на ма́ссу то́плива: нахо́дим то́лько высоту́ це́нтра масс z над основно́й пло́скостью.')
            if axis=='z' else
            ('P·x 的总和除以燃油总质量，只求重心的纵向坐标 x，即前后位置。','Су́мму P·x де́лим на ма́ссу то́плива: нахо́дим то́лько продо́льную координа́ту це́нтра масс x.')
        )
        beat(g,'L03:'+axis,zh,ru,[fr'{axis}_f=\frac{{\sum P_i {axis}_i}}{{\sum P_i}}',fr'=\frac{{{r[key]:.2f}}}{{1069}}',fr'={S["L03"][axis+"_m"]:.4f}\,\mathrm m'],bi('L03 · 燃油重心','L03 · Центр то́плива') if axis=='z' else None,params={'show_fuel':True,'show_centre':True,'focus_only':False},anchor='centre')
    g=group(c,'L04','全船十三项','Трина́дцать ста́тей')
    beat(g,'L04:carry','燃油行承接总质量和总矩，不能用已舍入的重心倒算总矩。','В стро́ку то́плива перено́сим су́ммы масс и моме́нтов; окру́глённый центр не перемножа́ем.',[r'P_f=1069\,\mathrm t',r'M_{z,f}=2047.50\,\mathrm{t\cdot m}',r'M_{x,f}=67576.40\,\mathrm{t\cdot m}'],bi('L04 · 全船载荷','L04 · Нагру́зка су́дна'),params={'focus':6,'show_fuel':False},anchor='load')
    names_ru=['Поро́жнее су́дно','Трюм 1','Трюм 2','Трюм 3','Трюм 4','Па́лубный груз','То́пливо','Питьева́я вода́','Ма́сло','Гря́зные жи́дкости','Кормовы́е запа́сы','Носовы́е запа́сы','Экипа́ж']
    for i,row in enumerate(S['L04']['rows']):
        j=i+1;pa={'focus':i,'focus_only':True,'show_fuel':False,'show_centre':False}
        lines=[fr'P_{{{j}}}={unit(row["mass_t"])}',fr'z_{{{j}}}={row["z_m"]:.4f}\,\mathrm m',fr'x_{{{j}}}={row["x_m"]:.4f}\,\mathrm m']
        if i==6:lines +=[r'M_{z,f}=2047.50\,\mathrm{t\cdot m}',r'M_{x,f}=67576.40\,\mathrm{t\cdot m}']
        else:lines +=[fr'P_{{{j}}}z_{{{j}}}={row["mass_t"]:g}\cdot{row["z_m"]:g}',fr'={unit(row["moment_z_tm"],r"t\cdot m")}',fr'P_{{{j}}}x_{{{j}}}={row["mass_t"]:g}\cdot{row["x_m"]:g}',fr'={unit(row["moment_x_tm"],r"t\cdot m")}']
        beat(g,f'L04:item{j}',row['name_zh']+'：将这一项加入全船载荷表。',names_ru[i]+': добавля́ем стро́ку в табли́цу.',lines,bi(f'{j:02} · '+row['name_zh'],f'{j:02} · '+names_ru[i]),params=pa,anchor='load')
    g=group(c,'L05','全船合计','Су́ммы для су́дна')
    for key,sym,u in [('P_t',r'D=\sum P_i','t'),('moment_z_tm',r'M_z=\sum P_i z_i',r't\cdot m'),('moment_x_tm',r'M_x=\sum P_i x_i',r't\cdot m')]:beat(g,'L05:'+key,'十三项按列相加，得到全船的质量与质量矩。','Скла́дываем трина́дцать стро́к по столбца́м.',[sym,'='+unit(S['L05'][key],u)],bi('L05 · 全船合计','L05 · Ито́го') if key=='P_t' else None,params={'focus_only':False})
    g=group(c,'L06','全船重心','Центр тя́жести су́дна')
    for axis,key in [('z','moment_z_tm'),('x','moment_x_tm')]:
        zh,ru = (
            ('全船 P·z 的总和除以总质量，只求重心 G 距基本平面的高度 z。','Су́мму P·z всего́ су́дна де́лим на его́ ма́ссу: нахо́дим то́лько высоту́ це́нтра G над основно́й пло́скостью.')
            if axis=='z' else
            ('全船 P·x 的总和除以总质量，只求重心 G 的纵向坐标 x，即前后位置。','Су́мму P·x всего́ су́дна де́лим на его́ ма́ссу: нахо́дим то́лько продо́льную координа́ту це́нтра G.')
        )
        beat(g,'L06:'+axis,zh,ru,[fr'{axis}_G=\frac{{M_{axis}}}{{D}}',fr'=\frac{{{S["L05"][key]:.2f}}}{{20616}}',fr'={S["L06"][axis+"G_m"]:.4f}\,\mathrm m'],bi('L06 · 全船重心','L06 · Центр G') if axis=='z' else None,params={'focus_only':False,'show_centre':True},anchor='centre')
    for g in c['groups']:
        for b in g['beats']:
            if b['scene_params'].get('show_fuel',False) and b['scene_params'].get('focus_only',True) and b['id']!='L01:origin':
                b['camera']='fuel'
                b['scene_params']['fuel_detail']=True
            if b['id']=='L01:tank2':b['words']=bi('2、3、4号舱的x、z相同；这里将它们横向分开展示。','У та́нков 2, 3 и 4 одина́ковые x и z; здесь они́ разнесены́ по ширине́.')
            if b['id']=='L02:free_surface_tm':b['words']=bi('九项给定值相加，自由液面矩合计1734吨·米。','Скла́дываем де́вять да́нных значе́ний: 1734 т·м.')
    return c

def solver_beats(g,step,symbol):
    trace=DATA['solvers'][step]['iterations'];a,b=trace[0]['left'],trace[0]['right']
    beat(g,step+':bracket','先取两端异号的区间，正根就在其中。','Берём интерва́л с ра́зными зна́ками на конца́х; в нём есть корень.',[fr'{symbol}\in[{a:g},{b:g}]',r'f(l)f(r)<0'],bi(step+' · 二分求根',step+' · Бисе́кция'))
    for i,row in enumerate(trace[:3]):
        # Every iteration is retained, but only the first three need a new verbal explanation.
        if i<3:
            zh=['取区间中点，计算方程残差。','保留两端异号的一半区间。','重复二分，区间继续缩小。'][i]
            ru=['Берём середи́ну и счита́ем невя́зку.','Оставля́ем полови́ну с ра́зными зна́ками.','Повторя́ем деле́ние попола́м.'][i]
        else:zh=f'第 {i+1} 次二分：继续缩小根的区间。';ru=f'Итера́ция {i+1}: сужа́ем интерва́л ко́рня.'
        lines=[fr'l={row["left"]:.10f}',fr'r={row["right"]:.10f}',fr'{symbol}=\frac{{l+r}}{{2}}',fr'={row["mid"]:.10f}',fr'f({symbol})={row["residual"]:.10f}']
        bbeat=beat(g,f'{step}:iteration{i+1}',zh,ru,lines,bi(f'迭代 {i+1}',f'Итера́ция {i+1}'),visual='interval');bbeat['solver_row']=row
    lines=[]
    for row in trace[3:]:
        lines += [fr'n={row["iteration"]}',fr'l={row["left"]:.10f}',fr'r={row["right"]:.10f}',fr'{symbol}={row["mid"]:.10f}',fr'f={row["residual"]:.10f}']
    bbeat=beat(g,step+':trace','继续二分至收敛；每次区间和残差都保留在右侧。','Продолжа́ем бисе́кцию до сходи́мости; все интерва́лы и невя́зки сохране́ны спра́ва.',lines,bi('完整迭代记录','По́лная исто́рия итера́ций'),visual='interval');bbeat['solver_row']=trace[-1]
    beat(g,step+':stop','残差或区间宽度达到阈值后停止。','Остана́вливаемся по невя́зке и́ли ширине́ интерва́ла.',[r'|f|\le10^{-8}',r'\mathrm{or}\quad r-l\le10^{-10}',fr'|f|={abs(trace[-1]["residual"]):.11f}',fr'r-l={trace[-1]["right"]-trace[-1]["left"]:.11f}',r'n\le200'])

def mass_course():
    c=course('mass','排水量估算 · Т2','Водоизмеще́ние · Т2','tanker');g=group(c,'task','新船与母型','Прое́кт и прототи́п')
    beat(g,'T:task','要运 30700 吨货、跑 15.9 节，求需要多重的船。','Нужно перевози́ть 30700 т со ско́ростью 15.9 у́зла; найдём водоизмеще́ние.',[r'P_{gr}=30700\,\mathrm t',r'v=15.9\,\mathrm{kn}',r'R=5500\,\mathrm{nmi}',r'D\;=?'],bi('Т2 · 新船任务','Т2 · Зада́ние'),step='T01')
    beat(g,'T:liquid','液货舱装运输的货物，燃油舱供船自身使用。','Грузовы́е та́нки перево́зят груз; то́пливные снабжа́ют само́ су́дно.',params={'cutaway_amount':0,'water':False,'liquid_focus':True},action={'cutaway_amount':1},camera='cutaway',anchor='liquid',step='T01')
    beat(g,'T:prototype','母型船提供已有设计的质量、功率和航行数据。','Прототи́п даёт ма́ссы, мо́щность и ходовы́е да́нные.',[r'D_0=27590\,\mathrm t',r'N_0=8580\,\mathrm{kW}',r'v_0=15\,\mathrm{kn}',r'R_0=5000\,\mathrm{nmi}'],bi('母型船','Прототи́п'),step='T02')
    g=group(c,'T01','供应质量','Ма́сса снабже́ния')
    specs=[('crew','船员和行李按每人 0.12 吨，人数为 20。','Экипа́ж с багажо́м: 20 челове́к по 0.12 т.',[r'P_{crew}=0.12\cdot20=2.40\,\mathrm t']),('food','食品按每人每天 0.003 吨，备 35 天。','Прови́зия: 0.003 т на челове́ка в су́тки на 35 су́ток.',[r'P_{food}=0.003\cdot20\cdot35',r'=2.10\,\mathrm t']),('water','淡水按每人每天 0.15 吨，备 20 天。','Вода́: 0.15 т на челове́ка в су́тки на 20 су́ток.',[r'P_{water}=0.15\cdot20\cdot20',r'=60.00\,\mathrm t']),('total','再加 20 吨器具，供应质量合计 84.50 吨。','Добавля́ем 20 т инвентаря́: ито́го 84.50 т.',[r'P_s=2.40+2.10+60+20',r'=84.50\,\mathrm t'])]
    for id,zh,ru,tex in specs:beat(g,'T01:'+id,zh,ru,tex,bi('T01 · 供应','T01 · Снабже́ние') if id=='crew' else None)
    g=group(c,'T02','母型系数','Коэффицие́нты прототи́па')
    specs=[('hull','船体设备质量与排水量之比，用于估算新船船体。','Доля́ ма́ссы ко́рпуса в водоизмеще́нии даёт оце́нку но́вого ко́рпуса.',[r'p_h=\frac{P_{h0}}{D_0}=\frac{6720}{27590}',r'\approx0.24',r'P_h=p_hD']),('engine','单位功率需要多少吨动力装置，由母型给出。','Прототи́п задаёт ма́ссу устано́вки на едини́цу мо́щности.',[r'p_e=\frac{720}{8580}\approx0.08',r'[p_e]=\mathrm{t/kW}',r'P_e=p_eN']),('fuel','航行时间是航程除以航速；由此反求单位功率耗油量。','Вре́мя хо́да равно́ да́льности, делённой на ско́рость; найдём расхо́д то́плива.',[r't=\frac{R}{v}\quad[\mathrm h]',r'p_f=\frac{690\cdot15}{8580\cdot5000}',r'\approx0.00024\,\mathrm{t/(kW\cdot h)}',r'P_f=p_fN\frac{R}{v}']),('admiralty','海军系数把排水量、航速与所需功率联系起来。','Адмиралте́йский коэффицие́нт свя́зывает водоизмеще́ние, ско́рость и мо́щность.',[r'C_A=\frac{D_0^{2/3}v_0^3}{N_0}',r'=\frac{27590^{2/3}\cdot15^3}{8580}',fr'={S["T02"]["CA"]:.2f}',r'N=\frac{D^{2/3}v^3}{C_A}'])]
    for id,zh,ru,tex in specs:beat(g,'T02:'+id,zh,ru,tex,bi('T02 · 系数','T02 · Коэффицие́нты') if id=='hull' else None)
    beat(g,'T02:precision','这些系数显示近似值，后续计算仍使用原分式的精度。','На экра́не приближе́ния; в расчёте сохраня́ем то́чность исхо́дных дро́бей.')
    g=group(c,'T03','质量方程','Уравне́ние масс')
    beat(g,'T03:dependencies','先试设排水量 D；按母型比例，船体质量随 D 增加。','Задади́м про́бное D; по до́ле прототи́па ма́сса ко́рпуса растёт с D.',[r'D\longrightarrow P_h=p_hD'],bi('T03 · 质量依赖','T03 · За́висимости'),visual='dependencies',params={'dependency_reveal':0},action={'dependency_reveal':1})
    beat(g,'T03:power_dependency','航速不变时，船越重，估算的推进功率越大。','При той же ско́рости бо́льшему водоизмеще́нию ну́жна бо́льшая мо́щность.',[r'D\longrightarrow N\propto D^{2/3}'],visual='dependencies',action={'dependency_reveal':2})
    beat(g,'T03:fuel_dependency','功率增加，动力装置和燃油也更重；这些质量又计入 D，因此必须联立求解。','С ро́стом мо́щности расту́т ма́ссы устано́вки и то́плива; они́ вхо́дят в D, поэ́тому реша́ем уравне́ние.',[r'N\longrightarrow P_e,\ P_f'],visual='dependencies',action={'dependency_reveal':3})
    beat(g,'T03:reserve','本题预留排水量的 1% 作为设计质量裕量。','В э́той зада́че оставля́ем 1% водоизмеще́ния как запа́с ма́ссы.',[r'P_r=0.01D'])
    beat(g,'T03:balance','六项质量相加，必须等于船的排水量。','Су́мма шести́ масс должна́ равня́ться водоизмеще́нию.',[r'D=P_h+P_e+P_f',r'\quad+P_r+P_s+P_{gr}',r'P_r=0.01D',r'P_s+P_{gr}=84.50+30700'],visual='dependencies')
    beat(g,'T03:substitute','把依赖功率的质量都改写成 D 的函数。','Вы́разим ма́ссы, зави́сящие от мо́щности, че́рез D.',[r'P_e=p_e\frac{v^3}{C_A}D^{2/3}',r'P_f=p_f\frac{Rv^2}{C_A}D^{2/3}'])
    for id,zh,ru,tex in [('a','将与 D 成正比的项移到左侧。','Перенесём чле́ны, пропорциона́льные D, вле́во.',[r'a=1-p_h-0.01',r'=1-\frac{6720}{27590}-0.01',fr'={S["T03"]["a"]:.10f}']),('b','动力与燃油共同组成 D 的三分之二次方项。','Устано́вка и то́пливо даю́т член с D^{2/3}.',[r'b=\left(p_e+p_f\frac{R}{v}\right)\frac{v^3}{C_A}',fr'={S["T03"]["b"]:.10f}']),('c','货物和供应是不依赖 D 的已知质量。','Груз и снабже́ние — изве́стные ма́ссы, не зави́сящие от D.',[r'c=P_{gr}+P_s=30784.50',r'aD-bD^{2/3}-c=0'])]:beat(g,'T03:'+id,zh,ru,tex)
    g=group(c,'T04','二分求排水量','По́иск водоизмеще́ния')
    beat(g,'T04:transform','令 X 为 D 的立方根，得到关于 X 的三次方程。','Поло́жим X ку́бическим ко́рнем из D; получи́м куби́ческое уравне́ние.',[r'X=\sqrt[3]{D},\quad D=X^3',r'f(X)=aX^3-bX^2-c=0'])
    solver_beats(g,'T04','X')
    beat(g,'T04:report','报告用四位小数的 X 立方，得到 44388.19 吨。','В отчёте возво́дим X с четырьмя́ зна́ками в куб: 44388.19 т.',[fr'X={S["T04"]["X"]:.10f}',r'X_{\mathrm{cube}}=35.4070',r'D_{\mathrm{report}}=35.4070^3',r'=44388.19\,\mathrm t'])
    g=group(c,'T05','采用排水量','При́нятое водоизмеще́ние')
    beat(g,'T05:adopt','后续采用老师给定的 44388 吨。','Да́лее принима́ем 44388 т по отчёту преподава́теля.',[r'D_1=44388\,\mathrm t'],bi('T05 · 采用值','T05 · При́нято'))
    g=group(c,'T06','回代质量','Обра́тная подстано́вка')
    beat(g,'T06:power','先用采用排水量回算功率，并取两位小数。','Снача́ла счита́ем мо́щность по при́нятому водоизмеще́нию до двух зна́ков.',[r'N_1=\frac{44388^{2/3}\cdot15.9^3}{C_A}',r'=14030.75\,\mathrm{kW}'],bi('T06 · 回代','T06 · Подстано́вка'))
    specs=[('hull','船体及设备','Ко́рпус',r'P_h=\frac{6720}{27590}\cdot44388',S['T06']['Phull_t']),('engine','动力装置','Устано́вка',r'P_e=\frac{720}{8580}\cdot14030.75',S['T06']['Pengine_t']),('fuel','能源储备','Энергети́ческие запа́сы',r'P_f=p_f\cdot14030.75\cdot\frac{5500}{15.9}',S['T06']['Penergy_t']),('reserve','排水量裕量','Запа́с водоизмеще́ния',r'P_r=0.01\cdot44388',S['T06']['Preserve_t'])]
    for id,zh,ru,tex,val in specs:beat(g,'T06:'+id,zh+'按刚才的质量函数回代。',ru+': подставля́ем в фу́нкцию ма́ссы.',[tex,'='+unit(val)])
    g=group(c,'T07','完整质量表','Табли́ца масс')
    beat(g,'T07:round','质量表逐项四舍五入到整吨；84.50 应取 85。','Ма́ссы в табли́це окру́гляем до тонн; 84.50 превраща́ется в 85.',[r'84.50\longrightarrow85\,\mathrm t'],bi('T07 · 质量与百分比','T07 · Ма́ссы и проце́нты'))
    for i,row in enumerate(S['T07']['rows']):
        lines=[fr'P_0={unit(row["prototype_mass_t"],n=0)}',fr'\frac{{{row["prototype_mass_t"]}}}{{27590}}\cdot100\%={row["prototype_percent"]:.2f}\%',fr'P_1={row["calculated_project_mass_t"]:.2f}',fr'\longrightarrow {row["project_mass_t"]}\,\mathrm t',fr'\frac{{{row["calculated_project_mass_t"]:.2f}}}{{44388}}\cdot100\%',fr'={row["project_percent"]:.2f}\%']
        beat(g,f'T07:row{i+1}',row['name_zh']+'：比较母型与新船的质量占比。',row['name_ru']+': сравни́м до́ли масс.',lines,bi(row['name_zh'],row['name_ru']))
    beat(g,'T07:check','六项整吨质量相加，恰好等于采用排水量。','Су́мма шести́ окру́глённых масс равна́ при́нятому водоизмеще́нию.',[r'10811+1177+1171',r'+444+85+30700',r'=44388\,\mathrm t',r'\sum P_i-D_1=0'])
    return c

def dimensions_course():
    c=course('dimensions','主尺度设计 · Т2','Гла́вные размере́ния · Т2','tanker');g=group(c,'T08','船长','Длина́')
    beat(g,'T08:goal','排水量已有 44388 吨，现在求 L、B、T、H。','Водоизмеще́ние уже́ 44388 т; найдём L, B, T и H.',[r'D_1=44388\,\mathrm t',r'L,B,T,H\;=?'],bi('T08 · 设计目标','T08 · Цель'))
    beat(g,'T08:length','经验式先确定船长，采用 189.64 米。','Эмпири́ческая фо́рмула задаёт длину́; принима́ем 189.64 м.',[r'\ell=2.13\sqrt[3]{15.9}=5.3560585',r'L=\ell\sqrt[3]{44388}',r'L_1=189.64\,\mathrm m'])
    g=group(c,'T09','船型系数','Коэффицие́нты фо́рмы')
    beat(g,'T09:froude','将节换成米每秒，再计算反映相对航速的弗劳德数。','Переведём у́злы в ме́тры в секу́нду и найдём число́ Фру́да.',[r'\mathrm{Fr}=\frac{0.514v}{\sqrt{gL}}',r'=\frac{0.514\cdot15.9}{\sqrt{9.81\cdot189.64}}',fr'={S["T09"]["Fr"]:.8f}'],bi('T09 · 船型系数','T09 · Фо́рма'))
    beat(g,'T09:delta','方形系数比较排水体积与 LBT，按本题经验式估算。','Коэффицие́нт о́бщей полноты́ сравни́вает объём с LBT; испо́льзуем фо́рмулу зада́ния.',[r'\delta=\frac{\nabla}{LBT}',r'\delta_{calc}=1.05-1.4\mathrm{Fr}',fr'={S["T09"]["delta_calculated"]:.8f}',r'\delta=0.785'])
    beat(g,'T09:alpha','水线面系数比较水线面面积与 LB，采用 0.850。','Полнота́ ватерли́нии сравни́вает её пло́щадь с LB; принима́ем 0.850.',[r'\alpha=\frac{A_{WL}}{LB}',r'\alpha_{calc}=0.96\sqrt{\delta_{calc}}',fr'={S["T09"]["alpha_calculated"]:.8f}',r'\alpha=0.850'])
    beat(g,'T09:zeta','重心高度按母型的型深比例估计，采用 0.62。','Высоту́ це́нтра тя́жести оце́ним по до́ле высоты́ бо́рта прототи́па.',[r'\zeta=\frac{z_{G0}}{H_0}=\frac{8.31}{13.4}',r'\zeta=0.62,\quad z_G=\zeta H'])
    beat(g,'T09:underdeck','甲板下容积系数按本题修正为 0.82。','Полноту́ подпа́лубного объёма в э́той зада́че принима́ем 0.82.',[r'\delta_{pp}=\delta+0.035',r'=0.785+0.035=0.82'])
    g=group(c,'T10','机舱系数','Маши́нное отделе́ние')
    beat(g,'T10:mu','由母型得到单位功率机舱容积，本题采用 0.55。','По прототи́пу нахо́дим объём на едини́цу мо́щности; принима́ем 0.55.',[r'\mu=\frac{4715}{8580}',r'\mu_{adopt}=0.55\,\mathrm{m^3/kW}'],bi('T10 · 采用系数','T10 · При́нятый коэффицие́нт'))
    g=group(c,'T11','所需容积','Потре́бный объём')
    specs=[('cargo','液货质量除以密度，再增加 4% 的容积。','Де́лим ма́ссу гру́за на пло́тность и добавля́ем 4% объёма.',r'W_c=1.04\frac{30700}{0.9}','Wcargo_m3'),('engine','机舱容积采用 0.55 乘功率。','Объём маши́нного отделе́ния равен 0.55, умно́женным на мо́щность.',r'W_e=0.55\cdot14030.75','Wengine_m3'),('fuel','能源储备按 0.85 吨每立方米换算。','Энергети́ческие запа́сы де́лим на 0.85 т/м³.',r'W_f=\frac{1170.93}{0.85}','Wenergy_m3'),('water','淡水密度取 1，60 吨需要 60 立方米。','При пло́тности воды́ 1 т/м³ ну́жно 60 м³.',r'W_w=\frac{60}{1}','Wwater_m3'),('ballast','压载舱容积取已算液货舱容积的 38%。','Объём балла́стных та́нков — 38% рассчи́танного грузово́го объёма.',r'W_b=0.38\cdot35475.56','Wballast_m3')]
    for i,(id,zh,ru,tex,key) in enumerate(specs):beat(g,'T11:'+id,zh,ru,[tex,'='+unit(S['T11'][key],'m^3')],bi('T11 · 各项容积','T11 · Объёмы') if i==0 else None,visual='volume',params={'volume_count':i+1})
    beat(g,'T11:total','各容积先取两位小数，再相加乘 1.06。','Объёмы с двумя́ зна́ками скла́дываем и умножа́ем на 1.06.',[r'W_\Sigma=35475.56+7716.91',r'+1377.56+60+13480.71',r'W_{req}=1.06W_\Sigma',r'=61597.38\,\mathrm m^3'],visual='volume',params={'volume_count':5})
    g=group(c,'T12','三个约束','Три усло́вия')
    beat(g,'T12:float:meaning','浮性要求排开水的质量等于全船质量。','Плаву́честь тре́бует ра́венства ма́ссы вы́тесненной воды́ и су́дна.',[r'D=\rho\nabla',r'\nabla=k\delta LBT'],bi('T12 · 浮性','T12 · Плаву́честь'),anchor='water')
    beat(g,'T12:float','固定船长和系数后，浮性约束确定 B 乘 T。','При изве́стной длине́ и коэффицие́нтах плаву́честь задаёт BT.',[r'BT=\frac{D}{k\rho\delta L}',r'=\frac{44388}{\begin{gathered}1.005\cdot1.025\cdot0.785\\\cdot189.64\end{gathered}}',r'=289.45\,\mathrm m^2'])
    beat(g,'T12:capacity','甲板下容积必须容纳所需空间，从而确定 B 乘 H。','Подпа́лубный объём до́лжен вмести́ть всё необходи́мое; э́то задаёт BH.',[r'W_{req}=\delta_{pp}LBH',r'BH=\frac{61597.38}{0.82\cdot189.64}',r'=396.11\,\mathrm m^2'],bi('T12 · 容积','T12 · Вмести́мость'))
    beat(g,'T12:centres','G 是质量中心；B 是排开水体积的中心，称为浮心。','G — центр ма́ссы; B — центр вы́тесненного объёма, центр величины́.',visual='stability')
    beat(g,'T12:metacentre','小角度倾斜后，浮力作用线与原竖直中心线交于初稳心 M。','При ма́лом накло́не ли́ния си́лы плаву́чести пересека́ет исхо́дную вертика́ль в метаце́нтре M.',visual='stability')
    beat(g,'T12:stability:meaning','M 高于 G 时有回复趋势；K 是基线上的高度起点。','При M вы́ше G возни́кает восстана́вливающий моме́нт; K — нача́ло отсчёта высо́т.',[r'h=GM=KB+BM-KG'],bi('T12 · 初稳性（小角度）','T12 · Нача́льная осто́йчивость'),visual='stability')
    beat(g,'T12:stability','本题要求 h 为船宽的 6%，用经验式联系 B、T、H。','В зада́нии h равно́ 6% шири́ны; эмпири́ческая фо́рмула свя́зывает B, T и H.',[r'KB=0.50\sqrt{\frac{\alpha}{\delta}}T',r'BM=\frac{0.0862\alpha^2B^2}{\delta T}',r'KG=\zeta H',r'KB+BM-KG=0.06B'],visual='stability')
    g=group(c,'T13','求宽度并回代','Шири́на и подстано́вка')
    beat(g,'T13:eliminate','用前两个约束把 T、H 都写成 B 的函数。','Из пе́рвых двух усло́вий вы́разим T и H че́рез B.',[r'T=\frac{289.45}{B}',r'H=\frac{396.11}{B}'],bi('T13 · 消元','T13 · Исключе́ние'))
    beat(g,'T13:function','代入初稳性方程，只剩一个未知量 B。','Подста́вим в уравне́ние осто́йчивости; остаётся то́лько B.',[r'f(B)=0.50\sqrt{\frac{0.850}{0.785}}\frac{289.45}{B}',r'+\frac{0.0862\cdot0.850^2B^2}{0.785(289.45/B)}',r'-0.62\frac{396.11}{B}-0.06B',r'f(B)=0'])
    solver_beats(g,'T13','B')
    beat(g,'T13:back','用未舍入的根回算 T、H，再显示两位小数。','По неокру́глённому ко́рню счита́ем T и H, зате́м пока́зываем два зна́ка.',[fr'B={S["T13"]["B_solver_value_m"]:.10f}',r'B_{calc}=26.61\,\mathrm m',r'T=289.45/B=10.88\,\mathrm m',r'H=396.11/B=14.88\,\mathrm m'])
    g=group(c,'T14','采用主尺度','При́нятые размере́ния')
    beat(g,'T14:adopt','最终按老师采用值：B 为 26.60 米，H 为 14.89 米。','По отчёту принима́ем B = 26.60 м и H = 14.89 м.',[r'L_1=189.64\,\mathrm m',r'B_1=26.60\,\mathrm m',r'T_1=10.88\,\mathrm m',r'H_1=14.89\,\mathrm m'],bi('T14 · 采用值','T14 · При́нято'),params={'dimensions':True,'dimension_reveal':0},action={'dimension_reveal':1},camera='dimensions')
    g=group(c,'T15','排水量差额','Прове́рка водоизмеще́ния')
    beat(g,'T15:check','用最终采用的尺度回算排水量。','Прове́рим водоизмеще́ние по оконча́тельно при́нятым размере́ниям.',[r'D_{check}=1.005\cdot1.025\cdot0.785',r'\quad\cdot189.64\cdot26.60\cdot10.88',r'=44381.30\,\mathrm t'],bi('T15 · 复核','T15 · Прове́рка'),params={'dimensions':True},camera='dimensions')
    beat(g,'T15:report','差额 6.70 吨，报告写 7 吨；满足本作业模板的允许范围。','Разни́ца 6.70 т; в отчёте 7 т — в преде́лах, ука́занных в шабло́не зада́ния.',[r'\Delta D=44388-44381.30',r'=6.70\,\mathrm t',r'\Delta D_{report}=7\,\mathrm t',r'7\le8\,\mathrm t'],bi('本题模板：5–8 吨','Шабло́н зада́ния: 5–8 т'))
    g=group(c,'T16','尺度比','Отноше́ния размере́ний')
    for a,b,oldv,newv in [('L','B',147.2/24.5,189.64/26.6),('B','T',24.5/9.8,26.6/10.88),('H','T',13.4/9.8,14.89/10.88)]:beat(g,'T16:'+a+b,'比较母型与新船的尺度比。','Сравни́м отноше́ния размере́ний прототи́па и прое́кта.',[fr'{a}_0/{b}_0={oldv:.2f}',fr'{a}_1/{b}_1={newv:.2f}'],bi('T16 · 尺度比','T16 · Отноше́ния') if a=='L' else None)
    beat(g,'T16:pass','H/T 约为 1.37，大于本题要求的 1.25。','H/T о́коло 1.37, бо́льше тре́буемых в зада́нии 1.25.',[r'\frac{H_1}{T_1}=\frac{14.89}{10.88}',r'=1.368566\ge1.25'])
    return c

def supplement():
    c=copy.deepcopy(OLD_BY['sample']);c['id']='supplement';c['title']=bi('补充理解','Дополне́ния');c['resume_aliases']={}
    c['groups']+=copy.deepcopy([g for g in OLD_BY['foundation']['groups'] if g['id']=='reserve'])
    for b in c['groups'][-1]['beats']:
        b['scene_params'].update(show_load=False,cargo_detail=False,move_z=0);b['anchor']='water'
        b['record_label']=bi('独立示例：水线面面积2000、2120 m²；高度7.5、10 m','Отде́льный приме́р: пло́щади 2000, 2120 м²; высо́ты 7.5, 10 м')
    free=copy.deepcopy(OLD_BY['load']['groups'][-1]['beats'][1]);c['groups'].append(dict(id='free_surface',title=bi('自由液面','Свобо́дная пове́рхность'),beats=[free]))
    for g in copy.deepcopy(OLD_BY['norman']['groups']):
        for b in g['beats']:b.setdefault('scene_params',{}).update(scene='tanker',show_load=False,cargo_detail=False)
        c['groups'].append(g)
    for g in c['groups']:
        for b in g['beats']:b['calculation_step']='supplement'
    return c
# Explicit mathematical line breaks for narrow windows; no whole-expression shrinking.
LATEX['reserve:volume']={lang:[dict(tex=t,linear=linear_tex(t)) for t in [r'A_{av}=\frac{2000+2120}{2}=2060',r'V_{res}=2060(10-7.5)',r'=5150\,\mathrm m^3']] for lang in ['zh','ru']}
LATEX['norman-apply:direct']={lang:[dict(tex=t,linear=linear_tex(t)) for t in [r'dP_h=D\,dp_h',r'dP_e=P_e\frac{dp_e}{p_e}',r'+P_e\left(3\frac{dv}{v}-\frac{dC}{C}\right)',r'dP_f=P_f\frac{dp_f}{p_f}+P_f\frac{dR}{R}',r'+P_f\left(2\frac{dv}{v}-\frac{dC}{C}\right)']] for lang in ['zh','ru']}
if __name__=='__main__':finish([intro(),foundation(),loads(),mass_course(),dimensions_course(),supplement()])
