extends VBoxContainer
# Original images remain separate from teacher questions. Zoom never stretches them.
var pictures:Array=[]
var current:=0
var texture:TextureRect
var caption:Label
var zoom:Window
var tags
var metadata:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/exam12/picture_labels.json"))
func setup(values:Array)->void:
	pictures=values;size_flags_horizontal=SIZE_EXPAND_FILL
	var row:=HBoxContainer.new();add_child(row)
	caption=Label.new();caption.size_flags_horizontal=SIZE_EXPAND_FILL;caption.add_theme_color_override("font_color",Color("304b42"));row.add_child(caption)
	for item in [["上一图",-1],["下一图",1]]:
		var b:=Button.new();b.text=item[0];row.add_child(b);b.visible=values.size()>1;b.pressed.connect(func():current=posmod(current+int(item[1]),pictures.size());refresh())
	var enlarge:=Button.new();enlarge.text="放大原图";row.add_child(enlarge);enlarge.pressed.connect(open_zoom)
	texture=TextureRect.new();texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;texture.custom_minimum_size=Vector2(0,320);add_child(texture)
	tags=preload("res://modules/review/view/exam_picture_tags.gd").new();tags.texture=texture;texture.add_child(tags);tags.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);texture.resized.connect(tags.queue_redraw);refresh()
func refresh()->void:
	var p:Dictionary=pictures[current];texture.texture=load(p.path);caption.text="原图 %02d · %d / %d"%[p.number,current+1,pictures.size()]
	tags.tags=metadata.get(str(int(p.number)),[]);tags.queue_redraw()
func open_zoom()->void:
	if is_instance_valid(zoom):zoom.queue_free()
	zoom=Window.new();zoom.title=caption.text;zoom.size=Vector2i(1100,780);zoom.min_size=Vector2i(500,380);add_child(zoom)
	if "--qa" in OS.get_cmdline_user_args():zoom.set_flag(Window.FLAG_NO_FOCUS,true)
	var bg:=ColorRect.new();bg.color=Color.WHITE;zoom.add_child(bg);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sc:=ScrollContainer.new();zoom.add_child(sc);sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var image:=TextureRect.new();image.texture=texture.texture;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.custom_minimum_size=Vector2(texture.texture.get_size())*1.6;sc.add_child(image)
	var zoom_tags=preload("res://modules/review/view/exam_picture_tags.gd").new();zoom_tags.texture=image;zoom_tags.tags=tags.tags;image.add_child(zoom_tags);zoom_tags.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.resized.connect(zoom_tags.queue_redraw)
	zoom.close_requested.connect(func():zoom.queue_free())
	if "--qa" in OS.get_cmdline_user_args():zoom.position=Vector2i(-6000,-6000);zoom.show()
	else:zoom.popup_centered()
func _exit_tree()->void:
	if is_instance_valid(zoom):zoom.queue_free()
