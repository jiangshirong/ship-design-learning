"""Idempotent extension of the existing course build; no learner data is touched."""
import json,re
from approximation_calculations import ROOT,build,verify
def bi(a,b):return dict(zh=a,ru=b)
def write(p,d):(ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf8')
def read(p):return json.loads((ROOT/p).read_text('utf8'))
def run():
 d=build();assert not verify(d)['failures'];write('content/approximation_calculated.json',d);write('qa/approximation-numerical.json',verify(d))
 s,t=d['second'],d['third'];latex=read('content/latex_source.json');new=[]
 def chapter(id,zh,ru,number):
  c=dict(id=id,title=bi(zh,ru),initial=dict(scene='tanker',show_load=False,show_centre=False,cutaway_amount=0,approximation=number,approx_scale=0),groups=[],resume_aliases={},characters_per_second=28);new.append(c);return c
 def group(c,id,zh,ru):
  g=dict(id=id,title=bi(zh,ru),beats=[]);c['groups'].append(g);return g
 def beat(g,id,zh,ru,tex=(),visual='',phase='',focus='',action=None,source=(),**kw):
  params=dict(part_focus=focus,cutaway_amount=0,dimensions=False,approx_focus=phase,approx_reveal=0 if action else 1,approx_scale=kw.pop('scale',0))
  params.update(kw.pop('params',{}))
  b=dict(id=id,text=zh,words=bi(zh,ru),lines=list(tex),visual=visual,scene_params=params,camera='overview',anchor=kw.pop('anchor','hull' if focus else 'ship'),**kw)
  if action:b['action']=dict(duration=2.2,params=action);b['start_params']={k:params.pop(k,0) for k in action}
  if source:
   rule=dict(kind='formula',teacher_reference='4a/КП-ПС-2 приближение.docx' if id.startswith('AP2:') else '5a/МУ-3прибл.cПрил.Fig.1-3.docx')
   b.update(source_rule=rule,source_rows={str(i):rule for i in source})
  latex[id]={lang:[dict(tex=re.sub(r'(?<=\d)\.(?=\d)','{,}',x) if lang=='ru' else x,linear=x) for x in tex] for lang in ['zh','ru']}
  g['beats'].append(b);return b
 def n(value):return f'{value:.2f}'
 def tables(g,prefix,table,stage,number):
  names=[('船体与设备','Ко́рпус с обору́дованием','к.об.'),('动力装置','Энергети́ческая устано́вка','сэу'),('能源储备','Энергети́ческие запа́сы','сэз'),('排水量裕量','Запа́с водоизмеще́ния','зв'),('供应品','Снабже́ние','сн'),('货物','Груз','гр')]
  total=sum(table)
  for i,(zh,ru,sub) in enumerate(names):
   beat(g,f'{prefix}:row{i}',f'{zh}采用 {table[i]:.0f} 吨。',f'{ru}: принима́ем {table[i]:.0f} т.',[fr'P_{{\text{{{sub}}}{number if i<4 else ""}}}={table[i]:.0f}\,\mathrm t',fr'\frac{{{table[i]:.0f}}}{{{total:.0f}}}\cdot100\%={table[i]/total*100:.2f}\%'],visual='approx_table',phase=stage,params={'approx_row':i,'approx_rows':i+1})
  beat(g,prefix+':closure','六项质量相加，检查是否等于采用排水量。','Сло́жим шесть масс и сравни́м с водоизмеще́нием.',[r'\sum P_i='+ '+'.join(str(int(x)) for x in table[:3]),r'\qquad+'+'+'.join(str(int(x)) for x in table[3:]),fr'={total:.0f}\,\mathrm t'],visual='approx_table',phase=stage,params={'approx_rows':6,'approx_row':-1})
 c=chapter('approximation2','第二次近似','Второ́е приближе́ние',2)
 g=group(c,'AP2:task','承接尺寸与质量','Исхо́дные да́нные')
 beat(g,'AP2:goal','已有船长、船宽和型深，现在重算船体质量，检查排水量是否够用。','По изве́стным разме́рам уточни́м ма́ссу ко́рпуса и прове́рим водоизмеще́ние.',params={'dimensions':True})
 beat(g,'AP2:input','沿用第一次近似的尺寸和六项质量。','Берём разме́ры и шесть масс из пе́рвого приближе́ния.',[r'D_1=44388\,\mathrm t',r'L_1=189.64\,\mathrm m,\quad B_1=26.60\,\mathrm m',r'T_1=10.88\,\mathrm m,\quad H_1=14.89\,\mathrm m'],visual='approx_table',phase='first',params={'approx_rows':6,'approx_row':0})
 g=group(c,'AP2:hull','钢船体与设备','Ко́рпус и обору́дование')
 beat(g,'AP2:steel_object','外板、甲板和内部钢结构，计入钢船体质量。','Обши́вка, па́лубы и стальны́е свя́зи вхо́дят в ма́ссу стально́го ко́рпуса.',focus='Steel',action={'cutaway_amount':1})
 beat(g,'AP2:equipment_object','管路及船舶设备另算；主动力装置不重复计入。','Трубопрово́ды и судово́е обору́дование счита́ем отде́льно; СЭУ не счита́ем два́жды.',focus='Equipment',params={'cutaway_amount':1})
 beat(g,'AP2:split','把钢船体和设备相加，得到这一项质量。','Сло́жим ма́ссы стально́го ко́рпуса и обору́дования.',[r'P_{\text{к.об.}2}=P_{\text{ст}2}+P_{\text{об}2}'],focus='Steel',source=[0])
 g=group(c,'AP2:coefficients','从母型取得系数','Коэффицие́нты прототи́па')
 beat(g,'AP2:prototype','母型已有钢船体和设备质量，可反求两个估算系数。','По ма́ссам прототи́па найдём два коэффицие́нта.',[r'P_{\text{ст}0}=5430\,\mathrm t,\quad P_{\text{об}0}=1290\,\mathrm t',r'L_0=147.20,\ B_0=24.50,\ H_0=13.40\,\mathrm m',r'D_0=27590\,\mathrm t,\quad T_0=9.80\,\mathrm m'],params={'dimensions':True})
 beat(g,'AP2:delta0','先用母型排水量与尺度，求母型丰满系数。','По водоизмеще́нию и разме́рам прототи́па найдём коэффицие́нт полноты́.',[r'\delta_0=\frac{D_0}{k\rho L_0B_0T_0}',r'=\frac{27590}{1.005\cdot1.025\cdot147.20\cdot24.50\cdot9.80}',fr'\approx{s["delta0"]:.2f}'],source=[0])
 beat(g,'AP2:gst','母型钢船体质量除以尺度组合，得到钢船体系数。','Де́лим ма́ссу стально́го ко́рпуса прототи́па на сочета́ние размере́ний.',[r'g_{\text{ст}}=\frac{P_{\text{ст}0}}{\delta_0^{1/3}L_0^{3/2}B_0H_0^{1/2}}',r'=\frac{5430}{0.76^{1/3}\cdot147.20^{3/2}\cdot24.50\cdot13.40^{1/2}}',fr'\approx{s["gst"]:.3f}\,\mathrm{{t/m^3}}'],focus='Steel',source=[0])
 beat(g,'AP2:steel','换入新船尺寸，计算钢船体质量。','Подста́вим разме́ры но́вого су́дна и найдём ма́ссу стально́го ко́рпуса.',[r'P_{\text{ст}2}=g_{\text{ст}}\delta^{1/3}L_1^{3/2}B_1H_1^{1/2}',r'=0.037\cdot0.785^{1/3}\cdot189.64^{3/2}',r'\qquad\cdot26.60\cdot14.89^{1/2}',fr'={n(s["steel"])}\,\mathrm t'],focus='Steel',source=[0])
 beat(g,'AP2:gob','设备采用另一条尺度关系，所以系数也另求。','Для обору́дования испо́льзуем друго́е сочета́ние размере́ний.',[r'g_{\text{об}}=\frac{P_{\text{об}0}}{(L_0B_0H_0)^{2/3}}',r'=\frac{1290}{(147.20\cdot24.50\cdot13.40)^{2/3}}',fr'\approx{s["gob"]:.2f}\,\mathrm{{t/m^2}}'],focus='Equipment',source=[0])
 beat(g,'AP2:equipment','设备系数乘新船尺度组合，得到设备质量。','Умно́жим коэффицие́нт на сочета́ние но́вых размере́ний.',[r'P_{\text{об}2}=g_{\text{об}}(L_1B_1H_1)^{2/3}',r'=0.97(189.64\cdot26.60\cdot14.89)^{2/3}',fr'={n(s["equipment"])}\,\mathrm t'],focus='Equipment',source=[0])
 beat(g,'AP2:hull_sum','两项合计，替换原质量表中的船体与设备这一行。','Су́ммой замени́м стро́ку ко́рпуса с обору́дованием.',[fr'P_{{\text{{к.об.}}2}}={n(s["steel"])}+{n(s["equipment"])}',fr'={n(s["hull"])}\,\mathrm t'],visual='approx_table',phase='second_raw',params={'approx_rows':6,'approx_row':0},action={'approx_reveal':1})
 g=group(c,'AP2:balance','是否需要改尺寸','Нужны́ ли но́вые разме́ры')
 beat(g,'AP2:sum','其余五项暂不变，重新求总质量。','Оста́льные пять масс пока́ не меня́ем; найдём су́мму.',[r'A_1=10875.98+1177+1171',r'\qquad+444+85+30700',fr'={n(s["A1"])}\,\mathrm t'],visual='approx_table',phase='second_raw',params={'approx_rows':6,'approx_row':-1})
 beat(g,'AP2:criterion','课程允许小差额通过调整排水量裕量消除。','Небольшу́ю ра́зность устраня́ем измене́нием запа́са водоизмеще́ния.',[r'|A_1-D_1|\le\frac12P_{\text{зв}1}',fr'|{n(s["A1"])}-44388|={n(s["gap"])}\,\mathrm t',r'\frac12\cdot444=222\,\mathrm t',r'64.98\le222'],visual='approx_decision',phase='second',source=[0],action={'approx_reveal':1})
 beat(g,'AP2:reserve','裕量是预留的设计质量份额，不是船上的货物或舱室。','Запа́с водоизмеще́ния — резе́рв ма́ссы в прое́кте, не груз и не отсе́к.',visual='approx_table',phase='second_raw',params={'approx_rows':6,'approx_row':3})
 beat(g,'AP2:adjust','船体变重了64.98吨，从裕量中扣掉同样的质量。','Ко́рпус стал тяжелեе на 64.98 т; на сто́лько же уменьша́ем запа́с.'.replace('тяжелեе','тяжеле́е'),[r'P_{\text{зв}2}=P_{\text{зв}1}-(A_1-D_1)',r'=444-64.98=379.02\,\mathrm t',r'P_{\text{зв}2}\approx379\,\mathrm t'],visual='approx_table',phase='second',params={'approx_rows':6,'approx_row':3},action={'approx_reveal':1},source=[0])
 beat(g,'AP2:unchanged','本题只调整裕量，排水量和四个尺度保持不变。','В э́той зада́че меня́ем то́лько запа́с; водоизмеще́ние и разме́ры пре́жние.',[r'D_2=D_1=44388\,\mathrm t',r'L_2=L_1,\ B_2=B_1,\ T_2=T_1,\ H_2=H_1'],params={'dimensions':True})
 beat(g,'AP2:branch','若差额超过允许值，就要修正排水量；下一章会遇到这种情况。','При большо́й ра́зности ну́жно измени́ть водоизмеще́ние; э́то бу́дет в сле́дующей главе́.',visual='approx_decision',phase='second')
 g=group(c,'AP2:check','采用表与校核','Табли́ца и прове́рка')
 tables(g,'AP2:table',s['table'],'second',2)
 beat(g,'AP2:float','用采用尺寸复核浮性，差额按本作业模板检查。','По при́нятым разме́рам прове́рим пла́вучесть и ра́зность.',[r'D_{\mathrm{check}}=k\rho\delta L_2B_2T_2',r'=1.005\cdot1.025\cdot0.785',r'\qquad\cdot189.64\cdot26.60\cdot10.88',fr'={n(s["float_check"])}\,\mathrm t',r'|44381.30-44388|=6.70\,\mathrm t',r'6.70\,\mathrm t\ \longrightarrow\ 7\,\mathrm t'],params={'dimensions':True},source=[0])
 beat(g,'AP2:ratio','尺度比仍满足本课程油船采用条件。','Отноше́ние размере́ний удовлетворя́ет усло́вию для та́нкера в ку́рсе.',[r'\frac{H_2}{T_2}=\frac{14.89}{10.88}=1.37',r'\frac{H}{T}\ge1.25'],params={'dimensions':True},source=[1])
 c=chapter('approximation3','第三次近似','Тре́тье приближе́ние',3)
 g=group(c,'AP3:task','航速与湿表面积','Ско́рость и смо́ченная пове́рхность')
 beat(g,'AP3:goal','计算达到规定航速所需的主机功率，再修正船舶质量和尺寸。','Найдём мо́щность для за́данной ско́рости, зате́м уточни́м ма́ссы и разме́ры.')
 beat(g,'AP3:input','接着第二次近似计算：使用刚才的质量表和尺寸。','Продолжа́ем второ́е приближе́ние с его́ ма́ссами и разме́рами.',[r'D_2=44388\,\mathrm t',r'P_{\text{к.об.}2}=10876\,\mathrm t',r'P_{\text{зв}2}=379\,\mathrm t'],visual='approx_table',phase='second',params={'approx_rows':6,'approx_row':0})
 beat(g,'AP3:wet','水下外壳与水接触的面积，叫湿表面积；它不是水下体积。','Смо́ченная пове́рхность — пло́щадь подво́дной обши́вки, а не объём.',focus='Wet',action={'approx_reveal':1},anchor='hull')
 beat(g,'AP3:omega','按课程公式，用尺度估算湿表面积。','По фо́рмуле ку́рса оце́ним пло́щадь смо́ченной пове́рхности.',[r'\Omega=L_2T_2\left[2+1.37(\delta-0.274)\frac{B_2}{T_2}\right]',r'=189.64\cdot10.88\left[2+1.37(0.785-0.274)\frac{26.60}{10.88}\right]',fr'={n(t["omega"])}\,\mathrm{{m^2}}'],focus='Wet',source=[0])
 beat(g,'AP3:velocity','计算阻力时，先把15.9节换成米每秒。','Для сопротивле́ния переведём 15.9 у́зла в ме́тры в секу́нду.',[r'v=15.9\cdot0.514=8.1726\,\mathrm{m/s}'],visual='approx_power',phase='velocity',action={'approx_reveal':1})
 g=group(c,'AP3:friction','摩擦与附体','Тре́ние и выступа́ющие ча́сти')
 beat(g,'AP3:re','雷诺数把速度、船长和水的黏性联系起来，用它查摩擦系数。','Число́ Ре́йнольдса свя́зывает ско́рость, длину́ и вя́зкость; по нему́ найдём тре́ние.',[r'Re=\frac{vL_2}{\nu}',r'=\frac{8.1726\cdot189.64}{1.56\cdot10^{-6}}',r'\approx9.93\cdot10^8'],focus='Wet',source=[0])
 beat(g,'AP3:friction_chart','由雷诺数查摩擦系数；本方案采用约1.57×10⁻³。','Коэффицие́нт тре́ния нахо́дим по Re; в прое́кте принима́ем о́коло 1.57·10⁻³.',[r'\zeta_f\approx1.57\cdot10^{-3}'],visual='approx_chart',phase='friction',action={'approx_reveal':1})
 beat(g,'AP3:roughness','船长在150至210米区间，粗糙度附加系数查这一行。','Длина́ в интерва́ле 150–210 м; берём надба́вку из э́той строки́.',[r'150\le L_2=189.64\le210\,\mathrm m',r'\zeta_n=0.20\cdot10^{-3}'],visual='approx_lookup',phase='roughness',source=[1],action={'approx_reveal':1})
 beat(g,'AP3:appendages','本方案按单桨船，在130至200米区间查附体系数。','Для одновинтово́го су́дна длино́й 130–200 м берём коэффицие́нт выступа́ющих часте́й.',[r'130\le L_2=189.64\le200\,\mathrm m',r'\zeta_a=0.10\cdot10^{-3}'],visual='approx_lookup',phase='appendages',source=[1],action={'approx_reveal':1})
 g=group(c,'AP3:residual','剩余阻力与查图','Оста́точное сопротивле́ние')
 beat(g,'AP3:fr','弗劳德数结合航速和船长，确定查图所用曲线。','Число́ Фру́да по ско́рости и длине́ задаёт кри́вую на диагра́мме.',[r'Fr=\frac{v}{\sqrt{gL_2}}',r'=\frac{8.1726}{\sqrt{9.81\cdot189.64}}\approx0.19'],source=[0])
 beat(g,'AP3:residual_chart','在δ＝0.785处，读Fr约0.19曲线的剩余阻力系数。','При δ = 0.785 чита́ем кри́вую Fr о́коло 0.19.',[r'\zeta_r(\delta)\approx1.55\cdot10^{-3}'],visual='approx_chart',phase='residual',action={'approx_reveal':1})
 beat(g,'AP3:standard_chart','同一张图还给出标准相对长度，从右侧刻度读取。','По пра́вой шка́ле той же диагра́ммы чита́ем станда́ртную относи́тельную длину́.',[r'\Psi_0\approx5.54'],visual='approx_chart',phase='standard',action={'approx_reveal':1})
 beat(g,'AP3:relative','新船相对长度用船长除以排水体积的立方根。','Относи́тельная длина́ — длина́, делённая на куби́ческий ко́рень из объёма.',[r'V_2=\frac{D_2}{\rho}=\frac{44388}{1.025}=43305.37\,\mathrm{m^3}',r'\Psi=\frac{L_2}{\sqrt[3]{V_2}}=\frac{189.64}{\sqrt[3]{43305.37}}\approx5.40'],source=[0,1])
 beat(g,'AP3:psi_chart','采用邻近Fr＝0.20曲线，分别读取新船和标准长度的修正值。','По бли́зкой кри́вой Fr = 0.20 чита́ем попра́вки для но́вой и станда́ртной длины́.',[r'\alpha_\Psi\approx1.26,\quad\alpha_{\Psi_0}\approx1.20',r'k_\Psi=\frac{\alpha_\Psi}{\alpha_{\Psi_0}}=\frac{1.26}{1.20}=1.05'],visual='approx_chart',phase='psi',source=[1],action={'approx_reveal':1})
 beat(g,'AP3:beam_chart','宽吃水比约2.44，接近图的标准值2.5，本作业修正乘积取约1。','Отноше́ние B/T о́коло 2.44, бли́зко к 2.5; произведе́ние попра́вок принима́ем о́коло 1.',[r'\frac{B_2}{T_2}=\frac{26.60}{10.88}\approx2.44',r'k_{B/T}\alpha_{B/T}\approx1.00'],visual='approx_chart',phase='beam',action={'approx_reveal':1})
 beat(g,'AP3:zr','把两项修正乘到基础读数上，得到本船剩余阻力系数。','Умно́жим исхо́дный коэффицие́нт на попра́вки.',[r'\zeta_r=\zeta_r(\delta)k_\Psi k_{B/T}\alpha_{B/T}',r'=1.55\cdot10^{-3}\cdot1.05\cdot1.00',r'\approx1.63\cdot10^{-3}'],source=[0])
 beat(g,'AP3:z','四项相加，得到总阻力系数。','Сло́жим четы́ре составля́ющие коэффицие́нта сопротивле́ния.',[r'\zeta=\zeta_r+\zeta_f+\zeta_n+\zeta_a',r'=(1.63+1.57+0.20+0.10)\cdot10^{-3}',r'=3.50\cdot10^{-3}'],visual='approx_power',phase='resistance',source=[0],action={'approx_reveal':1})
 g=group(c,'AP3:power','功率与选机','Мо́щность и дви́гатель')
 beat(g,'AP3:drag','阻力与航行方向相反；拖曳功率等于阻力乘航速。','Сопротивле́ние напра́влено про́тив движе́ния; буксиро́вочная мо́щность равна́ си́ле на ско́рость.',[r'EPS=\left(\zeta\frac{\rho v^2}{2}\Omega\right)v',r'=\zeta\frac{\rho}{2}\Omega v^3'],visual='approx_power',phase='drag',source=[0,1],action={'approx_reveal':1})
 beat(g,'AP3:eps','这里密度用吨每立方米，计算结果直接为千瓦。','При пло́тности в то́ннах на кубоме́тр получа́ем килова́тты.',[r'EPS=3.50\cdot10^{-3}\frac{1.025}{2}',r'\qquad\cdot7658.02\cdot8.1726^3',fr'={n(t["EPS"])}\,\mathrm{{kW}}',r'\frac{\mathrm t}{\mathrm{m^3}}\mathrm{m^2}\frac{\mathrm{m^3}}{\mathrm{s^3}}=\frac{\mathrm{t\,m^2}}{\mathrm{s^3}}=\mathrm{kW}'],visual='approx_power',phase='eps')
 beat(g,'AP3:required','推进存在损失，主机所需功率要大于拖曳功率。','Из-за поте́рь необходи́мая мо́щность дви́гателя бо́льше буксиро́вочной.',[r'\eta=0.70\quad(\text{Т2})',r'N_{\text{тр}}=\frac{EPS}{\eta}',fr'=\frac{{{n(t["EPS"])}}}{{0.70}}={n(t["required"])}\,\mathrm{{kW}}'],visual='approx_power',phase='required',source=[0,1],action={'approx_reveal':1})
 beat(g,'AP3:margin','在所需功率之上，还要留至少15%的功率余量。','К необходи́мой мо́щности добавля́ем не ме́нее 15 проце́нтов.',[r'N_{\text{гл}}\ge1.15N_{\text{тр}}',fr'1.15\cdot{n(t["required"])}={n(t["minimum"])}\,\mathrm{{kW}}'],visual='approx_power',phase='margin',source=[0],action={'approx_reveal':1})
 beat(g,'AP3:catalog','按200千瓦档位向上选；12200不足，采用12400千瓦。','Шаг катало́га — 200 кВт; 12200 недоста́точно, выбира́ем 12400.',[r'\Delta N=200\,\mathrm{kW}',r'12200<12318.54\le12400',fr'N_{{\text{{гл}}}}={t["engine"]}\,\mathrm{{kW}}'],visual='approx_power',phase='catalog',source=[0],action={'approx_reveal':1})
 g=group(c,'AP3:mass','选机后的质量','Ма́ссы по́сле вы́бора')
 beat(g,'AP3:engine_mass','采用主机功率乘母型单位功率质量，更新动力装置质量。','По при́нятой мо́щности и уде́льной ма́ссе прототи́па уточня́ем ма́ссу СЭУ.',[r'P_{\text{сэу}3}=p_{\text{сэу}}N_{\text{гл}}',fr'=\frac{{720}}{{8580}}\cdot12400={n(t["Pe"])}\,\mathrm t'],focus='Equipment',source=[0])
 beat(g,'AP3:energy_mass','航程除以节速得到小时；再乘功率和单位能耗得到储备质量。','Да́льность де́лим на ско́рость в узла́х; вре́мя умножа́ем на мо́щность и расхо́д.',[r'P_{\text{сэз}3}=p_{\text{сэз}}N_{\text{гл}}\frac{R}{v}',r'=\frac{690\cdot15}{8580\cdot5000}\cdot12400\cdot\frac{5500}{15.9}',fr'={n(t["Pf"])}\,\mathrm t',r'\frac{\mathrm t}{\mathrm{kW\,h}}\cdot\mathrm{kW}\cdot\mathrm h=\mathrm t'],focus='Equipment',source=[0])
 beat(g,'AP3:fixed','主机选定后，本轮修正不再让这两项随排水量变化。','Дви́гатель вы́бран; в э́той попра́вке две э́ти ма́ссы постоя́нны.',visual='approx_table',phase='third_raw',params={'approx_rows':6,'approx_row':1})
 g=group(c,'AP3:correction','差额与诺曼修正','Ра́зность и попра́вка')
 beat(g,'AP3:A3','更新两项质量，其他项仍取第二次近似。','Заменя́ем две ма́ссы; оста́льные берём из второ́го приближе́ния.',[r'A_3=10876+1040.56+1034.83',r'\qquad+379+85+30700',fr'={n(t["A3"])}\,\mathrm t'],visual='approx_table',phase='third_raw',params={'approx_rows':6,'approx_row':-1})
 beat(g,'AP3:criterion','这次差额超过半个裕量，不能只靠调整裕量解决。','Тепе́рь ра́зность бо́льше полови́ны запа́са; ну́жно измени́ть водоизмеще́ние.',[r'|A_3-D_2|\le\frac12P_{\text{зв}2}',r'|44115.39-44388|=272.61\,\mathrm t',r'\frac12\cdot379=189.50\,\mathrm t',r'272.61>189.50'],visual='approx_decision',phase='third',source=[0],action={'approx_reveal':1})
 beat(g,'AP3:norman','设备和能源质量已固定，本轮按课程公式计算诺曼系数。','Ма́ссы СЭУ и запа́сов фиксиро́ваны; вычисля́ем коэффицие́нт Но́рмана.',[r'\eta_{\text{Н}}=\frac{1}{1-P_{\text{к.об.}2}/D_2}',r'=\frac{1}{1-10876/44388}\approx1.32'],source=[0])
 beat(g,'AP3:sign','总质量比原排水量小，带符号的质量增量为负。','Су́мма масс ме́ньше водоизмеще́ния; прираще́ние ма́ссы отрица́тельно.',[r'dP=A_3-D_2',r'=44115.39-44388=-272.61\,\mathrm t'],visual='approx_decision',phase='third',source=[0])
 beat(g,'AP3:D','把质量增量及其连带影响一起计入排水量。','Учитыва́ем прираще́ние ма́ссы и свя́занное с ним измене́ние водоизмеще́ния.',[r'D_3=D_2+\eta_{\text{Н}}dP',r'=44388+1.32(-272.61)',fr'={n(t["D_raw"])}\,\mathrm t',fr'D_3\approx{t["D_adopt"]:.0f}\,\mathrm t'],source=[0])
 g=group(c,'AP3:dimensions','尺度与船体再计算','Разме́ры и ма́сса ко́рпуса')
 beat(g,'AP3:lambda','排水量比开立方，得到长度方向使用的缩放系数。','Куби́ческий ко́рень из отноше́ния водоизмеще́ний даёт коэффицие́нт ма́сштаба.',[r'\lambda=\sqrt[3]{\frac{D_3}{D_2}}',r'=\sqrt[3]{\frac{44028}{44388}}\approx0.9973'],params={'dimensions':True},source=[0])
 for key,title,ru in [('L','船长','длину́'),('B','船宽','ширину́'),('T','吃水','оса́дку')]:
  beat(g,'AP3:scale'+key,f'{title}乘λ；这里只按真实比例变化。',f'Умножа́ем {ru} на λ; ма́сштаб измене́ния реа́льный.',[fr'{key}_3={key}_2\lambda={s[key]:.2f}\cdot0.9973',fr'={t[key]:.2f}\,\mathrm m'],params={'dimensions':True,'dimension_kind':key},source=[0],action={'approx_scale':1})
 beat(g,'AP3:scaleH','型深按H₂除以λ²计算；本题λ小于1，所以型深略增。','Высоту́ бо́рта де́лим на λ²; при λ ме́ньше 1 она́ немно́го растёт.',[r'H_3=\frac{H_2}{\lambda^2}=\frac{14.89}{0.9973^2}',r'=14.97\,\mathrm m',r'(L_2\lambda)(B_2\lambda)\frac{H_2}{\lambda^2}=L_2B_2H_2'],params={'dimensions':True,'dimension_kind':'H'},source=[0],action={'approx_scale':1})
 beat(g,'AP3:steel3','用修正后的四个尺度，重新计算钢船体质量。','По испра́вленным разме́рам пересчита́ем ма́ссу стально́го ко́рпуса.',[r'P_{\text{ст}3}=g_{\text{ст}}\delta^{1/3}L_3^{3/2}B_3H_3^{1/2}',r'=0.037\cdot0.785^{1/3}\cdot189.13^{3/2}',r'\qquad\cdot26.53\cdot14.97^{1/2}',fr'={n(t["steel"])}\,\mathrm t'],focus='Steel',scale=1,source=[0])
 beat(g,'AP3:equipment3','设备按同一条公式重算，再与钢船体相加。','Пересчита́ем обору́дование и приба́вим ма́ссу стально́го ко́рпуса.',[r'P_{\text{об}3}=0.97(189.13\cdot26.53\cdot14.97)^{2/3}',fr'={n(t["equipment"])}\,\mathrm t',fr'P_{{\text{{к.об.}}3}}={n(t["steel"])}+{n(t["equipment"])}',fr'={n(t["hull"])}\,\mathrm t'],focus='Equipment',scale=1)
 g=group(c,'AP3:check','功率与最终校核','Оконча́тельная прове́рка')
 beat(g,'AP3:power_check','尺度变了，还要确认原先选的12400千瓦主机够用。','По́сле измене́ния размере́ний прове́рим вы́бранные 12400 кВт.',[r'N_{\text{гл}}^{\prime}=(1.15N_{\text{тр}})\lambda^2',r'=12318.54\cdot0.9973^2=12252.11\,\mathrm{kW}',r'12200<12252.11<12400'],visual='approx_power',phase='check',scale=1,source=[0])
 beat(g,'AP3:A4','船体质量更新后，再加总六项质量。','По́сле уточне́ния ко́рпуса сно́ва сло́жим шесть масс.',[r'A_4=10839.54+1040.56+1034.83',r'\qquad+379+85+30700=44078.93\,\mathrm t',r'|44078.93-44028|=50.93\le189.50'],visual='approx_table',phase='third_updated',params={'approx_rows':6,'approx_row':0},scale=1)
 beat(g,'AP3:reserve3','差额已足够小，从裕量中扣除50.93吨。','Ра́зность уже́ мала́; вычтем 50.93 т из запа́са.',[r'P_{\text{зв}3}=P_{\text{зв}2}-(A_4-D_3)',r'=379-50.93=328.07\,\mathrm t'],visual='approx_table',phase='third_updated',params={'approx_rows':6,'approx_row':3},scale=1,source=[0])
 beat(g,'AP3:round_table','各项取整吨后，裕量按总量倒算为327吨，保持表格闭合。','По́сле округле́ния масс запа́с равен 327 т, что́бы су́мма совпала́.',[r'P_{\text{зв}3}=44028-(10840+1041+1035+85+30700)',r'=327\,\mathrm t'],visual='approx_table',phase='preliminary',params={'approx_rows':6,'approx_row':3},scale=1)
 beat(g,'AP3:float','采用尺寸给出的浮性排水量约44024吨，据此作最后调整。','По при́нятым разме́рам пла́вучесть даёт о́коло 44024 т; уточни́м ито́г.',[r'D_{\mathrm{check}}=k\rho\delta L_3B_3T_3',r'=1.005\cdot1.025\cdot0.785',r'\qquad\cdot189.13\cdot26.53\cdot10.85',r'=44023.75\,\mathrm t',r'|44023.75-44028|=4.25\,\mathrm t',r'D_3=44024\,\mathrm t'],params={'dimensions':True},scale=1,source=[0])
 beat(g,'AP3:reserve4','最终排水量减少4吨，表中的裕量也减少4吨。','Оконча́тельное водоизмеще́ние ме́ньше на 4 т; запа́с то́же уменьша́ем на 4 т.',[r'P_{\text{зв}4}=327+(44024-44028)=323\,\mathrm t'],visual='approx_table',phase='final',params={'approx_rows':6,'approx_row':3},scale=1)
 tables(g,'AP3:table',t['table'],'final',3)
 # The final reserve uses the source's fourth correction subscript.
 latex['AP3:table:row3']={lang:[dict(x,tex=x['tex'].replace('зв}3','зв}4'),linear=x['linear'].replace('зв}3','зв}4')) for x in rows] for lang,rows in latex['AP3:table:row3'].items()}
 beat(g,'AP3:residual_check','最终质量表闭合；浮性复核只差0.25吨。','Ито́говая су́мма масс совпада́ет; ра́зность по пла́вучести — 0.25 т.',[r'\sum P_i-D_3=0',r'|44023.75-44024|=0.25\,\mathrm t'],params={'dimensions':True},scale=1)
 for a,b in [('L','B'),('B','T'),('H','T')]:
  beat(g,'AP3:ratio'+a+b,'比较母型与新船的这个尺度比。','Сравни́м э́то отноше́ние размере́ний с прототи́пом.',[fr'\frac{{{a}_0}}{{{b}_0}}={d["inputs"][a+"0"]/d["inputs"][b+"0"]:.2f}',fr'\frac{{{a}_3}}{{{b}_3}}=\frac{{{t[a]:.2f}}}{{{t[b]:.2f}}}={t[a]/t[b]:.2f}']+([r'\frac{H}{T}\ge1.25'] if a=='H' else []),params={'dimensions':True},scale=1,source=[2] if a=='H' else [])
 beat(g,'AP3:handoff','这些最终尺寸继续用于下一章的舱壁布置。','По э́тим оконча́тельным разме́рам расста́вим перебо́рки в сле́дующей главе́.',[r'L_3=189.13,\ B_3=26.53\,\mathrm m',r'T_3=10.85,\ H_3=14.97\,\mathrm m',r'D_3=44024\,\mathrm t,\quad N_{\text{гл}}=12400\,\mathrm{kW}'],params={'dimensions':True},scale=1)
 # Table beats at the end retain the final model dimensions on return to 3D.
 for g in c['groups']:
  for b in g['beats']:
   if b['id'].startswith('AP3:table:'):b['scene_params']['approx_scale']=1
 # Explicit mathematical line breaks, never shrink complete long expressions.
 replacements={
 'AP2:delta0':{1:r'=\frac{27590}{\begin{gathered}1.005\cdot1.025\cdot147.20\\\cdot24.50\cdot9.80\end{gathered}}'},
 'AP2:gst':{1:r'=\frac{5430}{\begin{gathered}0.76^{1/3}\cdot147.20^{3/2}\\\cdot24.50\cdot13.40^{1/2}\end{gathered}}'},
 'AP2:steel':{1:r'\begin{gathered}=0.037\cdot0.785^{1/3}\\\cdot189.64^{3/2}\end{gathered}'},
 'AP2:gob':{1:r'=\frac{1290}{\left(\begin{gathered}147.20\cdot24.50\\\cdot13.40\end{gathered}\right)^{2/3}}'},
 'AP2:equipment':{1:r'=0.97\left(\begin{gathered}189.64\\\cdot26.60\\\cdot14.89\end{gathered}\right)^{2/3}'},
 'AP3:omega':{0:r'\Omega=2L_2T_2+1.37(\delta-0.274)L_2B_2',1:r'\begin{gathered}=2\cdot189.64\cdot10.88\\+1.37(0.785-0.274)\\\cdot189.64\cdot26.60\end{gathered}'},
 'AP3:z':{1:r'=\left(\begin{gathered}1.63+1.57\\+0.20+0.10\end{gathered}\right)10^{-3}'},
 'AP3:energy_mass':{1:r'\begin{gathered}=\frac{690\cdot15}{8580\cdot5000}\\\cdot12400\cdot\frac{5500}{15.9}\end{gathered}'},
 'AP3:steel3':{1:r'\begin{gathered}=0.037\cdot0.785^{1/3}\\\cdot189.13^{3/2}\end{gathered}'},
 'AP3:equipment3':{0:r'P_{\text{об}3}=0.97\left(\begin{gathered}189.13\\\cdot26.53\\\cdot14.97\end{gathered}\right)^{2/3}'},
 'AP3:round_table':{0:r'P_{\text{зв}3}=44028-10840-1041-1035-85-30700'}}
 for c in new:
  for g in c['groups']:
   for b in g['beats']:
    b['scene_params']['approx_flow']=''
    if b['id'] in ['AP3:velocity','AP3:drag','AP3:z']:
     b['visual']='';b['scene_params']['approx_flow']='velocity' if b['id']=='AP3:velocity' else 'drag'
    if b['id'] in ['AP2:criterion','AP3:margin','AP3:required','AP3:catalog','AP3:norman'] and b.get('source_rule'):b['source_phrase']=b['words'].copy()
    if b['id'] in replacements:
     for i,value in replacements[b['id']].items():
      for lang in ['zh','ru']:
       latex[b['id']][lang][i]=dict(tex=re.sub(r'(?<=\d)\.(?=\d)','{,}',value) if lang=='ru' else value,linear=value)
    # Three dimensions shrink together once, then H changes separately.
    if b['id'] in ['AP3:scaleL','AP3:scaleB','AP3:scaleT']:
     b['scene_params']['approx_h_scale']=0
     if b['id']!='AP3:scaleL':
      b.pop('action',None);b.pop('start_params',None);b['scene_params']['approx_scale']=1
    elif b['id']=='AP3:scaleH':
     b['scene_params']['approx_scale']=1;b['action']['params']={'approx_h_scale':1};b['start_params']={'approx_h_scale':0}
    else:b['scene_params']['approx_h_scale']=b['scene_params'].get('approx_scale',0)
 for c in new:
  for g in c['groups']:
   for b in g['beats']:
    for lang in ['zh','ru']:
     for row in latex[b['id']][lang]:
      row['tex']=row['tex'].replace(r'\qquad',r'\;').replace(r'\quad(\text{Т2})','')
      row['linear']=row['tex']
    b['lines']=[row['tex'] for row in latex[b['id']]['zh']]
 courses=[c for c in read('content/courses.json') if c['id'] not in ['approximation2','approximation3']]
 idx=next(i for i,c in enumerate(courses) if c['id']=='dimensions')+1;courses[idx:idx]=new
 from chapter_refinements import apply as refine_chapters
 refine_chapters(courses,latex)
 write('content/courses.json',courses);write('content/latex_source.json',latex)
 graph=read('content/knowledge_map.json');graph['nodes']=[x for x in graph['nodes'] if x['id'] not in ['approximation2','approximation3']]
 for i,c in enumerate(new):graph['nodes'].append(dict(id=c['id'],course=c['id'],step='',title=c['title'],assignment=['4a','5a'][i],subject=bi('Т2','Т2'),position=[420,960+i*175]))
 for x in graph['nodes']:
  if x['id']=='bulkheads':x['position']=[420,1310]
 graph['edges']=[e for e in graph['edges'] if e['to'] not in ['bulkheads','approximation2','approximation3']]
 for i,(a,b) in enumerate([('dimensions','approximation2'),('approximation2','approximation3'),('approximation3','bulkheads')]):
  if any(x['id']==b for x in graph['nodes']):graph['edges'].append(dict(**{'from':a,'to':b,'kind':'recommended','route':[[420,833+175*i],[420,912+175*i]]}))
 graph['extent']=[1140,1395];write('content/knowledge_map.json',graph)
 # Shared generated constants are consumed by bulkhead math (no duplicated adoption).
 constants='extends RefCounted\n# Generated from approximation_calculations.py.\n'
 for key,value in d['final'].items():constants+=f'const {key}:={float(value)}\n'
 constants+=f'const HULL_MASS:={float(t["table"][0])}\nconst ENGINE_MASS:={float(t["table"][1])}\n'
 (ROOT/'core/approximation_final.gd').write_text(constants,encoding='utf8')
 terms=read('content/notation_terms.json')
 for base,sub,ru,zh in [('P','ст','стально́й ко́рпус','钢船体质量'),('P','об','обору́дование','船舶设备质量'),('P','к.об.','ко́рпус с обору́дованием','船体与设备合计质量'),('g','ст','стально́й ко́рпус','钢船体质量估算系数'),('g','об','обору́дование','设备质量估算系数'),('N','тр','тре́буемая мо́щность','所需主机功率'),('N','гл','гла́вный дви́гатель','主机功率'),('\\eta','Н','Но́рман','诺曼系数')]:
  terms[base+'|'+sub]=ru+'\n'+zh
  for j in range(5):terms[base+'|'+sub+str(j)]=ru+'\n'+zh+f'；阶段编号 {j}'
 write('content/notation_terms.json',terms)
 audit=read('content/notation_audit.json')
 audit['records']=[r for r in audit['records'] if not r['id'].startswith(('AP2:','AP3:'))]
 for c in new:
  for g in c['groups']:
   for b in g['beats']:
    rows=[r['tex'] for r in latex[b['id']]['zh']]
    audit['records'].append(dict(id=b['id'],sources=d['provenance']['methods'],before=rows,after=rows,changed=False,teaching_addition=True))
 write('content/notation_audit.json',audit)
 manifest=read('content/manifest.json');manifest['chapters']=len(courses);manifest['beats']=sum(len(g['beats']) for c in courses for g in c['groups']);write('content/manifest.json',manifest)
 print('Approximations:',[(c['id'],sum(len(g['beats']) for g in c['groups'])) for c in new])
if __name__=='__main__':run()
