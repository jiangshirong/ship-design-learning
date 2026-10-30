extends VBoxContainer
var font:SystemFont
func _init()->void:
	font=SystemFont.new();font.font_names=PackedStringArray(["Cambria Math","Segoe UI","Microsoft YaHei"])
func label(text:String,size_:int=23)->Control:
	var l=preload("res://view/math_text.gd").new();l.base_size=size_;l.intrinsic_width=true;l.set_content(text);return l
func show_expression(expression:Array)->void:
	for child in get_children():remove_child(child);child.queue_free()
	if expression.is_empty():return
	var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",14);add_child(row)
	for item in expression:
		if item is Array:
			var fraction:=VBoxContainer.new();fraction.add_theme_constant_override("separation",0);fraction.add_child(label(str(item[0])));fraction.add_child(HSeparator.new());fraction.add_child(label(str(item[1])));row.add_child(fraction)
		else:
			var text:=label(str(item));text.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(text)
