"""Shared editorial rules, applied after notation and adopted-value generation."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def apply(courses,formulas):
    for c in courses:
        for g in c['groups']:
            for b in g['beats']:
                key=b['id'];words=None
                for suffix,zh,ru in [('LB','长宽比：比较船长相对船宽的大小。','Сравни́м длину́, делённую на ширину́.'),('BT','宽吃水比：比较船宽相对吃水的大小。','Сравни́м ширину́, делённую на оса́дку.'),('HT','型深吃水比：比较型深相对吃水的大小。','Сравни́м высоту́ бо́рта, делённую на оса́дку.')]:
                    if key in ['T16:'+suffix,'AP3:ratio'+suffix]:words={'zh':zh,'ru':ru}
                if key in ['BH:webfore','BH:webaft']:
                    fore=key.endswith('webfore')
                    zh=('艏尖舱' if fore else '艉尖舱')+'强肋骨间距等于普通肋距，均为0.60米。'
                    ru=('В фо́рпике' if fore else 'В ахтерпи́ке')+' ра́мная шпа́ция равна́ обы́чной: 0.60 ме́тра.'
                    words={'zh':zh,'ru':ru}
                    b['source_phrase']={'zh':'强肋骨间距等于普通肋距','ru':'ра́мная шпа́ция равна́ обы́чной'}
                if words:b['words']=words;b['text']=words['zh']
                predicate=None
                if key=='T03:balance':predicate=lambda t:t.replace('{,}','.') in [r'P_{\text{зв}}=0.01D',r'P_r=0.01D']
                if key=='BH:aft_range':predicate=lambda t:r'\in\{13' in t
                if key=='norman-derive:differentiate':predicate=lambda t:t==r'D=F(D,\theta)+P'
                if predicate and key in formulas:
                    for lang,rows in formulas[key].items():
                        formulas[key][lang]=[row for row in rows if not predicate(row['tex'])]
                    b['lines']=[r['tex'] for r in formulas[key]['zh']]

def update_existing():
    load=lambda name:json.loads((ROOT/name).read_text(encoding='utf8'))
    save=lambda name,data:(ROOT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    courses=load('content/courses.json');latex=load('content/latex_source.json')
    bh=load('content/bulkheads.json');bhtex=load('content/bulkheads_latex.json')
    apply(courses,latex);apply([bh],bhtex)
    courses=[bh if c['id']=='bulkheads' else c for c in courses]
    for name,data in [('content/courses.json',courses),('content/latex_source.json',latex),('content/bulkheads.json',bh),('content/bulkheads_latex.json',bhtex)]:save(name,data)
if __name__=='__main__':update_existing()
