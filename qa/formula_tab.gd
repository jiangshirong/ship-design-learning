extends "res://modules/review/qa/sample_check.gd"
func exercise(page,label_:String)->void:
	var before:bool=page.drawer_open
	tap(KEY_TAB);await frames(2)
	check(page.drawer_open!=before,label_+" Tab opens")
	var repeat:=InputEventKey.new();repeat.physical_keycode=KEY_TAB;repeat.pressed=true;repeat.echo=true
	app.get_viewport().push_input(repeat,true);await frames(2)
	check(page.drawer_open!=before,label_+" held key does not toggle repeatedly")
	tap(KEY_TAB);await frames(2)
	check(page.drawer_open==before,label_+" Tab closes")
func start(host)->void:
	app=host
	await host.open_course("foundation")
	host.jump_to_step(host.player.beats.size()-1)
	await frames(4)
	if host.layout_tween and host.layout_tween.is_valid():host.layout_tween.custom_step(2)
	host.layout()
	await frames(3);check(host.formula_toggle.is_visible_in_tree(),"Original formula entry available")
	await exercise(host,"Original course")
	await host.open_bulkheads();await frames(3)
	for i in host.bulkheads.player.beats.size():
		host.bulkheads.jump_index(i)
		if host.bulkheads.formula_toggle.is_visible_in_tree():break
	await frames(3);check(host.bulkheads.formula_toggle.is_visible_in_tree(),"Bulkhead formula entry available")
	await exercise(host.bulkheads,"Bulkheads")
	host.show_home();host.open_review("reading");host.review.open_topic("freeboard");await frames(6)
	var page=host.review.stability
	for i in page.player.beats.size():
		page.goto_index(i)
		if page.formula_toggle.is_visible_in_tree():break
	await frames(3);check(page.formula_toggle.is_visible_in_tree(),"Topic formula entry available")
	await exercise(page,"Topic")
	host.show_home();var before:bool=page.drawer_open
	tap(KEY_TAB);await frames(2)
	check(page.drawer_open==before,"Hidden topic ignores Tab")
	var f:=FileAccess.open("res://qa/formula-tab.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close()
	get_tree().quit()
