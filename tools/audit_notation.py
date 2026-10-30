"""Read original OOXML without losing subscript/superscript identities."""
from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as E
import json,hashlib
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT.parent
W='{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
M='{http://schemas.openxmlformats.org/officeDocument/2006/math}'
A='{http://schemas.openxmlformats.org/drawingml/2006/main}'
def plain(el):
    return ''.join(x.text or '' for x in el.iter() if x.tag in [W+'t',M+'t',A+'t'])
def formula(el):
    if el is None:return ''
    if el.tag in [W+'t',M+'t',A+'t']:return el.text or ''
    if el.tag in [M+'sSub',M+'sSubSup',M+'sSup']:
        base=formula(el.find(M+'e'))
        sub=formula(el.find(M+'sub'));sup=formula(el.find(M+'sup'))
        return base+('_{'+sub+'}' if sub else '')+('^{'+sup+'}' if sup else '')
    if el.tag==M+'f':return '('+formula(el.find(M+'num'))+')/('+formula(el.find(M+'den'))+')'
    if el.tag==M+'rad':return 'root['+formula(el.find(M+'deg'))+']('+formula(el.find(M+'e'))+')'
    if el.tag==W+'r':
        value=plain(el);vertical=el.find('.//'+W+'vertAlign')
        if vertical is not None:
            v=vertical.get(W+'val');return ('_{' if v=='subscript' else '^{')+value+'}'
        return value
    return ''.join(formula(c) for c in el)
def extract():
    sources={}
    names=['1p/Задачи.docx','1p/Вариант 5 Расчёт нагрузки.docx','1p/5. Нагрузка-2024.docx',
           '1p/Modul_1.docx','1p/Modul_2.docx','1p/Modul_3.docx',
           '2p/2p-Женя.docx','2p/КП-ПС-1 приближение.docx','3a/Modul_4.docx']
    dest=ROOT/'qa/notation-sources';dest.mkdir(exist_ok=True)
    for name in names:
        p=BASE/name;z=ZipFile(p);tree=E.fromstring(z.read('word/document.xml'))
        rows=[dict(paragraph=i+1,text=formula(el)) for i,el in enumerate(tree.findall('.//'+W+'p'))]
        sources[name]=dict(sha256=hashlib.sha256(p.read_bytes()).hexdigest(),paragraphs=rows)
        (dest/(p.stem+'.txt')).write_text('\n'.join(f"[{r['paragraph']}] {r['text']}" for r in rows),'utf8')
    for name in ['2a/ПС-КР-1. Введение.pptx','2a/ПС-КР-2. Первое приближение.pptx']:
        p=BASE/name;z=ZipFile(p);slides=[]
        for n in range(1,100):
            path=f'ppt/slides/slide{n}.xml'
            if path not in z.namelist():continue
            tree=E.fromstring(z.read(path));slides.append(dict(slide=n,text='\n'.join(formula(el) for el in tree.findall('.//'+A+'p'))))
        sources[name]=dict(sha256=hashlib.sha256(p.read_bytes()).hexdigest(),slides=slides)
        (dest/(p.stem+'.txt')).write_text('\n'.join(f"[slide {s['slide']}] {s['text']}" for s in slides),'utf8')
    (dest/'sources.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2),'utf8')
    latex=json.loads((ROOT/'content/latex_source.json').read_text('utf8'))
    (dest/'current-formulas.txt').write_text('\n'.join(id+'\n'+'\n'.join(row['tex'] for row in langs['zh']) for id,langs in latex.items()),'utf8')
if __name__=='__main__':extract()
