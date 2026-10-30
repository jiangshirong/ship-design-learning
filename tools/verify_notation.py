"""Check source identity, full-course coverage, bindings and hover geometry."""
import json,re,hashlib
from collections import Counter
from xml.etree import ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads((ROOT/p).read_text('utf8'))
def main():
    checks=[]
    def check(ok,name):checks.append(dict(name=name,passed=bool(ok)))
    courses=read('content/courses.json');tex=read('content/latex_source.json');assets=read('content/latex_assets.json')
    audit=read('content/notation_audit.json');records={r['id']:r for r in audit['records']}
    typography=assets['typography']
    check(abs(typography['glyphs']['х']['height']-0.431)<0.00001,'Cyrillic x-height matches MathJax Latin x-height')
    for source,meta in read('qa/notation-sources/sources.json').items():
        if source=='2p/2p-Женя.docx':
            check((ROOT.parent/source).exists(),'Current student adoption record exists: '+source) # Editable homework, not a frozen teacher fixture.
        else:check(hashlib.sha256((ROOT.parent/source).read_bytes()).hexdigest()==meta['sha256'],'Original file unchanged: '+source)
    for id,langs in tex.items():
        check(id in records,'Audited display '+id)
        before='\n'.join(records[id]['before']);after='\n'.join(r['tex'] for r in langs['zh'])
        if id=='load-centre:free':
            check('@free_correction@' in str(tex['free_surface:height']), 'Free-surface binding moved to its calculation beat')
        elif not records[id].get('teaching_addition'):
            check(sorted(re.findall(r'@\w+@',before))==sorted(re.findall(r'@\w+@',after)),'Preserved numeric bindings '+id)
        if id.startswith('T'):
            check(not re.search(r'[Pp]_(?:[hefrs](?![a-z])|\{(?:gr|crew|food|water|h0)\})|W_[cefwb]|C_A|z_G|\\delta_\{pp\}',after),'No replaced T2 alias remains '+id)
        for lang,rows in langs.items():
            for row in rows:
                check(not re.search('[\u0400-\u04ff]',row['tex']) or re.search('[\u0400-\u04ff]',row['linear']),id+lang+' Cyrillic copy retained')
    for asset in assets['assets'].values():
        cyr=bool(re.search('[\u0400-\u04ff]',asset['tex']))
        check(not cyr or bool(asset['hints']),'Cyrillic glyphs have hover: '+asset['tex'])
        if cyr:
            xml=ET.fromstring(asset['svg'])
            ns={'s':'http://www.w3.org/2000/svg'}
            paths=xml.findall('.//s:path',ns)
            emitted=Counter(chr(int(p.attrib['data-c'],16)) for p in paths if 'data-c' in p.attrib and 0x400<=int(p.attrib['data-c'],16)<=0x4ff)
            check(emitted==Counter(re.findall('[А-Яа-яЁё]',asset['tex'])),'Every Cyrillic letter is a native sized SVG glyph: '+asset['tex'])
            check(not xml.findall('.//s:text',ns),'No fallback text in Cyrillic formula: '+asset['tex'])
            for group in xml.findall('.//s:g',ns):
                if not group.attrib.get('id','').startswith('term'):continue
                x=0.0
                for glyph in group.findall('s:path',ns):
                    letter=chr(int(glyph.attrib['data-c'],16))
                    pos=re.search(r'translate\(([-\d.]+)',glyph.attrib.get('transform',''))
                    check(abs((float(pos[1]) if pos else 0)-x)<0.15,'Real character advance in '+asset['tex'])
                    x+=typography['glyphs'][letter]['advance']*1000 if letter in typography['glyphs'] else 278 # MathJax period
        for hint in asset['hints']:
            x,y,w,h=hint['rect']
            check(w>0 and h>0 and x>=0 and y>=0 and x+w<=asset['width']+1 and y+h<=asset['height']+1,'Ink bounds inside SVG: '+asset['tex'])
            if re.search('[А-Яа-яЁё]',hint['text']):check('\u0301' in hint['text'] or hint['text'].split('\n')[0].endswith('груз'),'Accented expansion: '+hint['text'])
            check(bool(re.search('[\u4e00-\u9fff]',hint['text'])),'Chinese translation: '+hint['text'])
    beats=[b for c in courses if c['id']!='bulkheads' for g in c['groups'] for b in g['beats']]
    for b in beats:
        check(b['lines']==[r['tex'] for r in tex[b['id']]['zh']],'Course and formula agree '+b['id'])
    sample=next(b for b in beats if b['id']=='sample:move')
    check('按 D' in sample['words']['zh'],'Keyboard D is not a displacement variable')
    required={'T01:water':r'P_{\text{пр.вод}}','T02:hull':r'p_{\text{к.об.}}D','T02:engine':r'p_{\text{сэу}}N','T02:fuel':r'p_{\text{сэз}}N','T03:c':'P=','T09:underdeck':r'\delta_{\text{пп}}','T09:zeta':r'Z_{g0}','T11:water':r'W_{\text{пр.вод}}','T12:float':'B_1T_1','T15:check':r'D_{\text{пров}}','L06:x':r'M_{\text{кп}}','B03:sign':r'T_{\text{н}}','norman-derive:eta':r'\eta_{\text{н}}','B02:volume2':r'W_{\mathrm{rest}}','B02:check':r'W_{\mathrm{free}}'}
    for id,expected in required.items():check(expected in '\n'.join(r['tex'] for r in tex[id]['zh']),'Source or declared intermediate contract: '+id)
    fuel='\n'.join(r['tex'] for r in tex['T02:fuel']['zh'])
    check(r't_{\text{ход}}=' in tex['T02:fuel:units']['zh'][0]['tex'],'Running time retains source subscript')
    check(r'\mathrm{t/(kW\cdot h)}' in fuel,'Tonne unit is not the running-time variable')
    out=dict(checks=checks,total=len(checks),failed=sum(not r['passed'] for r in checks),chapters=len(courses),beats=len(beats),formula_records=len(records),changed_records=sum(r['changed'] for r in records.values()))
    (ROOT/'qa/notation-checks.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),'utf8')
    print(out['total'],out['failed'])
    for r in checks:
        if not r['passed']:print(r['name'])
    return bool(out['failed'])
if __name__=='__main__':raise SystemExit(main())
