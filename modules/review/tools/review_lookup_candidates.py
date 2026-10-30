"""One-time editorial decisions for the saved audit, never calls a model.

All candidate rows were read against coverage.json's course contexts. The
overrides below correct rejected readings; model notes/confidence are discarded.
The resulting reviewed overlay is the build input, not the model proposals.
"""
import copy
import hashlib
import json
from pathlib import Path
from audit_lookup import ROOT, OUT, read, write, norm, scan

if (ROOT/'content/glossary_review.json').exists():
    raise SystemExit('Review already adopted; use apply_glossary_review.py for rebuilds.')
rows = read(OUT / 'review-items.json')
contexts = read(OUT / 'coverage.json')['missing']
original = read(ROOT / 'content/glossary.json')
if not (OUT / 'glossary-before-review.json').exists():
    write(OUT / 'glossary-before-review.json', original)
entries = copy.deepcopy(original)

# form -> reviewed lemma, contextual Chinese. Other candidates were accepted
# after reading their actual sentence(s), not based on model confidence.
fixes = {
    'с': ('с', '与；和；从（依句中搭配）'),
    'к': ('к', '向；对于（后接第三格）'),
    'во': ('в', '在；во вре́мя：在……期间'),
    'её': ('её', '她的／它的（本句为不变的物主代词）'),
    'его': ('его́', '他的／它的（本句为不变的物主代词）'),
    'у': ('у', '在……处；公式中的У是给定数值的占位符'),
    'автономности': ('автоно́мность', '自持力：无需补给可维持的时间'),
    'чем': ('что', '比；与ме́ньше连用表示“小于”'),
    'величины': ('величина́', '量；це́нтр величины́整体指浮心'),
    'качестве': ('ка́чество', '性质；в ка́честве整体表示“作为”'),
    'речь': ('речь', '话；речь об…：这里说的是……'),
    'было': ('быть', '是；这里与мо́жно连用表示“能够”'),
    'отвечающие': ('отвеча́ть', '符合；满足（要求）'),
    'построенное': ('постро́ить', '建造；此处表示已建成的'),
    'перегородку': ('перегоро́дка', '隔板；分隔壁'),
    'всё': ('весь', '全部；всё те же：仍是原来的'),
    'занято': ('заня́ть', '占用；此处表示已占用'),
    'остаётся': ('остава́ться', '保持；仍然是；剩下'),
    'оставшийся': ('оста́ться', '剩下；此处表示剩余的'),
    'направлена': ('напра́вить', '使指向；此处表示力朝向'),
    'направлены': ('напра́вить', '使指向；此处表示力朝向'),
    'погружается': ('погружа́ться', '浸入水中；下沉'),
    'выходит': ('выходи́ть', '离开；此处指露出水面'),
    'их': ('их', '它们的；此处指两种力的'),
    'восстанавливающего': ('восстана́вливать', '恢复；此处指使船扶正'),
    'восстанавливающий': ('восстана́вливать', '恢复；此处指使船扶正'),
    'прямому': ('прямо́й', '直的；此处指船舶直立'),
    'сильнее': ('си́льный', '更强；修饰动作时表示“作用更强”'),
    'наибольшую': ('наибо́льший', '最大的'),
    'вдвое': ('вдво́е', '变为原来的两倍（本句指尺寸放大）'),
    'быстрее': ('бы́стро', '更快地'),
    'медленнее': ('ме́дленно', '更慢地'),
    'за': ('за', '在……时间内；за одно́ и то же вре́мя：同样时间内'),
    'одних': ('оди́н', '仅仅；此处表示“仅凭这些量”'),
    'должна': ('до́лжен', '应当；не должна́：不应当'),
    'самочувствие': ('самочу́вствие', '身体感受；舒适程度'),
    'избыточной': ('избы́точный', '过大的；过量的'),
    'отрицательно': ('отрица́тельный', '负的；此处指力臂为负'),
    'большего': ('бо́льший', '更大的'),
    'переборок': ('перебо́рка', '舱壁'),
    'затапливается': ('зата́пливаться', '进水；被水淹没'),
    'поправки': ('попра́вка', '修正；此处指干舷修正'),
    'выполнение': ('выполне́ние', '满足；执行（要求）'),
}
simple = set('кто или ли с нет из к в и о как во на её у а его по при чтобы чем да от два другой тоже оно разный это что каков большой нужный универсально через наиболее каждый просто раз новый место всё тот же здесь один но только есть прежний теперь сейчас весь слегка нуль высоко менее так сам они одинаковый более обратно недостаточно должен раньше отдельно первый второй ещё какой быть например сначала меньше можно больше мочь нужно'.split())
decisions = []
symbols = []
for row in rows:
    if row['kind'] == 'symbol':
        symbols.append(dict(form=row['form'], action='notation_not_lexical_word'))
        continue
    lemma, zh = fixes.get(row['form'], (row['lemma'], row['zh']))
    # A comparison conjunction is not an inflection of что.
    if row['form'] == 'чем':
        lemma = 'чем'
    existing = next((e for e in entries if norm(e['ru']) == norm(lemma)), None)
    if existing is None:
        existing = dict(id='checked_'+norm(lemma).replace(' ', '_'),
                        ru=lemma, zh=zh, meaning=zh, aliases=[],
                        study=row['kind'] != 'function' and norm(lemma) not in simple)
        entries.append(existing)
    existing['aliases'] = list(dict.fromkeys(existing['aliases']+[row['form'], norm(lemma)]))
    decisions.append(dict(form=row['form'], lemma=lemma, zh=zh,
                          entry_id=existing['id'], contexts=contexts[row['form']],
                          decision='corrected' if row['form'] in fixes else 'accepted_after_context_review'))

# Phrases need their own contextual meanings rather than a misleading component.
phrases = [
    ('checked_as', 'в ка́честве', '作为', ['в качестве'], False),
    ('checked_about', 'речь об', '这里说的是……', ['речь об', 'речь о'], False),
    ('checked_same', 'всё те же', '仍然是原来的', ['всё те же'], False),
    ('checked_same_mass', 'та же', '同样的；没有变化的', ['та же', 'той же', 'тех же', 'том же'], False),
    ('checked_same_time', 'одно́ и то же вре́мя', '相同的一段时间', ['одно и то же время'], False),
    ('checked_buoyancy_center', 'центр величины́', '浮心', ['центр величины', 'центра величины'], True),
    ('checked_restoring_moment', 'восстана́вливающий моме́нт', '复原力矩', ['восстанавливающий момент', 'восстанавливающего момента'], True),
]
for eid, ru, zh, aliases, study in phrases:
    entries.append(dict(id=eid, ru=ru, zh=zh, meaning=zh, aliases=aliases, study=study))

# Existing aliases sometimes used a synonym or a related part of speech as
# the "lemma". Transfer only those actual forms; keep all existing IDs intact.
transfers = [
    ('меняется', 'меня́ться', '变化'), ('меняются', 'меня́ться', '变化'),
    ('менять', 'меня́ть', '改变'), ('используется', 'испо́льзоваться', '被使用；用于'),
    ('сравним', 'сравни́ть', '比较'), ('обеспечивают', 'обеспе́чивать', '保证；提供'),
    ('обеспечивает', 'обеспе́чивать', '保证；提供'),
    ('ограничивается', 'ограни́чиваться', '受到限制'),
    ('ограничивают', 'ограни́чивать', '限制'),
    ('спасению', 'спасе́ние', '救助；救援'),
    ('закрытию', 'закры́тие', '封闭；关闭'),
    ('снижении', 'сниже́ние', '降低'),
    ('недостаточность', 'недоста́точность', '不足'),
    ('недостаточности', 'недоста́точность', '不足'),
]
for alias, lemma, zh in transfers:
    target = next((e for e in entries if norm(e['ru']) == norm(lemma)), None)
    if target is None:
        target = dict(id='checked_'+norm(lemma),ru=lemma,zh=zh,meaning=zh,aliases=[norm(lemma)],study=True)
        entries.append(target)
    for entry in entries:
        if entry is not target and alias in entry['aliases']:
            entry['aliases'].remove(alias)
    if alias not in target['aliases']: target['aliases'].append(alias)

byid = {e['id']: e for e in entries}
byid['topic_uchityvat']['meaning'] = 'учи́тывают：他们考虑；本句泛指应当考虑。'
byid['bank_автономность']['meaning'] = '自持力：无需补给可维持的时间；本题按淡水储备计算天数，不是航程。'
byid['quality']['meaning'] = '船舶性质／性能；в ка́честве是固定搭配，整体表示“作为”。'
for entry in entries:
    if norm(entry['ru']) in {'ещё','еще','какой','быть','например','сначала','меньше','можно','больше','мочь','нужно'}:
        entry['study'] = False
    entry['aliases'] = list(dict.fromkeys(entry['aliases']))

assert len(byid) == len(entries)
assert set(e['id'] for e in original).issubset(byid)
# Store only changed and new entries as the authoritative editorial overlay.
before = {e['id']:e for e in original}
updates = [e for e in entries if e != before.get(e['id'])]
overlay = dict(entries=updates, alias_transfers=transfers,
               sources=['https://gramota.ru/meta/vdvoe', 'https://gramota.ru/meta/zataplivat'],
               scope='37 cards and six continuous topics; 468 uncovered forms, including 12 notation tokens')
write(ROOT/'content/glossary_review.json', overlay)
write(ROOT/'content/glossary.json', entries)
write(OUT/'editorial-decisions.json', dict(lexical=decisions, notation=symbols))
print('Reviewed:', len(decisions), 'notation:', len(symbols),
      'entries:', len(original), '->', len(entries), 'updated:', len(updates))
