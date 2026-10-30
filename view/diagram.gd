extends Control
var params:Dictionary={}
var values:Dictionary={}
var lang:="zh"
var font:SystemFont
func _ready()->void:
	font=SystemFont.new();font.font_names=PackedStringArray(["Segoe UI","Microsoft YaHei"]);mouse_filter=Control.MOUSE_FILTER_IGNORE
func update_state(p:Dictionary,v:Dictionary,l:String)->void:params=p;values=v;lang=l;queue_redraw()
func _draw()->void:
	if values.is_empty():return
	var tanker:bool=params.get("scene","")=="tanker"
	var length:float=values.L if tanker else 150.0;var h:float=values.H if tanker else 17.0
	var t:float=values.T if tanker else params.get("draft",10.0)
	var origin:=Vector2(40,size.y-35);var scale_x:float=(size.x-80)/length;var scale_y:float=(size.y-70)/(h+9)
	var end:=origin+Vector2(length*scale_x,-h*scale_y)
	draw_style_box(style(),Rect2(Vector2.ZERO,size))
	draw_line(origin,Vector2(end.x,origin.y),Color("668799"),2)
	draw_line(origin,Vector2(origin.x,end.y),Color("668799"),2)
	draw_line(Vector2(origin.x,end.y),end,Color("668799"),2)
	draw_line(end,Vector2(end.x,origin.y),Color("668799"),2)
	draw_line(origin+Vector2(0,-t*scale_y),Vector2(end.x,origin.y-t*scale_y),Color("62b8dd"),2)
	var lead:="侧视 · x 从艉垂线起算" if lang=="zh" else "Вид сбо́ку · x от кормово́го перпендикуля́ра"
	draw_string(font,Vector2(18,24),lead,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("aabfcb"))
	if params.get("show_load",false):
		for i in range(values.display_rows.size()):
			if params.get("focus_only",false) and i!=int(params.get("focus",-1)):continue
			var r:Array=values.display_rows[i];var point:=origin+Vector2(r[3]*scale_x,-r[2]*scale_y)
			draw_circle(point,5 if i!=5 else 7,Color("7dd7cc"))
			var focused:int=int(params.get("fuel_index",-1)) if params.get("show_fuel",false) else int(params.get("focus",-1))
			if i==focused:
				draw_line(point,Vector2(point.x,origin.y),Color("f4b962"),1.5)
				draw_string(font,point+Vector2(5,-10),"P",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ffe0a0"))
				draw_string(font,point+Vector2(16,-6),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ffe0a0"))
		if params.get("show_centre",true):
			var g:=origin+Vector2(values.display_xG*scale_x,-values.display_zG*scale_y)
			draw_circle(g,7,Color("ffc466"));draw_string(font,g+Vector2(10,4),"G",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("ffc466"))
	if params.get("dimensions",false):
		# Dimension lines use the same transformed physical endpoints as the hull.
		var below:float=origin.y+12
		draw_line(Vector2(origin.x,below),Vector2(end.x,below),MUTE_COLOR(),1)
		for x in [origin.x,end.x]:draw_line(Vector2(x,below-4),Vector2(x,below+4),MUTE_COLOR(),1)
		var left:float=origin.x-14
		draw_line(Vector2(left,origin.y),Vector2(left,end.y),MUTE_COLOR(),1)
		for y in [origin.y,end.y]:draw_line(Vector2(left-4,y),Vector2(left+4,y),MUTE_COLOR(),1)
		var right_x:float=end.x+12
		draw_line(Vector2(right_x,origin.y),Vector2(right_x,origin.y-t*scale_y),Color("62b8dd"),1)
		draw_string(font,Vector2(size.x*.45,size.y-12),"L₁" if tanker else "L",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
		draw_string(font,Vector2(15,(origin.y+end.y)/2),"H₁" if tanker else "H",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
		draw_string(font,Vector2(end.x+10,origin.y-t*scale_y*.5),"T₁" if tanker else "T",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("62b8dd"))
func MUTE_COLOR()->Color:return Color("668799")
func style()->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=Color("10212e");s.set_corner_radius_all(10);return s
