"""Source-aware teaching edits. Applied after notation normalization on every build."""
import copy
import re
import json


def apply(courses, latex, linear, root):
    lookup = {b['id']: b for c in courses for g in c['groups'] for b in g['beats']}
    def words(id, zh, ru):
        lookup[id].update(text=zh, words={'zh': zh, 'ru': ru})
    def rows(id, values):
        lookup[id]['lines'] = values
        latex[id] = {lang: [{'tex': re.sub(r'(?<=\d)\.(?=\d)', '{,}', t) if lang == 'ru' else t,
                            'linear': linear(t)} for t in values] for lang in ['zh', 'ru']}
    def insert(before, id, zh, ru, values=()):
        original = lookup[before]
        b = copy.deepcopy(original)
        for key in ['action', 'defer_record', 'source_rule', 'source_rows', 'source_phrase', 'record_label']:
            b.pop(key, None)
        # A new explanatory beat inherits the stable starting scene, not its later action.
        b['id'] = id
        for c in courses:
            for g in c['groups']:
                if original in g['beats']:
                    g['beats'].insert(g['beats'].index(original), b)
                    lookup[id] = b; words(id, zh, ru); rows(id, list(values)); return b
    def source(id, indexes, ref, phrase=False):
        b = lookup[id]
        rule = {'kind': 'formula', 'teacher_reference': ref}
        b['source_rule'] = rule
        b['source_rows'] = {str(i): rule for i in indexes}
        if phrase: b['source_phrase'] = copy.deepcopy(b['words'])

    words('dimensions:length', '本图的船长 L 沿纵向量；计算时须沿用题目规定的长度口径。',
          'Длину́ L измеря́ем вдоль су́дна; в расчёте испо́льзуем длину́ из усло́вия.')
    words('dimensions:beam', '船宽 B 横向量取；它不一定等于甲板边缘的宽度。',
          'Шири́ну B измеря́ем поперёк су́дна; шири́на па́лубы мо́жет отлича́ться.')
    words('B01:width', '题给 B＝15 米，用作参考矩形的宽；不能据此确定真实水线轮廓。',
          'Да́нная шири́на B = 15 м задаёт прямоуго́льник, но не то́чную фо́рму ватерли́нии.')
    for id, zh, ru in [
        ('L05:P_t', '十三项质量相加，得到全船总质量。', 'Скла́дываем трина́дцать масс: получа́ем ма́ссу всего́ су́дна.'),
        ('L05:moment_z_tm', '十三项 P·z 相加，只汇总竖向质量矩。', 'Скла́дываем трина́дцать произведе́ний P·z: э́то моме́нт по высоте́.'),
        ('L05:moment_x_tm', '十三项 P·x 相加，只汇总纵向质量矩。', 'Скла́дываем трина́дцать произведе́ний P·x: э́то продо́льный моме́нт.'),
        ('sample:before', '竖向总质量矩除以总质量，得到移动前的重心高度。', 'Моме́нт по высоте́ де́лим на ма́ссу: получа́ем исхо́дную высоту́ G.'),
        ('T02:fuel', '每输出一千瓦时能量消耗多少吨燃油，由母型反算。', 'По прототи́пу нахо́дим расхо́д то́плива на оди́н килова́тт-час.'),
        ('T05:adopt', '本方案后续采用排水量44388吨。', 'В э́том прое́кте да́лее принима́ем водоизмеще́ние 44388 т.'),
        ('T14:adopt', '本方案最终采用：船宽26.60米，型深14.89米。', 'В прое́кте принима́ем шири́ну 26.60 м и высоту́ бо́рта 14.89 м.'),
        ('T09:underdeck', '油船按课件增加0.035，估算甲板下容积的丰满系数。', 'Для та́нкера добавля́ем 0.035: получа́ем полноту́ подпа́лубного объёма.'),
        ('T11:ballast', '本题油船的压载舱容积，按课件取液货舱容积的38%。', 'Для та́нкера по зада́нию объём балла́ста — 38% грузово́го объёма.'),
        ('T11:total', '乘1.06，为尚未逐项计算的干舱室增加容积。', 'Мно́житель 1.06 учитыва́ет дополни́тельные сухи́е помеще́ния.'),
        ('T12:centres', 'G是重心，C是浮心；分别用Z_g和z_c表示距基本平面的高度。', 'G — центр масс, C — центр величины́; Z_g и z_c — их высо́ты над основно́й пло́скостью.'),
        ('T12:stability:meaning', '初稳性高＝浮心高度＋横稳心半径－重心高度。', 'Метацентри́ческая высота́ равна́ z_c плюс r ми́нус Z_g.'),
        ('T12:stability', '本次初步设计按课件取h/B＝0.06；这不是所有载况的合格判据。', 'В э́том приближе́нии принима́ем h/B = 0.06; э́то не прове́рка всех слу́чаев нагру́зки.'),
    ]: words(id, zh, ru)
    for id,b in lookup.items():
        if id.startswith('L04:item') and b.get('record_label'):
            b['record_label']['zh']='全船载荷 '+b['record_label']['zh']
            b['record_label']['ru']='Нагру́зка су́дна '+b['record_label']['ru']

    insert('T02:fuel', 'T02:fuel:units', '航程除以节得小时；功率乘小时得千瓦时。',
           'Да́льность, делённая на у́злы, даёт часы́; мо́щность, умно́женная на часы́, — килова́тт-часы́.',
           [r't_{\text{ход}}=\frac{R}{v}', r'\frac{\mathrm{nmi}}{\mathrm{nmi/h}}=\mathrm h',
            r'E_{\mathrm{out}}=Nt_{\text{ход}}', r'[E_{\mathrm{out}}]=\mathrm{kW\cdot h}'])
    values=[r'p_{\text{сэз}}=\frac{690}{8580\cdot(5000/15)}',
            r'\approx0.00024\,\mathrm{t/(kW\cdot h)}',r'P_{\text{сэз}}=p_{\text{сэз}}Nt_{\text{ход}}',
            r'\frac{\mathrm t}{\mathrm{kW\cdot h}}\cdot\mathrm{kW}\cdot\mathrm h=\mathrm t']
    values[0]=r'p_{\text{сэз}}=\frac{690}{8580\cdot\frac{5000}{15}}'
    rows('T02:fuel',values)
    insert('T11:cargo', 'T11:cargo:margin', '液货不能把舱容全部占满；课件用1.04计入所需空余。',
           'Для жи́дкого гру́за оставля́ем свобо́дный объём; по зада́нию испо́льзуем 1.04.',
           [r'W_{\text{гр}}=1.04\frac{P_{\text{гр}}}{\rho_{\text{гр}}}'])
    rows('T12:float:meaning',[r'V=\delta L_1B_1T_1',r'D_1=k\rho V',r'k=1.005',r'\rho=1.025\,\mathrm{t/m^3}'])
    words('T12:float:meaning','V是理论船体的排水体积；k＝1.005计入附体，ρ＝1.025为海水密度。',
          'V — теорети́ческий подво́дный объём; k = 1.005 учитыва́ет выступа́ющие ча́сти, ρ = 1.025 — пло́тность морско́й воды́.')
    rows('T12:stability:meaning',[r'h=z_c+r-Z_g',r'z_c=KC',r'r=CM',r'Z_g=KG'])
    rows('T12:stability',[r'z_c=0.50\sqrt{\frac{\alpha}{\delta}}T_1',r'r=\frac{0.0862\alpha^2B_1^2}{\delta T_1}',r'Z_g=\zeta H_1',r'z_c+r-Z_g=0.06B_1'])
    rows('T09:zeta',[r'\zeta=\frac{Z_{g0}}{H_0}=\frac{8.31}{13.4}',r'\zeta=0.62,\quad Z_g=\zeta H_1'])
    rows('T08:length',[r'l=2.13\sqrt[3]{v}',r'L_1=l\sqrt[3]{D_1}',
                      r'l=2.13\sqrt[3]{15.9}=5.3560585',r'L_1=189.64\,\mathrm m'])
    rows('T11:ballast',[r'W_{\text{бл}}=0.38W_{\text{гр}}',r'=0.38\cdot35475.56',r'=13480.71\,\mathrm m^3'])
    rows('T11:total',[r'W_{\mathrm{sum}}=35475.56+7716.91',r'+1377.56+60+13480.71',r'k_{\mathrm{co}}=1.06',r'W_{\mathrm{req}}=k_{\mathrm{co}}W_{\mathrm{sum}}',r'=61597.38\,\mathrm m^3'])
    for id in ['T13:back','T13:function']:
        values=[r['tex'].replace('289.45/B_1',r'\frac{289.45}{B_1}').replace('396.11/B_1',r'\frac{396.11}{B_1}') for r in latex[id]['zh']]
        rows(id,values)
    for key,a,b in [('LB','L','B'),('BT','B','T'),('HT','H','T')]:
        id='T16:'+key
        rows(id,[r['tex'].replace(f'{a}_{i}/{b}_{i}',fr'\frac{{{a}_{i}}}{{{b}_{i}}}') for i,r in enumerate(latex[id]['zh'])])
    # Keep every numerical iteration in the record, without teaching bisection twice.
    dim=next(c for c in courses if c['id']=='dimensions')
    g=next(g for g in dim['groups'] if g['id']=='T13')
    merged=[]
    for n in [1,2,3]:merged += [fr'n={n}']+[r['tex'] for r in latex[f'T13:iteration{n}']['zh']]
    merged += [r['tex'] for r in latex['T13:trace']['zh']]+[r['tex'] for r in latex['T13:stop']['zh']]
    rows('T13:trace',merged)
    words('T13:trace','沿用二分法，保留每次迭代与停止检查；正根约为26.61264米。',
          'Сно́ва применя́ем деле́ние попола́м; все ша́ги и прове́рка сохране́ны. Положи́тельный ко́рень — о́коло 26.61264 м.')
    removed={f'T13:iteration{i}' for i in [1,2,3]}|{'T13:stop'}
    g['beats']=[b for b in g['beats'] if b['id'] not in removed]
    dim.setdefault('resume_aliases',{}).update({id:'T13:trace' for id in removed})

    insert('reserve:volume','reserve:known','独立题：吃水7.5米、型深10米；两层面积为2000和2120平方米。',
           'В отде́льной зада́че T = 7.5 м, H = 10 м; пло́щади — 2000 и 2120 м².',
           [r'T=7.5\,\mathrm m,\quad H=10\,\mathrm m',r'S_{\mathrm{water}}=2000\,\mathrm m^2',r'S_{\mathrm{deck}}=2120\,\mathrm m^2',r'V=12000\,\mathrm m^3'])
    insert('reserve:volume','reserve:height','水线以上还有2.5米高度；用上下两层面积的平均值近似。',
           'Над водо́й остаётся 2.5 м; берём сре́днее двух пло́щадей.',
           [r'H-T=10-7.5=2.5\,\mathrm m',r'S_{\mathrm{mean}}=\frac{2000+2120}{2}=2060\,\mathrm m^2'])
    rows('reserve:volume',[r'V_{\mathrm{res}}\approx2060\cdot2.5',r'=5150\,\mathrm m^3',r'\frac{V_{\mathrm{res}}}{V}\cdot100\%\approx42.92\%'])
    words('reserve:volume','平均面积乘高度，储备浮力容积约5150立方米，占排水体积42.92%。',
          'Сре́дняя пло́щадь на высоту́ даёт 5150 м³ — о́коло 42.92% подво́дного объёма.')
    lookup['reserve:volume'].pop('record_label',None)
    insert('load-centre:free','free_surface:given','九个舱的自由液面矩由原表给出，合计1734吨·米。',
           'Моме́нты свобо́дных пове́рхностей даны́ в табли́це; су́мма — 1734 т·м.',
           [r'\sum M_{\mathrm{free}}=1734\,\mathrm{t\cdot m}',r'\Delta=20616\,\mathrm t'])
    insert('load-centre:free','free_surface:height','总自由液面矩除以排水量，得到要扣去的稳性高。',
           'Су́мму моме́нтов де́лим на водоизмеще́ние: получа́ем попра́вку к высоте́ h.',
           [r'\Delta h=\frac{1734}{20616}=@free_correction@\,\mathrm m',r'\frac{\mathrm{t\cdot m}}{\mathrm t}=\mathrm m'])
    rows('load-centre:free',[r'h_{\mathrm{corr}}=h-\Delta h'])
    words('load-centre:free','从原初稳性高中扣去0.08411米；实际重心没有因此被整体抬高。',
          'Из h вычита́ем 0.08411 м; факти́ческий центр масс не поднима́ется на э́ту высоту́.')
    insert('norman-derive:differentiate','norman-derive:variables','F汇总随设计变化的质量；P是独立增加的载荷，θ代表航速等设计参数。',
           'F — ма́ссы, зави́сящие от прое́кта; P — незави́симая нагру́зка, θ — пара́метры, наприме́р ско́рость.',[r'D=F(D,\theta)+P'])
    insert('norman-derive:differentiate','norman-derive:fixed','先固定D，只改变设计参数，得到直接质量变化；随后计入D改变引起的连带变化。',
           'Снача́ла при постоя́нном D меня́ем пара́метры; зате́м учитыва́ем измене́ние масс из-за D.',
           [r'dF=\frac{\partial F}{\partial D}dD+[dF]^*'])
    rows('norman-derive:eta',[r'\eta_{\text{н}}=\frac{1}{1-\frac{\partial F}{\partial D}}',r'dD=\eta_{\text{н}}([dF]^*+dP)'])

    refs={'first':'2p/КП-ПС-1 приближение.docx','basic':'1p/Modul_1.docx','load':'1p/Modul_2.docx','norman':'3a/Modul_4.docx'}
    for id, indexes in {'T08:length':[0,1],'T09:delta':[1],'T09:alpha':[1],'T09:underdeck':[0],
                        'T11:cargo:margin':[0],'T11:ballast':[0],'T11:total':[2],
                        'T12:float:meaning':[0,1,2,3],'T12:stability':[0,1,2,3]}.items():
        source(id,indexes,refs['first'],id in ['T11:cargo:margin','T11:ballast','T11:total'])
    for id,indexes,ref in [('B01:ratio',[0],refs['basic']),('B03:sign',[0],refs['basic']),
                           ('B03:mean',[0],refs['basic']),('L01:meaning',[0,1],refs['load']),
                           ('T12:stability:meaning',[0],'5p/Modul_6. Остойчивость.docx'),
                           ('norman-derive:eta',[0,1],refs['norman'])]:source(id,indexes,ref)
    latex['_concept/stability']={lang:[dict(tex=r'h=z_c+r-Z_g',linear=linear(r'h=z_c+r-Z_g'))] for lang in ['zh','ru']}
    terms=json.loads((root/'content/notation_terms.json').read_text('utf8'))
    terms['k|со']='со — сухи́е отсе́ки\n干舱室；计入额外干舱室容积的修正系数'
    terms[r'\rho|гр']='гр — груз\n货物；液货密度'
    (root/'content/notation_terms.json').write_text(json.dumps(terms,ensure_ascii=False,indent=2),'utf8')
    # Each colored formula has a teacher reference; adopted values remain uncolored.
    report=[{'step':b['id'],'teacher_reference':b['source_rule']['teacher_reference'],'rows':list(b['source_rows'])}
            for b in lookup.values() if b.get('source_rule')]
    (root/'content/curriculum_source_styles.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),'utf8')
    audit=json.loads((root/'content/notation_audit.json').read_text('utf8'))
    records={r['id']:r for r in audit['records']}
    for id,langs in latex.items():
        if id not in lookup and not id.startswith('_'):continue
        final=[r['tex'] for r in langs['zh']]
        if id not in records:
            records[id]={'id':id,'sources':[], 'before':final, 'after':final, 'changed':False,
                         'teaching_addition':True}
        elif records[id]['after']!=final:
            records[id]['notation_pass']=records[id]['after']
            records[id]['after']=final;records[id]['changed']=True
            records[id]['teaching_revision']='2026-10-21: source formulas, units and continuous teaching audit'
    records['T09:zeta']['verified_teacher_symbol']='2p/КП-ПС-1 приближение.docx: Z_g, Z_g0 (Latin g)'
    records['T11:total']['verified_teacher_symbol']='2p/КП-ПС-1 приближение.docx: k_co (Latin co)'
    audit['records']=list(records.values())
    (root/'content/notation_audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),'utf8')
