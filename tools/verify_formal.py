"""Independent acceptance: approved expected values are read only here, never by the solver."""
import json,sys,math,hashlib
from pathlib import Path
from course_calculations import ROOT,SOURCE,calculate,bisect,rnd
def main():
    checks=[]
    def check(ok,name):checks.append(dict(name=name,passed=bool(ok)))
    def compare(actual,expected,path):
        if isinstance(expected,bool):check(actual==expected,path)
        elif isinstance(expected,(int,float)):check(isinstance(actual,(int,float)) and abs(actual-expected)<=1e-6,path)
        elif isinstance(expected,list):
            check(len(actual)==len(expected),path+' length')
            for i,(a,b) in enumerate(zip(actual,expected)):compare(a,b,path+f'/{i}')
        elif isinstance(expected,dict):
            for key,value in expected.items():
                if key in ['name_ru','name_zh','source']:continue
                if key in actual:compare(actual[key],value,path+'/'+key)
                else:check(False,path+'/'+key+' missing')
        else:check(actual==expected,path)
    inp=json.loads((SOURCE/'inputs.json').read_text('utf8'));expected=json.loads((SOURCE/'expected_results.json').read_text('utf8'))
    got=calculate(inp['cases'])
    for case in ['basics_v5','load_v5','t2_first']:
        for step,outputs in expected['cases'][case]['steps'].items():
            for name,meta in outputs.items():
                if name=='solver_trace':
                    trace=[dict(iteration=r['iteration'],left=r['left'],right=r['right'],midpoint=r['mid'],residual=r['residual']) for r in got['solvers'][step]['iterations']]
                    compare(trace,meta['value'],step+'/'+name)
                elif isinstance(meta,dict) and 'value' in meta:compare(got['steps'][step][name],meta['value'],step+'/'+name)
    check(rnd(84.5,0)==85,'Decimal half-up')
    check(bisect(lambda x:x,0,1)[0]==0,'Endpoint zero')
    for id,solver in got['solvers'].items():
        rows=solver['iterations'];check(len(rows)<=200,id+' iteration cap')
        for i,r in enumerate(rows):
            check(r['left']<=r['mid']<=r['right'],id+f' bracket {i}')
            if i:check(r['right']-r['left']<rows[i-1]['right']-rows[i-1]['left'],id+f' shrink {i}')
        check(abs(rows[-1]['residual'])<=1e-8 or rows[-1]['right']-rows[-1]['left']<=1e-10,id+' stopping condition')
    # Perturbing input proves outputs are calculated, rather than copied from the oracle.
    changed=json.loads(json.dumps(inp['cases']));changed['basics_v5']['midship']['area_m2']=30
    check(calculate(changed)['steps']['B01']['beta']==.4,'Input dependence B01')
    changed['load_v5']['fuel_tanks'][0]['mass_t']+=10
    changed_result=calculate(changed)
    check(abs(changed_result['steps']['L05']['P_t']-20626)<1e-6,'Input dependence load chain')
    courses=json.loads((ROOT/'content/courses.json').read_text('utf8'));latex=json.loads((ROOT/'content/latex_assets.json').read_text('utf8'))
    beats=[b for c in courses if c['id']!='bulkheads' for g in c['groups'] for b in g['beats']]
    check(len({b['id'] for b in beats})==len(beats),'Unique stable beat IDs')
    coverage={b.get('calculation_step') for b in beats}
    for step in got['steps']:check(step in coverage,'Teaching coverage '+step)
    check([c['id'] for c in courses]==['basics','foundation','load','mass','dimensions','approximation2','approximation3','supplement','bulkheads'],'Nine chapter order, no OST')
    graph=json.loads((ROOT/'content/knowledge_map.json').read_text('utf8'))
    check(len(graph['nodes'])==9 and not graph['groups'],'Home exposes chapters only')
    for edge in graph['edges']:check(edge['route'][-1][1]>edge['route'][0][1],'Downward tree '+edge['from']+'/'+edge['to'])
    for b in beats:
        check(bool(b['words']['zh']) and bool(b['words']['ru']),b['id']+' bilingual')
        check(len(latex['lessons'][b['id']]['zh'])==len(latex['lessons'][b['id']]['ru']),b['id']+' same formulas')
        for lang in ['zh','ru']:
            for row in latex['lessons'][b['id']][lang]:
                for id in row['pieces']:check(latex['assets'][id]['width']<=325,b['id']+'/'+lang+' unshrunk width '+id)
    out=dict(checks=checks,total=len(checks),failed=sum(not c['passed'] for c in checks),steps=len(got['steps']),beats=len(beats),source_hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.glob('*.json')})
    (ROOT/'qa/formal-data-checks.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),'utf8')
    print(out['total'],'checks;',out['failed'],'failures')
    for c in checks:
        if not c['passed']:print(c['name'])
    return bool(out['failed'])
if __name__=='__main__':sys.exit(main())
