"""Adapt authored content to the package's spatial explanation mode.
Narration and explanatory notes remain native, stepwise text in the scene.
Only formulas / numeric records remain in the calculation pane.
"""
from copy import deepcopy

def adapt(courses):
    for c in courses:
        if c['id']=='basics':c['initial'].update(cutaway_amount=0.0,dimension_reveal=0.0)
        for g in c['groups']:
            result=[]
            for b in g['beats']:
                scene=b.setdefault('scene_params',{})
                if b['id']=='parts:compartments':
                    scene.pop('cutaway',None)
                    b['action']={'params':{'cutaway_amount':1.0},'duration':2.8}
                    b['words']={'zh':'按 D 移开近侧船壳和舱盖。留意黄色舱壁：它把船内空间分成不同舱室。','ru':'Нажми́те D: уберём бли́жний борт и кры́шки лю́ков. Жёлтые перебо́рки разделя́ют простра́нство на отсе́ки.'}
                elif b['id'].startswith('parts:'):scene.pop('cutaway',None)
                if b['id']=='dimensions:show':
                    scene.update(cutaway_amount=0.0)
                    b['action']={'params':{'dimensions':True,'dimension_reveal':1.0},'duration':2.2}
                elif c['id']=='basics' and g['id']!='parts':scene.update(cutaway_amount=0.0)
                focus=scene.get('part_focus','')
                anchor={'ends':'bow','Hull':'hull','Decks':'deck','Bulkheads':'bulkheads'}.get(focus,'ship')
                if c['id']=='sample':anchor='centre' if b['id'] in ['sample:weighted','sample:before','sample:result','sample:check'] else 'load'
                elif c['id']=='load':anchor='centre' if g['id']=='load-centre' or b['id']=='load-fuel:combine' else 'load'
                elif g['id'] in ['dimensions','trim','reserve','dim-equations','dim-check']:anchor='water'
                b['anchor']=anchor
                notes=[line for line in b.get('lines',[]) if isinstance(line,dict)]
                b['lines']=[line for line in b.get('lines',[]) if isinstance(line,str)]
                # Intro terminology is already in its speech paragraph, not a separate redundant lesson.
                if b['id']=='sample:known':notes=[]
                # Keep calculated records while explanatory notes are read beside the same object.
                result.append(b)
                for i,note in enumerate(notes):
                    nb=deepcopy(b);nb['id']=b['id']+':note'+str(i+1);nb['words']=note;nb['text']=note['zh'];nb.pop('action',None)
                    nb['is_note']=True;result.append(nb)
            g['beats']=result
    return courses
