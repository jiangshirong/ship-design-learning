"""Q12 authored drawing sequence; shared by incremental update and full build."""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def apply(courses, formulas):
    course = next(c for c in courses if c['id'] == 'cargo')
    group = next(g for g in course['groups'] if g['id'] == 'Q12')
    answer = copy.deepcopy(group['beats'][-1])
    state = dict(qid='Q12', topic='cargo', db_cut=0., db_lines=0., db_station=0., db_inner=0., db_match=0., db_sweep=0.)
    beats = []
    def add(id_, phase, zh, ru, action=None):
        state['phase'] = phase
        b = dict(id=id_, text=zh, words=dict(zh=zh, ru=ru), phase=phase,
                 start_params=copy.deepcopy(state), view_kind='doublebottom', camera='overview', anchor='ship')
        if action:
            b['action'] = dict(params=action, duration=3.)
            state.update(action)
        beats.append(b)
    add('Q12:s1', 'locate', '要算这段双层底舱的容积，先找到外底与内底之间的空间。',
        'Найдём отсе́к ме́жду нару́жным и вну́тренним дном.', dict(db_cut=1.))
    add('Q12:s2', 'lines', '型线图用三个方向的投影，给出船壳形状。',
        'Теорети́ческий чертёж даёт фо́рму ко́рпуса.', dict(db_lines=1.))
    add('Q12:station', 'station', '取同一个横截面：图上的轮廓，对应船壳上的这一圈。',
        'Оди́н и тот же шпанго́ут на чертеже́ и на ко́рпусе.', dict(db_station=1.))
    add('Q12:inner', 'inner', '双层底图补上内底和舱壁，确定这个舱的边界。',
        'Чертёж двойно́го дна даёт вну́треннее дно и перебо́рки.', dict(db_inner=1.))
    add('Q12:match', 'match', '把两张图的同一截面对齐，围出的区域就是这个舱的截面积。',
        'Совмести́м сече́ния: получи́м пло́щадь сече́ния отсе́ка.', dict(db_match=1.))
    add('Q12:s3', 'volume', '按各段的截面积和长度求体积，再相加得到舱容。',
        'Скла́дываем объёмы ча́стей ме́жду перебо́рками.', dict(db_sweep=1.))
    answer.update(start_params=copy.deepcopy(state), phase='answer', camera='overview', anchor='ship')
    answer['start_params']['phase'] = 'answer'
    answer.pop('action', None)
    beats.append(answer)
    group.update(title=dict(zh='双层底容积', ru='Двойно́е дно'), beats=beats)
    for key in list(formulas):
        if key.startswith('Q12:') or key == 'TOP:Q12:answer':
            del formulas[key]
    rows = [r'V=\int_{x_a}^{x_b}A(x)\,\mathrm{d}x', r'V\approx\sum_i\frac{A_i+A_{i+1}}{2}\,\Delta x_i']
    formulas['Q12:s3'] = {lang:[dict(tex=t,linear=t) for t in rows] for lang in ('zh','ru')}

def glossary():
    path=ROOT/'content/glossary.json'
    entries=json.loads(path.read_text(encoding='utf-8'))
    def norm(s):return s.lower().replace('\u0301','').replace('ё','е')
    rows=[
        ('нару́жный','наружное;наружного','外部的；外侧的'),
        ('вну́тренний','внутреннее;внутреннего','内部的；内侧的'),
        ('нару́жное дно','наружное дно;наружным дном','外底'),
        ('вну́треннее дно','внутреннее дно;внутренним дном','内底'),
        ('шпанго́ут','шпангоут;шпангоуты','肋骨；型线图中的横剖线'),
        ('сече́ние','сечение;сечения;сечений','截面'),
        ('бок','бок','侧面；此处为侧投影'),
        ('полуширота́','полуширота','半宽图；船体的半幅水平投影'),
        ('совмести́ть','совместим;совместить','使对齐；重合'),
    ]
    for ru,aliases,zh in rows:
        existing=next((e for e in entries if norm(e['ru'])==norm(ru)),None)
        forms=list(dict.fromkeys(aliases.split(';')+[norm(ru)]))
        if existing:existing['aliases']=list(dict.fromkeys(existing['aliases']+forms))
        else:entries.append(dict(id='q12_drawing_'+norm(ru).replace(' ','_'),ru=ru,zh=zh,meaning=zh,aliases=forms,study=False))
    path.write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

if __name__ == '__main__':
    paths = [ROOT/'content/topics.json', ROOT/'content/topics_latex.json']
    data = [json.loads(p.read_text(encoding='utf-8')) for p in paths]
    apply(*data)
    for p,d in zip(paths,data):
        p.write_text(json.dumps(d, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    glossary()
