extends "res://qa/formal_check.gd"
func start(host)->void:
	app=host;app.lang="zh";app.build_home();await frames(10)
	await capture("approx-home")
	for id in ["approximation2","approximation3"]:
		var target:Vector2=app.home_map.cards[id].get_global_rect().get_center()
		check(app.get_global_rect().has_point(target),"Tree entry on screen "+id)
		await click_at(target);await frames(10);await settle()
		check(app.mode=="lesson" and app.course.id==id,"Actual home click opens "+id)
		tap(KEY_ESCAPE);await frames(10);check(app.mode=="home","Esc home "+id)
	var f:=FileAccess.open("res://qa/approximation-home.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"\t"));f.close()
	print("APPROXIMATION HOME ",results.size()," checks; failures ",results.filter(func(r):return not r.passed).size())
	get_tree().quit(0 if results.all(func(r):return r.passed) else 1)
