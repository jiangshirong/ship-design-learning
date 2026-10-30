extends Control
# Formula geometry and glyphs are compiled by MathJax, never laid out as text runs.
static var bundle:Dictionary={}
var text:=""
var full_text:=""
var latex_text:=""
var popup:PopupMenu
var rows:Array=[]
var drawings:Array=[]
var textures:Dictionary={}
var formatted:Dictionary={}
var render_errors:=0
var slot_overflows:=0
var current_id:=""
var current_lang:=""
var current_signature:=""
var min_render_scale:=1.0
var active_texture_keys:Dictionary={}
var draw_count:=0
var texture_builds:=0
var hint_regions:Array=[]
var layout_inset:=0.0
func _init()->void:
	if bundle.is_empty():bundle=JSON.parse_string(FileAccess.get_file_as_string("res://content/latex_assets.json"))
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	popup=PopupMenu.new();add_child(popup);popup.add_item("复制 LaTeX / Копи́ровать LaTeX",0);popup.add_item("复制线性公式 / Копи́ровать фо́рмулу",1);popup.id_pressed.connect(copy_formula)
	resized.connect(arrange)
	visibility_changed.connect(refresh_visibility)
	get_viewport().size_changed.connect(refresh_visibility)
	var ancestor:Node=get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:
			ancestor.get_v_scroll_bar().value_changed.connect(func(_v):refresh_visibility())
			ancestor.resized.connect(refresh_visibility)
			break
		ancestor=ancestor.get_parent()
	set_process(false)
	set_notify_transform(true)
func copy_formula(id:int)->void:
	var value:String=latex_text if id==0 else text
	DisplayServer.clipboard_set(value);set_meta("copied",value)
func bind(value:String)->String:
	for key in formatted:value=value.replace("@"+key+"@",formatted[key])
	return value
func set_beat(id:String,values:Dictionary,language:String)->void:
	if popup:
		popup.set_item_text(0,"复制 LaTeX" if language=="zh" else "Копи́ровать LaTeX")
		popup.set_item_text(1,"复制线性公式" if language=="zh" else "Копи́ровать ли́нейную фо́рмулу")
	formatted=values.duplicate()
	if language=="ru":
		for key in formatted:formatted[key]=str(formatted[key]).replace(".",",")
	var next_rows:Array=bundle.lessons.get(id,{}).get(language,[])
	var lines:Array=[];var tex:Array=[]
	for row in next_rows:lines.append(bind(row.linear));tex.append(bind(row.tex))
	var signature:String=id+language+"\n".join(tex)
	if signature==current_signature:return
	current_signature=signature;current_id=id;current_lang=language;rows=next_rows
	text="\n\n".join(lines);full_text=text;latex_text="\\begin{gathered}\n"+" \\\\\n".join(tex)+"\n\\end{gathered}" if not tex.is_empty() else ""
	arrange()
func slot_paths(value:String,width:float)->String:
	var length:=0.0
	for c in value:length+=float(bundle.glyphs[c].width)
	var factor:float=minf(1.0,width/maxf(length,1))
	if factor<.999:slot_overflows+=1
	var cursor:float=maxf(0,width-length);var result:="<g transform=\"scale(%f,1)\">"%factor
	for c in value:
		result+="<g transform=\"translate(%f,0)\">%s</g>"%[cursor,bundle.glyphs[c].body];cursor+=float(bundle.glyphs[c].width)
	return result+"</g>"
func texture_for(id:String)->Texture2D:
	var asset:Dictionary=bundle.assets[id];var key:=id
	key+="|"+str(get_viewport().get_stretch_transform().get_scale())+"|"+str(get_window().content_scale_factor)
	for slot in asset.slots:key+="|"+formatted.get(slot.key,"")
	active_texture_keys[key]=true
	if textures.has(key):return textures[key]
	var svg:String=asset.svg
	for slot in asset.slots:svg=svg.replace("@@"+slot.name+"@@",slot_paths(formatted[slot.key],float(slot.width)))
	var texture:=DPITexture.create_from_string(svg,1.0);textures[key]=texture;texture_builds+=1
	if textures.size()>80:textures.erase(textures.keys()[0])
	return texture
func finish_line(items:Array,y:float)->float:
	var above:=0.0;var below:=0.0
	for item in items:above=maxf(above,item.baseline);below=maxf(below,item.height-item.baseline)
	for item in items:drawings.append({"asset":item.asset,"row":item.row,"rect":Rect2(roundf(item.x),roundf(y+above-item.baseline),item.width,item.height)})
	return y+above+below+9
func arrange()->void:
	drawings.clear();hint_regions.clear();min_render_scale=1.0
	var limit:float=maxf(120,size.x-layout_inset);var y:=0.0
	var row_index:=-1
	for row in rows:
		row_index+=1
		var items:Array=[];var x:=layout_inset
		for id in row.pieces:
			var asset:Dictionary=bundle.assets[id]
			var factor:float=1.0
			var width:float=asset.width*factor
			if x+width>limit+.1 and not items.is_empty():y=finish_line(items,y);items.clear();x=18
			items.append({"asset":id,"row":row_index,"x":x,"width":width,"height":asset.height*factor,"baseline":asset.baseline*factor});x+=width+3
		if not items.is_empty():y=finish_line(items,y)
		y+=15
	for drawing in drawings:
		for hint in bundle.assets[drawing.asset].get("hints",[]):
			var r:Array=hint.rect
			var rect:=Rect2(drawing.rect.position+Vector2(r[0],r[1]),Vector2(r[2],r[3]))
			hint_regions.append({"rect":rect,"text":hint.text})
	custom_minimum_size=Vector2(0,maxf(1,y));queue_redraw()
func _get_tooltip(at:Vector2)->String:
	# Hit the actual subscript glyphs, not the whole formula or its blank padding.
	for hint in hint_regions:
		if hint.rect.grow(2).has_point(at):return hint.text
	return ""
func _make_custom_tooltip(value:String)->Object:
	# Godot also calls this factory when _get_tooltip returns no definition.
	if value.strip_edges().is_empty():return null
	var panel:=PanelContainer.new()
	var style:=StyleBoxFlat.new();style.bg_color=Color("203a4a");style.border_color=Color("78c9c1");style.set_border_width_all(1);style.set_corner_radius_all(6)
	style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=9;style.content_margin_bottom=9
	panel.add_theme_stylebox_override("panel",style)
	var label:=Label.new();label.text=value;label.add_theme_font_override("font",get_theme_font("font"));label.add_theme_font_size_override("font_size",22);label.add_theme_color_override("font_color",Color("f3f8fc"))
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var line_width:=0.0
	for line in value.split("\n"):line_width=maxf(line_width,get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x)
	label.custom_minimum_size.x=minf(365,line_width+2)
	panel.add_child(label);return panel
func _draw()->void:
	draw_count+=1
	active_texture_keys.clear()
	var clip:Rect2=visible_region()
	for item in drawings:
		if not item.rect.intersects(clip):continue
		var texture:=texture_for(item.asset)
		if texture:draw_texture_rect(texture,item.rect,false)

func visible_region()->Rect2:
	var ancestor:Node=get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:return Rect2(ancestor.global_position-global_position,ancestor.size).grow(100)
		ancestor=ancestor.get_parent()
	return Rect2(Vector2.ZERO,size)
func refresh_visibility()->void:
	if not is_visible_in_tree() or not visible_region().intersects(Rect2(Vector2.ZERO,size)):
		if not textures.is_empty():textures.clear();queue_redraw()
		return
	queue_redraw()
func _notification(what:int)->void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and is_node_ready():refresh_visibility()
	if what==NOTIFICATION_WM_DPI_CHANGE and is_node_ready():
		textures.clear();queue_redraw()
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		popup.position=Vector2i(global_position+event.position);popup.popup();accept_event()
