"""Reference-line chapter and subject-specific teaching cameras."""
def apply(courses):
    basic=next(c for c in courses if c['id']=='basics')
    basic['initial'].update(baseline_reveal=0,draft_measure=0,depth_measure=0)
    g={'id':'baseline','title':{'zh':'基线、吃水与型深','ru':'Осно́вная ли́ния, оса́дка и высота́'},'beats':[]}
    rows=[
      ('reference','基线是船底附近规定的水平参考线，记为 z = 0。','Осно́вная ли́ния — горизонта́льный у́ровень у дни́ща, при́нятый за z = 0.','',{'baseline_reveal':1}),
      ('draft','吃水 T：从基线到水线的竖直距离。','Оса́дка T — вертика́льное расстоя́ние от основно́й ли́нии до ватерли́нии.','T',{'draft_measure':1}),
      ('depth','型深 H：从基线到规定甲板的竖直距离。','Высота́ H — расстоя́ние от основно́й ли́нии до расчётной па́лубы.','H',{'depth_measure':1})]
    for id,zh,ru,kind,params in rows:
        g['beats'].append({'id':'baseline:'+id,'text':zh,'words':{'zh':zh,'ru':ru},'lines':[],'layout':'model','anchor':'ship','camera':'baseline','scene_params':{'baseline_mode':True,'measure_kind':kind,'cutaway_amount':0,'dimensions':False,'part_focus':''},'action':{'params':params,'duration':2.4}})
    basic['groups'].insert(1,g)
    for c in courses:
        for group in c['groups']:
            for b in group['beats']:
                if group['id']=='baseline':continue
                b.setdefault('scene_params',{})['baseline_mode']=False
                focus=b['scene_params'].get('part_focus','')
                b['camera']={'Hull':'hull','Decks':'deck','Bulkheads':'cutaway'}.get(focus,'overview')
                if c['id']=='sample':b['camera']='cargo'
                elif group['id']=='dimensions' or c['id']=='dimensions':b['camera']='dimensions'
                if b['id']=='dimensions:draft':
                    b['camera']='baseline'
                    b['scene_params'].update(baseline_mode=True,baseline_reveal=1,measure_kind='T',draft_measure=1,dimensions=False)
    return courses
