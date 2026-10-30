extends RefCounted
static var data:Dictionary={}
static func ensure()->void:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/stability_hydro.json"))
static func pair(state:Dictionary)->Dictionary:
	ensure()
	var route:String=state.get("route","base");var series:Array=data.routes[route]
	var value:float=clampf(float(state.get("morph",0)),0,1)*(series.size()-1)
	var i:int=mini(int(value),series.size()-1)
	return {"a":series[i],"b":series[mini(i+1,series.size()-1)],"t":value-i}
static func row(item:Dictionary,angle:float)->Array:
	var a:float=clampf(absf(angle),0,180);var angles:Array=data.angles
	var lo:=0;var hi:=angles.size()-1
	while hi-lo>1:
		var mid:int=(lo+hi)/2
		if float(angles[mid])<=a:lo=mid
		else:hi=mid
	var t:float=(a-float(angles[lo]))/(float(angles[hi])-float(angles[lo]))
	var result:Array=[]
	for i in 5:result.append(lerpf(float(item.hydro[lo][i]),float(item.hydro[hi][i]),t))
	if angle<0:result[2]=-result[2]
	return result
static func values(state:Dictionary)->Dictionary:
	var p:=pair(state);var angle:float=float(state.get("heel",0));var zg:float=float(state.get("zg",8.7))
	var a:=row(p.a,angle);var b:=row(p.b,angle);var r:Array=[]
	for i in 5:r.append(lerpf(float(a[i]),float(b[i]),p.t))
	var result:Dictionary={"level":r[0],"cx":r[1],"cy":r[2],"cz":r[3],"residual":r[4],"heel":angle,"zg":zg}
	result.xc0=lerpf(float(p.a.hydro[0][1]),float(p.b.hydro[0][1]),p.t)
	for key in ["volume","zc","km","r"]:result[key]=lerpf(float(p.a[key]),float(p.b[key]),p.t)
	for key in ["B","H","T"]:result[key]=lerpf(float(p.a.params[key]),float(p.b.params[key]),p.t)
	result.h=result.km-zg;result.arm=result.cy-zg*sin(deg_to_rad(angle))
	result.allowed=result.km-float(state.get("required",1.0))
	var scale:float=float(state.get("display_scale",1))
	for key in ["level","cx","cy","cz","zg","xc0","zc","km","r","B","H","T","h","arm","allowed"]:result[key]*=scale
	result.volume*=pow(scale,3)
	result.period=TAU*8.0*scale/sqrt(9.81*maxf(.05,result.h))
	result.accel=deg_to_rad(6.0)*9.81*maxf(.05,result.h)/(64.0*scale*scale)
	return result
static func curve(state:Dictionary)->Array:
	var p:=pair(state);var points:Array=[];var zg:float=float(state.get("zg",8.7))
	for i in data.angles.size():
		var angle:float=data.angles[i]
		points.append(Vector2(angle,lerpf(float(p.a.hydro[i][2]),float(p.b.hydro[i][2]),p.t)-zg*sin(deg_to_rad(angle))))
	return points.map(func(p:Vector2):return Vector2(p.x,p.y*float(state.get("display_scale",1))))
static func extrema(points:Array)->Dictionary:
	var peak:=Vector2.ZERO;var zero:=-1.0
	for i in range(1,points.size()):
		if points[i].y>peak.y:peak=points[i]
		if zero<0 and points[i-1].y>0 and points[i].y<=0:
			zero=lerpf(points[i-1].x,points[i].x,points[i-1].y/(points[i-1].y-points[i].y))
	return {"peak":peak,"zero":zero}
