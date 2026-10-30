"""Migrate the finite course notation to explicit, reviewable LaTeX sources.
This is a build-time converter, not the runtime math renderer.
"""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
GREEK=dict(zip('αβδφχρμζθηΔΣ∇ℓ', ['alpha','beta','delta','varphi','chi','rho','mu','zeta','theta','eta','Delta','sum','nabla','ell']))
SUB=dict(zip('₀₁₂₃₄₅₆₇₈₉ᵢⱼ','0123456789ij'))
SUP=dict(zip('⁰¹²³⁴⁵⁶⁷⁸⁹','0123456789'))
ALIASES={'WΣ':r'W_{\Sigma}','GMcorrected':r'GM_{\mathrm{corr}}','zGnew':r'z_{G,\mathrm{new}}','Vreserve':r'V_{\mathrm{reserve}}','Wrest':r'W_{\mathrm{rest}}','Wreq':r'W_{\mathrm{req}}','Dexact':r'D_{\mathrm{exact}}','Xnew':r'X_{\mathrm{new}}','zG':r'z_G','xG':r'x_G','kD':r'k_D','cB':r'c_B','Fr':r'\mathrm{Fr}','FSM':r'\mathrm{FSM}'}
REL={'=':'=', '≈':r'\approx','≤':r'\le','≥':r'\ge','→':r'\longrightarrow','>':'>','<':'<','∝':r'\propto'}
def top_split(s,chars):
    depth=0;start=0;parts=[]
    for i,c in enumerate(s):
        if c in '([{':depth+=1
        elif c in ')]}':depth-=1
        elif depth==0 and c in chars and i>start:
            if c in '+-' and (s[i-1] in 'eE' and i>1 and s[i-2].isdigit()):continue
            parts.append(s[start:i]);parts.append(c);start=i+1
    parts.append(s[start:]);return parts
def convert(s):
    s=s.strip()
    if not s:return ''
    parts=top_split(s,''.join(REL))
    if len(parts)>1:return ' '.join(REL.get(p,convert(p) if p not in REL else '') for p in parts)
    parts=top_split(s,',')
    if len(parts)>1:return r',\;'.join(convert(p) for p in parts[::2])
    parts=top_split(s,'+−-')
    if len(parts)>1:return ' '.join(('+' if p=='+' else '-') if p in ['+','−','-'] else convert(p) for p in parts)
    parts=top_split(s,'/×·')
    if len(parts)>1:
        result=convert(parts[0])
        for i in range(2,len(parts),2):
            if parts[i-1]=='/':result=r'\frac{'+ungroup(result)+'}{'+ungroup(convert(parts[i]))+'}'
            else:result+=r' \cdot '+convert(parts[i])
        return result
    return atoms(s)
def ungroup(s):
    if s.startswith(r'\left(') and s.endswith(r'\right)'):return s[6:-7]
    return s
def atoms(s):
    out=[];i=0
    while i<len(s):
        c=s[i]
        if c.isspace():i+=1;continue
        if c=='@':
            j=s.index('@',i+1);out.append(s[i:j+1]);i=j+1;continue
        if c in '([':
            level=1;j=i+1
            while j<len(s) and level:
                if s[j] in '([':level+=1
                elif s[j] in ')]':level-=1
                j+=1
            out.append(r'\left'+c+convert(s[i+1:j-1])+r'\right'+s[j-1]);i=j;continue
        if c=='√':
            if i+1<len(s) and s[i+1]=='(':
                level=1;j=i+2
                while level:
                    if s[j]=='(':level+=1
                    elif s[j]==')':level-=1
                    j+=1
                inner=convert(s[i+2:j-1]);i=j
            else:inner=convert(s[i+1]);i+=2
            out.append(r'\sqrt{'+inner+'}');continue
        if c in '^_':
            j=i+1
            if s[j] in '({':
                close=')' if s[j]=='(' else '}';end=s.index(close,j+1);inner=convert(s[j+1:end]);i=end+1
            else:inner=s[j];i=j+1
            out.append(c+'{'+inner+'}');continue
        if c in SUB or c in SUP:
            mapping=SUB if c in SUB else SUP;kind='_' if c in SUB else '^';chunk=''
            while i<len(s) and s[i] in mapping:chunk+=mapping[s[i]];i+=1
            # Indices on an already indexed symbol belong to that same subscript.
            if kind=='_' and out and '_' in out[-1]:
                last=out.pop();base,sub=last.split('_',1);sub=sub[1:-1] if sub.startswith('{') else sub;out.append(base+'_{'+sub+','+chunk+'}')
            else:out.append(kind+'{'+chunk+'}')
            continue
        number=re.match(r'\d+(?:\.\d+)?(?:[eE][+-]?\d+)?',s[i:])
        if number:
            n=number[0];i+=len(n)
            if 'e' in n.lower():a,b=n.lower().split('e');n=a+r'\times10^{'+str(int(b))+'}'
            out.append(n);continue
        match=next((a for a in ALIASES if s.startswith(a,i)),None)
        if match:out.append(ALIASES[match]);i+=len(match);continue
        if s.startswith('min',i):out.append(r'\min');i+=3;continue
        if c in GREEK:token='\\'+GREEK[c]+' '
        elif c in '×·':token=r'\cdot '
        elif c in '−-':token='-'
        elif c=='%':token=r'\%'
        elif c=='′':token="'"
        elif c=='*':token='^{*}'
        elif c==',':token=r',\;'
        elif c.isalpha():token=c
        else:token=c
        i+=1
        suffix=''
        while i<len(s) and '\u0400'<=s[i]<='\u04ff':suffix+=s[i];i+=1
        if suffix:token=token.strip()+r'_{\mathrm{'+suffix+'}}'
        out.append(token)
    return ' '.join(out)
def normalize(s):
    for a,b in [('Σ(Pz)','Σ(Pᵢ·zᵢ)'),('Σ(Px)','Σ(Pᵢ·xᵢ)'),('ΣPz','Σ(Pᵢ·zᵢ)'),('ΣPx','Σ(Pᵢ·xᵢ)'),('Pz','P · z'),('Px','P · x')]:s=s.replace(a,b)
    return s
UNITS={'t/m³':r'\frac{\mathrm{t}}{\mathrm{m}^{3}}','m³/t':r'\frac{\mathrm{m}^{3}}{\mathrm{t}}','t/kW':r'\frac{\mathrm{t}}{\mathrm{kW}}','t/(kW·h)':r'\frac{\mathrm{t}}{\mathrm{kW}\cdot\mathrm{h}}','m³/kW':r'\frac{\mathrm{m}^{3}}{\mathrm{kW}}','m/s':r'\frac{\mathrm{m}}{\mathrm{s}}','t/person':r'\frac{\mathrm{t}}{\mathrm{person}}','n mile':r'\mathrm{nmi}','t·m':r'\mathrm{t}\cdot\mathrm{m}','m³':r'\mathrm{m}^{3}','m²':r'\mathrm{m}^{2}'}
for unit in ['kn','kW','cm','m','t','d','h']:UNITS[unit]=r'\mathrm{'+unit+'}'
def latex(s):
    s=s.replace('zG,new','zGnew')
    protected={}
    for i,(unit,tex) in enumerate(UNITS.items()):
        key='@UNIT'+str(i)+'@'
        s=re.sub(r'(?<=[ \[])'+re.escape(unit)+r'(?=$|[ \]])',lambda m:key,s)
        protected[key]=r'\,'+tex
    annotation=re.match(r'^(.*?)(\s+\[[^\]]+\])$',s)
    value=convert(annotation[1])+r"\quad"+atoms(annotation[2].strip()) if annotation else convert(s)
    for key,tex in protected.items():value=value.replace(key,tex)
    return value

def prepare():
    courses=json.loads((ROOT/'content/courses.json').read_text(encoding='utf-8'))
    result={}
    for course in courses:
        for group in course['groups']:
            for beat in group['beats']:
                entry={}
                for lang in ['zh','ru']:
                    rows=[]
                    for line in beat.get('lines',[]):
                        line=line[lang] if isinstance(line,dict) else line
                        for part in line.split(';'):
                            rows.append({'linear':normalize(part.strip()),'tex':latex(normalize(part))})
                    entry[lang]=rows
                result[beat['id']]=entry
    auxiliary={'area':'Aм','fullness':'β = Aм / (B · T)','cargo':'6186 m³ / 1.21 m³/t = 5112.40 t',
               'root':'f(X) = aX³ − bX² − c','mass0':'Pк = pкD','mass1':'Pэ = pэN',
               'mass2':'Pт = pтNR/v','mass3':'Pз = 0.01D','mass4':'Pсн = 84.5 t','mass5':'Pгр = 30700 t',
               'mass_total':'D = Pк + Pэ + Pт + Pз + Pсн + Pгр','stability':'GM = KB + BM − KG','volume':'Wreq = 1.06 · ΣW'}
    for key,value in auxiliary.items():
        row={'linear':normalize(value),'tex':latex(normalize(value))}
        result['_concept/'+key]={'zh':[row],'ru':[row]}
    (ROOT/'content/latex_source.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print('LaTeX source:',len(result),'steps')
if __name__=='__main__':prepare()
