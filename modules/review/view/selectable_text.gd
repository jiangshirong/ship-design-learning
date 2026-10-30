extends TextEdit
# Native selection/copy with plain text. Avoids RichTextLabel's combining-mark
# rectangle merge bug (Godot PR #123611), without stripping Russian accents.
var full_text:=""
var fit_content:=true
var visible_characters:int=-1:
	set(value):
		visible_characters=value
		text=full_text if value<0 else full_text.substr(0,value)
var measuring:=false
func _ready()->void:
	editable=false;selecting_enabled=true;drag_and_drop_selection_enabled=false
	caret_draw_when_editable_disabled=false;caret_mid_grapheme=false
	wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY;autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	scroll_past_end_of_file=false;scroll_fit_content_width=false;scroll_fit_content_height=fit_content
	var empty:=StyleBoxEmpty.new()
	for name_ in ["normal","read_only","focus"]:add_theme_stylebox_override(name_,empty)
	add_theme_color_override("font_readonly_color",Color("dce7ee"));add_theme_color_override("selection_color",Color("39727f"))
	resized.connect(measure);measure()
	preload("res://modules/review/view/term_tooltip.gd").shared(self).bind(self)
func set_content(value:String)->void:
	if value==full_text:return
	full_text=value;deselect();text=full_text if visible_characters<0 else full_text.substr(0,visible_characters);measure()
func measure()->void:
	if not is_node_ready() or measuring or not fit_content:return
	measuring=true
	var f:=get_theme_font("font");var fs:=get_theme_font_size("font_size")
	var shown:=text
	if text!=full_text:text=full_text
	var rows:int=maxi(1,get_total_visible_line_count())
	custom_minimum_size.y=rows*(f.get_height(fs)+get_theme_constant("line_spacing"))+16
	if shown!=full_text:text=shown
	measuring=false
