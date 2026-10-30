extends RefCounted
const Hydro=preload("res://modules/review/core/stability_math.gd")
static func evaluate(state:Dictionary)->Dictionary:
	var base:=Hydro.values(state)
	var actual:=base.duplicate()
	var roll:bool=state.get("show","")=="roll"
	var compare:bool=roll and state.get("compare",false)
	var angle:float=base.heel
	if roll:
		angle=6*cos(TAU*float(state.get("clock",0))/base.period)
		var pose:=state.duplicate();pose.heel=angle;actual=Hydro.values(pose)
	actual.angle=angle
	var reference:Dictionary={}
	if compare:
		var ref_state:Dictionary={"zg":state.get("reference_zg",8.7)}
		var ref_base:=Hydro.values(ref_state)
		var ref_angle:float=6*cos(TAU*float(state.get("clock",0))/ref_base.period)
		ref_state.heel=ref_angle;reference=Hydro.values(ref_state);reference.angle=ref_angle
	return {"base":base,"actual":actual,"reference":reference}
