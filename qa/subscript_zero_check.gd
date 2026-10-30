extends RefCounted
func run(host)->void:
 var backdrop:=ColorRect.new();backdrop.color=Color("fffdf8");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);host.add_child(backdrop)
 var field=load("res://modules/review/view/notation_text.gd").new();field.theme=load("res://modules/review/mobile_ui/theme.gd").make();backdrop.add_child(field)
 field.position=Vector2(100,150);field.size=Vector2(1000,250);field.add_theme_font_size_override("font_size",40);field.add_theme_color_override("font_readonly_color",Color("273d36"));field.set_content("P_0, x_0, z_0; P0, D₁; p_сэу; h/B")
 field.set_meta("word_grade_ranges",[{"start":0,"end":2},{"start":24,"end":25}]);field.syntax_highlighter.clear_highlighting_cache()
 for i in 12:await host.get_tree().process_frame
 await RenderingServer.frame_post_draw
 host.get_viewport().get_texture().get_image().save_png("res://qa/subscript-zero.png")
 var ink:Dictionary=field.syntax_highlighter.get_line_syntax_highlighting(0)
 var ok:bool=ink[1].color.a<.01 and not ink.has(2)
 var columns:Array=ink.keys();var sorted_columns:Array=columns.duplicate();sorted_columns.sort();ok=ok and columns==sorted_columns
 for span in field.notation.spans(field.text):
  if span.get("native_subscript",false):continue
  for boundary in ink:
   if boundary>span.start+1 and boundary<span.end:ok=false
 print("SUBSCRIPT ZERO ","PASS" if ok else "FAIL")
 host.get_tree().quit(0 if ok else 1)
