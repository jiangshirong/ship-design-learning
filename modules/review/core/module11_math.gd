extends RefCounted
# Instructional geometry only; never shares mutable state with stability hydrostatics.
static var data:Dictionary={}
static var vertex_signature:PackedByteArray
static var vertex_cache:Array=[]
static func geometry()->Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/module11_geometry.json"))
	return data
static func vertices(s:Dictionary)->Array:
	var coefficients:=weights(s);var signature:=var_to_bytes([coefficients,s.get("scale_l",1),s.get("scale_b",1),s.get("scale_t",1)])
	if signature==vertex_signature and not vertex_cache.is_empty():return vertex_cache
	vertex_signature=signature;vertex_cache=[]
	for i in geometry().vertices.size():vertex_cache.append(vertex(s,i,coefficients))
	return vertex_cache
static func weights(s:Dictionary)->Dictionary:
	var w:float=float(s.get("waterline",0))
	return {"Bilge":float(s.get("bilge",0)),"WaterlineStraight":clampf(1.-absf(2*w-1),0,1),"Waterline":maxf(0,2*w-1),"BowV":float(s.get("bow_v",0)),"Flare":float(s.get("flare",0)),"Bulb":float(s.get("bulb",0))}
static func vertex(s:Dictionary,i:int,coefficients:Dictionary)->Vector3:
	var d:=geometry();var a:Array=d.vertices[i];var base:=Vector3(a[0],a[1],a[2]);var p:=base
	for key in coefficients:
		if coefficients[key]!=0:
			var b:Array=d.variants[key][i];p+=(Vector3(b[0],b[1],b[2])-base)*coefficients[key]
	return Vector3(p.x*float(s.get("scale_l",1)),p.z*float(s.get("scale_t",1)),-p.y*float(s.get("scale_b",1)))
static func ring(s:Dictionary,index:int)->Array:
	var n:int=geometry().ring_size;var result:Array=[];var coefficients:=weights(s)
	for j in n:result.append(vertex(s,index*n+j,coefficients))
	return result
static func section(s:Dictionary,x:float)->Array:
	if absf(x+1.59*float(s.get("scale_l",1)))<.0001:return ring(s,24)
	var d:=geometry();var n:int=d.ring_size;var out:Array=[];var coefficients:=weights(s)
	for j in n:
		var lo:=0;var hi:int=int(d.ring_count)-1
		while hi-lo>1:
			var mid:int=(lo+hi)/2
			if vertex(s,mid*n+j,coefficients).x<=x:lo=mid
			else:hi=mid
		var a:=vertex(s,lo*n+j,coefficients);var b:=vertex(s,hi*n+j,coefficients)
		if a.x<=x and b.x>=x and b.x-a.x>.0001:out.append(a.lerp(b,(x-a.x)/(b.x-a.x)))
	return out
static func submerged(poly:Array,water_y:float)->Array:
	var out:Array=[];var a:Vector3=poly[-1]
	for b:Vector3 in poly:
		if (a.y<=water_y)!=(b.y<=water_y):out.append(a.lerp(b,(water_y-a.y)/(b.y-a.y)))
		if b.y<=water_y:out.append(b)
		a=b
	return out
static func area(poly:Array)->float:
	var sum:=0.0
	for i in poly.size():sum+=poly[i].z*poly[(i+1)%poly.size()].y-poly[(i+1)%poly.size()].z*poly[i].y
	return absf(sum)*.5
static func values(s:Dictionary)->Dictionary:
	var b:float=26.6*float(s.get("scale_b",1));var t:float=10.88*float(s.get("scale_t",1))
	var a:=area(submerged(section(s,-1.59*float(s.get("scale_l",1))),t))
	return {"m11_area":"%.2f"%a,"m11_beta":"%.4f"%(a/(b*t)),"m11_l":"%.2f"%(189.64*float(s.get("scale_l",1))),"m11_b":"%.2f"%b,"m11_t":"%.2f"%t,"area":a,"beta":a/(b*t),"volume_ratio":float(s.get("scale_l",1))*float(s.get("scale_b",1))*float(s.get("scale_t",1))}
