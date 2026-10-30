extends "res://modules/review/view/speech_bubble.gd"
const Source=preload("res://view/source_style.gd")
var badge:Label
var source_active:=false
func _ready()->void:
	super._ready()
	panel.remove_child(caption)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",3);panel.add_child(column)
	badge=preload("res://view/source_label.gd").new();badge.add_theme_font_size_override("font_size",15);badge.add_theme_color_override("font_color",Color("694199"));badge.mouse_filter=Control.MOUSE_FILTER_STOP;badge.hide();column.add_child(badge);column.add_child(caption)
func set_source(b:Dictionary,language:String)->void:
	var phrase:String=b.get("source_phrase",{}).get(language,"")
	source_active=not phrase.is_empty()
	var rule:Dictionary=b.get("source_rule",{})
	badge.hide();badge.text="";badge.tooltip_text=""
	caption.set_meta("source_phrase",phrase);caption.remove_meta("source_hint") if caption.has_meta("source_hint") else null
	caption.syntax_highlighter.clear_highlighting_cache();caption.queue_redraw()
	var style:StyleBoxFlat=panel.get_theme_stylebox("panel").duplicate()
	style.border_width_left=3 if source_active else 1
	style.border_color=Color("bda5f5") if source_active else Color("b7cbd7")
	panel.add_theme_stylebox_override("panel",style)
	measurements.clear();measured_size=Vector2.ZERO
func sentence_size(sentence:String)->Vector2:
	return super.sentence_size(sentence)
func arrange()->void:
	super.arrange()
