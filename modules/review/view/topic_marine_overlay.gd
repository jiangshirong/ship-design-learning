extends Control
var view
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func label(text:String,at:Vector2,color:Color)->void:
	draw_string(get_theme_default_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,22,color)
func _draw()->void:
	if not view or view.source_state.is_empty():return
	var s:Dictionary=view.source_state
	var teal:=Color("71dacc");var gold:=Color("ffd078")
	var body:Node3D=view.bodies[0]
	if s.get("topic")=="freeboard":
		if s.get("phase","") in ["superstructure","bow_waves","flare"]:return
		if s.get("phase","")=="bow":
			var top3:Vector3=body.to_global(view.bow_deck_point())
			var top:Vector2=view.project(top3)
			var level:Vector2=view.project(Vector3(top3.x,0,top3.z))
			draw_line(top,level,gold,3,true)
			for p in [top,level]:draw_line(p-Vector2(8,0),p+Vector2(8,0),gold,2,true)
			var caption:String=view.tr2("艏部高度","Высота́ в носу́")
			var text_width:float=get_theme_default_font().get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x
			var label_at:=top.lerp(level,.5)+Vector2(12,0)
			label_at.x=clampf(label_at.x,12,size.x-text_width-12)
			label(caption,label_at,gold)
			return
		var deck:Vector2=view.project(body.to_global(Vector3(0,14.89,-13.3)))
		var baseline:Vector2=view.project(body.to_global(Vector3(0,0,-13.3)))
		var water:Vector2=view.project(Vector3(0,0,-13.3))
		draw_line(deck,water,gold,4,true);draw_line(water,baseline,teal,3,true)
		for p in [deck,water,baseline]:draw_line(p-Vector2(8,0),p+Vector2(8,0),gold,2,true)
		label("F",deck.lerp(water,.5)+Vector2(12,0),gold);label("T",baseline.lerp(water,.5)+Vector2(12,0),teal)
	else:
		if s.get("phase")=="G":label("G",view.project(view.marker.global_position)+Vector2(10,-10),gold)
		if s.get("phase")=="opening":
			var a:Vector2=view.project(view.opening.global_position)
			label(view.tr2("开口","Отве́рстие"),a+Vector2(10,-10),Color("ff907d"))
