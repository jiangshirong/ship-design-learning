extends CanvasLayer
var glossary=preload("res://modules/review/core/glossary.gd").new()
var panel:PanelContainer
var words:RichTextLabel
var owner_field:Control
var current:Dictionary={}
var cache_text:=""
var cache_spans:Array=[]
static func shared(owner:Node):
	var root=owner.get_tree().root
	var tip=root.get_node_or_null("SharedWordTooltip")
	if not tip:
		tip=load("res://modules/review/view/term_tooltip.gd").new()
		tip.name="SharedWordTooltip";root.add_child(tip)
	return tip
func _ready()->void:
	layer=30
	panel=PanelContainer.new();panel.theme=preload("res://view/focus_theme.gd").make();panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel)
	var box:=StyleBoxFlat.new();box.bg_color=Color("f2f6f9");box.set_corner_radius_all(7)
	box.content_margin_left=16;box.content_margin_right=16;box.content_margin_top=12;box.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",box)
	words=RichTextLabel.new();words.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	words.bbcode_enabled=true;words.fit_content=true;words.scroll_active=false
	words.custom_minimum_size.x=320;words.add_theme_font_size_override("normal_font_size",22);words.add_theme_font_size_override("bold_font_size",22);words.add_theme_color_override("default_color",Color("203f54"));panel.add_child(words);panel.hide()
func normalized(value:String)->String:
	return value.to_lower().replace("\u0301","").replace("\u0300","").strip_edges()
func escaped(value:String)->String:
	return value.replace("[","[lb]")
func entry_text(surface:String,entry:Dictionary)->String:
	var lemma:String=entry.ru
	var prefix:="" if normalized(surface)==normalized(lemma) else escaped(surface)+"\n"
	return prefix+"[b][color=#146b70]"+escaped(lemma)+"[/color][/b]\n"+escaped(entry.zh)
func bind(field:TextEdit)->void:
	if field.get_meta("word_tooltip_bound",false):return
	field.set_meta("word_tooltip_bound",true)
	field.gui_input.connect(func(event):
		if event is InputEventMouseMotion:
			if event.button_mask!=0:hide_tip()
			else:hover(field,event.position)
		elif event is InputEventMouseButton:hide_tip())
	field.mouse_exited.connect(hide_tip)
func hide_tip()->void:
	panel.hide();owner_field=null;current={}
func _process(_delta:float)->void:
	if not is_instance_valid(owner_field):owner_field=null;panel.hide();return
	if not owner_field.is_visible_in_tree():hide_tip()
	elif owner_field is TextEdit and owner_field.text!=cache_text:hide_tip()
func hover(field:TextEdit,point:Vector2)->void:
	if field.has_method("notation_hint"):
		var hint:String=field.notation_hint(point)
		if not hint.is_empty():
			owner_field=field;cache_text=field.text;cache_spans=glossary.spans(cache_text)
			words.text=hint;place_tip(field.global_position+point);return
	var lc:=field.get_line_column_at_pos(Vector2i(point),false,false)
	if lc.x<0 or lc.y<0:hide_tip();return
	# Use the native shaped-text hit test. Glyph-rectangle lookups can point to
	# the previous CJK cluster after switching away from combining-accent text.
	if lc.x>=field.get_line(lc.y).length():hide_tip();return
	var offset:=lc.x
	for line in lc.y:offset+=field.get_line(line).length()+1
	# Keyboard lookup also updates cache_text; always obtain spans for this field.
	cache_text=field.text;cache_spans=glossary.spans(cache_text)
	for span in cache_spans:
		if offset>=span.start and offset<span.end:
			owner_field=field;current=span.entry
			var surface:=field.text.substr(span.start,span.end-span.start)
			words.text=entry_text(surface,current)
			place_tip(field.global_position+point)
			return
	hide_tip()
func place_tip(point:Vector2)->void:
	panel.size=Vector2.ZERO;panel.reset_size();panel.show()
	var bounds:=get_viewport().get_visible_rect().size
	panel.position=(point+Vector2(14,24)).clamp(Vector2(12,12),(bounds-panel.size-Vector2(12,12)).max(Vector2(12,12)))
