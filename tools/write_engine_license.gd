extends SceneTree
func _initialize()->void:
	var file:=FileAccess.open("res://runtime/LICENSE-Godot.txt",FileAccess.WRITE)
	file.store_string(Engine.get_license_text()+"\n\nThird-party components\n"+JSON.stringify(Engine.get_copyright_info(),"\t")+"\n\nThird-party licenses\n"+JSON.stringify(Engine.get_license_info(),"\t"));file.close();quit()
