extends RefCounted
const Final=preload("res://core/approximation_final.gd")
const L:=Final.L
const B:=Final.B
const H:=Final.H
const T:=Final.T
const D:=Final.D
const BOUNDARIES=[0,24,60,85,109,133,157,181,185,221,243]
const COUNTS=[24,36,25,24,24,24,24,4,36,22]
const SPACINGS=[.6,.69,.85,.85,.85,.85,.85,.85,.85,.6]
const NAMES_ZH=["艏尖舱","货油舱组1","货油舱组2","货油舱组3","货油舱组4","货油舱组5","货油舱组6","泵舱","机舱","艉尖舱"]
const NAMES_RU=["Фо́рпик","Гру́ппа 1","Гру́ппа 2","Гру́ппа 3","Гру́ппа 4","Гру́ппа 5","Гру́ппа 6","Насо́сное отделе́ние","МО","Ахте́рпик"]
static func calculate()->Dictionary:
 var fore:=Vector2(.05*L,.08*L);var aft:=Vector2(.04*L,.08*L);var engine:=Vector2(.14*L,.17*L)
 var dw:=D-(Final.HULL_MASS+Final.ENGINE_MASS)
 return {"nominal_spacing":.002*L+.48,"adopted_spacing":.85,"fore_range":[fore.x,fore.y],"aft_range":[aft.x,aft.y],"engine_range":[engine.x,engine.y],"fore_intervals":integer_range(fore.x,fore.y,.6),"aft_intervals":integer_range(aft.x,aft.y,.6),"engine_intervals":integer_range(engine.x,engine.y,1.7),"cargo_length":L-14.4-13.2-30.6-3.4,"transition_length":.2*L-14.4,"transition_adopted":37*.69,"transition_reconciled":true,"double_bottom_calc":.0328*H+1.2,"double_bottom_min":(L-40)/570+.04*B+3.5*T/L,"double_bottom":1.7,"deadweight":dw,"double_side_calc":.5+dw/20000,"double_side":2.2,"cargo_width":B-4.4,"central_width":B-4.4-2*6.65,"bi":2.2+6.65,"tank_limit":.2*L,"rows":rows()}
static func frame_distance(frame:float)->float:
 if frame<=24:return frame*.6
 if frame<=61:return 14.4+(frame-24)*.69
 if frame<=221:return 39.93+(frame-61)*.85
 return 175.93+(frame-221)*.6
static func x(frame:float)->float:return L-frame_distance(frame)
static func integer_range(low:float,high:float,spacing:float)->Vector2i:
 return Vector2i(ceili(low/spacing),floori(high/spacing))
static func rows(movable_frame:=60.0)->Array:
 var boundaries:Array=BOUNDARIES.duplicate();boundaries[2]=movable_frame
 var result:Array=[]
 for i in 10:
  var start:float=boundaries[i];var finish:float=boundaries[i+1]
  var parts:Array=[]
  for zone in [[0,24,.6],[24,61,.69],[61,221,.85],[221,243,.6]]:
   var count:float=maxf(0,minf(finish,zone[1])-maxf(start,zone[0]))
   if count>0:parts.append("%d × %.2f"%[count,zone[2]])
  result.append({"name":{"zh":NAMES_ZH[i],"ru":NAMES_RU[i]},"start":start,"end":finish,"count":finish-start,"spacing":SPACINGS[i],"expression":" + ".join(parts),"length":frame_distance(finish)-frame_distance(start),"s":frame_distance(finish),"x":x(finish)})
 return result
static func values(s:Dictionary)->Dictionary:
 var frame:float=s.get("bh_frame",60.0);var table:=rows(frame)
 var total:=0.0
 for row in table:total+=row.length
 return {"bh_n":"%.0f"%frame,"bh_x":"%.2f"%x(frame),"bh_l1":"%.2f"%table[1].length,"bh_l2":"%.2f"%table[2].length,"bh_pair":"%.2f"%(table[1].length+table[2].length),"bh_total":"%.2f"%total}
