extends Button
const Icons = preload("res://modules/review/mobile_ui/ui_icons.gd")
var caption := ""
var icon_name := ""
var ink := Color("1f514a")
var fill := Color("edf2ec")
var selected := false
var vertical := false
var pill := false
var compact := false
var dense := false
var dense_font_size := 12
var content_root: BoxContainer

func _ready() -> void:
	text = ""; tooltip_text = caption
	custom_minimum_size.y = 68 if dense else (78 if vertical else (44 if compact else 58))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	update_style()
	var content: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	content_root = content
	add_child(content); content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10; content.offset_right = -10; content.offset_top = 8; content.offset_bottom = -8
	if dense:
		content.offset_left = 5; content.offset_right = -5; content.offset_top = 7; content.offset_bottom = -7
		content.modulate.a = 1.0
	content.alignment = BoxContainer.ALIGNMENT_CENTER; content.add_theme_constant_override("separation", 5 if vertical else 9)
	var icon := TextureRect.new(); icon.texture = Icons.texture(icon_name); icon.modulate = ink
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(23, 23) if dense else Vector2(26, 26); icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(icon)
	if not caption.is_empty():
		var label := Label.new(); label.text = caption; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", dense_font_size if dense else (14 if vertical else 16))
		label.add_theme_color_override("font_color", ink); label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)

func update_style() -> void:
	if dense and is_instance_valid(content_root): content_root.modulate.a = 1.0
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = fill if selected or state == "pressed" else fill.lightened(0.35)
		if dense and not selected and state != "pressed": style.bg_color = Color("fffefa")
		style.border_color = ink if selected else Color(ink, 0.16)
		style.set_border_width_all(2 if selected else 1)
		style.set_corner_radius_all(24 if pill else 16)
		add_theme_stylebox_override(state, style)
