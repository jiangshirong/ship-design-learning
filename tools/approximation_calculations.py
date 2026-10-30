"""T2 adoption chain. Teacher method and student's adopted readings are separate."""
from pathlib import Path
from decimal import Decimal, ROUND_HALF_UP
import math,json
ROOT=Path(__file__).resolve().parents[1]
def rounded(x,n=2):
    return float(Decimal(str(x)).quantize(Decimal(1).scaleb(-n),rounding=ROUND_HALF_UP))
def build():
    first=json.loads((ROOT/'content/confirmed/calculated.json').read_text('utf8'))['steps']
    d=first['T05']['D1_t'];s=first['T14']
    first_table=[r['project_mass_t'] for r in first['T07']['rows']]
    L,B,T,H=[s[k+'_m'] for k in ['L1','B1','T1','H1']]
    delta=.785;rho=1.025;k=1.005
    # Method constants and diagram readings are adopted inputs, not solver outputs.
    inputs=dict(L=L,B=B,T=T,H=H,D=d,delta=delta,alpha=.850,rho=rho,k=k,
        L0=147.2,B0=24.5,T0=9.8,H0=13.4,D0=27590,steel0=5430,equipment0=1290,
        speed_kn=15.9,knot_m_s=.514,viscosity=1.56e-6,eta=.70,range_nm=5500,
        friction=.00157,roughness=.00020,appendages=.00010,residual_base=.00155,
        psi_standard=5.54,alpha_psi=1.26,alpha_standard=1.20,beam_factor=1.00,
        propellers=1,stern_factor=1.00,power_margin=1.15,catalog_step=200)
    delta0=rounded(27590/(k*rho*147.2*24.5*9.8),2)
    gst_raw=5430/(delta0**(1/3)*147.2**1.5*24.5*13.4**.5);gst=rounded(gst_raw,3)
    gob_raw=1290/(147.2*24.5*13.4)**(2/3);gob=rounded(gob_raw,2)
    steel2=rounded(gst*delta**(1/3)*L**1.5*B*H**.5)
    equipment2=rounded(gob*(L*B*H)**(2/3));hull2=rounded(steel2+equipment2)
    A1=rounded(hull2+sum(first_table[1:]));gap2=rounded(A1-d)
    reserve2=rounded(first_table[3]-gap2)
    table2=[rounded(hull2,0),first_table[1],first_table[2],rounded(reserve2,0),first_table[4],first_table[5]]
    second=dict(delta0=delta0,gst_raw=gst_raw,gst=gst,gob_raw=gob_raw,gob=gob,
        steel=steel2,equipment=equipment2,hull=hull2,A1=A1,gap=gap2,limit=first_table[3]/2,
        reserve_raw=reserve2,table=table2,D=d,L=L,B=B,T=T,H=H,
        float_check=rounded(k*rho*delta*L*B*T))
    velocity=15.9*.514;omega=rounded(L*T*(2+1.37*(delta-.274)*B/T))
    re=velocity*L/1.56e-6;fr=velocity/math.sqrt(9.81*L)
    volume=rounded(d/rho);psi=rounded(L/volume**(1/3));kpsi=rounded(1.26/1.20)
    zr=rounded(.00155*kpsi*1,5);z=zr+.00157+.00020+.00010
    eps=rounded(z*rho/2*omega*velocity**3);required=rounded(eps/.7)
    minimum=rounded(1.15*required);engine=math.ceil(minimum/200)*200
    pe=rounded(720/8580*engine);pf=rounded(690*15/(8580*5000)*engine*5500/15.9)
    A3=rounded(table2[0]+pe+pf+sum(table2[3:]));gap3=rounded(A3-d)
    norman=rounded(1/(1-table2[0]/d));d3raw=rounded(d+norman*gap3);d3=rounded(d3raw,0)
    lam=rounded((d3/d)**(1/3),4)
    l3,b3,t3,h3=[rounded(x) for x in [L*lam,B*lam,T*lam,H/lam**2]]
    steel3=rounded(gst*delta**(1/3)*l3**1.5*b3*h3**.5)
    equipment3=rounded(gob*(l3*b3*h3)**(2/3));hull3=rounded(steel3+equipment3)
    powercheck=rounded(minimum*lam**2)
    A4=rounded(hull3+pe+pf+sum(table2[3:]));gap4=rounded(A4-d3)
    reserve3raw=rounded(table2[3]-gap4)
    table3=[rounded(hull3,0),rounded(pe,0),rounded(pf,0),0,table2[4],table2[5]]
    table3[3]=d3-sum(table3)
    float3=rounded(k*rho*delta*l3*b3*t3);finald=rounded(float3,0)
    finaltable=list(table3);finaltable[3]+=finald-d3
    third=dict(velocity=velocity,omega=omega,Re=re,Fr=fr,volume=volume,psi=psi,kpsi=kpsi,
        zr=zr,z=z,EPS=eps,required=required,minimum=minimum,engine=engine,Pe=pe,Pf=pf,
        A3=A3,gap=gap3,limit=table2[3]/2,norman=norman,D_raw=d3raw,D_adopt=d3,
        scale=lam,L=l3,B=b3,T=t3,H=h3,steel=steel3,equipment=equipment3,hull=hull3,
        power_check=powercheck,A4=A4,gap4=gap4,reserve_raw=reserve3raw,
        preliminary_table=table3,float_check=float3,D=finald,table=finaltable)
    return dict(inputs=inputs,first_table=first_table,second=second,third=third,
        final={key:third[key] for key in ['D','L','B','T','H']},
        provenance=dict(methods=['4a/КП-ПС-2 приближение.docx','5a/МУ-3прибл.cПрил.Fig.1-3.docx','5a/КП-ПС-3 приближение.docx'],
            adopted_records=['4a/4a-Женя.docx','5a/5a-Женя.docx'],
            rounding='ROUND_HALF_UP; each explicitly adopted coefficient, dimension and table value feeds the next stage'))
def verify(d):
    s,t=d['second'],d['third'];checks=[]
    def eq(name,a,b,tol=.011):
        checks.append(dict(name=name,actual=a,expected=b,passed=abs(a-b)<=tol))
    for name,val in dict(steel=9149.18,equipment=1726.80,hull=10875.98,gap=64.98,reserve_raw=379.02,D=44388).items():eq('second.'+name,s[name],val)
    for name,val in dict(omega=7658.02,EPS=7498.24,required=10711.77,engine=12400,Pe=1040.56,Pf=1034.83,A3=44115.39,norman=1.32,D_adopt=44028,scale=.9973,L=189.13,B=26.53,T=10.85,H=14.97,hull=10839.54,power_check=12252.11,A4=44078.93,float_check=44023.75,D=44024).items():eq('third.'+name,t[name],val)
    eq('second mass closure',sum(s['table']),s['D']);eq('third mass closure',sum(t['table']),t['D'])
    eq('final reserve',t['table'][3],323);eq('final float residual',abs(t['float_check']-t['D']),.25)
    for name,ok in [('second accepts',abs(s['gap'])<=s['limit']),('third requires correction',abs(t['gap'])>t['limit']),('third final accepts',abs(t['gap4'])<=t['limit']),('engine fits',t['engine']-200<t['power_check']<=t['engine']),('catalog ceiling',t['engine']>=t['minimum']>t['engine']-200)]:checks.append(dict(name=name,passed=ok))
    return dict(checks=checks,failures=[x for x in checks if not x['passed']])
if __name__=='__main__':
    data=build();report=verify(data)
    (ROOT/'content/approximation_calculated.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8')
    (ROOT/'qa/approximation-numerical.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps(report,ensure_ascii=False));assert not report['failures']
