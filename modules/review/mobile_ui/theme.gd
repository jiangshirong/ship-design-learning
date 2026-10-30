extends RefCounted
static func box(bg:String,border:String="e3dfd3",radius:int=16)->StyleBoxFlat:
 var b:=StyleBoxFlat.new();b.bg_color=Color(bg);b.border_color=Color(border);b.set_border_width_all(1);b.set_corner_radius_all(radius)
 b.content_margin_left=20;b.content_margin_right=20;b.content_margin_top=18;b.content_margin_bottom=18
 return b
static func make()->Theme:
 var font:FontFile=load("res://modules/review/mobile_ui/fonts/NotoSans-Regular.ttf")
 font.fallbacks=[load("res://modules/review/mobile_ui/fonts/NotoSansCJKsc-Regular.otf")]
 var t:=Theme.new();t.default_font=font;t.default_font_size=18
 for type in ["Label","RichTextLabel","Button","OptionButton","Tree"]:
  t.set_color("font_color",type,Color("273d36"));t.set_color("default_color",type,Color("273d36"))
 for state in ["font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:t.set_color(state,"Button",Color("285b52"))
 t.set_color("font_disabled_color","Button",Color("506158"))
 for type in ["Button","OptionButton"]:
  for state in ["normal","hover","pressed","hover_pressed","focus","disabled"]:
   var bg:String={"normal":"fffefa","hover":"edf2e9","pressed":"dce9dd","hover_pressed":"dce9dd","focus":"edf2e9","disabled":"eeeae1"}[state]
   var b:=box(bg,"dedfd4",12);b.content_margin_top=10;b.content_margin_bottom=10;b.content_margin_left=14;b.content_margin_right=14;t.set_stylebox(state,type,b)
 return t
static func primary(b:Button)->void:
 for s in ["normal","hover","pressed","hover_pressed","focus"]:
  var style:=box("1f514a" if s in ["pressed","hover_pressed"] else "285b52","285b52",12);style.content_margin_top=10;style.content_margin_bottom=10;b.add_theme_stylebox_override(s,style)
 for s in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:b.add_theme_color_override(s,Color.WHITE)
