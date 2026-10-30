extends RefCounted
# Shared geometric poses. Prescribed teaching states, not a lift/resistance solver.
static var data:Dictionary={}
static var last_key:=""
static var last_value:Dictionary={}
static func values(s:Dictionary)->Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/yacht_poses.json"))
	var scene:String=s.get("scene","overview")
	var p:float=clampf(float(s.get("p",0)),0,1)
	var key:String=scene+var_to_bytes(p).hex_encode()
	if key==last_key:return last_value
	var pose:float=p if scene in ["regimes","planing"] else 0.
	var t:float=pose*100;var i:int=mini(int(t),99);var a:Dictionary=data.rows[i];var b:Dictionary=data.rows[i+1]
	var out:Dictionary={}
	for field in ["trim","heave","volume","area","buoyancy","lift"]:out[field]=lerpf(a[field],b[field],t-i)
	out.speed=2.+p*14. if scene=="froude" else (2.+pose*14.)
	out.fr=out.speed/sqrt(9.81*pow(float(data.static_volume),1./3.))
	out.mass=1.025*float(data.static_volume)
	out.length=data.length;out.beam=data.beam
	last_key=key;last_value=out;return out
static func formatted(s:Dictionary)->Dictionary:
	var m:=values(s);var out:Dictionary={}
	for field in ["speed","fr","volume","area","trim"]:out["y_"+field]="%.2f"%m[field]
	return out
