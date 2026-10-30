extends SceneTree
func _initialize()->void:
	var text:=TextEdit.new()
	for p in text.get_property_list():
		if "scroll" in p.name or "wrap" in p.name or "select" in p.name or "caret" in p.name:print(p.name)
	text.free();quit()
