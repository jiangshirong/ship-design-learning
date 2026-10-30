extends Control
var view
var lookup=preload("res://modules/review/view/drawn_term_lookup.gd").new()
const GOLD=Color("ffd078")
const TEAL=Color("75d7c8")
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(lookup)
func label(z:String,r:String,at:Vector2,color:=Color("dce7ee"))->void:
 var s:String=z if view.language=="zh" else r
 draw_string(get_theme_default_font(),at,s,HORIZONTAL_ALIGNMENT_LEFT,-1,22,color)
 lookup.add_label(s,at,get_theme_default_font(),22)
func arrow(a:Vector2,b:Vector2,c:Color)->void:
 if a.distance_to(b)<2:return
 draw_line(a,b,c,3,true);var u:Vector2=(b-a).normalized();var n:=Vector2(-u.y,u.x)
 draw_colored_polygon(PackedVector2Array([b,b-u*13+n*6,b-u*13-n*6]),c)
func _draw()->void:
 lookup.clear_labels()
 if not view or view.source_state.is_empty():return
 var s:Dictionary=view.source_state;var p:float=float(s.get("p",0));var scene:String=s.get("scene","overview")
 var w:=size.x;var mid:=w*.5;var y:=175.
 # Draw explanatory diagrams above the retained detailed ship, never substitute a toy hull.
 if scene.begins_with("free_"):
  var side:=Vector3(0,14.89,-14)
  var top:Vector3=view.bodies[0].to_global(side)
  var water:=Vector3(top.x,0,top.z)
  var a:Vector2=view.project(water);var b:Vector2=view.project(top)
  arrow(a,b,TEAL);label("干舷","Надво́дный борт",b+Vector2(-80,-18),TEAL)
  var req:Vector3=water+Vector3(0,14.89-(8.+8./3.),0)
  var r:Vector2=view.project(req)+Vector2(65,0)
  arrow(a+Vector2(65,0),r,GOLD);label("最小要求","Минима́льный",r+Vector2(12,0),GOLD)
 elif scene in ["plan","crew"]:
  var x:=w*.20;var length:=w*.60;var rect:=Rect2(x,y,length,130)
  draw_rect(rect,Color(.04,.12,.16,.85));draw_rect(rect,TEAL,false,2)
  for t in [.16,.4,.65,.87]:draw_line(Vector2(x+length*t,y),Vector2(x+length*t,y+130),Color("6b8795"),2)
  var cabin:=Rect2(x+length*.04,y+20,length*.18,90)
  draw_rect(cabin,Color(1.,.75,.25,.15+p*.25));draw_rect(cabin,GOLD,false,3)
  label("甲板平面 / 船艏 →","План па́лубы / нос →",Vector2(x,y-18))
  if scene=="crew":
   for i in range(1+int(p*6)):
    var at:=Vector2(x+30+i*26,y+55);draw_circle(at,6,GOLD);draw_line(at+Vector2(0,8),at+Vector2(0,24),GOLD,3)
  else:arrow(cabin.get_center(),view.project(view.bodies[0].to_global(Vector3(-78,26,0))),GOLD)
 elif scene=="bridge":
  var eye:Vector3=view.bridge_eye();var start:Vector2=view.project(eye)
  for side in [-1,1]:
   arrow(start,view.project(Vector3(35,9,side*11)),GOLD)
  label("驾驶室","Ходова́я ру́бка",start+Vector2(-70,-26),GOLD)
 elif scene=="width":
  var factor:float=lerpf(1.,.62,p)
  for sign_ in [-1,1]:
   var edge:Vector2=view.project(view.bodies[0].to_global(Vector3(-8,14.95,sign_*13.3)))
   var wall:Vector2=view.project(view.bodies[0].to_global(Vector3(-8,14.95,sign_*12.9*factor)))
   arrow(edge,wall,GOLD)
  var point:Vector2=view.project(view.bodies[0].to_global(Vector3(-9,21,0)))
  label("上层建筑" if p<.15 else "甲板室","Надстро́йка" if p<.15 else "Ру́бка",point+Vector2(-65,-18),TEAL)
 elif scene=="forecastle":
  var point:Vector2=view.project(view.bodies[0].to_global(Vector3(75,16+5*p,0)))
  label("艏楼","Бак",point+Vector2(-30,-20),GOLD)

 else:
  var names=["主机","轴系","螺旋桨","有效功率"]
  var rus=["Дви́гатель","Валопрово́д","Винт","EPS"]
  if scene in ["froude","regimes","planing"]:
   names=["排水","过渡","滑行"];rus=["Водоизмеща́ющий","Перехо́дный","Глисси́рование"]
  var count:=names.size();var gap:=minf(240.,(w-100)/count)
  for i in count:
   var at:=Vector2(mid+(i-(count-1)*.5)*gap,y+40)
   var selected:bool=i==int(round(p*(count-1)))
   draw_rect(Rect2(at-Vector2(gap*.45,30),Vector2(gap*.90,70)),Color(.1,.23,.28,.92))
   draw_rect(Rect2(at-Vector2(gap*.45,30),Vector2(gap*.90,70)),GOLD if selected else TEAL,false,2)
   label(names[i],rus[i],at-Vector2(gap*.42,-5),GOLD if selected else TEAL)
   if i<count-1:arrow(at+Vector2(gap*.46,5),at+Vector2(gap*.54,5),TEAL)
  if scene in ["froude","regimes","planing"]:
   var at:=Vector2(mid,y+140)
   var hull:=PackedVector2Array([Vector2(-100,-15),Vector2(100,-15),Vector2(60,12),Vector2(-70,12)])
   for i in hull.size():hull[i]=at+hull[i].rotated(-.12*p)
   draw_polyline(hull,TEAL,3,true)
   arrow(at+Vector2(0,65),at+Vector2(0,35-55*p),GOLD)
   label("滑行艇受力示意","Схе́ма глисси́рования",Vector2(mid-140,y+238))
  else:
   if scene=="tow":
    var start:Vector2=view.project(view.bodies[0].to_global(Vector3(0,8,0)))
    var end:Vector2=view.project(view.bodies[0].to_global(Vector3(-35*p,8,0)))
    arrow(start,end,GOLD)
   elif scene=="wake":
    var start:Vector2=view.project(view.bodies[0].to_global(Vector3(-53,2.6,0)))
    var end:Vector2=view.project(view.bodies[0].to_global(Vector3(-53-40*p,2.6,0)))
    arrow(start,end,GOLD)
