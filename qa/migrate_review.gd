extends SceneTree
func _initialize()->void:
	var report:Dictionary=preload("res://modules/review/core/migration.gd").run()
	var f:=FileAccess.open("res://qa/review-migration.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("Review migration: ",report)
	quit(0 if report.errors.is_empty() else 1)
