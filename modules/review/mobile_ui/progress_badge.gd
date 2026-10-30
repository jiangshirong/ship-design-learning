extends Control
var current := 1
var total := 1
var fill := Color("e8eee6")
var ink := Color("1f514a")

func _ready() -> void:
	custom_minimum_size = Vector2(94, 45); size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_progress(value: int, count: int) -> void:
	if current == value and total == maxi(count, 1): return
	current = value; total = maxi(count, 1); queue_redraw()

func _draw() -> void:
	var pill := StyleBoxFlat.new(); pill.bg_color = fill; pill.set_corner_radius_all(13)
	draw_style_box(pill, Rect2(Vector2.ZERO, size))
	var font := get_theme_default_font()
	draw_string(font, Vector2(12, 25), "%02d" % current, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, ink)
	draw_string(font, Vector2(43, 24), "/ %02d" % total, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(ink, 0.65))
	draw_line(Vector2(12, 35), Vector2(size.x - 12, 35), Color(ink, 0.12), 3, true)
	var progress := clampf(float(current) / total, 0, 1)
	draw_line(Vector2(12, 35), Vector2(12 + (size.x - 24) * progress, 35), ink, 3, true)
