extends RefCounted
static func values(id:String,p:float)->Dictionary:
	match id:
		"Q06":return {"D":200.0,"x2":6.0+2*p,"z2":1.0+2*p,"xg":4.0+p,"zg":1.0+p}
		"Q07":return {"D":1000.0,"coefficient":.4,"mass":1000.0*.4}
		"Q08":return {"mass":100.0,"coefficient":.02,"power":100.0/.02}
		"Q09":return {"time":120.0/12.0*p,"fuel_kg":.2*1000*120.0/12.0*p}
		"Q10":return {"litres":150.0*5*2*p,"tonnes":.15*5*2*p}
		"Q16":return {"zc":1.0,"r":3.0,"zm":4.0,"zg":2.0+p,"h":2.0-p,"zg_max":3.0}
		"Q17":
			var width:=2.0+p;var r:=width*width/12.0
			return {"B":width,"T":1.0,"r":r,"zc":.5,"zg":.7,"h":.5+r-.7}
		"Q18":return {"angle_before":rad_to_deg(acos(-.35)),"angle_after":rad_to_deg(acos(-.35-.2*p))}
		"Q20":return {"period_ratio":sqrt(2.0),"angle_a":.18*sin(p*4*PI),"angle_b":.18*sin(p*4*PI/sqrt(2.0))}
		"Q21":return {"frequency_ratio":2.0,"acceleration_ratio":4.0,"angle_a":.18*sin(p*4*PI),"angle_b":.18*sin(p*8*PI)}
	return {}
static func arm(id:String,theta:float,p:float)->float:
	if id=="Q18":return sin(theta)*(cos(theta)+.35+.2*p)
	return sin(theta)*(.8*cos(theta)+.3)-.25*p*pow(sin(theta),3)
