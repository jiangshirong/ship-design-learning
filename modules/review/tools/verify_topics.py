"""Source/content checks independent of the Godot navigation suite."""
import hashlib
import json
import re
import zipfile
import xml.etree.ElementTree as ET
from decimal import Decimal as D
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
COURSE=ROOT.parents[2]
def read(name):return json.loads((ROOT/name).read_text(encoding="utf-8"))
def norm(value):return " ".join(value.lower().replace("\u0301","").replace("ё","е").split())
checks=[]
def check(value,name):checks.append(dict(passed=bool(value),name=name))
bank=read("content/question_bank.json");cards=read("content/reading.json");topics=read("content/topics.json")
byid={q["id"]:q for q in bank}
check(len(bank)==len(cards)==62,"62 canonical questions")
check(len({q["id"] for q in cards})==62,"Canonical IDs unique")
aliases={source:q["id"] for q in bank for source in q["sources"]}
check(len(aliases)==90,"90 source aliases")
check(len(topics)==9,"Nine courses")
original=next((COURSE/"6p").glob("Вопросы*.docx"))
with zipfile.ZipFile(original) as z:tree=ET.fromstring(z.read("word/document.xml"))
paragraphs=["".join(p.itertext()).strip() for p in tree.findall(".//{http://schemas.openxmlformats.org/wordprocessingml/2006/main}p")]
source={}
for p in paragraphs:
    m=re.match(r"(\d+)\.\s*(.*)",p)
    if m:source[int(m[1])]=m[2]
check(len(source)==16,"16 original 6p questions extracted")
for n,raw in source.items():
    q=byid[aliases[f"6p-{n}"]]
    check(norm(q["question_original"])==norm(raw),f"Exact 6p source {n}")
    check(norm(q["question_ru"])==norm(raw),f"Accented 6p text preserves wording {n}")
old=read("content/authoring/question_bank_5p.json")
for q in old:
    check(q["question_ru"]==byid[q["id"]]["question_ru"],f"5p full text retained {q['id']}")
for q in cards:
    check(bool(q["translation"]) and bool(q["answer"]["zh"]) and bool(q["answer"]["ru"]),f"Bilingual card {q['id']}")
    check(q["topic"]==byid[q["id"]]["topic"],f"Shared catalogue {q['id']}")
flat=[]
for topic in topics:
    steps=[b for g in topic["groups"] for b in g["beats"]]
    ids=[b["id"] for b in steps]
    check(len(ids)==len(set(ids)),f"Unique stable beats {topic['id']}")
    check(topic["foundation_end"] in ids,f"Foundation endpoint {topic['id']}")
    for qid in topic["questions"]:
        flat.append(qid);check(topic["question_targets"][qid] in ids,f"Question target {qid}")
    for b in steps:check(bool(b["words"]["zh"]) and bool(b["words"]["ru"]),f"Bilingual beat {b['id']}")
check(set(flat)==set(byid) and len(flat)==62,"All cards assigned once")
for a,b in [(22,7),(23,8),(24,9),(25,11)]:check(aliases[f"5p-{a}"]==aliases[f"6p-{b}"],f"Merged mastery identity {a}/{b}")
excluded={"еще","какой","быть","например","сначала","меньше","можно","больше","мочь","нужно"}
for e in read("content/glossary.json"):
    if norm(e["ru"]) in excluded:check(e.get("study")==False,f"Excluded {e['ru']}")
check(D(1200)*D(".35")==D(420),"Hull mass 420 t")
check(D(120)/D(".024")==D(5000),"Power 5000 kW")
check(D(240)/D(12)*D(1500)*D(".0002")==D(6),"Energy 6 t")
check(D(12)*D(5)*D(150)==D(9000),"Water 9000 L")
report=dict(checks=len(checks),failures=[c for c in checks if not c["passed"]],results=checks,
            source_sha256=hashlib.sha256(original.read_bytes()).hexdigest(),
            answers=[dict(id=q["id"],sources=q["sources"],ru=q["answer"]["ru"],words=len(q["answer"]["ru"].split())) for q in cards])
(ROOT/"qa/topics-content.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
print(f"{len(checks)} content checks; {len(report['failures'])} failures")
for c in report["failures"]:print(c["name"])
raise SystemExit(bool(report["failures"]))
