"""13a-only vocabulary and actual word forms; reuse existing IDs first."""
import json,re
from pathlib import Path
import pymorphy3
ROOT=Path(__file__).resolve().parents[1];C=ROOT/'modules/review/content'
ROWS='''
заостри́ть|使尖削；使艏部变尖
смеща́ть|移动；使偏移
ча́стично|部分地|0
до́лжный|应当的；应有的|0
неудаля́емый|不能排除的；无法排出的
пита́ться|进餐；吃饭
аргуме́нт|自变量；依据
вы́звать|引起
выявля́ть|发现；查明
доста́точность|足够程度；充分性
избы́ток|富余；多余量
лежа́ть|位于
непосре́дственно|直接地
непра́вильно|不正确地
ни|表示否定列举：既不……也不……|0
остана́вливать|阻止
переде́лка|返工；重新修改
по́здний|晚的；过迟的
приго́дность|适用性
расхо́довать|消耗
убеди́ться|确认；查实
балла́стный|压载的
бы|表示假设语气的助词|0
вариа́нт|方案；情况；此处常指载况
взве́шивание|称重
включи́ть|纳入；计入
восстанови́ть|还原；恢复
выделя́ть|单独列出；划分
вы́теснить|排开；此处指船排开水
загру́зка|装载；载况
за́пись|表达式；记录
зара́нее|预先|0
интегри́рование|积分运算
интерполя́ция|插值
конструкти́вный|结构方面的
корректи́ровать|修正；调整
корректиро́вка|修正；调整
курсово́й|课程设计的
ли́шний|多余的
ма́ленький|小的|0
меша́ть|妨碍
надёжный|可靠的
назнача́ть|指定；选定
наиху́дший|最不利的；最差的
нежела́тельный|不希望出现的；不合适的
неизве́стный|未知的
необходи́мость|必要性
неприго́дный|不适用的
несовмести́мый|互不相容的；不能同时采用的
несовпаде́ние|不一致；不匹配
нехва́тка|不足；缺少
ну́жда|需要；用途需求
обрабо́тка|处理；装卸操作
образова́ние|形成
объявля́ться|被宣称；被宣布
обя́занный|必须的；有义务的
ока́зываться|结果是；发现处于某状态
оптимизи́ровать|优化
о́пытный|经验性的；试验得到的
организа́ция|组织；安排方式
ордина́та|型值；给定船体表面位置的坐标
отложи́ть|推迟
отменя́ть|取消；使不再需要
оце́нивать|估算；评价
перепроекти́рование|重新设计
перераспределе́ние|重新分配
перераспределя́ть|重新分配
перестано́вка|重新放置；移位
пересчи́тывать|重新计算
повто́р|重复
подбо́р|选取；选配
подро́бный|详细的
помеща́ться|容纳得下；放得进
попа́сть|进入
построе́ние|绘制；建立
потому́|因为；所以|0
потре́бный|所需的
потре́бовать|需要；要求
потре́боваться|变得需要；有必要
пра́вило|规则
представле́ние|表达方式；图示
приближённо|近似地
принципиа́льный|原则上的；根本的
приходи́ться|不得不；有必要
разде́л|项目；类别
разде́льный|分别的；单独的
разме́рный|与尺度有关的；有量纲的
разме́рность|量纲
ра́но|早；在早期|0
рейс|航次
скрыть|掩盖；隐藏
служи́ть|起……作用；作为
смысл|意义
снима́ть|读取；此处指从曲线图读取数值
содержа́ть|包含
соста́вить|编制；建立
сра́зу|立即；一起|0
строева́я по шпанго́утам|横剖面积曲线；沿船长绘制水下横剖面积
счита́ться|被视为；被计作
устрани́ть|消除
хара́ктер|性质；变化特点
хвати́ть|足够
'''
def read(p):return json.loads(p.read_text(encoding='utf8'))
def norm(s):return s.lower().replace('\u0301','').replace('ё','е')
def build():
    morph=pymorphy3.MorphAnalyzer();base=[]
    for path in [C/'glossary.json',ROOT/'content/approximation_glossary.json',C/'exam12/glossary.json',C/'reasoned_glossary.json']:base+=read(path)
    aliases={a for e in base for a in e['aliases']};lemmas={norm(e['ru']):e for e in base}
    definitions={}
    for row in ROWS.strip().splitlines():
        f=row.split('|');ru,zh=f[:2];key=norm(ru)
        e=lemmas.get(key,{'id':'p13_'+key.replace(' ','_'),'ru':ru,'zh':zh,'meaning':zh,'study':len(f)<3 or f[2]!='0','aliases':[ru.lower().replace('\u0301','')]})
        definitions[key]=e
    forms=set()
    for q in read(C/'exam12/reading.json')+(read(C/'exams/reading.json') if (C/'exams/reading.json').exists() else []):
        if q['id'].startswith(('P12_', 'P13_', 'THU')):
            for text in [q['question_ru'],q['answer']['ru']]:forms.update(re.findall('[а-яё]+',text.lower().replace('\u0301','')))
    output={};missing={}
    fixes={'обвод':'обводы','плохой':'наихудший','обязать':'обязанный','строевой':'строевая по шпангоутам','неудалять':'неудаляемый'}
    for w in sorted(forms):
        if w in aliases:continue
        parses=morph.parse(w);lemma=fixes.get(norm(parses[0].normal_form),norm(parses[0].normal_form))
        if lemma in lemmas:e=lemmas[lemma]
        elif lemma in definitions:e=definitions[lemma]
        else:
            matches=[lemmas[norm(p.normal_form)] for p in parses if norm(p.normal_form) in lemmas]
            if not matches:missing[w]=lemma;continue
            e=matches[0]
        if e['id'] not in output:output[e['id']]=dict(e,aliases=list(e['aliases']))
        output[e['id']]['aliases']=list(dict.fromkeys(output[e['id']]['aliases']+[w]))
    (C/'exam12/glossary13.json').write_text(json.dumps(list(output.values()),ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    (ROOT/'qa/exam13/lexical-results.json').write_text(json.dumps({'missing':missing,'entries':len(output)},ensure_ascii=False,indent=2),encoding='utf8')
    print('13a glossary:',len(output),'entries/alias extensions; missing:',missing)
    return missing
if __name__=='__main__':build()
