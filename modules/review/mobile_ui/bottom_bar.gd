extends Control
signal selected(tab:String)
const TABS=["题目","词汇","科学复习"]
var buttons:Array=[]
var indicator:ColorRect
var motion:Tween
var current:=0
var bottom_inset:=8
func _ready()->void:
 var bg:=ColorRect.new();bg.color=Color("fffdf8");bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(bg);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var rule:=ColorRect.new();rule.color=Color("dedfd4");rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(rule);rule.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);rule.offset_bottom=1
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",0);add_child(row);row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);row.offset_bottom=-bottom_inset
 for title in TABS:
  var b:=Button.new();b.text=title;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",18)
  for state in ["normal","hover","pressed","focus"]:b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
  for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:b.add_theme_color_override(state,Color("859087"))
  row.add_child(b);buttons.append(b);b.pressed.connect(func():selected.emit(title))
 indicator=ColorRect.new();indicator.color=Color("285b52");indicator.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(indicator)
 resized.connect(func():select(TABS[current],false));select(TABS[0],false)
func select(tab:String,animated:=true)->void:
 var next:int=TABS.find(tab)
 if next<0 or not indicator:return
 for i in buttons.size():
  for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:buttons[i].add_theme_color_override(state,Color("285b52" if i==next else "859087"))
 var section:float=size.x/3.;indicator.size=Vector2(maxf(1,section-48),3);var target:=Vector2(section*next+24,0)
 if next==current and indicator.position.is_equal_approx(target):return
 current=next
 if motion and motion.is_valid():motion.kill()
 if animated:motion=create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);motion.tween_property(indicator,"position",target,.24)
 else:indicator.position=target
