"""Continuous teaching repairs shared by every topic rebuild."""
import copy
import re

def apply(courses, formulas, readings):
    index={b['id']:b for c in courses for g in c['groups'] for b in g['beats']}
    def words(id,zh,ru):index[id].update(text=zh,words={'zh':zh,'ru':ru})
    def row(id,values):formulas[id]={lang:[dict(tex=t,linear=t) for t in values] for lang in ['zh','ru']}
    def insert(before,id,zh,ru,values):
        old=index[before];b=copy.deepcopy(old);b.pop('action',None);b['id']=id
        for c in courses:
            for g in c['groups']:
                if old in g['beats']:
                    g['beats'].insert(g['beats'].index(old),b);index[id]=b;words(id,zh,ru);row(id,values);return
    titles={
        'Q01':('谁提出要求','Кто задаёт тре́бования'), 'Q02':('哪些量会变','Что меня́ется'),
        'Q03':('何时检查稳性','Когда́ проверя́ть осто́йчивость'), 'Q04':('竣工资料','Исполни́тельная документа́ция'),
        'Q05':('选择母型','Вы́бор прототи́па'),'Q06':('质量与重心','Ма́сса и центр масс'),
        'Q07':('船体质量','Ма́сса ко́рпуса'),'Q08':('动力功率','Мо́щность устано́вки'),
        'Q09':('能源储备','Энергети́ческие запа́сы'),'Q10':('淡水质量','Ма́сса пре́сной воды́'),
        'Q11':('增大舱容','Увеличе́ние объёма'),'Q12':('双层底容积','Объём двойно́го дна'),
        'Q13':('液货怎样计容','Объём жи́дкого гру́за'),'Q14':('先到质量上限','Преде́л по ма́ссе'),
        'Q15':('单位舱容不足','Недоста́ток вмести́мости')}
    for c in courses:
        c.setdefault('resume_aliases',{})
        for g in c['groups']:
            if g['id'] in titles:g['title']=dict(zip(['zh','ru'],titles[g['id']]))
            else:
                g['title']={lang:re.sub(r'^\d+\s*[·.]\s*','',text) for lang,text in g['title'].items()}
            if c['id']=='stability':
                qid=g['id'];old_id=f'ST:{qid}:answer';new_id=f'TOP:{qid}:answer'
                if old_id in index and new_id in index:
                    # Keep the established stable ID and its state, controls and formula record.
                    b=index[old_id];recap=index[new_id]
                    b.update(words=recap['words'],text=recap['text'],recap=recap['recap'])
                    if recap.get('condition'):b['condition']=recap['condition']
                    g['beats']=[x for x in g['beats'] if x['id']!=new_id]
                    c['resume_aliases'][new_id]=old_id
    words('Q03:s2','草图设计和技术设计结束时，都要检查稳性。',
          'В конце́ эски́зного и техни́ческого прое́ктов проверя́ют осто́йчивость.')
    words('TOP:loads:foundation_end','本课DW指随装载改变的实际载荷；额定载货能力是另一回事。',
          'Здесь дедве́йт — переменная нагру́зка; преде́льная грузоподъёмность — друго́е поня́тие.')
    words('Q09:s2','功率乘航行时间，得到输出能量；不是燃油质量。',
          'Мо́щность на вре́мя даёт эне́ргию, а не ма́ссу то́плива.')
    words('Q09:s3','再乘每千瓦时耗油量；本例统一用吨、千瓦和小时。',
          'Умножа́ем на расхо́д за килова́тт-час; здесь испо́льзуем то́нны, килова́тты и часы́.')
    # Preserve the original numerical example and add its dimensional check.
    # Existing static rows live in latex_source, hence the new record has its own ID.
    insert('Q09:s3','Q09:units','先核对单位：吨每千瓦时乘千瓦时，结果才是吨。',
           'Прове́рим едини́цы: то́нны на килова́тт-час умножа́ем на килова́тт-часы́; получа́ем то́нны.',
           [r'\frac{\mathrm{nmi}}{\mathrm{nmi/h}}=\mathrm h',r'\frac{\mathrm t}{\mathrm{kW\cdot h}}\cdot\mathrm{kW}\cdot\mathrm h=\mathrm t'])
    insert('Q14:example','Q14:ratios','μгр是每吨货需要的空间；μс是船每吨载货能力配有的舱容。',
           'μгр — объём на то́нну гру́за; μс — вмести́мость на то́нну грузоподъёмности.',
           [r'\mu_{\text{гр}}\;[\mathrm{m^3/t}]',r'\mu_{\text{с}}=\frac{W}{P_{\text{гр}}}\;[\mathrm{m^3/t}]'])
    insert('Q15:shortage','Q15:ratio','这题不足的是船提供的单位舱容；并不是货物每吨占用的空间变小。',
           'Здесь недоста́точна вмести́мость су́дна на то́нну; объём то́нны гру́за не меня́ется.',
           [r'\mu_{\text{с}}<\mu_{\text{гр}}',r'W_{\mathrm{req}}=P_{\text{гр}}\mu_{\text{гр}}'])
    words('TOP:N04:type','课件统计针对满货、满储备：油船h/B常为0.08—0.10，须与当前载况区分。',
          'В мо́дуле для та́нкера с по́лным гру́зом и запа́сами h/B обы́чно 0.08–0.10.')
    index['TOP:N04:type']['condition']={'zh':'初步设计的0.06与这里的统计范围用途不同。',
        'ru':'0.06 в пе́рвом приближе́нии и э́тот диапазо́н испо́льзуются для ра́зных це́лей.'}
    # These are teacher examples/statistics, never universal pass/fail thresholds.
    row('TOP:N04:type',[r'0.08\leq\frac{h}{B}\leq0.10'])
    rule={'kind':'range','teacher_reference':'6p/Modul_9. Обеспечение остойчивости.docx · 满货、满储备油船统计'}
    index['TOP:N04:type'].update(source_rule=rule,source_rows={'0':rule})
    index['TOP:N04:type']['source_phrase']=copy.deepcopy(index['TOP:N04:type']['words'])
    for c in courses:
        if c['id']!='stability':continue
        fixed={
            'Q18':('固定船型、排水量，只改变G高度。','Фо́рма и водоизмеще́ние постоя́нны; меня́ем высоту́ G.'),
            'Q19':('比较型深时固定B、T、G；比较G时固定船型和排水量。','При измене́нии H фикси́руем B, T, G; при измене́нии G — фо́рму и водоизмеще́ние.'),
            'Q20':('小角度自由横摇；固定等效回转半径，h保持为正。','Ма́лая свобо́дная ка́чка; ра́диус ине́рции постоя́нен, h положи́тельно.'),
            'Q21':('同初始摇幅、同等效回转半径；比较周期与加速度。','Одина́ковая амплиту́да и ра́диус ине́рции; сравни́м пери́од и ускоре́ние.')}
        for g in c['groups']:
            if g['id'] in fixed:
                for b in g['beats']:b.setdefault('condition',dict(zip(['zh','ru'],fixed[g['id']])))
    words('TOP:Q25:symmetry','对称进水使艏部下沉、产生艏倾；这不保证所有事故都能保持稳性。',
          'При симметри́чном затопле́нии нос опуска́ется; э́то не гаранти́рует осто́йчивость при любо́й ава́рии.')
    index['TOP:Q25:symmetry']['action']={'params':{'trim_demo':2.5},'duration':3}
    index['TOP:Q25:symmetry']['anchor']='ship'
    index['TOP:Q25:symmetry']['condition']={'zh':'定性展示纵倾方向，不计算事故角度。','ru':'Пока́зано направле́ние диффере́нта, без расчёта авари́йного у́гла.'}
    for c in courses:
        c['initial']['trim_demo']=0
        for g in c['groups']:
            if c['id']=='damage':g['beats'][0].setdefault('start_params',{})['trim_demo']=0
    words('TOP:N15:condition','合格的封闭上层建筑增加储备浮力，计算最小干舷时可计入减小修正。',
          'Допусти́мая закры́тая надстро́йка увеличи́вает запа́с плаву́чести; попра́вка уменьша́ет минима́льный надво́дный борт.')
    index['TOP:N15:condition']['condition']=copy.deepcopy(readings['N15']['condition'])
    index['TOP:N16:sheer'].setdefault('start_params',{}).update(sheer=0,forecastle=0)
    index['TOP:N16:forecastle'].setdefault('start_params',{}).update(sheer=0,forecastle=0)
