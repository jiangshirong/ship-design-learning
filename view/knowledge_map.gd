extends Control
signal chapter_requested(course:String,step:String)
const PanZoom=preload("res://view/map_pan_zoom.gd")
const Canvas=preload("res://view/knowledge_canvas.gd")
var graph:Dictionary={}
var nodes_by_id:Dictionary={}
var cards:Dictionary={}
var captions:Dictionary={}
var subjects:Dictionary={}
var headings:Array=[]
var styles:Dictionary={}
var view
var canvas
var legend:Label
var current_id:=""
var hovered_id:=""
var pressed_id:=""
var language:="zh"
var label_font:SystemFont
var pixel_labels:Array=[]
func card_style(fill:String,border:String,width:int=1)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color(fill);style.border_color=Color(border);style.set_border_width_all(width);style.set_corner_radius_all(9);return style
func _ready()->void:
	# Geometry follows the map transform; labels cancel that scale and use
	# integer screen-pixel font sizes, so glyphs are never enlarged as textures.
	var map_font:=SystemFont.new();label_font=map_font
	map_font.font_names=PackedStringArray(["Arial","Microsoft YaHei"])
	map_font.multichannel_signed_distance_field=false
	map_font.oversampling=1.0
	map_font.msdf_size=128
	map_font.msdf_pixel_range=8
	var map_theme:=Theme.new();map_theme.default_font=map_font;map_theme.default_font_size=20
	map_theme.set_color("font_color","Label",Color("dce7ee"));theme=map_theme
	graph=JSON.parse_string(FileAccess.get_file_as_string("res://content/knowledge_map.json"))
	styles={"normal":card_style("1a3543","1a3543",0),"hover":card_style("294a54","42606b",1),"pressed":card_style("16394c","d2f2ff",3),"current":card_style("214d55","93ddc3",3)}
	legend=Label.new();legend.hide();add_child(legend)
	view=PanZoom.new();add_child(view)
	canvas=Canvas.new();canvas.graph=graph;view.attach(canvas,Vector2(graph.extent[0],graph.extent[1]),"height")
	view.content_clicked.connect(on_click);view.pointer_updated.connect(on_pointer)
	for region in graph.groups:
		var heading:=Label.new();heading.position=Vector2(region.rect[0]+8,region.rect[1]+12);heading.size=Vector2(region.rect[2]-16,56);heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;heading.add_theme_font_size_override("font_size",25);heading.modulate=Color("a0c5d4");heading.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(heading);headings.append(heading)
	for node in graph.nodes:
		nodes_by_id[node.id]=node
		var card:=Panel.new();card.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.size=Vector2(380,100);card.position=Vector2(node.position[0],node.position[1])-card.size*.5;canvas.add_child(card);cards[node.id]=card;canvas.cards[node.id]=card
		var caption:=Label.new();caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.position=Vector2(10,4);caption.size=card.size-Vector2(20,8);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.add_child(caption);captions[node.id]=caption
		caption.position=Vector2(22,12);caption.size=Vector2(336,40);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		var subject:=Label.new();subject.mouse_filter=Control.MOUSE_FILTER_IGNORE;subject.position=Vector2(22,60);subject.size=Vector2(336,30)
		subject.add_theme_font_size_override("font_size",16);subject.add_theme_color_override("font_color",Color("a0bac4"));card.add_child(subject);subjects[node.id]=subject
	for field in captions.values()+subjects.values()+headings:
		pixel_labels.append({"node":field,"position":field.position,"size":field.size})
	var bounds:Rect2=cards.values()[0].get_rect()
	for card in cards.values():bounds=bounds.merge(card.get_rect())
	view.fit_bounds=bounds
	resized.connect(arrange);arrange();set_language(language);refresh_feedback()
func arrange()->void:
	legend.position=Vector2(8,0);legend.size=Vector2(size.x-16,26)
	view.position=Vector2.ZERO;view.size=size
func set_language(value:String)->void:
	language=value
	legend.text="实线：前置知识　虚线：建议顺序" if value=="zh" else "Сплошна́я: основа́　Пункти́р: рекоменду́емый поря́док"
	for i in range(headings.size()):headings[i].text=graph.groups[i].title[value]
	for id in captions:
		captions[id].text=nodes_by_id[id].title[value];captions[id].add_theme_font_size_override("font_size",28 if value=="zh" else 24)
	for id in subjects:
		var n:Dictionary=nodes_by_id[id];subjects[id].text=n.get("subject",{}).get(value,"")+(" · "+n.assignment if not n.get("assignment","").is_empty() else "")
func hit_node(point:Vector2)->String:
	for id in cards:
		if cards[id].get_rect().has_point(point):return id
	return ""
func on_click(point:Vector2)->void:
	var id:=hit_node(point)
	if id.is_empty():return
	current_id=id;refresh_feedback();chapter_requested.emit(nodes_by_id[id].course,nodes_by_id[id].step)
func on_pointer(point:Vector2,pressed:bool,dragging:bool)->void:
	hovered_id="" if dragging else hit_node(point);pressed_id=hovered_id if pressed else "";refresh_feedback()
	view.mouse_default_cursor_shape=Control.CURSOR_DRAG if dragging else (Control.CURSOR_POINTING_HAND if not hovered_id.is_empty() else Control.CURSOR_ARROW)
func refresh_feedback()->void:
	for id in cards:
		var role:="current" if id==current_id else "normal"
		if id==hovered_id:role="hover"
		if id==pressed_id:role="pressed"
		cards[id].add_theme_stylebox_override("panel",styles[role]);cards[id].set_meta("visual_state",role)
func mark_current(course:String,_group:String)->void:
	var id:=course
	if not cards.has(id):
		for node in graph.nodes:
			if node.course==course:id=node.id;break
	current_id=id;refresh_feedback()

func _process(_dt:float)->void:
	if not is_visible_in_tree() or not view:return
	var z:float=maxf(view.zoom,.01)
	for item in pixel_labels:
		var field:Label=item.node
		var base_size:int=28 if language=="zh" else 24
		if field in subjects.values():base_size=16
		elif field in headings:base_size=25
		field.scale=Vector2.ONE/z
		field.add_theme_font_size_override("font_size",maxi(8,roundi(base_size*z)))
		field.size=(item.size*z).round()
		field.position=item.position
		field.global_position=field.global_position.round()
