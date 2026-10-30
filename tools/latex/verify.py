"""Independent numeric checks of migrated TeX, including division precedence."""
import ast,json,operator,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
source=json.loads((ROOT/'content/latex_source.json').read_text(encoding='utf-8'))
def numeric(tex):
    tex=re.sub(r'\\mathrm\{[^}]*\}', '',tex).replace(r'\,','').replace(r'\quad','')
    def group(pos):
        assert tex[pos]=='{'
        depth=1;end=pos+1
        while depth:
            if tex[end]=='{':depth+=1
            if tex[end]=='}':depth-=1
            end+=1
        return tex[pos+1:end-1],end
    while r'\frac' in tex:
        pos=tex.rfind(r'\frac');a,end=group(pos+5);b,end=group(end)
        tex=tex[:pos]+f'(({a})/({b}))'+tex[end:]
    tex=tex.replace(r'\left','').replace(r'\right','').replace(r'\cdot','*').replace(r'\times','*').replace(r'\%','')
    tex=re.sub(r'\^\{([^{}]+)\}',r'**(\1)',tex)
    node=ast.parse(tex.strip(),mode='eval').body
    def calc(n):
        if isinstance(n,ast.Constant) and isinstance(n.value,(int,float)):return n.value
        if isinstance(n,ast.BinOp):return {ast.Add:operator.add,ast.Sub:operator.sub,ast.Mult:operator.mul,ast.Div:operator.truediv,ast.Pow:operator.pow}[type(n.op)](calc(n.left),calc(n.right))
        if isinstance(n,ast.UnaryOp):return (-1 if isinstance(n.op,ast.USub) else 1)*calc(n.operand)
        raise ValueError(ast.dump(n))
    return calc(node)
cases=[('reserve:volume',4,1,5150),('reserve:volume',5,0,42.91666666666667),('norman-apply:limits',0,0,60.88437839797028)]
results=[]
for id,row,side,expected in cases:
    tex=source[id]['zh'][row]['tex'].split('=')[side]
    value=numeric(tex);assert abs(value-expected)<1e-8,(id,value,expected)
    results.append({'case':id,'computed_from_tex':value,'expected':expected})
assert r'\frac{W}{P}' in source['mass-volume:units']['zh'][2]['tex']
assert r'\frac{R}{v}' in source['t2-coefficients:fuel']['zh'][0]['tex']
assert r'W_{\Sigma}' in source['dim-volume:total']['zh'][0]['tex']
assert r',\;\frac{W' in source['cargo:limits']['zh'][2]['tex']
bundle=json.loads((ROOT/'content/latex_assets.json').read_text(encoding='utf-8'))
for id,langs in source.items():
    for lang,rows in langs.items():
        assert len(rows)==len(bundle['lessons'][id][lang])
        for row,rendered in zip(rows,bundle['lessons'][id][lang]):
            assert row['tex']==rendered['tex']
            for piece in rendered['pieces']:
                asset=bundle['assets'][piece]
                assert '<text' not in asset['svg'] and 'merror' not in asset['svg']
                for slot in asset['slots']:assert '@@'+slot['name']+'@@' in asset['svg']
(ROOT/'qa/latex-verification.json').write_text(json.dumps({'numeric_cases':results,'source_asset_match':True,'annotation_checks':4,'all_svgs_paths_only':True},ensure_ascii=False,indent=2),encoding='utf-8')
print('LaTeX numerical precedence, units, symbols and all SVG assets verified')
