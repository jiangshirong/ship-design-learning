extends RefCounted
static func make()->Theme:
	var theme:=Theme.new()
	var font:=SystemFont.new();font.font_names=PackedStringArray(["Arial","Microsoft YaHei"])
	theme.default_font=font;theme.default_font_size=20
	for type in ["Label","Button","OptionButton","Tree"]:theme.set_color("font_color",type,Color("ecf1ef"))
	theme.set_stylebox("panel","TooltipPanel",StyleBoxEmpty.new())
	for state in ["normal","hover","pressed","focus","disabled"]:
		var box:=StyleBoxFlat.new();box.bg_color=Color("294a54" if state in ["normal","disabled"] else "42606b");box.set_corner_radius_all(8)
		box.content_margin_left=16;box.content_margin_right=16;box.content_margin_top=12;box.content_margin_bottom=12
		for type in ["Button","OptionButton"]:theme.set_stylebox(state,type,box)
	return theme
