extends Control
# One scrollable list, with cached text layout and painting limited to the
# visible rows. Switching kinds no longer constructs thousands of UI nodes.
signal activated(id: String)
const Icons = preload("res://modules/review/mobile_ui/ui_icons.gd")
const LEVELS = ["已掌握","认识","不熟","完全不会"]
static var paragraph_cache: Dictionary = {}
static var cache_shape := ""
var entries: Array = []
var marks: Dictionary = {}
var rows: Dictionary = {}
var layout: Array = []
var font_size := 22
var layout_width := -1.0
var scroller: ScrollContainer
var armed := false
var touch_index := -1
var pressed_id := ""
var origin := Vector2.ZERO
var normal: StyleBoxFlat
var pressed: StyleBoxFlat
var drawn_rows := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS; size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in [false, true]:
		var style := StyleBoxFlat.new(); style.bg_color = Color("e3ece1" if state else "fffefa")
		style.border_color = Color("e3dfd3"); style.set_border_width_all(1); style.set_corner_radius_all(14)
		if state: pressed = style
		else: normal = style
	var parent := get_parent()
	while parent and not parent is ScrollContainer: parent = parent.get_parent()
	scroller = parent
	if scroller: scroller.get_v_scroll_bar().value_changed.connect(func(_value): queue_redraw())
	resized.connect(func():
		if not is_equal_approx(layout_width, size.x): rebuild())

func set_entries(values: Array, grades: Dictionary, text_size: int) -> void:
	entries = values; marks = grades; font_size = text_size
	if size.x > 0: rebuild()

func rebuild() -> void:
	layout_width = size.x
	if layout_width <= 0: return
	var font := get_theme_default_font()
	var text_width := maxf(20, layout_width - 62)
	var shape := str(font.get_instance_id()) + ":" + str(font_size) + ":" + str(text_width)
	if cache_shape != shape: paragraph_cache.clear(); cache_shape = shape
	rows.clear(); layout.clear()
	var top := 0.0
	for entry in entries:
		var text: TextParagraph = paragraph_cache.get(entry.id)
		if text == null:
			text = TextParagraph.new(); text.width = text_width
			text.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
			text.add_string(entry.ru, font, font_size); paragraph_cache[entry.id] = text
		var height := maxf(70, ceilf(text.get_size().y) + 28)
		var row := {"id":entry.id, "top":top, "height":height, "paragraph":text}
		layout.append(row); rows[entry.id] = row; top += height + 8
	custom_minimum_size.y = maxf(0, top - 8); queue_redraw()

func row_rect(id: String) -> Rect2:
	var row: Dictionary = rows[id]
	return Rect2(global_position + Vector2(0, row.top), Vector2(size.x, row.height))

func _draw() -> void:
	drawn_rows = 0
	if not scroller: return
	var visible_top := maxf(0, scroller.global_position.y - global_position.y)
	var visible_bottom := visible_top + scroller.size.y
	for row in layout:
		if row.top + row.height < visible_top: continue
		if row.top > visible_bottom: break
		drawn_rows += 1
		draw_style_box(pressed if armed and row.id == pressed_id else normal, Rect2(0, row.top, size.x, row.height))
		row.paragraph.draw(get_canvas_item(), Vector2(14, row.top + (row.height - row.paragraph.get_size().y) / 2), Color("273d36"))
		var index: int = LEVELS.find(marks.get(row.id, ""))
		var texture := Icons.texture(Icons.GRADE_ICONS[index] if index >= 0 else "circle-dashed")
		draw_texture_rect(texture, Rect2(size.x - 36, row.top + (row.height - 22) / 2, 22, 22), false, Color(Icons.GRADE_COLORS[index] if index >= 0 else "7c897e"))

func id_at(point: Vector2) -> String:
	for row in layout:
		if point.y >= row.top and point.y < row.top + row.height: return row.id
	return ""

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCROLL_BEGIN:
		armed = false; queue_redraw()

func release(point: Vector2, canceled: bool = false) -> void:
	var choose := armed and not canceled and origin.distance_to(point) <= 10 and id_at(point) == pressed_id
	armed = false; queue_redraw()
	if choose and not pressed_id.is_empty(): activated.emit(pressed_id)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index; origin = event.position; pressed_id = id_at(origin); armed = true; queue_redraw()
		elif not event.pressed and event.index == touch_index:
			touch_index = -1; release(event.position, event.canceled)
	elif event is InputEventScreenDrag and event.index == touch_index:
		if origin.distance_to(event.position) > 10: armed = false; queue_redraw()
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			origin = event.position; pressed_id = id_at(origin); armed = true; queue_redraw()
		else: release(event.position)
	elif event is InputEventMouseMotion and armed and origin.distance_to(event.position) > 10:
		armed = false; queue_redraw()
