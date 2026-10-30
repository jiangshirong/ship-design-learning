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
		if key in ["p","load","loaded","height","progress","heel","zg","morph","required","clock","display_scale","partitions","flood","side","heel_demo","sink","spread","superstructure","sheer","forecastle","draft","demo_zg","cutaway","bilge","waterline","bow_v","bulb","closed_stern","flare","scale_l","scale_b","scale_t","lines","station","wave"]:
			result[key]=lerpf(float(a.get(key,0)),float(b[key]),t)
		else:result[key]=b[key]
	return result
static func sample(a:Dictionary,b:Dictionary,frames:Array,t:float)->Dictionary:
	var old:Dictionary=a;var start:=0.0
	for frame in frames:
		var finish:float=frame.at
		if t<=finish:return segment(old,frame.state,clampf((t-start)/maxf(finish-start,.00001),0,1))
		old=frame.state;start=finish
	return segment(old,b,clampf((t-start)/maxf(1-start,.00001),0,1))
static func segment(a:Dictionary,b:Dictionary,t:float)->Dictionary:
	var value:=blend(a,b,smoothstep(0.0,1.0,t))
	# Physical time must not inherit the ease-in/out of geometry transitions.
	if b.has("clock"):value.clock=lerpf(float(a.get("clock",0)),float(b.clock),t)
	return value
