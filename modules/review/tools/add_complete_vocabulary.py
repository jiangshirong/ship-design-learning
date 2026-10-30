"""Inflections used by the completed short answers; preserve study exclusions."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'content/glossary.json'
entries=json.loads(p.read_text(encoding='utf-8'))
def norm(s):return s.replace('\u0301','').lower()
rows='''
эски́зный|草图设计的|эскизного
техни́ческий|技术的；本题指技术设计|технического
прое́кт|设计方案|проектов
координа́та|坐标|координаты
умножа́ть|乘；умножа́ем：我们乘以|умножаем
дели́ть|除；де́лим：我们除以|делим
уде́льный|单位的／比…的|удельный
литр|升|литров
число́|数量|число
лю́ди|人；число́ люде́й：人数|людей
теорети́ческий чертёж|型线图|теоретический чертёж
рассчи́тывать|计算|рассчитывают
цисте́рна|液舱；用于装液体的舱|цистерн
фо́рма|形状|формы
необходи́мый|必要的／所需的|необходимой
положе́ние|位置|положение
метаце́нтр|稳心；本题为横稳心|метацентра
у́гол|角度|угол
увели́читься|增大|увеличится
уме́ньшиться|减小|уменьшится
при про́чих ра́вных|其他条件相同的情况下|при прочих равных
бортова́я ка́чка|横摇|бортовая качка
ре́зкий|急促的；本题形容横摇|резкой
возмо́жный|可能的|возможна
поте́ря|丧失|потеря потерей
затопле́нный|进水的／被淹的|затопленных
отсе́к|分隔舱室|отсеков
сравне́ние|比较|сравнении
фо́рпик|艏尖舱|форпик
у́зкий|窄的|узкий
обы́чно|通常|обычно
симметри́чный|对称的|симметричное
'''
for line in rows.strip().splitlines():
    ru,zh,forms=line.split('|')
    aliases=[forms] if ' ' in norm(ru) else forms.split()
    aliases=list(dict.fromkeys([norm(ru)]+aliases))
    entry=next((e for e in entries if norm(e['ru'])==norm(ru)),None)
    if entry:entry['aliases']=list(dict.fromkeys(entry['aliases']+aliases))
    else:entries.append(dict(id='complete_'+norm(ru).replace(' ','_'),ru=ru,zh=zh.split('；')[0],meaning=zh,aliases=aliases))
p.write_text(json.dumps(entries,ensure_ascii=False,indent=2),encoding='utf-8')
print('Completed-answer vocabulary merged; existing exclusions retained.')
