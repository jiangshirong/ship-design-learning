extends "res://view/latex_panel.gd"
const Source=preload("res://view/source_style.gd")
var source_rows:Dictionary={}
var source_condition:=""
var source_blocks:Array=[]
func _init()->void:
	super._init();layout_inset=12
func arrange()->void:
	super.arrange()
	source_blocks.clear()
	var offset:=0.0
	var index:=0
	while index<rows.size():
		var key:=str(index)
		if not source_rows.has(key):
			for item in drawings:
				if item.row==index:item.rect.position.y+=offset
			index+=1;continue
		var first:=index
		var last:=index
		while source_rows.has(str(last+1)):last+=1
		var top:=INF;var bottom:=0.0
		var extra:=10.0+(30.0 if not source_condition.is_empty() else 0.0)
		for item in drawings:
			if item.row>=first and item.row<=last:
				top=minf(top,item.rect.position.y);bottom=maxf(bottom,item.rect.end.y)
				item.rect.position.y+=offset+extra
		if top!=INF:
			source_blocks.append({"rect":Rect2(0,top+offset,size.x,bottom-top+extra+12),"rule":source_rows[key]})
		offset+=extra+12
		index=last+1
	# Rebuild exact symbol regions after shifting, so source tags never displace lookup.
	hint_regions.clear()
	for drawing in drawings:
		for h in bundle.assets[drawing.asset].get("hints",[]):
			var r:Array=h.rect
			hint_regions.append({"rect":Rect2(drawing.rect.position+Vector2(r[0],r[1]),Vector2(r[2],r[3])),"text":h.text})
	custom_minimum_size.y+=offset
	queue_redraw()
func _draw()->void:
	for block in source_blocks:
		var style:=StyleBoxFlat.new();style.bg_color=Color("2b2941");style.border_color=Color("bda5f5");style.border_width_left=3;style.set_corner_radius_all(8)
		draw_style_box(style,block.rect)
		if not source_condition.is_empty():draw_string(get_theme_font("font"),block.rect.position+Vector2(12,23),source_condition,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d8c9fa"))
	super._draw()
func _get_tooltip(at:Vector2)->String:
	return super._get_tooltip(at)
func _make_custom_tooltip(value:String)->Object:
	return super._make_custom_tooltip(value)
