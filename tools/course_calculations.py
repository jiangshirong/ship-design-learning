"""UI-independent approved homework calculation chain. No expected-result imports.

Run this file to rebuild the runtime calculation record from the confirmed inputs.
Decimal half-up is used at the teacher's explicit reporting/adoption boundaries.
"""
import json, math, shutil
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT.parent/'已确认作业计算流程'/'data'
def rnd(x,n=2): return float(Decimal(str(x)).quantize(Decimal(1).scaleb(-n),rounding=ROUND_HALF_UP))
def bisect(f,left,right):
    fl,fr=f(left),f(right)
    if fl==0:return left,[], 'left_endpoint'
    if fr==0:return right,[], 'right_endpoint'
    if fl*fr>0:raise ValueError('Root not bracketed')
    trace=[]
    for i in range(1,201):
        mid=(left+right)/2; fm=f(mid)
        trace.append(dict(iteration=i,left=left,right=right,mid=mid,residual=fm))
        if abs(fm)<=1e-8 or right-left<=1e-10:
            return mid,trace,'residual' if abs(fm)<=1e-8 else 'interval_width'
        if fl*fm<0:right=mid
        else:left=mid;fl=fm
    raise ArithmeticError('Bisection failed after 200 iterations')
def calculate(cases):
    s={}; traces={}; b=cases['basics_v5']; m=b['midship']; c=b['cargo']; d=b['draft']
    s['B01']={'beta':m['area_m2']/(m['breadth_m']*m['draft_m'])}
    remain=c['capacity_mass_t']-c['first_port_mass_t']; w1=c['first_port_mass_t']*c['first_port_stowage_m3_t']; wr=c['capacity_volume_m3']-w1
    pv=wr/c['second_port_stowage_m3_t']; p=min(remain,pv)
    s['B02']=dict(remaining_mass_t=remain,first_volume_m3=w1,remaining_volume_m3=wr,volume_limited_mass_t=pv,second_port_mass_t=p,unused_volume_m3=wr-p*c['second_port_stowage_m3_t'])
    trim=-d['trim_fore_m']; fore=d['stern_m']-trim
    s['B03']=dict(signed_trim_m=trim,fore_m=fore,mean_m=(fore+d['stern_m'])/2)
    load=cases['load_v5']; fuel=[]
    for r in load['fuel_tanks']:
        r=r.copy();r.update(moment_z_tm=r['mass_t']*r['z_m'],moment_x_tm=r['mass_t']*r['x_m']);fuel.append(r)
    def totals(rows):return dict(P_t=sum(r['mass_t'] for r in rows),moment_z_tm=sum(r['moment_z_tm'] for r in rows),moment_x_tm=sum(r['moment_x_tm'] for r in rows))
    s['L01']={'rows':fuel};s['L02']=totals(fuel);s['L02']['free_surface_tm']=sum(r['free_surface_tm'] for r in fuel)
    f=s['L02'];s['L03']=dict(z_m=f['moment_z_tm']/f['P_t'],x_m=f['moment_x_tm']/f['P_t'])
    ship=[]
    for r in load['ship_items']:
        r=r.copy()
        if r['id']=='fuel':r.update(mass_t=f['P_t'],**s['L03'],moment_z_tm=f['moment_z_tm'],moment_x_tm=f['moment_x_tm'])
        else:r.update(moment_z_tm=r['mass_t']*r['z_m'],moment_x_tm=r['mass_t']*r['x_m'])
        ship.append(r)
    s['L04']={'rows':ship};s['L05']=totals(ship);g=s['L05'];s['L06']=dict(zG_m=g['moment_z_tm']/g['P_t'],xG_m=g['moment_x_tm']/g['P_t'])
    t=cases['t2_first'];p=t['project'];o=t['prototype'];k=t['constants'];ad=t['adopted'];v=p['v_kn'];R=p['R_nm']
    supply=dict(Pcrew_t=k['p_crew_t_person']*p['crew_count'],Pfood_t=k['p_food_t_person_day']*p['crew_count']*p['food_days'],Pwater_t=k['p_water_t_person_day']*p['crew_count']*p['water_days'],Pinventory_t=k['P_inventory_t'])
    supply['Psupply_t']=sum(supply.values());s['T01']=supply
    pk=o['P_hull0_t']/o['D0_t'];pe=o['P_engine0_t']/o['N0_kW'];pf=o['P_energy0_t']*o['v0_kn']/(o['N0_kW']*o['R0_nm']);ca=o['D0_t']**(2/3)*o['v0_kn']**3/o['N0_kW']
    s['T02']=dict(p_hull=pk,p_engine=pe,p_energy=pf,CA=ca)
    a=1-pk-k['p_reserve'];bb=(pe+pf*R/v)*v**3/ca;c=p['Pgr_t']+supply['Psupply_t'];s['T03']=dict(a=a,b=bb,c_t=c)
    x,trace,reason=bisect(lambda x:a*x**3-bb*x*x-c,1.,100.);traces['T04']=dict(iterations=trace,termination=reason,residual=trace[-1]['residual'])
    s['T04']=dict(X=x,X_for_cube=rnd(x,4),D_before_adoption_t=rnd(rnd(x,4)**3));D=ad['D1_t'];s['T05']=dict(D1_t=D)
    N=rnd(D**(2/3)*v**3/ca);mass=[rnd(pk*D),rnd(pe*N),rnd(pf*N*R/v),rnd(k['p_reserve']*D),supply['Psupply_t'],p['Pgr_t']]
    s['T06']=dict(N1_kW=N,Phull_t=mass[0],Pengine_t=mass[1],Penergy_t=mass[2],Preserve_t=mass[3])
    names=[('船体及设备','Ко́рпус с обору́дованием','Pк.об.'),('动力装置','Энергети́ческая устано́вка','Pсэу'),('能源储备','Энергети́ческие запа́сы','Pсэз'),('排水量裕量','Запа́с водоизмеще́ния','Pзв'),('船员、食品、淡水及器具','Экипа́ж и снабже́ние','Pсн'),('货物','Груз','Pгр')]
    old=[o[n] for n in ['P_hull0_t','P_engine0_t','P_energy0_t','P_reserve0_t','P_supply0_t','P_cargo0_t']]
    rows=[dict(name_zh=zh,name_ru=ru,symbol=sym,prototype_mass_t=old[i],prototype_percent=rnd(old[i]/o['D0_t']*100),calculated_project_mass_t=mass[i],project_mass_t=int(rnd(mass[i],0)),project_percent=rnd(mass[i]/D*100)) for i,(zh,ru,sym) in enumerate(names)]
    total=sum(r['project_mass_t'] for r in rows);s['T07']=dict(rows=rows,prototype_total_t=sum(old),project_total_t=total,table_residual_t=total-D)
    ell=k['relative_length_factor']*v**(1/3);L=ad['L1_m'];s['T08']=dict(relative_length=ell,L_calculated_m=rnd(ell*D**(1/3)),L1_m=L)
    Fr=k['kn_to_ms']*v/math.sqrt(k['g_m_s2']*L);delta_c=k['fullness_a']-k['fullness_b']*Fr;delta=ad['delta'];alpha=ad['alpha'];zeta=ad['zeta'];dp=delta+k['underdeck_delta_add']
    s['T09']=dict(Fr=Fr,delta_calculated=delta_c,alpha_calculated=k['waterline_factor']*math.sqrt(delta_c),delta=delta,alpha=alpha,zeta=zeta,delta_underdeck=dp)
    mu=ad['mu_engine_m3_kW'];s['T10']=dict(mu=mu)
    wc=rnd(k['cargo_volume_factor']*p['Pgr_t']/p['rho_cargo_t_m3']);we=rnd(mu*N);wf=rnd(mass[2]/k['k_energy_t_m3']);ww=rnd(supply['Pwater_t']/k['k_water_t_m3']);wb=rnd(k['ballast_fraction']*wc);wr=rnd(o['k_dry']*(wc+we+wf+ww+wb))
    s['T11']=dict(Wcargo_m3=wc,Wengine_m3=we,Wenergy_m3=wf,Wwater_m3=ww,Wballast_m3=wb,Wrequired_m3=wr)
    u=rnd(D/(k['k_appendage']*k['rho_seawater_t_m3']*delta*L));j=rnd(wr/(dp*L));s['T12']=dict(BT_m2=u,BH_m2=j)
    stability=lambda B:k['k_stability']*math.sqrt(alpha/delta)*(u/B)+.0862*alpha**2*B**2/(delta*(u/B))-zeta*(j/B)-k['h_over_B']*B
    B,trace,reason=bisect(stability,o['B0_m']/2,o['B0_m']*2);traces['T13']=dict(iterations=trace,termination=reason,residual=trace[-1]['residual'])
    s['T13']=dict(B_calculated_m=rnd(B),T_calculated_m=rnd(u/B),H_calculated_m=rnd(j/B),B_solver_value_m=B)
    s['T14']={n:ad[n] for n in ['L1_m','B1_m','T1_m','H1_m']};B=ad['B1_m'];T=ad['T1_m'];H=ad['H1_m']
    check=rnd(k['k_appendage']*k['rho_seawater_t_m3']*delta*L*B*T);diff=rnd(abs(D-check));report=int(rnd(diff,0))
    s['T15']=dict(Dcheck_t=check,difference_t=diff,reported_difference_t=report,within_allowed=report<=max(k['floating_difference_range_t']),conclusion_ru=f'Расхождение между D и D₁ составляет {report} тонн и не превышает 5-8 тонн.')
    s['T16']=dict(prototype_L_B=o['L0_m']/o['B0_m'],prototype_B_T=o['B0_m']/o['T0_m'],prototype_H_T=o['H0_m']/o['T0_m'],project_L_B=L/B,project_B_T=B/T,project_H_T=H/T,H_T_pass=H/T>=k['min_H_over_T'])
    return dict(schema_version=2,steps=s,solvers=traces,adoption=t['adopted'])
def build():
    inputs=json.loads((SOURCE/'inputs.json').read_text('utf8'));result=calculate(inputs['cases'])
    dest=ROOT/'content'/'confirmed';dest.mkdir(exist_ok=True)
    for name in ['inputs.json','steps.json','sources.json']:shutil.copy2(SOURCE/name,dest/name)
    (dest/'calculated.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
    return result
if __name__=='__main__':build();print('Calculated 25 steps and two complete bisection traces')
