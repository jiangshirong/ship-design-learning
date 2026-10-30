"""Source-scoped display notation. Calculation keys and numeric values stay unchanged.

The final T2 report takes precedence over the method template's spelling variants.
Load moments follow the original worksheet; its completed solution supplies Δ, zG, xG.
New pedagogical intermediates retain English subscripts. Never transliterate Russian.
"""
import re,json

def sub(base, suffix):
    return base+r'_{\text{'+suffix+'}}'

def replace_symbols(tex, mapping):
    # Single pass: replacements must not match part of a command, identifier, or binding.
    keys=sorted(mapping,key=len,reverse=True)
    # An uppercase neighbour can be a multiplied symbol (p_hD, p_eN).
    pattern=r'(?<![A-Za-z\\])(?:'+ '|'.join(re.escape(k) for k in keys)+r')(?![a-z_])'
    return re.sub(pattern,lambda m:mapping[m[0]],tex)

T2={}
for old,new in [('h','к.об.'),('e','сэу'),('f','сэз'),('r','зв'),('s','сн'),('gr','гр'),('crew','эк'),('food','пров'),('water','пр.вод')]:
    for base in ['P','p']:
        T2[base+'_'+old]=sub(base,new)
        T2[base+'_{'+old+'}']=sub(base,new)
        T2[base+'_{'+old+'0}']=base+r'_{\text{'+new+'}0}'
T2.update({r'C_A':sub('C','А'),r'\delta_{pp}':sub(r'\delta','пп'),r'z_{G0}':r'z_{\text{г}0}',r'z_G':sub('z','г'),r'D_{check}':sub('D','пров'),r'\ell':'l',r'A_{WL}':'S',r'\nabla':'V',r'W_\Sigma':r'W_{\mathrm{sum}}'})
for old,new in [('c','гр'),('e','сэу'),('f','сэз'),('w','пр.вод'),('b','бл')]:T2['W_'+old]=sub('W',new)

LOAD={r'D':r'\Delta',r'M_z':sub('M','оп'),r'M_x':sub('M','кп'),r'M_{z,i}':r'M_{\text{оп},i}',r'M_{x,i}':r'M_{\text{кп},i}',r'M_{z,f}':r'M_{\text{оп},\mathrm{fuel}}',r'M_{x,f}':r'M_{\text{кп},\mathrm{fuel}}',r'z_f':r'z_{\mathrm{fuel}}',r'x_f':r'x_{\mathrm{fuel}}',r'P_f':r'P_{\mathrm{fuel}}'}

def canonical(id, tex):
    if id.startswith('T'):
        tex=replace_symbols(tex,T2)
        # Only the time variable on the left gets the source subscript;
        # the tonne unit inside \mathrm{t/(kW\cdot h)} must stay untouched.
        if id=='T02:fuel':tex=re.sub(r'^t(?==)',lambda _:sub('t','ход'),tex)
        if id.startswith(('T03:','T04:')):tex=replace_symbols(tex,{'c':'P'})
        if id.startswith('T06:'):
            for name in ['к.об.','сэу','сэз','зв']:tex=tex.replace(sub('P',name),'P_{\\text{'+name+'}1}')
        if id.startswith('T07:row'):
            name=['к.об.','сэу','сэз','зв','сн','гр'][int(id.split('row')[1])-1]
            tex=replace_symbols(tex,{f'P_{n}':f'P_{{\\text{{{name}}}{n}}}' for n in [0,1]})
        if id.startswith(('T08:','T09:','T12:','T13:')):
            tex=replace_symbols(tex,{s:''.join(v+'_1' for v in s) for s in ['LBT','LBH','BT','BH','LB']})
            tex=re.sub(r'(?<![A-Za-z\\])([LBTHD])(?![A-Za-z_0-9])',lambda m:m[1]+'_1',tex)
        if id=='T10:mu':tex=replace_symbols(tex,{r'\mu_{adopt}':sub(r'\mu','сэу'),r'\mu':sub(r'\mu','сэу')})
    elif id.startswith('B02:'):
        tex=replace_symbols(tex,{r'P_{\max}':sub('P','гр'),r'W_{\max}':sub('W','гр')})
    elif id.startswith('B03:'):
        tex=replace_symbols(tex,{'T_k':sub('T','к'),'T_n':sub('T','н')})
    elif id.startswith('L'):
        tex=replace_symbols(tex,LOAD)
        tex=re.sub(r'I_\{f,([^}]+)\}',r'M_{\\mathrm{free},\1}',tex)
    elif id.startswith('sample:'):
        tex=replace_symbols(tex,{'D':r'\Delta','D _{1}':r'\Delta_1','D _{2}':r'\Delta_2','M _{z}':sub('M','оп')})
    elif id=='load-centre:free':
        tex=replace_symbols(tex,{'GM_{\mathrm{corr}}':r'h_{\mathrm{corr}}','G M':'h',r'\mathrm{FSM}':r'M_{\mathrm{free}}'})
    elif id.startswith('norman-'):
        tex=replace_symbols(tex,{r'\eta':sub(r'\eta','н'),r'F _{D}':r'\frac{\partial F}{\partial D}',r'P_{\mathrm{э}}':sub('P','сэу'),r'P_{\mathrm{т}}':sub('P','сэз'),r'P_{\mathrm{з}}':sub('P','зв')})
    elif id.startswith('_concept/'):
        tex=replace_symbols(tex,{r'A_{\mathrm{м}}':'A_M','c':'P',r'P_{\mathrm{к}}':sub('P','к.об.'),r'p_{\mathrm{к}}':sub('p','к.об.'),r'P_{\mathrm{э}}':sub('P','сэу'),r'p_{\mathrm{э}}':sub('p','сэу'),r'P_{\mathrm{т}}':sub('P','сэз'),r'p_{\mathrm{т}}':sub('p','сэз'),r'P_{\mathrm{з}}':sub('P','зв')})
    # Added English word subscripts are upright words, not a product of letters.
    tex=re.sub(r'_\{(calc|req|report|av|res)\}',r'_{\\mathrm{\1}}',tex)
    return tex

# The direct variations in Modul_4 are [dF_i]* at fixed D, not total dP_i.
# Explicit rows also keep long Cyrillic formulae readable at 30 px in the narrow panel.
OVERRIDES={
 'norman-derive:differentiate':[r'D=F(D,\theta)+P',r'dD=\frac{\partial F}{\partial D}dD',r'\quad+[dF]^*+dP',r'\left(1-\frac{\partial F}{\partial D}\right)dD',r'=[dF]^*+dP'],
 'norman-derive:eta':[r'\eta_{\text{н}}=\frac{1}{1-\partial F/\partial D}',r'dD=\eta_{\text{н}}([dF]^*+dP)'],
 'norman-apply:derivative':[r'\frac{\partial F}{\partial D}=\frac{P_{\text{к}}}{D}',r'+\frac{2P_{\text{сэу}}}{3D}+\frac{2P_{\text{сэз}}}{3D}',r'+\frac{P_{\text{зв}}}{D}',r'\eta_{\text{н}}=@eta@',r'dP=100\,\mathrm t',r'dD\approx\eta_{\text{н}}\cdot100',r'\approx140.6146\,\mathrm t'],
 'norman-apply:direct':[r'[dF_{\text{к}}]^*=D\,dp_{\text{к}}',r'[dF_{\text{сэу}}]^*=P_{\text{сэу}}\frac{dp_{\text{сэу}}}{p_{\text{сэу}}}',r'+P_{\text{сэу}}\left(3\frac{dv}{v}-\frac{dC}{C}\right)',r'[dF_{\text{сэз}}]^*=P_{\text{сэз}}\frac{dp_{\text{сэз}}}{p_{\text{сэз}}}',r'+P_{\text{сэз}}\frac{dR}{R}',r'+P_{\text{сэз}}\left(2\frac{dv}{v}-\frac{dC}{C}\right)'],
}

def source_for(id):
    if id.startswith(('T','_concept/mass','_concept/root','_concept/volume','_concept/stability')):return ['2p/КП-ПС-1 приближение.docx','2p/2p-Женя.docx（方案采用值）']
    if id.startswith('norman-'):return ['3a/Modul_4.docx']
    if id.startswith(('L','sample:','load-centre:')):return ['1p/5. Нагрузка-2024.docx','1p/Вариант 5 Расчёт нагрузки.docx','1p/Modul_2.docx']
    return ['1p/Задачи.docx','1p/Modul_1.docx']

def apply(courses, latex, linear, root):
    used={b['id']:b for c in courses for g in c['groups'] for b in g['beats']}
    coverage=[]
    for id,langs in latex.items():
        if id not in used and not id.startswith('_'):continue
        before=[x['tex'] for x in langs['zh']]
        rows=OVERRIDES.get(id,[canonical(id,t) for t in before])
        for lang in ['zh','ru']:
            langs[lang]=[dict(tex=re.sub(r'(?<=\d)\.(?=\d)',r'{,}',t) if lang=='ru' else t,linear=linear(t)) for t in rows]
        if id in used:
            used[id]['lines']=rows
            used[id].pop('formula',None) # Obsolete pre-LaTeX widget data must not retain aliases.
            # Short source-specific symbols in narration; no UI audit explanations.
            for lang,s in used[id].get('words',{}).items():
                s=s.replace('осно́вная','основна́я').replace('Осно́вная','Основна́я').replace('осно́вной','основно́й')
                if id=='sample:moment':s=s.replace('分母 D','分母 Δ').replace('Знамена́тель D','Знамена́тель Δ')
                if id.startswith('norman-'):s=s.replace('η','ηн')
                used[id]['words'][lang]=s
            for detail in used[id].get('details',[]):
                for lang,s in detail.items():
                    s=s.replace('осно́вная','основна́я').replace('Осно́вная','Основна́я').replace('осно́вной','основно́й')
                    if id=='sample:moment':s=s.replace('分母 D','分母 Δ').replace('Знамена́тель D','Знамена́тель Δ')
                    if id.startswith('norman-'):s=s.replace('F_D','∂F/∂D').replace('η','ηн')
                    detail[lang]=s
            used[id]['text']=used[id].get('words',{}).get('zh',used[id].get('text',''))
        coverage.append(dict(id=id,sources=source_for(id),before=before,after=rows,changed=before!=rows))
    (root/'content/notation_audit.json').write_text(json.dumps(dict(policy='原文已有符号按各章来源保留；未命名中间量使用英文下标；0/1及i为原有对象或序号。',records=coverage),ensure_ascii=False,indent=2),'utf8')
    terms={}
    for suffix,phrase in [('к.об.','ко́рпус с обору́дованием'),('сэу','судова́я энергети́ческая устано́вка'),('сэз','судовы́е энергети́ческие запа́сы'),('зв','запа́с водоизмеще́ния'),('сн','снабже́ние'),('гр','груз'),('эк','экипа́ж'),('пров','прови́зия'),('пр.вод','пре́сная вода́'),('инв','инвента́рь'),('бл','балла́ст'),('к','ко́рпус')]:
        for base in ['P','p','W',r'\mu','F']:terms[base+'|'+suffix]=suffix+' — '+phrase
    terms.update({
        r'\delta|пп':'пп — подпа́лубный объём',r'\eta|н':'н — Но́рмана',
        'T|к':'к — корма́; оса́дка кормо́й','T|н':'н — нос; оса́дка но́сом',
        'M|оп':'оп — основна́я пло́скость','M|кп':'кп — кормово́й перпендикуля́р',
        'C|А':'А — адмиралте́йский коэффицие́нт','D|пров':'пров — прове́рка',
        't|ход':'ход — ходово́е вре́мя',
        'z|г':'г — центр тя́жести (обозначе́ние в отчёте)',
    })
    chinese={'к.об.':'船体及设备','сэу':'船舶动力装置','сэз':'船舶能源储备','зв':'排水量裕量','сн':'供应品','гр':'货物','эк':'船员','пров':'食品储备','пр.вод':'淡水','инв':'器具','бл':'压载','к':'船体'}
    contextual={r'\delta|пп':'甲板下容积',r'\eta|н':'诺曼（系数）','T|к':'艉；艉吃水','T|н':'艏；艏吃水','M|оп':'基本平面','M|кп':'艉垂线','C|А':'海军系数','D|пров':'复核','t|ход':'航行时间','z|г':'重心（原报告记号）'}
    for key in terms:
        translation=contextual.get(key,chinese.get(key.split('|')[1]))
        assert translation,key
        terms[key]+='\n'+translation
    (root/'content/notation_terms.json').write_text(json.dumps(terms,ensure_ascii=False,indent=2),'utf8')
