extends RefCounted
# Example datum: x from the aft perpendicular (mesh x=-95), z from the baseline.
static var entries:Dictionary={}
static func entry(id:String)->Dictionary:
	if entries.is_empty():
		for q in JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/exam12/reading.json")):entries[q.id]=q
	return entries.get(id,{})
static func values(s:Dictionary)->Dictionary:
	var q:=entry(s.get("qid",""));var rows:Array=[]
	if q.has("example_data"):
		var all:Array=q.example_data.rows
		var count:float=clampf(float(s.get("load",0)),0,1)*all.size()
		for i in all.size():
			var r:Array=all[i].duplicate();r[1]*=clampf(count-i,0,1);rows.append(r)
	else:
		rows=[["空船",1000.,95.,6.],["货物",100.*float(s.get("load",0)),float(s.get("cargo_x",112)),float(s.get("cargo_z",5))]]
	var total:=0.;var mx:=0.;var mz:=0.
	for r in rows:total+=float(r[1]);mx+=float(r[1])*float(r[2]);mz+=float(r[1])*float(r[3])
	return {"rows":rows,"D":total,"mx":mx,"mz":mz,"xg":mx/total if total>0 else 0.,"zg":mz/total if total>0 else 0.}
static func formatted(s:Dictionary)->Dictionary:
	var v:=values(s);var out:Dictionary={}
	for k in ["D","mx","mz","xg","zg"]:out["ex_"+k]=("%.4f" if k in ["xg","zg"] else "%.2f")%v[k]
	var index:int=int(s.get("row_index",0))
	var rows:Array=v.rows
	if index<rows.size():
		out.ex_item_mass="%.2f"%rows[index][1];out.ex_item_mx="%.2f"%(rows[index][1]*rows[index][2]);out.ex_item_mz="%.2f"%(rows[index][1]*rows[index][3])
	return out

static var section_integrals:Array=[]
static var section_profile:Array=[]
static func lcb(shift:float)->Dictionary:
	if section_integrals.is_empty():
		var geo=preload("res://modules/review/core/module11_math.gd")
		var volume:=0.;var first:=0.;var second:=0.;var vertical:=0.;var cross:=0.
		for i in range(-98,102):
			var x:float=i+.5;var poly:Array=geo.section({},x)
			if poly.size()<3:continue
			poly=geo.submerged(poly,10.88)
			var area:float=geo.area(poly);var cy:=0.;var signed_area:=0.
			for j in poly.size():
				var a:Vector3=poly[j];var b:Vector3=poly[(j+1)%poly.size()];var cross_:float=a.z*b.y-b.z*a.y
				signed_area+=cross_;cy+=(a.y+b.y)*cross_
			var zc:float=cy/(3.*signed_area) if absf(signed_area)>.00001 else 0.
			section_profile.append(Vector3(x,area,zc))
			volume+=area;first+=area*x;second+=area*x*x;vertical+=area*zc;cross+=area*zc*x
		section_integrals=[volume,first,second,vertical,cross]
	var a:Array=section_integrals;var k:float=shift*.18/95.;var denominator:float=a[0]+k*a[1]
	return {"norm":a[0]/denominator,"xc":(a[1]+k*a[2])/denominator,"zc":(a[3]+k*a[4])/denominator,"volume":a[0]}
static func drawing_x(x:float)->float:
	if x< -49.79:return remap(x,-98.,-49.79,-75.,-15.)
	if x<30.55:return remap(x,-49.79,30.55,-15.,22.5)
	return remap(x,30.55,101.421,22.5,75.)
