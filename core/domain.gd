extends RefCounted
var tanker_cache:Dictionary={}
var loads_cache:Dictionary={}
var reference:Dictionary
var confirmed:Dictionary
var formal:Dictionary
var cargo_input:Dictionary
var approximations:Dictionary={}
func _init()->void:
	confirmed=JSON.parse_string(FileAccess.get_file_as_string("res://content/confirmed/calculated.json"));formal=confirmed.steps
	cargo_input=JSON.parse_string(FileAccess.get_file_as_string("res://content/confirmed/inputs.json")).cases.basics_v5.cargo
	reference={"fuel":[]}
	for r in formal.L01.rows:reference.fuel.append([r.name_zh,r.mass_t,r.z_m,r.x_m,r.moment_z_tm,r.moment_x_tm])
func loads(params:Dictionary={})->Dictionary:
	var key:=var_to_bytes([params.get("move_x",0.0),params.get("move_z",0.0),params.get("added_mass",0.0)]).hex_encode()
	if loads_cache.has(key):return loads_cache[key]
	var rows:Array=[]
	for r in formal.L04.rows:rows.append([r.name_zh,r.mass_t,r.z_m,r.x_m,r.moment_z_tm,r.moment_x_tm])
	rows[5][3]+=float(params.get("move_x",0.0))
	rows[5][2]+=float(params.get("move_z",0.0))
	rows[5][1]+=float(params.get("added_mass",0.0))
	var d:=0.0;var mz:=0.0;var mx:=0.0
	for row in rows:
		if row[0]!="燃油":row[4]=row[1]*row[2];row[5]=row[1]*row[3]
		d+=row[1];mz+=row[4];mx+=row[5]
	var result:Dictionary={"rows":rows,"Dload":d,"MZ":mz,"MX":mx,"zG":mz/d,"xG":mx/d,"free_correction":1734.0/d}
	loads_cache[key]=result
	if loads_cache.size()>64:loads_cache.erase(loads_cache.keys()[0])
	return result
func tanker()->Dictionary:
	if not tanker_cache.is_empty():return tanker_cache.duplicate()
	# Formal homework follows the compiled, independently verified adoption chain.
	# No alternate full-precision/Newton path runs behind the displayed results.
	var m:Array=[formal.T06.Phull_t,formal.T06.Pengine_t,formal.T06.Penergy_t,formal.T06.Preserve_t,formal.T01.Psupply_t,30700.0]
	var d:float=formal.T05.D1_t;var b:float=formal.T14.B1_m;var t:float=formal.T14.T1_m;var h:float=formal.T14.H1_m;var length:float=formal.T14.L1_m
	var alpha:float=formal.T09.alpha;var delta:float=formal.T09.delta;var zeta:float=formal.T09.zeta
	var eta:float=1.0/(formal.T03.a-(2.0/3.0)*formal.T03.b*pow(d,-1.0/3.0))
	tanker_cache={"valid":true,"speed":15.9,"pk":formal.T02.p_hull,"pe":formal.T02.p_engine,"pfcoef":formal.T02.p_energy,"C":formal.T02.CA,"supply":formal.T01.Psupply_t,"a":formal.T03.a,"b":formal.T03.b,"c":formal.T03.c_t,"D":d,"D_exact":pow(formal.T04.X,3),"N":formal.T06.N1_kW,"mass":m,"mass_sum":formal.T07.project_total_t,"mass_error":formal.T07.table_residual_t,"L":length,"B":b,"T":t,"H":h,"delta":delta,"alpha":alpha,"delta_pp":formal.T09.delta_underdeck,"zeta":zeta,"Fr":formal.T09.Fr,"ell":formal.T08.relative_length,"Wcargo":formal.T11.Wcargo_m3,"Wpower":formal.T11.Wengine_m3,"Wfuel":formal.T11.Wenergy_m3,"Wfresh":formal.T11.Wwater_m3,"Wballast":formal.T11.Wballast_m3,"Wreq":formal.T11.Wrequired_m3,"U":formal.T12.BT_m2,"V":formal.T12.BH_m2,"H_T":h/t,"freeboard":h-t,"GM":.06*b,"eta":eta,"residual_float":-formal.T15.difference_t,"residual_volume":formal.T09.delta_underdeck*length*b*h-formal.T11.Wrequired_m3,"residual_stability":.5*sqrt(alpha/delta)*t+.0862*alpha*alpha*b*b/(delta*t)-zeta*h-.06*b}
	return tanker_cache.duplicate()
func values(params:Dictionary={})->Dictionary:
	var out:=tanker()
	if params.has("approximation"):
		if approximations.is_empty():approximations=JSON.parse_string(FileAccess.get_file_as_string("res://content/approximation_calculated.json"))
		var progress:float=clampf(float(params.get("approx_scale",0)),0,1)
		for key in ["L","B","T","H"]:out[key]=lerpf(float(approximations.second[key]),float(approximations.third[key]),progress)
		out["H"]=lerpf(float(approximations.second.H),float(approximations.third.H),float(params.get("approx_h_scale",progress)))
		out["D"]=lerpf(float(approximations.second.D),float(approximations.third.D),progress)
	out["move_z"]=float(params.get("move_z",0.0))
	out.merge(loads(params),true)
	out["fuel_rows"]=reference.fuel
	if params.get("show_fuel",false):
		out["display_rows"]=reference.fuel;out["display_xG"]=67576.4/1069;out["display_zG"]=2047.5/1069
	else:
		out["display_rows"]=out.rows;out["display_xG"]=out.xG;out["display_zG"]=out.zG
	for i in range(out.mass.size()):out["mass%d"%i]=out.mass[i]
	for key in cargo_input:out["b02_"+key]=cargo_input[key]
	for key in formal.B02:out["b02_"+key]=formal.B02[key]
	out["b02_added_t"]=formal.B02.second_port_mass_t*clampf(float(params.get("cargo_second_fraction",0)),0,1)
	out["b02_total_t"]=cargo_input.first_port_mass_t+out.b02_added_t
	out["b02_used_m3"]=formal.B02.first_volume_m3+out.b02_added_t*cargo_input.second_port_stowage_m3_t
	out["b02_free_m3"]=cargo_input.capacity_volume_m3-out.b02_used_m3
	return out
func format_number(value:float,digits:int=4)->String:
	return ("%.*f"%[digits,value]).trim_suffix(".")
func display_values(values:Dictionary)->Dictionary:
	var result:Dictionary={}
	for key in values:
		if typeof(values[key]) in [TYPE_FLOAT,TYPE_INT]:
			var digits:=12 if key in ["q","pfcoef"] else (8 if key in ["pk","pe","Fr","delta","alpha"] else 4)
			result[key]=format_number(float(values[key]),digits)
	return result
func bind(text:String,values:Dictionary)->String:
	var result:=text;var formatted:=display_values(values)
	for key in formatted:result=result.replace("@%s@"%key,formatted[key])
	return result
