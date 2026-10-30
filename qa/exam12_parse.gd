extends SceneTree
func _initialize()->void:
 for p in ["res://modules/review/module.gd","res://modules/review/view/exam12_ship.gd","res://modules/review/view/exam12_overlay.gd","res://main.gd"]:print("LOAD ",p,": ",load(p))
 quit()
