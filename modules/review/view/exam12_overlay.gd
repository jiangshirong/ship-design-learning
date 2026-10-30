extends Control
const Geo=preload("res://modules/review/core/module11_math.gd")
var view
var bounds:Array=[]
var lookup=preload("res://modules/review/view/drawn_term_lookup.gd").new()
var images:Dictionary={}
var geometry_key:Dictionary={}
var vertices:Array=[]
func _ready()->void:mouse_filter=MOUSE_FILTER_IGNORE;add_child(lookup)
func tr2(zh:String,ru:String)->String:return zh if view.language=="zh" else ru
func point(v:Vector3)->Vector2:return view.project(view.bodies[0].to_global(v))
func label(value:String,p:Vector2,color:=Color("e9f1ef"),font_size:=20)->void:
 var f:=get_theme_default_font();var extent:=f.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
 p=p.clamp(Vector2(12,24),size-Vector2(extent.x+12,16))
 if view.source_state.get("concept","") in ["rooms","hygiene"]:color=Color("154a3b");draw_string_outline(f,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,Color("eef6ef"))
 draw_string(f,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color);lookup.add_label(value,p,f,font_size);bounds.append(Rect2(p-Vector2(0,font_size),Vector2(extent.x,font_size+6)))
func line(a:Vector3,b:Vector3,color:=Color("ffd078"))->void:draw_line(point(a),point(b),color,2,true)
func _draw()->void:
 bounds.clear();lookup.regions.clear()
 if not view or view.source_state.is_empty():return
 var s:Dictionary=view.source_state;var c:String=s.get("concept","");var gold:=Color("ffd078");var teal:=Color("83e0cd")
 var index:int=int(s.get("image_index",0))
 if index>0:
  if not images.has(index):images[index]=load("res://modules/review/assets/exam12/image%d.png"%index)
  var texture:Texture2D=images[index]
  var rect:=Rect2(18,105,minf(size.x*.34,400),minf(size.y*.32,290));draw_rect(rect,Color.WHITE)
  var ratio:float=minf(rect.size.x/texture.get_width(),rect.size.y/texture.get_height());var sz:=texture.get_size()*ratio
  draw_texture_rect(texture,Rect2(rect.get_center()-sz*.5,sz),false);bounds.append(rect);label(tr2("原图 %02d"%index,"Рису́нок %02d"%index),rect.position+Vector2(0,-8),gold,17)
 if c=="lcb":
  label(tr2("艏艉容积分配 → 纵向浮心","Объём по длине́ → це́нтр величины́"),point(Vector3(0,18,0)),gold)
  var center:Dictionary=view.Calc.lcb(float(s.get("shift",0)));var cp:=point(Vector3(center.xc,center.zc,0));draw_circle(cp,5,teal);label("C",cp+Vector2(8,-10),teal)
 if c in ["load","longitudinal","lightship"]:
  var v:Dictionary=view.calculation
  for i in v.rows.size():
   var r:Array=v.rows[i]
   if r[1]<=0:continue
   var p:=Vector3(float(r[2])-95,float(r[3]),-4.+float(i%2)*8.)
   if i==0:p.z=0
   var pt:=point(p);draw_circle(pt,4,gold)
   var lp:=pt+Vector2(-45,-55-35*(i%2));draw_line(pt,lp+Vector2(5,4),gold,1,true);var names:Dictionary={"空船":"Су́дно порожнём","货物":"Груз","货物1":"Груз 1","货物2":"Груз 2","储备":"Запа́сы","钢船体":"Стально́й ко́рпус","船体设备":"Обору́дование","动力装置":"СЭУ","系统":"Систе́мы","导航设备":"Навига́ция","永久压载":"Постоя́нный балла́ст"}
   label(tr2(str(r[0]),names.get(r[0],str(r[0])))+" · %.0f t"%r[1],lp,gold,18)
   if float(s.get("axis",0))!=2.:line(Vector3(-95,0,-16),Vector3(p.x,0,-16))
   if float(s.get("axis",0))!=1.:line(Vector3(p.x,0,-16),Vector3(p.x,p.y,-16))
  var gtext:="G"
  if float(s.get("axis",0))==1.:gtext="G: x = %.4f m"%v.xg
  elif float(s.get("axis",0))==2.:gtext="G: z = %.4f m"%v.zg
  label(gtext,point(Vector3(v.xg-95,v.zg,0))+Vector2(12,27),teal)
  label(tr2("艉垂线原点","Ноль у кормово́го перпендикуля́ра"),point(Vector3(-95,0,-16))+Vector2(0,25),teal,17)
 elif c in ["rooms","hygiene"]:
  for row in [["食品库","Кладова́я",Vector3(-78,18,-7)],["餐厅","Столо́вая",Vector3(-68,18,-6)],["厨房","Ка́мбуз",Vector3(-59,18,-7)],["卫生区","Санита́рная зо́на",Vector3(-78,18,7)],["卧室","Каю́ты",Vector3(-68,18,7)]]:label(tr2(row[0],row[1]),point(row[2]),teal,18)
  var p:float=clampf(float(s.get("room",0)),0.,1.);var route:Array=[Vector3(-78,16.2,-6),Vector3(-78,16.2,0),Vector3(-59,16.2,0),Vector3(-59,16.2,-6),Vector3(-59,16.2,0),Vector3(-69,16.2,0),Vector3(-69,16.2,-6)]
  var qid:String=s.get("qid","")
  if qid in ["P12_T06","P12_T30","P12_F03"]:
   var food_x:float=-59. if qid=="P12_T06" else -78.
   route=[Vector3(food_x,16.2,-6),Vector3(food_x,16.2,-1.8)]
   line(Vector3(-78,16.2,1.8),Vector3(-78,16.2,8),Color("e2b09b"))
   label(tr2("食品区与卫生区隔离","Изоля́ция пище́вой и санита́рной зон"),point(Vector3(-72,19.5,0)),gold,17)
  elif qid=="P12_T29":route=[Vector3(-69,16.2,-6),Vector3(-69,16.2,-1.8)]
  var remaining:float=p*(route.size()-1)
  for i in route.size()-1:
   var fraction:float=clampf(remaining-i,0.,1.)
   if fraction>0:line(route[i],route[i].lerp(route[i+1],fraction),teal)
  var segment:int=mini(route.size()-2,int(remaining));draw_circle(point(route[segment].lerp(route[segment+1],clampf(remaining-segment,0.,1.))),5,gold)
  if str(s.get("qid","")).begins_with("P12_C04"):label(tr2("演示座位：","Приме́р: мест ")+str(ceili(12*float(s.get("load",0)))),point(Vector3(-68,19,-6))+Vector2(0,-30),gold)
 elif c=="engine":
  label(tr2("主机","Гла́вный дви́гатель"),point(Vector3(-64,8,0)),teal);line(Vector3(-62,3,-1),Vector3(-95,3,-1));label(tr2("轴系","Валопрово́д"),point(Vector3(-83,3,-1))+Vector2(0,30),gold)
 elif c in ["sections","lines"]:
  projections(s,c)
 elif c in ["prototype","inverse","tradeoff"]:
  label(tr2("示例母型：L = 190 m，B = 26.6 m","Приме́р: L = 190 m, B = 26.6 m"),Vector2(22,140),teal)
  label("L = %.1f m   B = %.2f m"%[190.*float(s.get("scale_l",1)),26.6*float(s.get("scale_b",1))],point(Vector3(0,16,0)),gold)
  line(Vector3(-95,0,-18),Vector3(95,0,-18));line(Vector3(0,0,-13.3),Vector3(0,0,13.3))
 elif c in ["reserve","depth","forecastle"]:
  var h:float=14.89+float(s.get("depth",0));var x:=76. if c=="forecastle" else 0.
  line(Vector3(x,10.88,-14),Vector3(x,h+5*float(s.get("forecastle",0)),-14))
  label(tr2("水线 → 甲板","Ватерли́ния → па́луба"),point(Vector3(x,12.5,-14))+Vector2(8,0),teal)
  if c=="reserve":label(tr2("水线上方的水密空间","Водонепроница́емый объём вы́ше ватерли́нии"),point(Vector3(0,13,0)),gold,18)
 elif c in ["damage","flood","double","waterplane","tank"]:
  var pos:=Vector3(-40.+24.*mini(4,int(float(s.get("shift",0))*4)),9,5.9)
  if c=="double":pos=Vector3(8,1.3,-10);label(tr2("内底 / 内舷","Вну́треннее дно / борт"),point(pos),gold)
  elif c=="tank":label(tr2("舱内结构占据空间","Констру́кции занима́ют объём"),point(Vector3(12,2,-9)),gold)
  else:label(tr2("进水区域","Зато́пленный отсе́к"),point(pos),gold)
  if c=="waterplane":
   # Effective waterplane excludes the open flooded region; no damaged GM is fabricated.
   var r:=Rect2(22,410 if index>0 else 120,minf(360,size.x*.4),90);draw_rect(r,Color("39515e"));var removed:=Rect2(r.position+Vector2(80,0),Vector2(60,r.size.y));draw_rect(removed,Color("be7962"));label(tr2("有效水线面：扣除连海舱段","Действу́ющая ватерли́ния"),r.position+Vector2(0,-10),teal,18);bounds.append(r)
 elif c in ["resistance","bulb","breadth"]:
  var speed:float=float(s.get("speed",0));var amp:=.4+speed*.8
  for kind in 3:
   var poly:=PackedVector2Array()
   for j in 120:
    var x:float=60.+j*.5;var phase:float=j*.16-view.elapsed*2;var hull:float=sin(phase)*amp;var bulb:float=sin(phase+PI*speed)*amp*.65*float(s.get("bulb",0));var y:float=hull if kind==0 else (bulb if kind==1 else hull+bulb)
    poly.append(point(Vector3(x,10.9+y,-18.-kind*5)))
   draw_polyline(poly,teal if kind==1 else (Color("e2eeee") if kind==2 else gold),2,true)
  label(tr2("波形关系示意","Схе́ма волн"),point(Vector3(90,14,-23)),gold,18)
func projections(s:Dictionary,concept:String)->void:
 var shape:Dictionary={}
 for k in ["bilge","bow_v","waterline","bulb","scale_l","scale_b","scale_t"]:shape[k]=s.get(k,0 if k in ["bilge","bow_v","waterline","bulb"] else 1.)
 shape.drawing=s.get("drawing",false)
 if shape!=geometry_key:
  geometry_key=shape;vertices=Geo.vertices(shape).duplicate()
  if s.get("drawing",false):
   for i in vertices.size():vertices[i].x=view.Calc.drawing_x(vertices[i].x)
 if concept=="sections":
  view.Calc.lcb(0.)
  var chart:=Rect2(30,130,minf(600,size.x*.55),180);draw_rect(chart.grow(16),Color(.05,.12,.16,.94));bounds.append(chart.grow(18))
  var points:=PackedVector2Array()
  for p:Vector3 in view.Calc.section_profile:points.append(chart.position+Vector2((p.x+100)/200.,1.-p.y/320.)*chart.size)
  draw_polyline(points,Color("83dfcf"),2.4,true)
  label("A(x) / m²",chart.position-Vector2(0,8),Color("ffd078"),18);label("x / m",chart.end+Vector2(-45,24),Color("ffd078"),18)
  var x:float=lerpf(-70,70,float(s.get("scan",0)));var at:float=chart.position.x+(x+100)/200.*chart.size.x;draw_line(Vector2(at,chart.position.y),Vector2(at,chart.end.y),Color("ffd078"),2,true)
  var poly:Array=Geo.section(s,x)
  for j in poly.size():line(poly[j],poly[(j+1)%poly.size()],Color("ffd078"))
  label("A(x)",point(Vector3(x,15,0)),Color("ffd078"))
  return
 var n:int=Geo.geometry().ring_size;var rect:=Rect2(20,110,size.x-40,minf(245,size.y*.28));draw_rect(rect,Color(.05,.12,.16,.94));bounds.append(rect)
 for projection in 3:
  var box_:Rect2=Rect2(rect.position+Vector2(projection*rect.size.x/3+12,30),Vector2(rect.size.x/3-24,rect.size.y-45))
  label(tr2(["侧面","半宽","横剖面"][projection],["Бок","Полуширота́","Ко́рпус"][projection]),box_.position-Vector2(0,6),Color("ffd078"),17)
  for ring in [0,4,8,12,24,32,40,52,64,72,80,87]:
   var poly:=PackedVector2Array()
   for j in n+1:
    var p:Vector3=vertices[ring*n+j%n];var extent:float=150. if s.get("drawing",false) else 200.;var v:=Vector2((p.x+extent/2)/extent,1.-p.y/17)
    if projection==1:v=Vector2((p.x+extent/2)/extent,1.-absf(p.z)/16)
    if projection==2:
     if (ring>24 and p.z<0) or (ring<24 and p.z>0):continue
     v=Vector2(.5+p.z/32,1.-p.y/17)
    poly.append(box_.position+v*box_.size)
   draw_polyline(poly,Color("83dfcf"),1.3,true)
 # Longitudinal traces complete the side and half-breadth views; sections alone are vertical stripes.
 for projection in 2:
  var box_:Rect2=Rect2(rect.position+Vector2(projection*rect.size.x/3+12,30),Vector2(rect.size.x/3-24,rect.size.y-45))
  for j in range(0,n,maxi(1,n/8)):
   var poly:=PackedVector2Array()
   for ring in int(Geo.geometry().ring_count):
    var p:Vector3=vertices[ring*n+j];var extent:float=150. if s.get("drawing",false) else 200.
    var v:=Vector2((p.x+extent/2)/extent,1.-p.y/17) if projection==0 else Vector2((p.x+extent/2)/extent,1.-absf(p.z)/16)
    poly.append(box_.position+v*box_.size)
   draw_polyline(poly,Color("85c3b9"),1.3,true)
 if s.get("drawing",false):
  for ring in [8,12,20,28,32,40,60,80]:
   for j in n:line(vertices[ring*n+j],vertices[ring*n+(j+1)%n],Color("dcb76d"))
 if concept=="sections":
  var x:float=lerpf(-70,70,float(s.get("scan",0)));var poly:Array=Geo.section(s,x)
  for j in poly.size():line(poly[j],poly[(j+1)%poly.size()],Color("ffd078"))
  label("A(x)",point(Vector3(x,15,0)),Color("ffd078"))
 if str(s.get("qid",""))=="P12_D01":
  for item in [[-75.,-15.,"60 m"],[-15.,22.5,"37.5 m"],[22.5,75.,"52.5 m"]]:
   line(Vector3(item[0],0,-18),Vector3(item[1],0,-18));label(item[2],point(Vector3((item[0]+item[1])*.5,0,-18))+Vector2(0,26),Color("ffd078"))
