"""Explicit source semantics, independent of computed/adopted values."""
def apply(groups, formulas):
 beats={b['id'].split(':')[1]:b for g in groups for b in g['beats']}
 def rows(id, tex):
  formulas['BH:'+id]={l:[dict(tex=t,linear=t) for t in tex] for l in ['zh','ru']}
  beats[id]['lines']=['formula']
 def mark(id, kind, section, ru, zh, indices=(0,), phrase=None):
  b=beats[id]
  s=dict(kind=kind,section=section,ru=ru,zh=zh)
  b['source_rule']=s
  b['source_rows']={str(i):s for i in indices}
  if phrase:b['source_phrase']=dict(zip(['zh','ru'],phrase))
 def words(id,zh,ru):
  beats[id]['words']=dict(zh=zh,ru=ru);beats[id]['text']=zh
 mark('normal','formula',1,'a0 = 0,002L + 0,48','按船长计算普通肋距。')
 words('normal','按资料公式求普通肋距；算得约0.86米，采用0.85米。','По фо́рмуле из материа́ла получа́ем о́коло 0.86 ме́тра; принима́ем 0.85.')
 beats['normal']['source_phrase']=dict(zh='按资料公式求普通肋距',ru='По фо́рмуле из материа́ла')
 frame_ru='Рамная шпация в средней части равна четырем обычным шпациям, в машинном отделении — двум. В переходном районе принимаем две обычные шпации.'
 mark('web','limit',1,frame_ru,'船中部（不含艏部过渡区）的强肋骨间距为四个普通肋距，机舱为两个；过渡区采用两个。',(),('船中部（不含艏部过渡区），每四个普通肋距设一道强肋骨','В сре́дней ча́сти вне перехо́дного райо́на: оди́н ра́мный шпанго́ут че́рез четы́ре обы́чные шпа́ции'))
 for id,tex,ru,zh,section in [
 ('fore_range',None,'Lф = (0,05÷0,08)L','艏尖舱长度为船长的5%—8%。',2),
 ('aft_range',r'L_{\text{ахт}}\in[0.04L,0.08L]','Lахт = (0,04÷0,08)L','艉尖舱长度为船长的4%—8%。',2),
 ('engine_range',None,'LМО = (0,14÷0,17)L','机舱长度按船长的14%—17%估算。',2),
 ('transition',None,'Переходный район должен доходить не менее чем до сечения 0,2L.','过渡区至少延伸到距艏端0.2倍船长处。',2)]:
  if tex:rows(id,[tex]+[r['tex'] for r in formulas['BH:'+id]['zh']])
  mark(id,'limit',section,ru,zh,phrase=(beats[id]['words']['zh'],beats[id]['words']['ru']))
 words('fore_range','艏尖舱长度取船长的5%到8%。','Длина́ фо́рпика — от 5 до 8 проце́нтов длины́ су́дна.')
 beats['fore_range']['source_phrase']=beats['fore_range']['words'].copy()
 for id,section,ru,zh,phrase in [
 ('remaining',2,'Lгр = L − (Lф + Lахт + LМО + LНО)','货区长度等于船长扣除两尖舱、机舱和泵舱长度。','扣除两个尖舱、机舱和泵舱'),
 ('dbformula',4,'hдд = 0,0328H + 1,2','按型深估算双层底高度。','用型深估算双层底高度'),
 ('dbcheck',4,'hдд = (L−40)/570 + 0,04B + 3,5T/L','用船长、船宽和吃水计算双层底高度下限。','用船长、船宽和吃水计算下限'),
 ('deadweight',4,'DW = D − (Pк.об + Pсэу)','载重量为排水量减去船体设备和动力装置质量。','从排水量扣除船体设备与动力装置质量'),
 ('sideformula',4,'bдб = 0,5 + DW/20000','按载重量计算双舷侧宽度。','代入载重量'),
 ('cargo_width',5,'Bгр = B − 2bдб','货区净宽扣除两侧双舷侧宽度。','船宽扣除两侧双舷侧')]:
  mark(id,'formula',section,ru,zh,phrase=(phrase,beats[id]['words']['ru'].split(';')[0].split(':')[0]))
 rows('dbadopt',[r'h_{\text{дд}}\le2.00\,\mathrm{m}',r'h_{\text{дд}}=1.70\,\mathrm{m}',r'1.52<1.70\le2.00'])
 mark('dbadopt','limit',4,'Высота больше 1,52 м и не превышает 2,00 м.','高度不超过2.00米；1.52米是本方案算出的下限。',phrase=('没有超过2米','не бо́лее 2 ме́тров'))
 rows('sideadopt',[r'1.00\le b_{\text{дб}}\le2.50\,\mathrm{m}',r'b_{\text{дб}}=2.20\,\mathrm{m}',r'1.00\le2.20\le2.50'])
 mark('sideadopt','limit',4,'Ширина находится в пределах 1,00–2,50 м.','双舷侧宽度在1.00—2.50米范围内。',phrase=('本作业规定的1到2.5米之间','в преде́лах от 1 до 2.5 ме́тра'))
 mark('six','limit',3,'При длине более 185 м общее число поперечных переборок определяется по согласованию с Регистром.','船长超过185米时，横舱壁总数须与船级社商定。',())
 beats['six'].pop('record_label',None)
 beats['six']['record_text']=dict(zh='本方案采用9道横舱壁。',ru='В э́том вариа́нте приня́то 9 перебо́рок.')
 beats['six']['source_notice']=dict(zh='船长超过185米时，舱壁总数须与船级社商定。',ru='При длине́ бо́лее 185 м число́ перебо́рок согласу́ют с Реги́стром.')
 beats['six']['lines']=['source']
 rows('tanklimits',[r'\frac{b_i}{B}\ge\frac{1}{5}',r'l_{\text{доп}}=0.2L',r'=0.2\cdot189.13=37.826',r'\approx37.83\,\mathrm{m}'])
 mark('tanklimits','formula',5,'При двух продольных переборках и bᵢ/B ≥ 1/5 допустимая длина бортовых и центральных танков равна 0,2L.','有两道纵舱壁，且所示比例不小于五分之一时，允许舱长为0.2倍船长。',(0,1),('两道纵舱壁且满足这个比例时，本作业采用0.2倍船长作为舱长上限','При двух продо́льных перебо́рках и э́том отноше́нии преде́л длины́ та́нка — 0.2L'))
 beats['tanklimits']['source_condition']=dict(zh='两道纵舱壁，并且',ru='Две продо́льные перебо́рки, и')

 # Keep numerical outcomes out of the Russian source-colored spans, too.
 for id,phrase in {'dbformula':'По высоте́ бо́рта','dbcheck':'По длине́, ширине́ и оса́дке проверя́ем ми́нимум','deadweight':'Из водоизмеще́ния вычита́ем ма́ссы ко́рпуса с обору́дованием и СЭУ','sideformula':'Подставля́ем дедве́йт','cargo_width':'Вычита́ем двойны́е борта́'}.items():
  beats[id]['source_phrase']['ru']=phrase
 rows('webvalues',[r'a_{\mathrm{web,cargo}}=4a',r'4\cdot0.85=3.40\,\mathrm{m}',r'a_{\mathrm{web,engine}}=2a',r'2\cdot0.85=1.70\,\mathrm{m}',r'2\cdot0.69=1.38\,\mathrm{m}'])
 mark('webvalues','limit',1,frame_ru,'船中部（不含艏部过渡区）的强肋骨间距是四个普通肋距，机舱是两个；过渡区采用两个。',(0,2))
 # The paragraph explains an adopted layout; only its stated placement requirement is marked.
 if 'closure' in beats:
  mark('closure','limit',3,'Все поперечные переборки устанавливаем на рамных шпангоутах: 24, 60, 85, 109, 133, 157, 181, 185 и 221.','横舱壁设置在强肋骨处；所列肋位是本方案布置。',(),('全部落在强肋骨肋位','стоя́т на ра́мных шпанго́утах'))

 # Explain the missing regional limits from the course methods, without mixing
 # the example's 139.5 m dimensions into this T2 calculation.
 words('peakspacing','资料要求尖舱取0.60米、过渡区不超过0.70米；本方案过渡区取0.69米。','В пи́ках по материа́лу — 0.60 ме́тра; в перехо́дном райо́не — не бо́лее 0.70. Здесь принима́ем 0.69.')
 rows('peakspacing',[r'a_{\mathrm{peak}}=0.60\,\mathrm{m}',r'a_{\mathrm{transition}}\le0.70\,\mathrm{m}',r'0.75a_0\le a_{\mathrm{transition}}\le1.25a_0',r'a\le1.00\,\mathrm{m}',r'0.75\cdot0.86=0.645\,\mathrm{m}',r'a_{\mathrm{transition}}=0.69\,\mathrm{m}',r'0.645\le0.69\le0.70',r'a_{\mathrm{mid}}=0.85\,\mathrm{m}'])
 mark('peakspacing','limit',1,'В форпика и ахтерпике принять 0,6 м.\nВ переходном районе ... не более 0,7 м.\nФактическая шпация не отличается от нормальной не более чем на 25%.\nШпация не должна быть больше 1 м.','课件要求尖舱取0.60米；示例说明过渡区不超过0.70米。课件规定普通肋距相对正常肋距的偏差不超过25%，且肋距不超过1米；尖舱按其专用取值。0.85米是船中部采用值，不是过渡区上限。',(0,1,2,3),('资料要求尖舱取0.60米、过渡区不超过0.70米','В пи́ках по материа́лу — 0.60 ме́тра; в перехо́дном райо́не — не бо́лее 0.70'))
 reference='ПС-КР-6. Расстановка переборок.pptx · 第3页\n3. Пример компоновки ОР.docx · 肋距划分'
 beats['peakspacing']['source_rule']['reference']=reference

 # The student's T2 calculation supplies adopted values, never authority.
 teacher_refs={
 'normal':'ПС-КР-6. Расстановка переборок.pptx · 3',
 'web':'3. Пример компоновки ОР.docx · Определение и разбивка судна на шпации',
 'webvalues':'3. Пример компоновки ОР.docx · рамная шпация',
 'fore_range':'3. Пример компоновки ОР.docx · Lф（PPT4另写lфп）',
 'aft_range':'3. Пример компоновки ОР.docx · Lахт（PPT4另写lахт）',
 'engine_range':'3. Пример компоновки ОР.docx · Длина машинного отделения',
 'transition':'ПС-КР-6. Расстановка переборок.pptx · 4',
 'dbformula':'ПС-КР-6. Расстановка переборок.pptx · 9',
 'dbcheck':'ПС-КР-6. Расстановка переборок.pptx · 9 (formula image)',
 'dbadopt':'ПС-КР-6. Расстановка переборок.pptx · 9',
 'sideformula':'ПС-КР-6. Расстановка переборок.pptx · 10',
 'sideadopt':'ПС-КР-6. Расстановка переборок.pptx · 10',
 'six':'ПС-КР-6. Расстановка переборок.pptx · 6',
 'tanklimits':'ПС-КР-6. Расстановка переборок.pptx · 15 (table image)',
 'closure':'3. Пример компоновки ОР.docx · Переборка должна стоять на рамной шпации',
 'peakspacing':reference}
 for id,b in beats.items():
  if 'source_rule' not in b:continue
  if id not in teacher_refs:
   for key in ['source_rule','source_rows','source_phrase','source_condition']:b.pop(key,None)
  else:
   # Minimal runtime semantics; teacher evidence is retained in build documentation.
   b['source_rule']={'kind':b['source_rule']['kind'],'teacher_reference':teacher_refs[id]}
   b['source_rows']={i:b['source_rule'] for i in b['source_rows']}
 words('sideadopt','采用2.20米，处于规定的1到2.5米之间。','Принима́ем 2.20 ме́тра: в преде́лах от 1 до 2.5 ме́тра.')
 beats['sideadopt']['source_phrase']['zh']='规定的1到2.5米之间'

 # Three spatial beats share the same completed structural context.
 from copy import deepcopy
 original=beats['webvalues'];group=next(g for g in groups if original in g['beats']);at=group['beats'].index(original)
 original['words']={'zh':'船中部（不含艏部过渡区）：强肋骨间距为四个普通肋距，即3.40米。','ru':'В грузовы́х та́нках вне перехо́дного райо́на: четы́ре шпа́ции даю́т 3.40 ме́тра.'};original['text']=original['words']['zh']
 specs=[('webvalues','cargo','rib'),('webengine','engine','engine'),('webtransition','transition','transition')]
 for offset,(id,region,anchor) in enumerate(specs):
  b=original if offset==0 else deepcopy(original)
  b['id']='BH:'+id;b['spacing_region']=region;b['anchor']=anchor;b['camera']='side'
  b['start_params']['bh_spacing_reveal']=0
  b['action']={'duration':1.4,'params':{'bh_spacing_reveal':1}}
  if offset==1:b['words']={'zh':'机舱：两个普通间隔合成1.70米强肋骨间距。','ru':'В МО две обы́чные шпа́ции даю́т 1.70 ме́тра.'}
  if offset==2:b['words']={'zh':'艏部过渡区也在货油舱区域内；这里两个间隔合成1.38米。','ru':'Перехо́дный райо́н вхо́дит в зо́ну грузовы́х та́нков; две шпа́ции здесь даю́т 1.38 ме́тра.'}
  b['text']=b['words']['zh'];b.pop('source_phrase',None)
  if offset:group['beats'].insert(at+offset,b);beats[id]=b
  if offset==0:rows(id,[r'a_{\mathrm{web,cargo}}=4a',r'4\cdot0.85=3.40\,\mathrm{m}'])
  elif offset==1:rows(id,[r'a_{\mathrm{web,engine}}=2a',r'2\cdot0.85=1.70\,\mathrm{m}'])
  else:rows(id,[r'2\cdot0.69=1.38\,\mathrm{m}'])
  b['source_rows']={'0':b['source_rule']} if offset<2 else {}
  if offset==2:b.pop('source_rule',None)

 # Show both adopted spacings at every spatial stop, including both peaks.
 for id,region,zh,ru in [
 ('webfore','fore','艏尖舱：普通肋距与强肋骨间距均为0.60米。','В фо́рпике обы́чная и ра́мная шпа́ции — по 0.60 ме́тра.'),
 ('webaft','aft','艉尖舱：普通肋距与强肋骨间距均为0.60米。','В ахте́рпике обы́чная и ра́мная шпа́ции — по 0.60 ме́тра.')]:
  b=deepcopy(beats['webtransition']);b['id']='BH:'+id;b['spacing_region']=region;b['anchor']=region
  b['words']={'zh':zh,'ru':ru};b['text']=zh;group['beats'].append(b);beats[id]=b
  rows(id,[r'a=0.60\,\mathrm{m}',r'a_{\mathrm{web}}=0.60\,\mathrm{m}'])
 for id,ordinary in [('webvalues',0.85),('webengine',0.85),('webtransition',0.69)]:
  for lang in ['zh','ru']:
   formulas['BH:'+id][lang].insert(0,{'tex':rf'a={ordinary:.2f}\,\mathrm{{m}}','linear':f'a = {ordinary:.2f} m'})
  b=beats[id];b['source_rows']={str(int(k)+1):v for k,v in b.get('source_rows',{}).items()}

 # Each region teaches ordinary spacing first, then its frame-spacing relation.
 definitions=[
 ('webvalues','船中部','Средняя часть',
 '先按船长算得0.85826米；本方案把普通肋距取为0.85米。',
 'По длине́ получа́ем 0.85826 ме́тра; принима́ем обы́чную шпа́цию 0.85 ме́тра.',
 [r'a_0=0.002L+0.48',r'=0.002\cdot189.13+0.48',r'=0.85826\approx0.86\,\mathrm{m}',r'a_{\mathrm{mid}}=0.85\,\mathrm{m}'],
 '强肋骨间距取四个普通肋距：4乘0.85，得到3.40米。',
 'Ра́мная шпа́ция равна́ четырём обы́чным: 4 на 0.85 — получа́ем 3.40 ме́тра.',
 [r'a_{\mathrm{web,cargo}}=4a_{\mathrm{mid}}',r'=4\cdot0.85=3.40\,\mathrm{m}']),
 ('webengine','机舱','МО',
 '机舱沿用船中部的普通肋距，采用0.85米。',
 'В МО обы́чная шпа́ция така́я же, как в сре́дней ча́сти: 0.85 ме́тра.',
 [r'a_{\mathrm{engine}}=a_{\mathrm{mid}}',r'=0.85\,\mathrm{m}'],
 '强肋骨间距取两个普通肋距：2乘0.85，得到1.70米。',
 'Ра́мная шпа́ция равна́ двум обы́чным: 2 на 0.85 — получа́ем 1.70 ме́тра.',
 [r'a_{\mathrm{web,engine}}=2a_{\mathrm{engine}}',r'=2\cdot0.85=1.70\,\mathrm{m}']),
 ('webtransition','艏部过渡区','Перехо́дный райо́н',
 '普通肋距需在0.645至0.70米内；本方案选0.69米，并非唯一取值。',
 'Обы́чная шпа́ция — от 0.645 до 0.70 ме́тра; здесь выбира́ем 0.69.',
 [r'0.75a_0\le a_{\mathrm{transition}}\le1.25a_0',r'a_{\mathrm{transition}}\le0.70\,\mathrm{m}',r'0.75\cdot0.86=0.645',r'1.25\cdot0.86=1.075',r'0.645\le a_{\mathrm{transition}}\le0.70',r'a_{\mathrm{transition}}=0.69\,\mathrm{m}'],
 '本方案强肋骨间距采用两个普通间隔：2乘0.69，得到1.38米。',
 'Здесь принима́ем две обы́чные шпа́ции: 2 на 0.69 — получа́ем 1.38 ме́тра.',
 [r'a_{\mathrm{web,transition}}=2a_{\mathrm{transition}}',r'=2\cdot0.69=1.38\,\mathrm{m}'])]
 for id,zh,ru in [('webfore','艏尖舱','Фо́рпик'),('webaft','艉尖舱','Ахте́рпик')]:
  suffix='fore' if id=='webfore' else 'aft'
  definitions.append((id,zh,ru,
   zh+'普通肋距按课件指定取0.60米，不由船长公式算出。',
   'В пи́ке по материа́лу принима́ем обы́чную шпа́цию 0.60 ме́тра.',
   [rf'a_{{\mathrm{{{suffix}}}}}=0.60\,\mathrm{{m}}'],
   '尖舱的强肋骨间距等于一个普通肋距：1乘0.60，仍是0.60米。',
   'В пи́ке ра́мная шпа́ция равна́ одно́й обы́чной: 1 на 0.60 — получа́ем 0.60 ме́тра.',
   [r'a_{\mathrm{web,'+suffix+r'}}=a_{\mathrm{'+suffix+r'}}',r'=1\cdot0.60=0.60\,\mathrm{m}']))
 for id,region_zh,region_ru,ozh,oru,otex,wzh,wru,wtex in definitions:
  b=beats[id];ordinary=deepcopy(b);ordinary_id=id+'_ordinary'
  ordinary['id']='BH:'+ordinary_id;ordinary['spacing_stage']='ordinary'
  ordinary['words']={'zh':ozh,'ru':oru};ordinary['text']=ozh
  ordinary['record_text']={'zh':region_zh+' · 普通肋距','ru':region_ru+' · обы́чная шпа́ция'}
  ordinary.pop('source_rule',None);ordinary['source_rows']={}
  group['beats'].insert(group['beats'].index(b),ordinary);beats[ordinary_id]=ordinary;rows(ordinary_id,otex)
  b['spacing_stage']='web';b['words']={'zh':wzh,'ru':wru};b['text']=wzh
  b['record_text']={'zh':region_zh+' · 强肋骨间距','ru':region_ru+' · ра́мная шпа́ция'}
  rows(id,wtex);b['source_rows']={'0':b['source_rule']} if id in ['webvalues','webengine'] else {}
  if id=='webvalues':ref='ПС-КР-6. Расстановка переборок.pptx · 3';source_indices=[0]
  elif id=='webtransition':ref=reference;source_indices=[0,1]
  elif id in ['webfore','webaft']:ref='ПС-КР-6. Расстановка переборок.pptx · 3';source_indices=[0]
  else:ref='';source_indices=[]
  if ref:
   ordinary['source_rule']={'kind':'formula' if id=='webvalues' else 'limit','teacher_reference':ref}
   ordinary['source_rows']={str(i):ordinary['source_rule'] for i in source_indices}
  if id in ['webfore','webaft']:
   b['source_rule']={'kind':'formula','teacher_reference':'3. Пример компоновки ОР.docx · в оконечностях: рамная шпация = обычная шпация'}
   b['source_rows']={'0':b['source_rule']}

 # Highlight the requirement and its positional check using the existing source style.
 b=beats['recheck']
 b['source_rule']={'kind':'limit','teacher_reference':'ПС-КР-6. Расстановка переборок.pptx · 4'}
 b['source_phrase']={'zh':'满足要求不小于0.2L','ru':'тре́бование не ме́нее 0.2L вы́полнено'}
 b['source_rows']={'2':b['source_rule']}

 # Teach each regional rule at its region, not in an opening preview.
 for g in groups:
  g['beats']=[b for b in g['beats'] if b['id'] not in ['BH:normal','BH:peakspacing']]
 for id in ['BH:normal','BH:peakspacing']:formulas.pop(id,None)
