extends SceneTree
func _initialize()->void:
	var domain=load("res://core/domain.gd").new()
	var file:=FileAccess.open("res://qa/formula-values.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(domain.values({})));file.close();quit()
