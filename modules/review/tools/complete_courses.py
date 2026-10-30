"""Remaining oral lessons: short answers, sourced conditions, staged visual explanations."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def pair(zh,ru):return {'zh':zh,'ru':ru}
def complete(courses,bank):
    def add(n,title,answer,beats,module,boundary='',formulas=None):
        q=bank[n-1];qid=q['id'];bs=[]
        for i,(zh,ru) in enumerate(beats):
            beat={'id':f'{qid}:s{i+1}','text':zh,'words':pair(zh,ru),'phase':['intro','change','result'][i]}
            if i==1:beat['action']={'params':{'progress':1.0},'duration':4.5 if n in [20,21,24] else 3.0}
            bs.append(beat)
        courses.append({'id':qid,'title':pair(f'{n:02} · {title[0]}',f'{n:02} · {title[1]}'),
          'question':pair(q['title_zh'],q['question_ru']),'question_original':q['question_original'],
          'question_speech':q['question_ru'],'answer':pair(*answer),'initial':{'progress':0.0},
          'summary':{'params':{'progress':1.0},'phase':'result'},'characters_per_second':25,'busy_policy':'finish','view':'technical',
          'groups':[{'id':qid,'title':pair('看原因','Почему́?'),'beats':bs}],
          'source':{'question':f'5p/Вопросы для подготовки по первой недели обучения.docx #{n}','module':module,'boundary':boundary},
          'formulas':formulas or {}})
    add(3,('哪些阶段检查稳性？','Когда́ проверя́ют осто́йчивость?'),
        ('草图设计和技术设计结束时。','В конце́ эски́зного и техни́ческого прое́ктов.'),[
        ('原题未附选项；模块列出草图设计和技术设计。','В мо́дуле: эски́зный и техни́ческий прое́кты.'),
        ('每个阶段结束时，都要检查稳性。','В конце́ ка́ждого эта́па проверя́ют осто́йчивость.')], '1p/Modul_1.docx §1.2','Original multiple-choice options absent; two stages from module.')
    add(6,('哪些载荷要素会变？','Что меня́ется в нагру́зке?'),
        ('排水量和重心的两个坐标都可能改变。','Водоизмеще́ние и координа́ты це́нтра масс.'),[
        ('D是总质量；xg、zg分别是重心的纵向和高度坐标。','D — ма́сса; xg и zg — координа́ты це́нтра масс.'),
        ('移动货物时，总质量不变，重心随质量位置改变。','Перемеща́ем груз: ма́сса та же, центр масс меня́ется.'),
        ('装卸货又会改变D，因此三者都可能变化。','При погру́зке и вы́грузке меня́ется и D.')], '1p/Modul_2.docx §2.1',
        'Two-point teaching system: 100 t at (2,1), 100 t moved from (6,1) to (8,3); not full ship geometry.',
        {'intro':[r'D=\sum P_i',r'x_g=\frac{\sum P_i x_i}{D},\quad z_g=\frac{\sum P_i z_i}{D}'],
         'change':[r'D=200\,\mathrm{t}',r'x_g=@xg@\,\mathrm{m},\quad z_g=@zg@\,\mathrm{m}'],
         'result':[r'D=200\,\mathrm{t},\quad x_g=5\,\mathrm{m},\quad z_g=2\,\mathrm{m}']})
    add(7,('怎样估算船体质量？','Как найти́ ма́ссу ко́рпуса?'),
        ('排水量乘船体质量系数。','Умножа́ем водоизмеще́ние на измери́тель ма́ссы ко́рпуса.'),[
        ('pк是船体质量占总质量的比例。','Измери́тель — до́ля ма́ссы ко́рпуса в D.'),
        ('例如总质量1000吨，船体占40%。','Приме́р: D — 1000 тонн; ко́рпус — 40 проце́нтов.'),
        ('船体质量为400吨；原题未给数值，答通式即可。','Ма́сса ко́рпуса — 400 тонн.')], '1p/Modul_2.docx §2.2.3',
        'Original X and coefficient unspecified; 1000 t and 0.4 are illustrative, not original inputs.',
        {'intro':[r'p_{\mathrm{к}}=\frac{P_{\mathrm{к}}}{D}'],
         'change':[r'P_{\mathrm{к}}=p_{\mathrm{к}}D'],
         'result':[r'P_{\mathrm{к}}=0.4\times1000=400\,\mathrm{t}']})
    add(8,('由装置质量求功率','Ма́сса → мо́щность'),
        ('装置质量除以每千瓦的质量系数。','Де́лим ма́ссу устано́вки на измери́тель.'),[
        ('系数表示每千瓦功率对应多少吨装置质量。','Измери́тель: то́нны на килова́тт.'),
        ('已知总质量，就用除法反求功率。','Де́лим ма́ссу на измери́тель; получа́ем мо́щность.'),
        ('例：100吨除以0.02吨每千瓦，得到5000千瓦。','Приме́р: 100 де́лим на 0,02 — 5000 килова́тт.')], '1p/Modul_2.docx §2.2.4',
        'Illustrative 100 t and 0.02 t/kW; original uses unspecified Y and p.',
        {'intro':[r'P_{\mathrm{сэу}}=p_{\mathrm{сэу}}N'],
         'change':[r'N=\frac{P_{\mathrm{сэу}}}{p_{\mathrm{сэу}}}'],
         'result':[r'N=\frac{100\,\mathrm{t}}{0.02\,\mathrm{t/kW}}=5000\,\mathrm{kW}']})
    add(9,('航行要多少能源储备？','Как рассчита́ть запа́сы?'),
        ('航程除以航速，再乘功率和单位消耗。','Да́льность де́лим на ско́рость; умножа́ем на мо́щность и уде́льный расхо́д.'),[
        ('先求航行时间：航程除以航速。','Вре́мя: да́льность де́лим на ско́рость.'),
        ('功率乘时间，得到这段航程的能量消耗。','Умножа́ем мо́щность на вре́мя.'),
        ('再乘单位消耗；注意公斤与吨的换算。','Умножа́ем на уде́льный расхо́д; перево́дим килогра́ммы в то́нны.')], '1p/Modul_2.docx §2.2.5',
        'Original unit incomplete. Example R=120 nmi, v=12 kn, N=1000 kW, p=0.2 kg/(kW h); 10 h and 2 t.',
        {'intro':[r't=\frac{R}{v}=\frac{120}{12}=10\,\mathrm{h}'],
         'change':[r'P_{\mathrm{сэз}}=p_{\mathrm{сэз}}N\frac{R}{v}'],
         'result':[r'P_{\mathrm{сэз}}=0.2\times1000\times10=2000\,\mathrm{kg}',r'2000\,\mathrm{kg}=2\,\mathrm{t}']})
    add(10,('要准备多少淡水？','Ско́лько ну́жно воды́?'),
        ('每人每天150升乘人数和天数，再除以1000得到约合吨数。','150 ли́тров умножа́ем на число́ люде́й и су́ток; де́лим на 1000 — получа́ем то́нны.'),[
        ('模块取每人每天150升淡水。','На челове́ка в су́тки — 150 ли́тров.'),
        ('例：5人、2天，需要10个人日的淡水。','Приме́р: 5 челове́к, 2 дня.'),
        ('共1500升，淡水质量约1.5吨。','Всего́ 1500 ли́тров: приме́рно 1,5 то́нны.')], '1p/Modul_2.docx §2.2.6',
        '150 L/person/day is course estimate, not assertion of current legal requirement; example n=5,S=2.',
        {'intro':[r'P_{\mathrm{пр.вод}}=0.15nS\,\mathrm{t}'],
         'change':[r'W=150\times5\times2\,\mathrm{L}'],
         'result':[r'W=1500\,\mathrm{L}',r'P_{\mathrm{пр.вод}}\approx1.5\,\mathrm{t}']})
    add(12,('双层底容积用哪些图？','Каки́е чертежи́ ну́жны?'),
        ('型线图和双层底图。','Теорети́ческий чертёж и чертежи́ двойно́го дна.'),[
        ('双层底是外底与内底之间的舱，不是船底外的水。','Двойно́е дно — ме́жду нару́жным и вну́тренним дном.'),
        ('型线图给外形，双层底图给内底与舱壁边界。','Чертежи́ даю́т фо́рму и грани́цы отсе́ка.'),
        ('每段容积约为截面积乘段长，再相加。','Объём ча́сти: пло́щадь × длина́. Объёмы скла́дываем.')], '5p/Modul_5. Виды вместимости.docx §4.1',
        'Drawing combination inferred from module theoretical boundaries; transverse/longitudinal sections illustrate a segmented area-times-length approximation.',
        {'result':[r'W\approx\sum_i A_i\,\Delta x_i']})
    add(13,('油船要算包装货舱容吗？','Ну́жна вмести́мость по шту́чному гру́зу?'),
        ('不用，计算液货舱的容积。','Нет. Рассчи́тывают вмести́мость цисте́рн.'),[
        ('件装货物会留下肋骨间隙，液体能进入这些间隙。','Я́щики оставля́ют ме́сто ме́жду констру́кциями; жи́дкость его́ заполня́ет.'),
        ('油船按液舱容积计算，不按箱货可占空间计算。','Для не́фти рассчи́тывают вмести́мость цисте́рн.'),
        ('实际舱容仍需扣除构件、残液和必要空余。','Из объёма вычита́ют ко́нструкции и необходи́мый недоли́в.')], '5p/Modul_5. Виды вместимости.docx §4.1',
        'Schematic liquid fill excludes structural solids and leaves ullage; no physical fluid solver.')
    add(16,('允许重心多高？','От чего́ зави́сит высота́ це́нтра масс?'),
        ('取决于水下形状、吃水和所需稳性。','От подво́дной фо́рмы, оса́дки и необходи́мой осто́йчивости.'),[
        ('M是横稳心；G在M下方的距离是初稳性高h。','M — метаце́нтр; h — расстоя́ние от G до M.'),
        ('重心越高，h越小；所需h限制重心高度。','Центр масс вы́ше — h ме́ньше.'),
        ('水下形状和吃水决定M的位置；这里只讨论初稳性。','Фо́рма и оса́дка определя́ют положе́ние M.')], '5p/Modul_6. Остойчивость.docx',
        'Initial stability only; example zc=1,r=3,required h=1 => zg max=3. Not full-angle stability verification.',
        {'intro':[r'h=z_c+r-z_g'],
         'change':[r'z_g\leq z_c+r-h_{\min}'],
         'result':[r'z_{g,\max}=1+3-1=3\,\mathrm{m}']})
    add(17,('船型影响横稳性吗？','Влия́ет ли фо́рма на осто́йчивость?'),
        ('会，船型影响横稳心的位置。','Да. Фо́рма влия́ет на положе́ние метаце́нтра.'),[
        ('C是水下体积的中心；CM这段距离就是r。','C — центр подво́дного объёма; CM — э́то r.'),
        ('比较同吃水的矩形船型：变宽使r增大。','Для прямоуго́льной фо́рмы: ши́ре — r бо́льше.'),
        ('保持重心不变时，M升高，初稳性高增大。','G тот же; M вы́ше — h бо́льше.')], '5p/Modul_6. Остойчивость.docx',
        'Upright prismatic rectangular comparison at T=1,G height=.7, B from2 to3; r=Ix/V=B²/(12T). C, G and M use this same metric scale.',
        {'intro':[r'r=\frac{I_x}{V}'],
         'change':[r'r=\frac{B^2}{12T}'],
         'result':[r'B:2\to3\,\mathrm{m},\quad r:0.33\to0.75\,\mathrm{m}']})
    add(18,('降低重心怎样改变稳性曲线？','Что бу́дет с угло́м зака́та?'),
        ('稳性消失角增大。','У́гол зака́та увели́чится.'),[
        ('曲线从正值回到零的位置，是稳性消失角。','У́гол зака́та: плечо́ по́сле положи́тельных значе́ний равно́ нулю́.'),
        ('船型与排水量不变，降低重心会增加复原力臂。','При той же фо́рме и D снижа́ем центр масс.'),
        ('正力臂延续到更大角度；须排除提前进水。','У́гол зака́та бо́льше, е́сли вода́ не поступа́ет ра́ньше.')], '5p/Modul_6. Остойчивость.docx',
        'Analytic teaching curve l0=sin(theta)(cos(theta)+.35), Δz=.2; updated l=l0+Δz sin(theta). No real hull/downflooding inference.',
        {'change':[r'l_1(\theta)=l_0(\theta)+\Delta z\sin\theta'],
         'result':[r'\Delta z>0\ \Longrightarrow\ l_1>l_0\quad(0<\theta<\pi)']})
    add(19,('减小型深怎样改变力臂峰值？','Как изме́нится ма́ксимум плеча́?'),
        ('最大复原力臂减小。','Ма́ксимум плеча́ уме́ньшится.'),[
        ('比较时保持船宽、吃水和重心高度不变。','B, T и апплика́та це́нтра масс неизме́нны.'),
        ('型深减小，甲板更早入水，大角度扶正能力减弱。','Высота́ бо́рта ме́ньше — па́луба ра́ньше в воде́.'),
        ('峰值下降，不代表初始斜率也下降。','Ма́ксимум ме́ньше; нача́льный накло́н мо́жет не измени́ться.')], '5p/Modul_6. Остойчивость.docx',
        'Illustrative trend curves with equal initial slope and different large-angle peaks; not integrated hydrostatics.')
    add(20,('船变窄，横摇周期怎样变？','Как изме́нится пери́од ка́чки?'),
        ('按其他条件相同的简化比较，周期增大。','При про́чих ра́вных пери́од увели́чится.'),[
        ('一次完整往返才是一个周期，不是摇摆角度。','Пери́од — вре́мя о́дного по́лного колеба́ния.'),
        ('按惯量等条件不变、初稳性降低的比较，横摇变慢。','При том же моме́нте ине́рции h ме́ньше — ка́чка ме́дленнее.'),
        ('只给船宽和重心，严格说不能唯一确定周期。','То́лько B и высоты́ G недоста́точно для то́чного пери́ода.')], '5p/Modul_6. Остойчивость.docx',
        'Conditional comparison: effective inertia and D fixed, h halves => period sqrt2 times. Width alone does not determine inertia or h.',
        {'intro':[r'\tau\approx2\pi\sqrt{\frac{I_{\mathrm{eff}}}{Dgh}}'],
         'result':[r'I_{\mathrm{eff}},D=\mathrm{const}:\quad h\downarrow\Rightarrow\tau\uparrow']})
    add(21,('横稳性为什么不能过大？','Почему́ осто́йчивость не должна́ быть сли́шком большо́й?'),
        ('横摇会过于急促。','Бортова́я ка́чка бу́дет сли́шком ре́зкой.'),[
        ('初稳性高过大，扶正作用很强。','Большо́е h — си́льное восстана́вливающее де́йствие.'),
        ('在相近惯量下，周期缩短，横摇变急。','При той же ине́рции пери́од ме́ньше, ка́чка ре́зче.'),
        ('图中摇幅相同；急促横摇会增大乘客加速度。','У́гол одина́ков; ускоре́ние пассажи́ров бо́льше.')], '5p/Modul_6. Остойчивость.docx',
        'Equal amplitude and effective inertia; h ratio4 gives frequency ratio2, peak angular acceleration ratio4. Not forced-wave amplitude claim.',
        {'change':[r'\tau\propto\frac{1}{\sqrt{h}}'],
         'result':[r'\theta=A\sin(\omega t),\quad |\ddot\theta|_{\max}=A\omega^2']})
    add(22,('进水会造成什么后果？','Како́вы после́дствия поступле́ния воды́?'),
        ('可能失去浮性和稳性。','Возмо́жна поте́ря плаву́чести и осто́йчивости.'),[
        ('进水可能使船下沉，消耗储备浮力。','Вода́ мо́жет уменьши́ть запа́с плаву́чести.'),
        ('不对称进水还可能造成横倾，并降低稳性。','Несимметри́чное затопле́ние мо́жет вы́звать крен.'),
        ('严重时可能沉没或倾覆，不是每次进水都必然如此。','Возмо́жны затопле́ние и опроки́дывание; не при ка́ждой ава́рии.')], '5p/Modul_7. Непотопляемость.docx §6.1–6.2',
        'Qualitative consequences, not computed damage equilibrium; no additive double-counting of lost buoyancy and added water.')
    add(23,('事故后怎样保住储备浮力？','От чего́ зави́сит сохра́нность плаву́чести?'),
        ('取决于初始储备浮力和水密分舱。','От нача́льного запа́са плаву́чести и деле́ния на водонепроница́емые отсе́ки.'),[
        ('水线上方水密封闭的体积提供储备浮力。','Водонепроница́емый объём над водо́й — запа́с плаву́чести.'),
        ('水密舱壁限制进水蔓延，保住未进水的舱。','Перебо́рка ограни́чивает поступле́ние воды́.'),
        ('若水密边界失效，更多舱进水，剩余储备更少。','При нару́шении грани́ц затопле́нных отсе́ков бо́льше.')], '5p/Modul_7. Непотопляемость.docx §6.2–6.4',
        'Side-view comparison of contained vs spreading flooding. Green above the blue waterline is surviving reserve volume; not a quantitative damage solution.')
    add(24,('事故中哪种情况更危险？','Како́й слу́чай опа́снее?'),
        ('若比较失去浮性和失去稳性：失去稳性更危险。','При сравне́нии с поте́рей плаву́чести — поте́ря осто́йчивости.'),[
        ('原题没有比较对象；先确认老师指哪两种情况。','Каки́е слу́чаи ну́жно сравни́ть?'),
        ('模块比较沉没与倾覆：失稳可能很快导致倾覆。','Поте́ря осто́йчивости мо́жет бы́стро приве́сти к опроки́дыванию.'),
        ('这个结论针对模块中的比较，不能套用所有事故。','Отве́т отно́сится к э́тому сравне́нию.')], '5p/Modul_7. Непотопляемость.docx §6.1',
        'Original comparison missing. Conditional answer for buoyancy loss vs stability loss only. Illustrative timelines are not seconds or universal speed ordering.')
    add(25,('艏尖舱进水为何通常不致失稳？','Почему́ фо́рпик обы́чно не вы́зывает поте́рю осто́йчивости?'),
        ('艏尖舱窄小，进水通常对称；“永远不会”并不普遍成立。','Фо́рпик у́зкий; затопле́ние обы́чно симметри́чное. Но не всегда́.'),[
        ('艏尖舱位于最前端，通常窄小、左右对称。','Фо́рпик в носу́: у́зкий и симметри́чный.'),
        ('典型进水主要引起艏倾，不直接产生左右不平衡。','Вода́ в носу́ вы́зывает диффере́нт на нос.'),
        ('对称不等于稳性不变，破损后仍须复核稳性。','Симме́трия не гаранти́рует осто́йчивость. Нужна́ прове́рка.')], '5p/Modul_7. Непотопляемость.docx §6.1–6.4',
        'Module gives a historical symmetric bow-damage example, not universal never-loss theorem; narrow symmetric flooding can still change GM.')
    courses.sort(key=lambda c:c['id'])
    assert len(courses)==25 and len({c['id'] for c in courses})==25
    # Compile each phase as one or two MathJax rows; reveal numeric examples only at result.
    src=json.loads((ROOT/'content/latex_source.json').read_text(encoding='utf-8'))
    for c in courses:
        for phase,rows in c.get('formulas',{}).items():
            src[c['id']+':'+phase]={lang:[{'tex':s,'linear':s} for s in rows] for lang in ['zh','ru']}
    (ROOT/'content/latex_source.json').write_text(json.dumps(src,ensure_ascii=False,indent=2),encoding='utf-8')
    (ROOT/'content/lessons.json').write_text(json.dumps(courses,ensure_ascii=False,indent=2),encoding='utf-8')
    terms=json.loads((ROOT/'content/notation_terms.json').read_text(encoding='utf-8'))
    for key,meaning in {'к':'ко́рпус\n船体','сэу':'судова́я энергети́ческая устано́вка\n船舶动力装置','сэз':'судовы́е энергети́ческие запа́сы\n船舶能源储备','пр.вод':'пре́сная вода́\n淡水'}.items():
        for base in ['P','p']:terms[base+'|'+key]=meaning
    (ROOT/'content/notation_terms.json').write_text(json.dumps(terms,ensure_ascii=False,indent=2),encoding='utf-8')
    audit=json.loads((ROOT/'qa/content-checks.json').read_text(encoding='utf-8'))
    audit['animated_questions']=list(range(1,26));audit['app_answers']=25
    (ROOT/'qa/content-checks.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
    from build_question_bank import words
    vocab=json.loads((ROOT/'qa/answer-vocabulary-audit.json').read_text(encoding='utf-8'))
    vocab['completed_answers']=[{'id':c['id'],'zh':c['answer']['zh'],'ru':c['answer']['ru'],'words':len(words(c['answer']['ru']))} for c in courses]
    vocab['answer_forms_not_in_questions']=sorted({w for c in courses for w in words(c['answer']['ru']) if w not in vocab['question_word_forms']})
    (ROOT/'qa/answer-vocabulary-audit.json').write_text(json.dumps(vocab,ensure_ascii=False,indent=2),encoding='utf-8')
    print('25 lessons authored; numerical examples and conditional answers explicitly bounded.')
