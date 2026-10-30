"""6a teaching sequence. Source values stay separate from design choices."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8'))
def write(p,v):(ROOT/p).write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf-8')
groups=[]; formulas={}
state=dict(bh_cut=0,bh_walls=0,bh_frames=0,bh_frame=60,bh_insert=0,bh_bottom=0,bh_side=0,bh_long=0,bh_range=0)
def group(id,zh,ru):
 g=dict(id=id,title=dict(zh=zh,ru=ru),beats=[]);groups.append(g)
def beat(id,zh,ru,focus='ship',camera='overview',change=None,formula=None,**kw):
 b=dict(id='BH:'+id,text=zh,words=dict(zh=zh,ru=ru),anchor=focus,camera=camera,start_params=dict(state),**kw)
 if change:
  state.update(change);b['action']=dict(duration=1.7,params=change)
 if formula:
  formulas[b['id']]={lang:[dict(tex=t,linear=t.replace('\\text','').replace('\\mathrm','').replace('\\cdot',' * ').replace('\\,',' ')) for t in formula] for lang in ['zh','ru']};b['lines']=['formula']
 groups[-1]['beats'].append(b)
group('purpose','目标与舱壁','Цель и перебо́рка')
beat('opening','把船长分配给各个舱室，确定舱壁落在哪个肋位，最后检查各舱能否拼成整艘船。','Разде́лим длину́ су́дна на отсе́ки, поста́вим перебо́рки на шпанго́уты и прове́рим о́бщую длину́.')
beat('inside','先打开外壳，看清船内待划分的空间。','Откро́ем ко́рпус и уви́дим простра́нство для отсе́ков.',change={'bh_cut':1},camera='cut')
beat('wall','横舱壁横跨船体，把前后的空间隔开。','Попере́чная перебо́рка разделя́ет простра́нство вдоль су́дна.',focus='wall',camera='wall',change={'bh_insert':1})
group('frames','肋骨与间距','Шпанго́уты')
state.update(bh_insert=0)
beat('rib','肋骨是支撑外板的骨架，内部仍然相通。','Шпанго́ут подде́рживает обши́вку; внутри́ остаётся прохо́д.',focus='rib',camera='rib',change={'bh_frames':1})
beat('spacing','两根相邻肋骨之间的距离，叫肋距。','Расстоя́ние ме́жду сосе́дними шпанго́утами называ́ется шпа́цией.',focus='rib',camera='rib',dimension='spacing')
beat('four','这里是四个间隔，因此需要看五根肋骨。','Здесь четы́ре проме́жутка и пять шпанго́утов.',focus='rib',camera='rib',dimension='four',change={'bh_frames':2})
beat('web','本算例船中部（不含艏部过渡区），每四个普通肋距设一道强肋骨。','В сре́дней ча́сти вне перехо́дного райо́на: оди́н ра́мный шпанго́ут че́рез четы́ре обы́чные шпа́ции.',focus='rib',camera='rib',dimension='four')
group('spacing','Т2肋距','Разме́ры Т2 и шпа́ция')
beat('dimensions','本章按这份Т2作业第三次近似的尺寸继续布置。','Испо́льзуем разме́ры Т2 из тре́тьего приближе́ния.',formula=[r'L=189.13\,\mathrm{m},\quad B=26.53\,\mathrm{m}',r'H=14.97\,\mathrm{m},\quad T=10.85\,\mathrm{m}',r'D=44024\,\mathrm{t}'])
beat('normal','算得普通肋距约0.86米，实际采用0.85米。','Расчётная шпа́ция — о́коло 0.86 ме́тра; принима́ем 0.85.',focus='rib',camera='side',formula=[r'a_0=0.002L+0.48',r'=0.002\cdot189.13+0.48',r'=0.85826\approx0.86\,\mathrm{m}',r'a_{\mathrm{adopt}}=0.85\,\mathrm{m}'],change={'bh_frames':3})
beat('peakspacing','尖舱采用0.60米；过渡区采用0.69米。','В пи́ках принима́ем 0.60 ме́тра, в перехо́дном райо́не — 0.69.',focus='fore',camera='side',formula=[r'0.75\cdot0.86=0.645\approx0.65',r'0.65<0.69<0.85<1.00\,\mathrm{m}'])
beat('webvalues','船中部（不含艏部过渡区）的强肋骨间距为3.40米；机舱为1.70米，艏部过渡区为1.38米。','Ра́мная шпа́ция: в грузово́й ча́сти 3.40, в МО 1.70, в перехо́дном райо́не 1.38 ме́тра.',focus='rib',formula=[r'4\cdot0.85=3.40\,\mathrm{m}',r'2\cdot0.85=1.70\,\mathrm{m}',r'2\cdot0.69=1.38\,\mathrm{m}'])
group('peaks','艏艉尖舱','Пи́ковые отсе́ки')
beat('fore_range','先求艏尖舱舱壁允许的位置范围。','Найдём допусти́мое положе́ние перебо́рки фо́рпика.',focus='fore',change={'bh_range':1},formula=[r'L_{\text{ф}}\in[0.05L,0.08L]',r'=[9.4565,15.1304]\,\mathrm{m}'])
beat('fore_integer','按0.60米肋距，可选16到25个整数间隔。','При шпа́ции 0.60 ме́тра допусти́мы от 16 до 25 проме́жутков.',focus='fore',formula=[r'\frac{L_{\text{ф}}}{0.60}\in[15.7608,25.2173]',r'n_{\text{ф}}\in\{16,\ldots,25\}'])
beat('fore_place','本作业选24个间隔，艏尖舱长14.40米。','Принима́ем 24 шпа́ции: длина́ фо́рпика 14.40 ме́тра.',focus='fore',camera='fore',change={'bh_walls':1,'bh_range':0},formula=[r'L_{\text{ф}}=24\cdot0.60=14.40\,\mathrm{m}'])
beat('aft_range','艉尖舱按船长的4%到8%取范围。','Для ахте́рпика берём от 4 до 8 проце́нтов длины́.',focus='aft',formula=[r'L_{\text{ахт}}\in[7.5652,15.1304]\,\mathrm{m}',r'n_{\text{ахт}}\in\{13,\ldots,25\}'])
beat('aft_integer','范围除以0.60米，下界向上取整、上界向下取整，允许13到25个间隔。','Де́лим грани́цы на 0.60 ме́тра: це́лых шпа́ций от 13 до 25.',focus='aft',formula=[r'\frac{7.5652}{0.60}=12.6087',r'\frac{15.1304}{0.60}=25.2173',r'n_{\text{ахт}}\in\{13,\ldots,25\}'])
beat('aft_place','13到25均在长度范围内；本方案选22个，得到13.20米。','Допусти́мы от 13 до 25; принима́ем 22 шпа́ции, получа́ем 13.20 ме́тра.',focus='aft',camera='aft',change={'bh_walls':2},formula=[r'L_{\text{ахт}}=22\cdot0.60=13.20\,\mathrm{m}'])
group('engine','机舱与泵舱','МО, насо́сное отделе́ние и та́нки')
beat('engine_range','机舱长度先按船长的14%到17%估算。','Длина́ МО составля́ет 14–17 проце́нтов длины́ су́дна.',focus='engine',formula=[r'L_{\text{МО}}\in[0.14L,0.17L]',r'=[26.4782,32.1521]\,\mathrm{m}'])
beat('engine_integer','按1.70米强肋骨间距，可选16到18个间隔。','При ра́мной шпа́ции 1.70 ме́тра выбира́ем от 16 до 18 проме́жутков.',focus='engine',formula=[r'\frac{L_{\text{МО}}}{1.70}\in[15.5754,18.913]',r'n_{\mathrm{web}}\in\{16,17,18\}'])
beat('engine_place','选18个强肋骨间隔，即36个普通间隔。','Принима́ем 18 ра́мных, и́ли 36 обы́чных шпа́ций.',focus='engine',camera='side',change={'bh_walls':3},formula=[r'L_{\text{МО}}=18\cdot1.70',r'=36\cdot0.85=30.60\,\mathrm{m}'])
beat('pump','本方案为泵舱采用一个框架间隔，长3.40米；不是所有油船都必须取此值。','Для насо́сного отделе́ния принима́ем одну́ ра́мную шпа́цию, 3.40 ме́тра; э́то вы́бор прое́кта.',focus='pump',camera='side',change={'bh_walls':4},formula=[r'L_{\text{НО}}=1\cdot3.40',r'=4\cdot0.85=3.40\,\mathrm{m}'])
beat('remaining','扣除两个尖舱、机舱和泵舱，得到货区长度。','Вычита́ем пи́ки, МО и насо́сное отделе́ние; получа́ем длину́ грузово́й ча́сти.',focus='cargo',formula=[r'L_{\text{гр}}=L-(L_{\text{ф}}+L_{\text{ахт}}+L_{\text{МО}}+L_{\text{НО}})',r'=189.13-(14.40+13.20',r'\qquad+30.60+3.40)',r'=127.53\,\mathrm{m}'])
group('transition','过渡区','Перехо́дный райо́н')
beat('transition','老师资料要求：过渡区至少延伸到距艏端0.2倍船长的位置。','По тре́бованию из материа́ла преподава́теля перехо́дный райо́н дохо́дит как ми́нимум до 0.2 длины́ от но́са.',focus='transition',camera='fore',change={'bh_range':2},formula=[r'L_{\text{пр}}\ge0.2L-L_{\text{ф}}',r'L_{\text{пр}}\ge37.826-14.40',r'L_{\text{пр}}\ge23.426\,\mathrm{m}'])
beat('transition_integer','最低长度除以0.69米并向上取整，至少需要34个普通间隔。','Минима́льную длину́ де́лим на 0.69 и округля́ем вверх: ну́жно не ме́нее 34 шпа́ций.',focus='transition',formula=[r'\frac{23.426}{0.69}=33.9507',r'\left\lceil33.9507\right\rceil=34'])
beat('conflict','本方案为衔接舱段采用37个间隔，长25.53米；37不是下限唯一确定的值。','Для компоно́вки принима́ем 37 шпа́ций, 25.53 ме́тра; нижняя грани́ца не тре́бует и́менно 37.',focus='transition',formula=[r'L_{\text{пр}}=37\cdot0.69=25.53\,\mathrm{m}',r'25.53\ge23.426'])
beat('recheck','本方案终点在61号肋位，距艏39.93米，满足要求不小于0.2L。','Коне́ц райо́на — шпанго́ут 61, в 39.93 ме́тра от но́са; тре́бование не ме́нее 0.2L вы́полнено.',focus='transition',formula=[r'24+37=61',r'x_{\text{пр}}=14.40+25.53=39.93\,\mathrm{m}',r'39.93\ge0.2L=37.826\,\mathrm{m}'])
group('cargo','六组货油舱','Шесть групп грузовы́х та́нков')
state.update(bh_range=0,bh_frames=0)
beat('six','本方案采用九道横水密舱壁，划出六组货油舱。','Принима́ем де́вять попере́чных водонепроница́емых перебо́рок и шесть групп та́нков.',focus='cargo',camera='top',record_label={'zh':'船长超过185 m；文件要求舱壁总数与船级社商定。本方案的九道为采用布置。','ru':'При длине́ бо́лее 185 м число́ перебо́рок согласу́ют с Реги́стром; здесь приня́то 9.'})
beat('fourholds','货区内再加入五道横舱壁，形成六组。','Пять перебо́рок внутри́ грузово́й ча́сти образу́ют шесть групп.',focus='cargo',camera='top',change={'bh_walls':9})
beat('allocate','第一组用36个过渡间隔；第二组接过渡区最后一个间隔。','В пе́рвой гру́ппе 36 перехо́дных шпа́ций; во второ́й остаётся одна́.',focus='hold1',formula=[r'37=36+1'])
beat('firsthold','第一组长24.84米。','Длина́ пе́рвой гру́ппы — 24.84 ме́тра.',focus='hold1',formula=[r'L_{\text{гр1}}=36\cdot0.69=24.84\,\mathrm{m}'])
beat('secondhold','第二组跨两种肋距，必须分段相加。','Во второ́й гру́ппе одна́ шпа́ция 0.69 ме́тра и 24 шпа́ции по 0.85.',focus='hold2',formula=[r'L_{\text{гр2}}=1\cdot0.69+24\cdot0.85',r'=21.09\,\mathrm{m}'])
beat('otherholds','其余四组各用24个普通间隔，每组20.40米。','В остальны́х четырёх гру́ппах по 24 шпа́ции; длина́ ка́ждой — 20.40 ме́тра.',focus='hold3',formula=[r'L_{\text{гр}3-6}=24\cdot0.85=20.40\,\mathrm{m}',r'24.84+21.09+4\cdot20.40=127.53\,\mathrm{m}'])
beat('webjoin','60到61号只有0.69米；61号设强肋骨，再按3.40米排列。','От 60 до 61 — 0.69 ме́тра; на 61 ста́вим ра́мный шпанго́ут, да́лее шаг 3.40 ме́тра.',focus='transition',formula=[r'n=60\to61:\quad a=0.69\,\mathrm{m}',r'n=61,65,69,\ldots,85'])
group('table','肋位校核','Шпанго́уты и прове́рка длины́')
beat('numbering','肋位从艏向艉编号；坐标换算必须按四个肋距区间计算。','Номера́ иду́т от но́са к корме́; расстоя́ние счита́ем по четырём уча́сткам.',camera='side',dimension='axis',formula=[r'x=L-s',r'0\le n\le24:\quad s=0.60n',r'24<n\le61:',r's=14.40+0.69(n-24)',r'61<n\le221:',r's=39.93+0.85(n-61)',r'221<n\le243:',r's=175.93+0.60(n-221)'])
names=['艏尖舱']+[f'货油舱组{i}' for i in range(1,7)]+['泵舱','机舱','艉尖舱']
rus=['Фо́рпик']+[f'Гру́ппа {i}' for i in range(1,7)]+['Насо́сное отделе́ние','МО','Ахте́рпик']
ns=[0,24,60,85,109,133,157,181,185,221,243]
ls=[14.4,24.84,21.09,20.4,20.4,20.4,20.4,3.4,30.6,13.2]
ss=[0]
for l in ls:ss.append(round(ss[-1]+l,2))
expr=['24\\cdot0.60','36\\cdot0.69','1\\cdot0.69+24\\cdot0.85']+['24\\cdot0.85']*4+['4\\cdot0.85','36\\cdot0.85','22\\cdot0.60']
for i in range(10):
 beat('row'+str(i),f'{names[i]}：{ns[i]}到{ns[i+1]}号肋位，长{ls[i]:.2f}米。',f'{rus[i]}: шпанго́уты {ns[i]}–{ns[i+1]}, длина́ {ls[i]:.2f} ме́тра.',focus=(['fore']+[f'hold{k}' for k in range(1,7)]+['pump','engine','aft'])[i],camera='side',table_rows=i+1,record_label={'zh':names[i],'ru':rus[i]},formula=[fr'n={ns[i]}\ldots{ns[i+1]}',fr'l={expr[i]}={ls[i]:.2f}\,\mathrm{{m}}',fr's={ss[i+1]:.2f}\,\mathrm{{m}}',fr'x={189.13-ss[i+1]:.2f}\,\mathrm{{m}}'])
beat('closure','十个纵向舱段合计189.13米，九道内部横舱壁全部落在强肋骨肋位。','Де́сять отсе́ков даю́т 189.13 ме́тра; де́вять перебо́рок стоя́т на ра́мных шпанго́утах.',camera='top',table_rows=10,formula=[r'14.40+24.84+21.09+4\cdot20.40',r'\quad+3.40+30.60+13.20=189.13\,\mathrm{m}',r'n=24,60,85,109,133,',r'\quad157,181,185,221'])
beat('drag','可移动第一、第二组之间的舱壁；两组总长保持不变。','Передви́ньте перебо́рку ме́жду пе́рвой и второ́й гру́ппами; о́бщая длина́ сохраня́ется.',camera='side',focus='wall',table_rows=10,experiment=True,formula=[r'n=@bh_n@\quad x=@bh_x@\,\mathrm{m}',r'l_1=@bh_l1@\,\mathrm{m}',r'l_2=@bh_l2@\,\mathrm{m}',r'l_1+l_2=@bh_pair@\,\mathrm{m}',r'\sum l_i=@bh_total@\,\mathrm{m}'])
group('section','双层结构','Двойно́е дно и двойно́й борт')
beat('doublebottom','外底和内底围成双层底空间，先确定它的高度。','Нару́жное и второ́е дно образу́ют двойно́е дно; найдём его́ высоту́.',focus='bottom',camera='section',change={'bh_bottom':1})
beat('dbformula','用型深估算双层底高度，得到约1.69米。','По высоте́ бо́рта получа́ем высоту́ двойно́го дна о́коло 1.69 ме́тра.',focus='bottom',camera='section',formula=[r'h_{\text{дд}}=0.0328H+1.2',r'=0.0328\cdot14.97+1.2',r'=1.691016\approx1.69\,\mathrm{m}'])
beat('dbcheck','再用船长、船宽和吃水计算下限，约1.52米。','По длине́, ширине́ и оса́дке проверя́ем ми́нимум: о́коло 1.52 ме́тра.',focus='bottom',camera='section',formula=[r'h_{\text{дд},\min}=\frac{L-40}{570}+0.04B+\frac{3.5T}{L}',r'=\frac{189.13-40}{570}+0.04\cdot26.53',r'\quad+\frac{3.5\cdot10.85}{189.13}',r'\approx1.52\,\mathrm{m}'])
beat('dbadopt','采用1.70米：高于计算下限，也没有超过2米。','Принима́ем 1.70 ме́тра: вы́ше ми́нимума и не бо́лее 2 ме́тров.',focus='bottom',camera='section',change={'bh_db_value':1},formula=[r'h_{\text{дд}}=1.70\,\mathrm{m}',r'1.52<1.70\le2.00'])
beat('doubleside','船侧外板和内舷围成双舷侧空间。','Нару́жный и вну́тренний борта́ образу́ют двойно́й борт.',focus='side',camera='section',change={'bh_side':1})
beat('deadweight','从排水量扣除船体设备与动力装置质量，得到载重量。','Из водоизмеще́ния вычита́ем ма́ссы ко́рпуса с обору́дованием и СЭУ; получа́ем дедве́йт.',focus='side',camera='section',formula=[r'DW=D-(P_{\text{к.об}}+P_{\text{сэу}})',r'=44024-(10840+1041)',r'=32143\,\mathrm{t}'])
beat('sideformula','代入载重量，双舷侧宽度算得约2.11米。','Подставля́ем дедве́йт: шири́на двойно́го бо́рта о́коло 2.11 ме́тра.',focus='side',camera='section',formula=[r'b_{\text{дб}}=0.5+\frac{DW}{20000}',r'=0.5+\frac{32143}{20000}',r'=2.10715\approx2.11\,\mathrm{m}'])
beat('sideadopt','采用2.20米，处于本作业规定的1到2.5米之间。','Принима́ем 2.20 ме́тра: в преде́лах от 1 до 2.5 ме́тра.',focus='side',camera='section',change={'bh_side_value':1},formula=[r'b_{\text{дб}}=2.20\,\mathrm{m}',r'1.00\le2.20\le2.50'])
group('longitudinal','纵向分隔','18 та́нков и ограни́чение длины́')
beat('longitudinal','加入两道纵舱壁，每组分成左、中央、右三个货油舱。','Две продо́льные перебо́рки де́лят ка́ждую гру́ппу на ле́вый, центра́льный и пра́вый та́нки.',focus='long',camera='section',change={'bh_long':1},formula=[r'6\cdot3=18'])
beat('longtop','六组乘三个，共18个货油舱；两侧双舷空间与货油舱分开。','Шесть групп по три — 18 грузовы́х та́нков; двойно́й борт отделён от них.',focus='long',camera='top')
beat('cargo_width','船宽扣除两侧双舷侧，得到货区净宽22.13米。','Вычита́ем двойны́е борта́: шири́на грузово́й ча́сти 22.13 ме́тра.',focus='side',camera='section',formula=[r'B_{\text{гр}}=B-2b_{\text{дб}}',r'=26.53-2\cdot2.20=22.13\,\mathrm{m}'])
beat('central','左右货油舱各采用6.65米，中央舱剩8.83米。','Бортовы́е та́нки — по 6.65 ме́тра; центра́льный — 8.83 ме́тра.',focus='long',camera='section',change={'bh_width_value':1},formula=[r'b_{\text{ц}}=22.13-2\cdot6.65',r'=8.83\,\mathrm{m}'])
beat('bi','从外舷到纵舱壁，要加上双舷侧宽度与边货油舱宽度。','От нару́жного бо́рта до продо́льной перебо́рки скла́дываем две ши́рины.',focus='long',camera='section',formula=[r'b_i=2.20+6.65=8.85\,\mathrm{m}'])
beat('multiple','这个距离与船宽之比大于五分之一。','Отноше́ние э́того расстоя́ния к ширине́ бо́льше одно́й пя́той.',focus='long',camera='section',formula=[r'\frac{b_i}{B}=\frac{8.85}{26.53}',r'\approx0.33>\frac{1}{5}'])
beat('tanklimits','两道纵舱壁且满足这个比例时，本作业采用0.2倍船长作为舱长上限。','При двух продо́льных перебо́рках и э́том отноше́нии преде́л длины́ та́нка — 0.2L.',focus='hold1',camera='top',formula=[r'l_{\text{доп}}=0.2L=37.826',r'\approx37.83\,\mathrm{m}'])
beat('tankcheck','最长货油舱24.84米，小于允许的37.83米。','Наибо́льшая длина́ та́нка 24.84 ме́тра, ме́ньше допусти́мой.',focus='hold1',camera='top',formula=[r'l_{\max}=24.84\,\mathrm{m}',r'24.84<37.826'])
beat('finish','现在对照全船：六组货油舱、泵舱、机舱和两个尖舱均已定位。','Тепе́рь все отсе́ки на ме́сте: шесть групп та́нков, насо́сное отделе́ние, МО и два пи́ка.',focus='ship',camera='top',table_rows=10)
for g in groups:
 for b in g['beats']:b['source']='6a/6a-Женя.docx · '+g['title']['zh']

from bulkhead_sources import apply
apply(groups, formulas)
from bulkhead_notation import apply as apply_notation
apply_notation(formulas)

course=dict(id='bulkheads',title={'zh':'舱壁布置','ru':'Расстано́вка перебо́рок'},initial=groups[0]['beats'][0]['start_params'],groups=groups,characters_per_second=26)
course['resume_aliases']={'BH:normal':'BH:webvalues_ordinary','BH:peakspacing':'BH:webtransition_ordinary'}
from chapter_refinements import apply as refine_chapters
refine_chapters([course],formulas)
write('content/bulkheads.json',course)
write('content/bulkheads_latex.json',formulas)
courses=read('content/courses.json');courses=[c for c in courses if c['id']!='bulkheads'];courses.append(course);write('content/courses.json',courses)
graph=read('content/knowledge_map.json')
graph['nodes']=[n for n in graph['nodes'] if n['id']!='bulkheads']
graph['nodes'].append(dict(id='bulkheads',course='bulkheads',step='',title=course['title'],assignment='6a',subject={'zh':'Т2 · 189.13 m','ru':'Т2 · 189.13 м'},position=[420,960]))
graph['edges']=[e for e in graph['edges'] if e['to']!='bulkheads'];graph['edges'].append(dict(**{'from':'dimensions','to':'bulkheads','kind':'recommended','route':[[420,833],[420,912]]}));graph['extent']=[1140,1045];write('content/knowledge_map.json',graph)
print(sum(len(g['beats']) for g in groups),'bulkhead beats')
from build_approximations import run as build_approximations
build_approximations()
