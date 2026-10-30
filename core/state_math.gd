extends RefCounted
# Shared parameter state. Renderers never independently interpolate derived answers.
static func patch(base:Dictionary,changes:Dictionary)->Dictionary:
	var result:Dictionary=base.duplicate(true)
	for key in changes.get("params",{}):result[key]=changes.params[key]
	return result
static func blend(a:Dictionary,b:Dictionary,t:float)->Dictionary:
	if t<=0:return a.duplicate(true)
	if t>=1:return b.duplicate(true)
	var result:Dictionary=a.duplicate(true)
	for key in b:
		if key in ["bh_cut","bh_walls","bh_frames","bh_insert","bh_bottom","bh_side","bh_long","bh_range","dependency_reveal","pair_measure","pair_merge","surface_roll","fuel_merge","b01_reveal","cargo_progress","cargo_second_fraction","trim_progress","move_x","move_z","added_mass","speed","roll","reveal","draft","cutaway_amount","dimension_reveal","baseline_reveal","draft_measure","depth_measure"]:
			result[key]=lerpf(float(a.get(key,0)),float(b[key]),t)
		else:result[key]=b[key]
	return result
static func sample(a:Dictionary,b:Dictionary,frames:Array,t:float)->Dictionary:
	var old:Dictionary=a;var start:=0.0
	for frame in frames:
		var finish:float=frame.at
		if t<=finish:return blend(old,frame.state,smoothstep(0.0,1.0,clampf((t-start)/maxf(finish-start,.00001),0,1)))
		old=frame.state;start=finish
	return blend(old,b,smoothstep(0.0,1.0,clampf((t-start)/maxf(1-start,.00001),0,1)))
