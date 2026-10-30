"""Source-faithful notation and complete worked examples for all four questions.

The question text is immutable. English subscripts identify quantities the
teacher did not name. No numerical trim, GM or dining fraction is invented.
"""
import copy

SPECS={
 'P12_C01':(['0',r'\mathrm{гр}',r'\mathrm{зап}'],['空船','货物','储备'],['Судно порожнём','Груз','Запасы']),
 'P12_C02':([r'\mathrm{'+s+'}' for s in ['hull','equipment','plant','systems','navigation','ballast']],['钢船体','船体设备','动力装置','系统','导航设备','永久压载'],['Корпус','Оборудование корпуса','Судовая энергетическая установка','Системы','Навигационное вооружение','Постоянный балласт']),
 'P12_C03':(['0','1','2',r'\mathrm{зап}'],['空船','货物1','货物2','储备'],['Судно порожнём','Груз 1','Груз 2','Запасы'])}

def apply(entries,courses,formula,stress):
 by={q['id']:q for q in entries}
 def put(key,lines):formula[key]={l:[{'tex':t,'linear':t} for t in lines] for l in ['zh','ru']}
 def sym(letter,suffix):return letter+'_{'+suffix+'}'
 def chain(lhs,terms,result,unit):
  # Explicit lines, at most two additive terms per row; never shrink a long sum.
  out=[]
  for i in range(0,len(terms),2):out.append((lhs+'=' if i==0 else r'\quad+')+'+'.join(terms[i:i+2]))
  out.append('='+str(result)+unit)
  return out
 for qid,(subs,names,russian) in SPECS.items():
  q=by[qid];rows=q['example_data']['rows'];group=next(g for c in courses for g in c['groups'] if g['id']==qid)
  all_details=[];numbers=[]
  for i,row in enumerate(rows):
   row[0]=names[i];_,m,x,z=row
   p,xs,zs=[sym(l,subs[i]) for l in ['P','x','z']]
   coords=xs+f'={x}'+r'\,\mathrm{m},\quad '+zs+f'={z}'+r'\,\mathrm{m}'
   def row_lines(dynamic):
    dm='@ex_item_mass@' if dynamic else str(m)
    mx='@ex_item_mx@' if dynamic else str(m*x)
    mz='@ex_item_mz@' if dynamic else str(m*z)
    return [p+'='+dm+r'\,\mathrm{t}',coords,p+xs+'='+dm+r'\cdot '+str(x)+'='+mx+r'\,\mathrm{t\,m}',p+zs+'='+dm+r'\cdot '+str(z)+'='+mz+r'\,\mathrm{t\,m}']
   beat=next(b for b in group['beats'] if b['id']==qid+f':row{i}')
   zh=f'{names[i]}{m}吨，分别计算纵向矩和竖向矩。'
   ru=stress(f'{russian[i]}: масса {m} т; считаем продольный и вертикальный моменты.')
   beat['text']=zh;beat['words']={'zh':zh,'ru':ru};beat['record_text']={'zh':names[i],'ru':stress(russian[i])}
   beat['start_params'].update(row_index=i,cargo_x=x,cargo_z=z)
   put(beat['id'],row_lines(True));all_details+=row_lines(False)
   numbers.append((m,m*x,m*z))
  v=q['example_data'];total=r'P_{\mathrm{пор}}' if qid=='P12_C02' else 'D'
  mlong=r'M_{\mathrm{long}}';mvert=r'M_{\mathrm{vert}}'
  mass_lines=chain(total,[sym('P',s) for s in subs],v['total'],r'\,\mathrm{t}')[:-1]
  mass_lines+=chain('',['%g'%n[0] for n in numbers],v['total'],r'\,\mathrm{t}')
  sections={'sum':mass_lines}
  for axis,moment,col,key,field in [('x',mlong,1,'xg','mx'),('z',mvert,2,'zg','mz')]:
   coord=r'x_{\mathrm{пор}}' if qid=='P12_C02' and axis=='x' else r'z_{\mathrm{пор}}' if qid=='P12_C02' else axis+'_g'
   lines=chain(moment,[sym('P',s)+sym(axis,s) for s in subs],v[field],r'\,\mathrm{t\,m}')[:-1]
   lines+=chain('',[str(n[col]) for n in numbers],v[field],r'\,\mathrm{t\,m}')
   lines += [coord+r'=\frac{'+moment+'}{'+total+'}',r'=\frac{'+str(v[field])+'}{'+str(v['total'])+'}='+f'{v[key]:.4f}'+r'\,\mathrm{m}']
   sections[axis+'sum']=lines
  for suffix,lines in sections.items():put(qid+':'+suffix,lines)
  put(qid+':solution',all_details+sections['sum']+sections['xsum']+sections['zsum'])
  group['beats'][0]['record_text']={'zh':q['sources'][0]+' · 独立演示算例','ru':stress('Учебный пример '+qid[-1])}
  q['formula_id']=qid+':solution';ex=q['calculation']['example'];ex['formula_id']=qid+':solution'
  ex['steps']=['已知：'+'；'.join(f'{n} {r[1]} t，x={r[2]} m，z={r[3]} m' for n,r in zip(names,rows)), '逐项列出质量、纵向坐标和竖向坐标，再分别计算质量×纵向坐标、质量×竖向坐标。','累计质量、纵向矩、竖向矩；两个方向的总矩分别除以总质量。','单位：质量t，坐标m，质量矩t·m；重心结果保留四位小数，计算使用未取位值。']
  if qid=='P12_C02':ex['steps'].insert(1,'只计入题干所列六项空船组成；货物、燃油和油料、船员、食品和淡水不计入。本题未命名单项变量，英文下标只区分这六项。')
  else:
   ex['steps'].append('定性判断只比较重心移动的作用：向艏移有艏倾趋势，向艉移有艉倾趋势；降低重心有利于初稳性，升高则不利。其余条件保持不变。')
   # Stable comparison stage before the answer; preserve all existing IDs.
   bid=qid+':compare';existing=next((b for b in group['beats'] if b['id']==bid),None)
   dx=v['xg']-rows[0][2];dz=v['zg']-rows[0][3]
   zh='本算例重心向'+('艏' if dx>0 else '艉')+f'移{abs(dx):.4f}米、降低{abs(dz):.4f}米；仅比较重心移动，'+('艏' if dx>0 else '艉')+'倾趋势增强，初稳性增强。'
   words={'zh':zh,'ru':stress('В примере центр масс смещается '+('к носу' if dx>0 else 'к корме')+' и ниже. При прочих равных начальная остойчивость больше.')}
   if existing is None:
    existing=copy.deepcopy(next(b for b in group['beats'] if b['id']==qid+':zsum'));existing['id']=bid;existing.pop('action',None)
    group['beats'].insert(next(i for i,b in enumerate(group['beats']) if b['id']==qid+':answer'),existing)
   existing.update(text=zh,words=words,record_text={'zh':'装载前后比较','ru':stress('Сравним координаты центра масс')},start_params={'load':1.,'axis':2.})
   x0,z0=rows[0][2:];put(bid,[r'\Delta x_g=x_g-x_0',f'={v["xg"]:.4f}-{x0}={v["xg"]-x0:.4f}'+r'\,\mathrm{m}',r'\Delta z_g=z_g-z_0',f'={v["zg"]:.4f}-{z0}={v["zg"]-z0:.4f}'+r'\,\mathrm{m}'])
   # Show comparison in the reading solution too.
   for lang in ['zh','ru']:formula[qid+':solution'][lang]+=copy.deepcopy(formula[bid][lang])
  # Remove the former numeric-only summary or generic-sum aliases.
  formula.pop(qid+':goal',None)
  group['beats'][0].pop('source_rule',None);group['beats'][0].pop('source_rows',None)
 q=by['P12_C04'];group=next(g for c in courses for g in c['groups'] if g['id']==q['id'])
 area=r'S';seat=r'n_{\mathrm{seat}}';share=r'q_{\mathrm{share}}';norm=r'\mathrm{Х}'
 original=[seat+'=N'+share,area+'='+seat+norm+'=N'+share+norm]
 given=[r'N=24,\quad '+share+r'=\frac{1}{2}',norm+r'=1.2\,\mathrm{m^2}']
 seating=[seat+'=N'+share,r'=24\cdot\frac{1}{2}=12']
 worked=[area+'='+seat+norm,r'=12\cdot1.2=14.4\,\mathrm{m^2}']
 # Half the crew is explicitly a teaching assumption, not a teacher rule.
 put(q['id']+':goal',given);put(q['id']+':seats',seating);put(q['id']+':sum',worked);put(q['id']+':solution',given+original+seating+worked)
 q['formula_id']=q['id']+':solution';q['calculation']['example']['formula_id']=q['formula_id']
 q['calculation']['example']['question_ru']=stress('Учебный пример: экипаж 24 человека, одновременно питается половина экипажа. Норма площади на одно место — 1,2 квадратного метра. Найдите число мест и площадь столовой.')
 q['calculation']['example']['translation']='独立演示：船员24人，假定一半船员同时就餐，每座面积1.2平方米。求座位数与餐厅面积；一半是演示条件，不是教师规定。'
 q['calculation']['example']['steps']=['演示已知：N=24人，同时就餐比例q_share=1/2，每座面积Х=1.2 m²。','先求座位数：n_seat=24×1/2=12座。','再求面积：S=12×1.2=14.4 m²。','比例1/2为本演示额外给定；考试按题目或课堂明确的比例计算，不将演示比例当成规则。']
 q['calculation']['example']['dining_data']={'crew':24,'share':0.5,'seats':12,'area_per_seat':1.2,'area':14.4,'share_is_teaching_assumption':True}
 goal=group['beats'][0];goal['record_text']={'zh':'演示已知：24人，一半同时就餐','ru':stress('Учебный пример: 24 человека')}
 goal['text']='演示假定：24名船员，一半同时就餐，每座1.2平方米。';goal['words']={'zh':goal['text'],'ru':stress('Учебный пример: 24 человека, одновременно питается половина экипажа.')}
 b=next(b for b in group['beats'] if b['id']==q['id']+':sum')
 new=next((beat for beat in group['beats'] if beat['id']==q['id']+':seats'),None)
 if new is None:
  new=copy.deepcopy(b);new['id']=q['id']+':seats';group['beats'].insert(group['beats'].index(b),new)
 new['text']='24人乘一半，餐厅需要12个座位。';new['words']={'zh':new['text'],'ru':stress('Половина экипажа — 12 человек; нужны 12 мест.')};new['record_text']={'zh':'先求座位数','ru':stress('Число мест')}
 b.pop('action',None);b['text']='12个座位乘每座1.2平方米，面积为14.4平方米。';b['words']={'zh':b['text'],'ru':stress('Площадь столовой: 12 умножить на 1,2 — 14,4 квадратного метра.')};b['record_text']={'zh':'再求餐厅面积','ru':stress('Площадь столовой')}
 return entries,courses,formula
