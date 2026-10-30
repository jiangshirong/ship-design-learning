"""Canonical 5p + 6p catalogue and continuous courses. No user data access."""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def read(name): return json.loads((ROOT / name).read_text(encoding="utf-8"))
def write(name, data): (ROOT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
def words(zh, ru): return {"zh": zh, "ru": ru}
def norm(s): return s.replace("\u0301", "").lower().replace("ё", "е")

# Full original question, accented display, full translation, short answer.
NEW = [
(1, "Почему в качестве относительной поперечной метацентрической высоты используется отношение h/В, а не h/Н или h/Т?",
"Почему́ в ка́честве относи́тельной попере́чной метацентри́ческой высоты́ испо́льзуется отноше́ние h/В, а не h/Н и́ли h/Т?",
"为什么相对横稳心高采用h/B，而不是h/H或h/T？",
"Ширина́ свя́зана с попере́чной осто́йчивостью и ка́чкой.", "船宽与横稳性和横摇有关。"),
(2, "Почему отношение h/В считают универсальным показателем поперечной остойчивости судна?",
"Почему́ отноше́ние h/В счита́ют универса́льным показа́телем попере́чной осто́йчивости су́дна?",
"为什么把h/B看作船舶横稳性的通用指标？",
"Оно́ позволя́ет сравни́вать осто́йчивость судо́в ра́зных разме́ров.", "它便于比较不同尺度船舶的稳性。"),
(3, "В чем заключается опасность для судна, если h/В = 0,01?",
"В чём заключа́ется опа́сность для су́дна, е́сли h/В = 0,01?",
"如果h/B=0.01，船舶有什么危险？",
"Нача́льная осто́йчивость мо́жет быть недоста́точной.", "初稳性可能不足。"),
(4, "В чем заключается опасность для судна, если h/В = 0,10?",
"В чём заключа́ется опа́сность для су́дна, е́сли h/В = 0,10?",
"如果h/B=0.10，船舶有什么危险？",
"Возмо́жна ре́зкая ка́чка. Для та́нкеров э́то мо́жет быть допусти́мо. Для та́нкера э́то мо́жет быть допусти́мо.", "可能横摇急促；对油船，这个值可能允许。"),
(5, "Какова цель составления и решения уравнения остойчивости?",
"Какова́ цель составле́ния и реше́ния уравне́ния осто́йчивости?",
"建立并求解稳性方程的目的是什么？",
"Определи́ть отноше́ние ширины́ к оса́дке для тре́буемой осто́йчивости.", "求满足所需稳性的船宽与吃水之比。"),
(6, "Почему нельзя гарантированно обеспечить остойчивость на больших углах крена при выборе основных элементов судна?",
"Почему́ нельзя́ гаранти́рованно обеспе́чить осто́йчивость на больши́х угла́х кре́на при вы́боре основны́х элеме́нтов су́дна?",
"为什么在选择船舶主要要素时，不能保证大倾角稳性？",
"Ну́жны то́чная фо́рма ко́рпуса и положе́ние це́нтра масс.", "还需要准确船体形状和重心位置。"),
(10, "Какие меры обеспечивают достаточную аварийную остойчивость судна?",
"Каки́е ме́ры обеспе́чивают доста́точную авари́йную осто́йчивость су́дна?",
"哪些措施能够保证船舶具有足够的事故稳性？",
"Сни́зить центр масс и ограни́чить затопле́ние водонепроница́емыми перебо́рками.", "降低重心，并用水密舱壁限制进水范围。"),
(12, "С какой целью ограничивается допустимый угол крена при аварии?",
"С како́й це́лью ограни́чивается допусти́мый у́гол кре́на при ава́рии?",
"为什么要限制事故时允许的横倾角？",
"Что́бы вода́ не поступа́ла че́рез отве́рстия и мо́жно бы́ло спасти́ люде́й.", "避免水从开口继续进入，并使人员能够获救。"),
(13, "Каковы цели нормирования надводного борта судна?",
"Каковы́ це́ли норми́рования надво́дного бо́рта су́дна?",
"规定船舶干舷的目的有哪些？",
"Обеспе́чить запа́с плаву́чести и ограни́чить поступле́ние воды́.", "保证储备浮力，限制水进入船内。"),
(14, "Какому состоянию нагрузки соответствует нормирование надводного борта?",
"Како́му состоя́нию нагру́зки соотве́тствует норми́рование надво́дного бо́рта?",
"干舷的规定对应什么载荷状态？",
"По́лной нагру́зке при наибо́льшей допусти́мой оса́дке.", "最大允许吃水下的满载货物、储备齐全的状态。"),
(15, "Почему учет надстроек приводит к возможности уменьшить минимальный надводный борт?",
"Почему́ учёт надстро́ек приво́дит к возмо́жности уме́ньшить минима́льный надво́дный борт?",
"为什么计入上层建筑后，可以减小最小干舷？",
"Закры́тые надстро́йки увеличи́вают запа́с плаву́чести.", "封闭水密的上层建筑增加储备浮力。"),
(16, "Назовите два наиболее приемлемых способа увеличения высоты борта в носу, если расчет по Правилам Регистра выявил ее недостаточность.",
"Назови́те два наибо́лее прие́млемых спо́соба увеличе́ния высоты́ бо́рта в носу́, е́сли расчёт по Пра́вилам Реги́стра вы́явил её недоста́точность.",
"如果按船级社规则计算发现艏部舷高不足，请说出两种最合适的增高办法。",
"Увели́чить носову́ю седлова́тость и́ли устро́ить бак.", "增大艏部舷弧，或者设置艏楼。"),
]
TOPICS = [
("design", "设计任务与设计过程", "Проекти́рование", [1,5,3,4], [],
 "看懂谁提出要求、设计怎样落实，以及为什么保留竣工资料。", "Поймём тре́бования, эта́пы прое́кта и документа́цию."),
("loads", "载荷与质量计算", "Нагру́зка и ма́ссы", [2,6,7,8,9,10], [],
 "分清船的能力与实际装载，再逐项算出船体、动力和供应质量。", "Различи́м возмо́жности су́дна и нагру́зку; рассчита́ем ма́ссы."),
("cargo", "货舱容积与装载", "Грузовмести́мость", [12,13,14,11,15], [],
 "看懂货物先受到质量限制还是空间限制，以及怎样增加舱容。", "Узна́ем, что ограни́чивает погру́зку: ма́сса и́ли объём."),
("stability", "稳性与横摇", "Осто́йчивость и ка́чка", [17,16,20,21,18,19], [1,2,3,4,5,6],
 "看懂船怎样扶正，以及船型、重心和尺度怎样影响稳性与横摇。", "Поймём влия́ние фо́рмы, це́нтра масс и разме́ров на осто́йчивость."),
("damage", "进水与不沉性", "Непотопля́емость", [22,23,24,25], [10,12],
 "跟踪水进入哪些舱，区分船为什么下沉、倾斜，以及怎样限制危险。", "Проследи́м затопле́ние и узна́ем, как ограни́чить опа́сность."),
("freeboard", "干舷与艏部高度", "Надво́дный борт", [], [13,14,15,16],
 "从水线量出干舷，理解储备浮力，再比较两种增高艏部的办法。", "Изме́рим надво́дный борт и сравни́м два спо́соба увели́чить высоту́ в носу́."),
]
DUP = {22:7,23:8,24:9,25:11}
CONDITIONS = {
"N01": words("船宽直接关联横向几何与横摇；另外两个比值也无量纲。","Два други́х отноше́ния то́же безразме́рны."),
"N02": words("用于初稳性比较，不能单独证明大倾角稳性或规范合格。","Э́то сравне́ние нача́льной осто́йчивости, а не по́лная прове́рка."),
"N03": words("本题沿用课件的一般运输船比较口径，仍须结合船型、载况。","Оце́нка зави́сит от ти́па су́дна и нагру́зки."),
"N04": words("一般运输船可能横摇急促；课件对油船另给出0.08—0.10的常见范围。","Для тра́нспортного су́дна возмо́жна ре́зкая ка́чка; для та́нкера оце́нка друга́я."),
"N10": words("加压载须同时检查储备浮力；降低重心不能替代水密分舱。","При приёме балла́ста прове́ряют запа́с плаву́чести."),
"N15": words("只有符合课程所列封闭及保护条件的上层建筑才能计入。","Учи́тывают надстро́йки, отвеча́ющие тре́бованиям к закры́тию."),
"Q20": words("仅比较小角度自由横摇，固定等效回转半径且初稳性高为正。","Ма́лые свобо́дные колеба́ния; эффекти́вный ра́диус ине́рции постоя́нен."),
"Q24": words("此处比较失去浮性与失去稳性；失去稳性可造成迅速倾覆。","Сра́вниваем поте́рю плаву́чести и поте́рю осто́йчивости."),
"Q25": words("题目沿用狭窄艏尖舱、通常对称进水的情景；“永远不会”并非普遍保证。","Речь об у́зком фо́рпике и обы́чно симметри́чном затопле́нии; «никогда́» не универса́льно."),
}

def beat(id, zh, ru, start=None, action=None, **extra):
    b = dict(id=id, text=zh, words=words(zh,ru))
    if start is not None: b["start_params"]=start
    if action: b["action"]=dict(params=action,duration=3)
    b.update(extra)
    return b

def build():
    readings = read("content/authoring/reading_5p.json")
    bank = read("content/authoring/question_bank_5p.json")
    legacy = read("content/authoring/lessons_5p.json")
    byid={r["id"]:r for r in readings}; old={l["id"]:l for l in legacy}
    for q in bank:
        q["sources"]=[f"5p-{q['number']}"]
        if q["number"] in DUP:q["sources"].append(f"6p-{DUP[q['number']]}")
    for n,original,ru,zh,aru,azh in NEW:
        qid=f"N{n:02}"
        bank.append(dict(id=qid,number=n,title_zh=zh,question_original=original,question_ru=ru,sources=[f"6p-{n}"]))
        r=dict(id=qid,number=n,question_ru=ru,translation=zh,answer=words(azh,aru),source={"question":f"6p/Вопросы к модулям 9 и 10.docx #{n}","module":f"6p/Modul_{9 if n<=6 else 10}.docx"})
        readings.append(r);byid[qid]=r
    # Concise revised answers use question vocabulary; qualifications live adjacent.
    overrides={
      "Q16":("От фо́рмы подво́дной ча́сти, оса́дки и тре́буемой осто́йчивости.","取决于水下形状、吃水及所要求的稳性。"),
      "Q17":("Да, фо́рма влия́ет на положе́ние це́нтра величины́ и метаце́нтра.","会，船型影响浮心和稳心的位置。"),
      "Q18":("При сниже́нии це́нтра масс у́гол зака́та обы́чно увели́чивается.","降低重心通常使稳性消失角增大。"),
      "Q19":("Ма́ксимальное плечо́ обы́чно уменьша́ется.","最大复原力臂通常减小。"),
      "Q20":("Пери́од увели́чивается, е́сли метацентри́ческая высота́ уменьша́ется.","若初稳性高减小，周期增长。"),
      "Q21":("Сли́шком больша́я осто́йчивость вызыва́ет ре́зкую ка́чку.","稳性过大可造成横摇急促。"),
      "Q24":("Поте́ря осто́йчивости: су́дно мо́жет бы́стро опроки́нуться.","失去稳性：船可能迅速倾覆。"),
      "Q25":("Фо́рпик у́зкий; затопле́ние обы́чно симметри́чное.","艏尖舱狭窄，进水通常对称。"),
    }
    for qid,(ru,zh) in overrides.items():byid[qid]["answer"]=words(zh,ru)
    for r in readings:
        r.pop("fact",None);r.pop("phrases",None)
        if r["id"] in CONDITIONS:r["condition"]=CONDITIONS[r["id"]]
    courses=[]; formulas={}
    def formula(id,*tex):
        formulas[id]={lang:[dict(tex=t,linear=t) for t in tex] for lang in ["zh","ru"]}
    def conclude(qid):
        r=byid[qid]
        return beat(f"TOP:{qid}:answer",r["answer"]["zh"],r["answer"]["ru"],
                    condition=r.get("condition",{}),
                    recap=words(r["translation"]+"\n"+r["answer"]["zh"],r["question_ru"]+"\n"+r["answer"]["ru"]))
    for tid,zh,ru,oq,nq,goal,goalru in TOPICS:
        ids=[f"Q{x:02}" for x in oq]+[f"N{x:02}" for x in nq]
        course=dict(id=tid,title=words(zh,ru),goal=words(goal,goalru),questions=ids,
                    initial={"progress":0,"loaded":0,"height":2,"topic":tid,"qid":ids[0]},
                    groups=[],question_targets={})
        if tid=="stability":
            course.update(copy.deepcopy(read("content/authoring/stability_course_5p.json")))
            course["title"]=words(zh,ru);course["goal"]=words(goal,goalru);course["questions"]=ids;course["question_targets"]={}
        else:
            base=beat(f"TOP:{tid}:goal",goal,goalru,start={"qid":ids[0],"topic":tid,"phase":"intro","progress":0})
            btexts={
             "design":("要求说明要完成什么；方案说明怎样做到。","Тре́бования задаю́т зада́чу, прое́кт даёт реше́ние."),
             "loads":("实际载荷可以改变；船的能力指标不是每次装载的质量。","Нагру́зка меня́ется; дедве́йт — возмо́жность су́дна."),
             "cargo":("舱室是空间，舱容是它能用于装货的体积。","Грузовы́е помеще́ния — простра́нство, грузовмести́мость — его́ объём."),
             "damage":("水密舱壁把船内分开，限制破损后水能到达的范围。","Водонепроница́емые перебо́рки ограни́чивают затопле́ние."),
             "freeboard":("干舷从水线向上量到舷侧甲板边缘。","Надво́дный борт измеря́ют от ватерли́нии до кро́мки па́лубы."),
            }
            z,r=btexts[tid]
            end=beat(f"TOP:{tid}:foundation_end",z,r,action={"progress":1,"partitions":1},anchor="water")
            if tid=="damage":
                base["start_params"].update(phase="exterior",cutaway=0);end["action"]["params"].update(phase="bulkheads",cutaway=1)
            course["groups"]=[dict(id="foundation",title=words("基础","Осно́вы"),beats=[base,end])]
            if tid=="damage":
                opening=beat("TOP:damage:cutaway","打开这段舷侧和甲板，保留船底与其余船壳。","Откро́ем часть бо́рта и па́лубы.",start={"phase":"section"},action={"cutaway":1,"partitions":1})
                frames=beat("TOP:damage:frames","密集的骨架支撑船体；封闭的板面才把舱室隔开。","Набо́р укрепля́ет ко́рпус; перебо́рки разделя́ют отсе́ки.",start={"phase":"frames"})
                height=beat("TOP:damage:wall_height","这里的舱壁从内底接到甲板，封住整个舱高。","Здесь перебо́рки иду́т от второ́го дна до па́лубы.",start={"phase":"bulkheads"})
                end["start_params"]={"phase":"bulkheads"}
                course["groups"][0]["beats"]=[base,opening,frames,height,end]
        if tid not in ["stability","damage","freeboard"]:
            for qid in ids:
                source=old[qid];bs=[]
                for group in source["groups"]:
                    for raw in group["beats"]:
                        b=copy.deepcopy(raw)
                        b["start_params"]={**source["initial"],"qid":qid,"topic":tid,"phase":b.get("phase","intro")} if not bs else {"qid":qid,"phase":b.get("phase","intro")}
                        b["view_kind"]=source.get("view","design" if qid in ["Q01","Q04","Q05"] else "hold")
                        # Same renderer objects remain alive across all beats.
                        b["camera"]="overview";b["anchor"]="ship"
                        bs.append(b)
                        source_formula=read("content/latex_source.json").get(qid+":"+b.get("phase","intro"))
                        if source_formula:formulas[b["id"]]=source_formula
                bs.append(conclude(qid))
                course["groups"].append(dict(id=qid,title=words(byid[qid]["translation"].split("，")[0][:13],f"5p-{int(qid[1:])}"),beats=bs))
                course["question_targets"][qid]=bs[0]["id"]
        courses.append(course)

    stability=next(c for c in courses if c["id"]=="stability")
    orig={g["id"]:g for g in stability["groups"]}
    for qid in [f"Q{x:02}" for x in range(16,22)]:
        if qid != "Q19": orig[qid]["beats"].append(conclude(qid))
        stability["question_targets"][qid]=orig[qid]["beats"][0]["id"]
    hydro=read("content/stability_hydro.json")["routes"]["base"][0]
    km=hydro["km"];B=hydro["params"]["B"]
    def stgroup(qid,title,items):
        bs=[]
        for key,z,r,patch,action,tex in items:
            b=beat(f"TOP:{qid}:{key}",z,r,start=patch,action=action,camera="front_scale" if qid=="N02" else "front",anchor="M")
            if tex:formula(b["id"],*tex)
            bs.append(b)
        bs.append(conclude(qid));g=dict(id=qid,title=words(title,f"6p-{int(qid[1:])}"),beats=bs)
        stability["question_targets"][qid]=bs[0]["id"];return g
    ratio=[
      stgroup("N01","相对稳性高",[
        ("goal","同样的稳性高，对宽船和窄船的相对意义不同。","Одина́ковая высота́ име́ет ра́зное отноше́ние к ширине́.",{"route":"base","morph":0,"heel":0,"zg":8.7,"show":"M","plot":"","compare":False},None,[r"\frac{h}{B}=\frac{z_c+r-z_g}{B}"]),
        ("width","船宽直接影响横向几何；换成更窄船型，观察稳心变化。","Ширина́ влия́ет на попере́чную геоме́трию и метаце́нтр.",{"route":"narrow","morph":0},{"morph":1},[r"r=\frac{I_x}{\nabla}",r"\frac{h}{B}=@st_ratio@"]),
        ("limits","其他比值也无量纲；选船宽还因为它与横稳性和横摇有关。","Два други́х отноше́ния то́же безразме́рны; ширина́ свя́зана с ка́чкой.",{},None,[r"\frac{h}{H},\quad\frac{h}{T}"])
      ]),
      stgroup("N02","比较尺度",[
        ("goal","把相似船整体放大两倍，高度与船宽也都放大两倍。","У подо́бных судо́в при увеличе́нии вдво́е высота́ и ширина́ удва́иваются.",{"route":"base","morph":0,"zg":8.7,"heel":5,"show":"M","display_scale":1}, {"display_scale":2},[r"h'=2h,\quad B'=2B",r"\frac{h'}{B'}=\frac{2h}{2B}=\frac{h}{B}"]),
        ("boundary","这个比值便于比较初稳性，但没有给出整条复原力臂曲线。","Отноше́ние сравни́вает нача́льную осто́йчивость, но не всю диагра́мму.",{"display_scale":1},None,None)
      ]),
    ]
    risks=[
      stgroup("N03","稳性偏弱",[
        ("goal","固定船型，把重心升高，直到相对稳性高降到0.01。","При той же фо́рме поднима́ем центр масс.",{"route":"base","morph":0,"zg":8.7,"heel":6,"show":"arm","plot":""}, {"zg":km-.01*B},[r"\frac{h}{B}=0.01",r"h=0.01B",r"l_{\mathrm{ст}}=@st_arm@\,\mathrm{m}"]),
        ("weak","重力与浮力的水平间距变小，扶正作用变弱。","Плечо́ уменьша́ется; восстана́вливающий моме́нт уменьша́ется.",{},None,None)
      ]),
      stgroup("N04","稳性偏强",[
        ("goal","保持等效回转半径，增大稳性高，比较同一时钟下的横摇。","При постоя́нном ра́диусе ине́рции увели́чим метацентри́ческую высоту́.",{"route":"base","morph":0,"zg":km-.1*B,"heel":0,"show":"roll","plot":"roll","clock":0,"compare":True,"reference_zg":km-.04*B}, {"clock":24},[r"\frac{h}{B}=0.10",r"\tau=\frac{2\pi k_{\mathrm{eff}}}{\sqrt{gh}}"]),
        ("type","较短周期可能使运输船横摇急促；油船须按其船型与载况判断。","Ка́чка мо́жет быть ре́зкой; для та́нкера учи́тывают тип и нагру́зку.",{},None,None)
      ])
    ]
    ends=[
      stgroup("N05","稳性方程",[
        ("goal","先给定所需稳性高，再选择能满足它的船宽、吃水和重心高度。","Задаём тре́буемую высоту́ и выбира́ем разме́ры.",{"show":"limit","plot":"","compare":False,"route":"base","morph":0,"zg":8.7,"required":1,"heel":0},None,[r"h=z_c+r-z_g"]),
        ("required","提高要求时，实际重心不动，允许的重心上界下降。","При повыше́нии тре́бований допусти́мая высота́ це́нтра масс уменьша́ется.",{},{"required":2},[r"z_g\leq z_c+r-h_{\min}"]),
        ("dimensions","也可以调整主尺度，重新计算浮心和横稳心。","Мо́жно измени́ть разме́ры и пересчита́ть центр величины́ и метаце́нтр.",{"route":"narrow","morph":0},{"morph":.7},[r"z_c=k_1\sqrt{\frac{\alpha}{\delta}}\,T",r"r=\frac{\alpha^2B^2}{k_2\delta T}",r"z_g=\xi H"])
      ]),
      stgroup("N06","大倾角复核",[
        ("goal","从微倾继续倾斜，直接看浮心移动形成的完整力臂曲线。","Увели́чим крен и рассмо́трим по́лную диагра́мму плеч.",{"route":"base","morph":0,"zg":8.7,"heel":0,"show":"arm","plot":"arm","compare":False}, {"heel":110},[r"l_{\mathrm{ст}}(\theta)=y_C(\theta)-z_g\sin\theta"]),
        ("limits","主尺度和初稳性高没有唯一确定大倾角下的船体形状与力臂。","Основны́е разме́ры не определя́ют всю фо́рму ко́рпуса.",{},None,None)
      ])
    ]
    stability["groups"]=[orig["foundation"],orig["Q17"],orig["Q16"],*ratio,orig["Q20"],orig["Q21"],*risks,orig["Q18"],orig["Q19"],*ends]
    # Explicit per-stage initial snapshots prevent context-dependent jumps.
    for g in stability["groups"]:
        b=g["beats"][0];b["start_params"]={**stability["initial"],**b.get("start_params",{})}
    damage=next(c for c in courses if c["id"]=="damage")
    free=next(c for c in courses if c["id"]=="freeboard")
    def marine_group(c,qid,title,items):
        bs=[]
        base={"topic":c["id"],"qid":qid,"partitions":1,"flood":0,"side":0,"bay":2,"heel_demo":0,"sink":0,"superstructure":0,"sheer":0,"forecastle":0,"draft":8.0,"phase":"section"}
        for i,(key,z,r,patch,act,tex) in enumerate(items):
            b=beat(f"TOP:{qid}:{key}",z,r,start={**base,**patch} if i==0 else patch,action=act,camera="overview",anchor=patch.get("anchor","ship"))
            bs.append(b)
            if tex:formula(b["id"],*tex)
        bs.append(conclude(qid));c["groups"].append(dict(id=qid,title=words(title," / ".join(next(q["sources"] for q in bank if q["id"]==qid))),beats=bs));c["question_targets"][qid]=bs[0]["id"]
    marine_group(damage,"Q22","进水后果",[
      ("water","先让水进入一个舱，观察原有密闭空间被占去。","Вода́ поступа́ет в оди́н отсе́к.",{},{"flood":1},None),
      ("sink","如果剩余浮力不足，船会继续下沉。","При недоста́тке плаву́чести су́дно погружа́ется.",{},{"sink":2},None),
      ("heel","单侧舱室进水，还要观察横倾。","Несимметри́чное затопле́ние вызыва́ет крен.",{"sink":0,"flood":0},{"flood":1,"side":1,"heel_demo":12},None)])
    marine_group(damage,"Q23","保留储备浮力",[
      ("reserve","水线上方的封闭空间提供储备浮力。","Закры́тый объём над водо́й создаёт запа́с плаву́чести.",{"phase":"reserve"},None,None),
      ("barrier","相同破口，有水密舱壁时进水限制在局部。","При той же пробо́ине перебо́рки ограни́чивают затопле́ние.",{},{"flood":1},None),
      ("spread","失去水密分隔，水会扩展到更多舱室。","Без водонепроница́емых перебо́рок зата́пливается бо́льший объём.",{},{"partitions":0,"spread":1},None)])
    marine_group(damage,"Q24","为什么翻覆更危险",[
      ("compare","现在比较失去浮性与失去稳性。","Сра́вним поте́рю плаву́чести и осто́йчивости.",{"spread":0}, {"flood":.7},None),
      ("capsize","横倾继续增大时，人员撤离和救生更困难。","При большо́м кре́не спасти́ люде́й тру́днее.",{"side":1},{"heel_demo":38},None)])
    marine_group(damage,"Q25","艏尖舱",[
      ("forepeak","把进水位置移到狭窄的艏尖舱。","Перенесём затопле́ние в у́зкий фо́рпик.",{"phase":"forepeak","bay":4,"spread":0}, {"flood":1},None),
      ("symmetry","对称进水主要改变纵向状态，不等于所有事故都不会失稳。","Симметри́чное затопле́ние не исключа́ет все случа́и поте́ри осто́йчивости.",{},None,None)])
    marine_group(damage,"N10","改善事故稳性",[
      ("limit","先限制进水范围：让水密舱壁保住未破损空间。","Ограни́чим затопле́ние перебо́рками.",{"flood":1,"partitions":0,"spread":1},{"partitions":1,"spread":0},None),
      ("G","再降低重心，增加稳性储备；压载仍要检查储备浮力。","Сни́зим центр масс; при балла́сте прове́рим запа́с плаву́чести.",{"phase":"G","demo_zg":11},{"demo_zg":7},None)])
    marine_group(damage,"N12","限制横倾",[
      ("opening","让船向开口一侧倾斜，观察开口与水面的距离。","Наклони́м су́дно к отве́рстию.",{"phase":"opening","side":1,"flood":.8},{"heel_demo":28},None),
      ("limit","限制横倾既减少继续进水的风险，也保留救生条件。","Ограни́чение кре́на уменьша́ет поступле́ние воды́ и помога́ет спасе́нию.",{},None,None)])
    marine_group(free,"N13","最小干舷",[
      ("measure","水线不变，从水线到甲板边缘量出干舷。","От ватерли́нии до кро́мки па́лубы измеря́ем надво́дный борт.",{"phase":"freeboard"},None,[r"F=H-T"]),
      ("reserve","船装得更深，干舷和水面以上的封闭体积一起减小。","При увеличе́нии оса́дки надво́дный борт и запа́с плаву́чести уменьша́ются.",{},{"draft":11},[r"T\uparrow\quad\Longrightarrow\quad F\downarrow"])])
    marine_group(free,"N14","载况与吃水",[
      ("full","逐渐加深吃水，直到最小干舷所对应的允许水线。","Увели́чим оса́дку до допусти́мой ватерли́нии.",{"phase":"freeboard"},{"draft":11},[r"T_{\max}=H-F_{\min}"]),
      ("limit","满载状态仍不能超过这条允许水线。","При по́лной нагру́зке нельзя́ превыша́ть допусти́мую оса́дку.",{},None,[r"T\leq T_{\max}"])])
    marine_group(free,"N15","封闭上层建筑",[
      ("volume","增加封闭上层建筑，观察水线上方多出的密闭空间。","Закры́тая надстро́йка добавля́ет объём над водо́й.",{"phase":"superstructure"},{"superstructure":1},None),
      ("condition","只有满足封闭与保护条件，才能用于最小干舷的修正。","Для попра́вки ну́жно выполне́ние тре́бований к закры́тию.",{},None,None)])
    marine_group(free,"N16","提高艏部",[
      ("sheer","第一种办法：使艏部甲板向上翘，增加艏部舷弧。","Пе́рвый спо́соб: увели́чить носову́ю седлова́тость.",{"phase":"bow"},{"sheer":1},None),
      ("forecastle","第二种办法：设置艏楼，增加艏部高度。","Второ́й спо́соб: устро́ить бак.",{"sheer":0},{"forecastle":1},None)])
    from q12_drawings import apply as apply_q12_drawings
    apply_q12_drawings(courses, formulas)
    for c in courses:
        c["characters_per_second"]=25
        c["foundation_end"]="ST:foundation_end" if c["id"]=="stability" else f"TOP:{c['id']}:foundation_end"
        for qid in c["questions"]:
            q=next(q for q in bank if q["id"]==qid)
            q["topic"]=c["id"];q["target"]=c["question_targets"][qid]
            byid[qid].update(sources=q["sources"],topic=c["id"],target=q["target"])
        if c["id"] in ["damage","freeboard"]:
            c["initial"].update(partitions=0,flood=0,spread=0,draft=8.0,heel_demo=0,sink=0,phase="section",superstructure=0,sheer=0,forecastle=0,demo_zg=10)
    from topic_repairs import apply as repair_topics
    repair_topics(courses,formulas,byid)
    from module11 import apply as apply_module11
    apply_module11(courses,formulas,bank,byid)
    from revision9p import apply as apply_revision9p
    apply_revision9p(courses,formulas,bank,byid)
    from topic_refinements import apply as refine_topics
    refine_topics(courses,formulas,bank,byid)
    # Inserted concept beats are part of the question, including first-entry handoff.
    for c in courses:
        for g in c['groups']:
            if g['id'] not in c['questions']:continue
            target=g['beats'][0]['id']
            c['question_targets'][g['id']]=target
            byid[g['id']]['target']=target
            next(q for q in bank if q['id']==g['id'])['target']=target
    # Stable topic order is also the reading A/D order.
    ordered=[byid[qid] for c in courses for qid in c["questions"]]
    import sys
    sys.path.insert(0,str(ROOT.parents[1]/'tools'))
    from apply_reasoned_answers import apply as apply_reasoned
    apply_reasoned(ordered,courses)
    write("content/question_bank.json",bank);write("content/reading.json",ordered)
    for key in ["B","H","T"]:formula("_inline:ratio"+key,r"\tfrac{h}{"+key+"}")
    write("content/topics.json",courses);write("content/topics_latex.json",formulas)
    for l in legacy:
        l["answer"]=byid[l["id"]]["answer"];l.pop("question_speech",None)
    write("content/lessons.json",legacy)
    add_vocabulary()
    from q12_drawings import glossary as q12_glossary
    q12_glossary()
    from module11 import glossary as module11_glossary
    module11_glossary()
    from revision9p import vocabulary as revision9p_vocabulary
    revision9p_vocabulary()
    from build_reasoned_lexicon import build as build_answer_words
    build_answer_words()
    print(f"{len(ordered)} cards; {sum(len(q['sources']) for q in bank)} source IDs; {len(courses)} topics; {sum(len(g['beats']) for c in courses for g in c['groups'])} beats")

def add_vocabulary():
    entries=read("content/glossary.json")
    rows="""
увели́чиваться|увеличивается;увеличиваться|增大
уменьша́ться|уменьшается;уменьшаться|减小
вызыва́ть|вызывает;вызывать|引起
свя́занный|связана;связанный|相关的
нача́льный|начальная;начальный|初始的
то́чный|точная;точный|准确的
це́ль|цель;целью;цели|目的
вы́брать|выбрать;выборе|选择
тре́буемый|требуемой;требуемую;требуемый|所要求的
ма́ксимальный|максимальное;максимальный|最大的
плечо́|плечо;плеча|力臂
у́гол|углах;угол;угла;углы|角
крен|крена;крен;крене|横倾
ка́чка|качку;качкой;качка|摇荡；本题指横摇
шири́на|ширина;ширины;ширине|船宽
разме́р|размеров;размеры;размер|尺度
состоя́ние|состоянию;состояние;состояния|状态
по́лный|полной;полный;полным|满的；完整的
нагру́зка|нагрузке;нагрузки;нагрузка|载荷；载况
оса́дка|осадке;осадка;осадки|吃水
запа́с|запас;запаса;запасы|储备
увели́чивать|увеличивают;увеличивать|增大
увеличе́ние|увеличения;увеличение|增加
пра́вила|правилам;правила|规则
реги́стр|регистра;регистр|船级社
теорети́ческий чертёж|теоретический чертеж;теоретический чертёж|型线图
бы́стро|быстро|迅速地
относи́тельный|относительной;относительная;относительный|相对的
отноше́ние|отношение;отношения;отношению|比值；关系
показа́тель|показателем;показатель;показатели|指标
универса́льный|универсальным;универсальный|通用的
счита́ть|считают;считать|认为；计算
испо́льзовать|используется;использовать;используют|使用
сра́внивать|сравнивать;сравним;сравнивают|比较
позволя́ть|позволяет;позволяют;позволять|允许；使能够
заключа́ться|заключается;заключаться|在于
опа́сность|опасность;опасности|危险
недоста́точный|недостаточной;недостаточность;недостаточности;недостаточный|不足的
доста́точный|достаточную;достаточный|足够的
допусти́мый|допустимый;допустимой;допустимо;допустимую|允许的
гаранти́рованно|гарантированно|有保证地
основно́й|основных;основные;основной|主要的
элеме́нт|элементов;элементы;элемент|要素
составле́ние|составления;составление|建立；编制
реше́ние|решения;решение|求解；方案
уравне́ние|уравнения;уравнение|方程
обеспе́чить|обеспечить;обеспечивают;обеспечив;обеспечивает|保证；提供
поступле́ние|поступление;поступления|进入；流入
поступа́ть|поступала;поступает;поступать|进入
ограни́чить|ограничить;ограничивается;ограничивают;ограничить|限制
ограниче́ние|ограничение;ограничения|限制
ме́ра|меры;мер;мера|措施
авари́йный|аварийную;аварийной;аварийный|事故后的；破损状态的
авари́йная осто́йчивость|аварийную остойчивость;аварийной остойчивости|事故稳性
водонепроница́емый|водонепроницаемыми;водонепроницаемые;водонепроницаемых|水密的
перебо́рка|переборками;переборки;переборка|舱壁
отве́рстие|отверстия;отверстие;отверстий|开口
спасти́|спасти;спасению|救助
норми́рование|нормирования;нормирование|规定标准
надво́дный борт|надводного борта;надводный борт|干舷
наибо́льший|наибольшей;наибольший|最大的
соотве́тствовать|соответствует;соответствовать|对应；符合
учёт|учет;учёт|计入；考虑
надстро́йка|надстроек;надстройки;надстройка|上层建筑
закры́тый|закрытые;закрытию;закрытый|封闭的
приводи́ть|приводит;приводить|导致；使得
минима́льный|минимальный;минимального;минимальную|最小的
но́с|носу;носа;нос|船艏
носова́я седлова́тость|носовую седловатость;носовая седловатость|艏部舷弧
седлова́тость|седловатость;седловатости|舷弧
бак|бак;бака|艏楼
устро́ить|устроить|设置
вы́явить|выявил;выявить|发现；查明
назва́ть|назовите;назвать|说出；列举
спо́соб|способа;способы;способ|办法
прие́млемый|приемлемых;приемлемый|适用的；可接受的
сни́зить|снизить;снижении|降低
ре́зкий|резкая;резкую;резкой|急促的
опроки́нуться|опрокинуться|倾覆
симметри́чный|симметричное;симметричном;симметричный|对称的
"""
    for line in rows.strip().splitlines():
        ru,aliases,zh=line.split("|");als=aliases.split(";")
        existing=next((e for e in entries if norm(e["ru"])==norm(ru)),None)
        if existing:
            existing["aliases"]=list(dict.fromkeys(existing["aliases"]+als))
        else:entries.append(dict(id="topic_"+norm(ru).replace(" ","_"),ru=ru,zh=zh,meaning=zh,aliases=als,study=True))
    excluded={"еще","какой","быть","например","сначала","меньше","можно","больше","мочь","нужно"}
    for e in entries:
        if norm(e["ru"]) in excluded:e["study"]=False
    write("content/glossary.json",entries)
    from apply_glossary_review import apply
    apply()

if __name__=="__main__":build()
