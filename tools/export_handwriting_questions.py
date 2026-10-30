"""Question-only A4 booklet. No answer fields enter the authoring model.

Russian second-word alphabet, paired horizontal rules and 65-degree guides.
Uses ReportLab + HarfBuzz for proper combining-accent positioning.
"""
from pathlib import Path
import sys,json,re,math,html,hashlib
ROOT=Path(__file__).resolve().parents[2]
WORK_ROOT=ROOT/'tmp/pdfs/handwriting'
WORK=WORK_ROOT/'deduplicated'
sys.path.insert(0,str(WORK_ROOT/'deps'))
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph

OUT=ROOT/'output/pdf/新题66道_第二词字母排序_紧凑手写版.pdf'
ALPHABET='АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'
PAGE_W,PAGE_H=A4
LEFT=18*mm;RIGHT=PAGE_W-18*mm;WIDTH=RIGHT-LEFT
BODY_TOP=PAGE_H-27*mm;BODY_BOTTOM=18*mm
BLOCK_GAP=3.5*mm
META_HEIGHT=5*mm;TEXT_GRID_GAP=2.5*mm
# Compact adaptation of paired ruling: 3-mm writing body, 3-mm gap.
# Preserve the 65-degree slant and visibly stronger baseline.
GRID_PITCH=6*mm;GRID_BODY=3*mm;GRID_SLANT=18*mm
FONTS={
 'Question':'C:/Windows/Fonts/times.ttf',
 'QuestionBold':'C:/Windows/Fonts/timesbd.ttf',
 'Meta':'C:/Windows/Fonts/arial.ttf',
}
def plain(s):return s.replace('\u0301','').replace('\u0300','').lower()
def alphabet_key(s):
    return ''.join(chr(0x400+ALPHABET.index(c.upper())) if c.upper() in ALPHABET else c for c in plain(s))
def load_questions():
    source=ROOT/'船舶原理学习/modules/review/content/exam12/reading.json'
    data=json.loads(source.read_text(encoding='utf8'));result=[]
    for entry in data:
        if entry.get('kind')=='figure' or entry['id'].startswith('THU'):continue
        text=entry['question_ru']
        tokens=list(re.finditer('[А-Яа-яЁё][А-Яа-яЁё\u0301\u0300]*',text))
        assert len(tokens)>=2,entry['id']
        second=tokens[1]
        letter=plain(second[0])[0].upper()
        tail=text[second.start():]
        qid=entry['id']
        if qid.startswith('P13_Q'):label='13a-'+str(int(qid[-2:]))
        elif qid.startswith('P12_T'):label='12p-'+str(int(qid[-2:]))
        elif qid.startswith('P12_C'):label='12p / Задача '+str(int(qid[-2:]))
        else:label='12p / Чертёж'
        if entry.get('legacy_ids'):label=' / '.join(entry['sources'])
        result.append({'id':qid,'question':text,'letter':letter,'second_word':second[0],
                       'tail':tail,'source':label,'writing_pairs':8 if qid in ['P12_C01','P12_C02','P12_C03','P12_D01'] else 4,
                       'sort_key':alphabet_key(tail)})
    assert len(result)==66 and len({q['id'] for q in result})==66
    return sorted(result,key=lambda q:(ALPHABET.index(q['letter']),q['sort_key'],q['id']))
def markup(text):
    # Preserve the question; only typeset literal variable subscripts.
    text=text.replace('D₁','D_1')
    pattern=r'(?<![A-Za-zА-Яа-яЁё])([DPpРрμxzWh])_?(сэу|сэз|пор|зап|гр|с|c|g|к|[0-9]+)(?![A-Za-zА-Яа-яЁё])'
    parts=[];end=0
    for match in re.finditer(pattern,text):
        parts.append(html.escape(text[end:match.start()]))
        parts.append(html.escape(match[1])+'<sub size="8.5">'+html.escape(match[2])+'</sub>')
        end=match.end()
    parts.append(html.escape(text[end:]))
    return ''.join(parts).replace('\n','<br/>')
def plan_pages(questions,style):
    pages=[];page=[];used=0
    for q in questions:
        paragraph=Paragraph(markup(q['question']),style)
        _,height=paragraph.wrap(WIDTH,1000)
        q=dict(q,question_height=height,block_height=META_HEIGHT+height+TEXT_GRID_GAP+(q['writing_pairs']-1)*GRID_PITCH+GRID_BODY)
        extra=q['block_height']+(BLOCK_GAP if page else 0)
        if page and used+extra>BODY_TOP-BODY_BOTTOM:
            pages.append(page);page=[];used=0;extra=q['block_height']
        assert extra<=BODY_TOP-BODY_BOTTOM,q['id']
        page.append(q);used+=extra
    if page:pages.append(page)
    return pages
def guides(pdf,x,top,width,rows):
    grid_bottom=top-(rows-1)*GRID_PITCH-GRID_BODY
    pdf.saveState()
    clip=pdf.beginPath();clip.rect(x,grid_bottom-.3*mm,width,top-grid_bottom+.6*mm);pdf.clipPath(clip,stroke=0,fill=0)
    dx=(top-grid_bottom)/math.tan(math.radians(65))
    pdf.setStrokeGray(.80);pdf.setLineWidth(.30)
    start=-dx-GRID_SLANT
    while start<width+GRID_SLANT:
        pdf.line(x+start,grid_bottom,x+start+dx,top);start+=GRID_SLANT
    for row in range(rows):
        y=top-row*GRID_PITCH
        pdf.setStrokeGray(.68);pdf.setLineWidth(.30);pdf.line(x,y,x+width,y)
        pdf.setStrokeGray(.52);pdf.setLineWidth(.65);pdf.line(x,y-GRID_BODY,x+width,y-GRID_BODY)
    pdf.restoreState()
    return rows,grid_bottom
def make_pdf():
    WORK.mkdir(parents=True,exist_ok=True);OUT.parent.mkdir(parents=True,exist_ok=True)
    for name,file in FONTS.items():pdfmetrics.registerFont(TTFont(name,file,shapable=True))
    questions=load_questions()
    style=ParagraphStyle('question',fontName='Question',fontSize=12.5,leading=17,
                         textColor='#111111',spaceBefore=0,spaceAfter=0,shaping=True,
                         allowWidows=0,allowOrphans=0,splitLongWords=False)
    pages=plan_pages(questions,style)
    assert len(pages)<=14, f'Compact booklet exceeds 14 pages: {len(pages)}'
    pdf=canvas.Canvas(str(OUT),pagesize=A4,pageCompression=1)
    pdf.setTitle('Вопросы к экзамену - 12p и 13a')
    pdf.setSubject('66 вопросов. Алфавит по второму русскому слову. Место для рукописных ответов.')
    pdf.setAuthor('')
    layout=[]
    seen_letters=set()
    for number,page in enumerate(pages,1):
        group=page[0]['letter'] if page[0]['letter']==page[-1]['letter'] else page[0]['letter']+' - '+page[-1]['letter']
        pdf.setFillGray(.12);pdf.setFont('QuestionBold',14);pdf.drawString(LEFT,PAGE_H-16*mm,group,shaping=True)
        pdf.setFillGray(.42);pdf.setFont('Meta',8.5);pdf.drawString(LEFT+23*mm,PAGE_H-15*mm,'ВОПРОСЫ  /  12p + 13a',shaping=True)
        pdf.setStrokeGray(.72);pdf.setLineWidth(.35);pdf.line(LEFT,PAGE_H-20*mm,RIGHT,PAGE_H-20*mm)
        top=BODY_TOP
        for q in page:
            if q['letter'] not in seen_letters:
                pdf.bookmarkPage('letter-'+q['letter']);pdf.addOutlineEntry(q['letter'],'letter-'+q['letter'],level=0,closed=False);seen_letters.add(q['letter'])
            pdf.setFillGray(.20);pdf.setFont('QuestionBold',11);pdf.drawString(LEFT,top-3*mm,q['letter'],shaping=True)
            pdf.setFillGray(.36);pdf.setFont('Meta',8.5);pdf.drawString(LEFT+7*mm,top-3*mm,q['source'],shaping=True)
            paragraph=Paragraph(markup(q['question']),style)
            _,question_height=paragraph.wrap(WIDTH,1000)
            question_top=top-META_HEIGHT;question_bottom=question_top-question_height
            paragraph.drawOn(pdf,LEFT,question_bottom)
            grid_top=question_bottom-TEXT_GRID_GAP
            line_count,grid_bottom=guides(pdf,LEFT,grid_top,WIDTH,q['writing_pairs'])
            layout.append({k:v for k,v in q.items() if k not in ['sort_key','question_height','block_height']}|{
                'page':number,'question_bbox':[LEFT,PAGE_H-question_top,RIGHT,PAGE_H-question_bottom],
                'writing_bbox':[LEFT,PAGE_H-grid_top,RIGHT,PAGE_H-grid_bottom],
                'writing_pairs':line_count,'writing_height_mm':(grid_top-grid_bottom)/mm,
                'question_height_mm':question_height/mm})
            top=grid_bottom-BLOCK_GAP
        pdf.setFillGray(.42);pdf.setFont('Meta',8)
        pdf.drawRightString(RIGHT,9*mm,f'{number} / {len(pages)}')
        pdf.showPage()
    pdf.save()
    manifest={'output':str(OUT),'page_count':len(pages),'question_count':len(questions),
              'source_sha256':hashlib.sha256((ROOT/'船舶原理学习/modules/review/content/exam12/reading.json').read_bytes()).hexdigest(),
              'sorting':'First letter of the second Russian word for EVERY question; stress ignored; Russian alphabet including Ё.',
              'grid':{'pair_height_mm':3,'inter_row_gap_mm':3,'row_pitch_mm':6,'slant_degrees':65,'slant_pitch_mm':18,'top_line_pt':.30,'baseline_pt':.65},
              'ruling_reference':'Compact adaptation of paired-slant ruling; not original exercise-book dimensions.',
              'questions':layout}
    (WORK/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps({'pdf':str(OUT),'questions':len(questions),'pages':len(pages),
                      'minimum_writing_pairs':min(q['writing_pairs'] for q in layout),
                      'minimum_writing_height_mm':round(min(q['writing_height_mm'] for q in layout),1)},ensure_ascii=False))
if __name__=='__main__':make_pdf()
