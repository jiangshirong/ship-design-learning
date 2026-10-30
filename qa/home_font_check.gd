extends "res://modules/review/qa/sample_check.gd"
func start(host)->void:
	app=host;await frames(12)
	var map=host.home_map
	var font:SystemFont=map.theme.default_font
	check(font.multichannel_signed_distance_field and font.msdf_size==128,"Zoomable high resolution MSDF map font")
	check(host.review_buttons.get_child_count()==2,"Two home entries")
	check(host.review_buttons.get_child(0).text=="题目","Question label")
	check(host.review_buttons.get_child(1).text=="科学复习","Scientific label")
	var id:String=map.cards.keys()[1]
	var centre:Vector2=map.cards[id].position+map.cards[id].size*.5
	for lang in ["zh","ru"]:
		map.set_language(lang)
		for factor in [1.0,2.0,4.0]:
			map.view.zoom_at(factor,map.view.size*.5);map.view.center_on(centre);await frames(8)
			check(map.captions[id].get_theme_font("font")==font,"Node inherits scalable font "+lang+str(factor))
			await capture("home-font-"+lang+"-"+str(factor))
	map.set_language("zh");map.view.zoom_at(2,map.view.size*.5);map.view.center_on(centre);await frames(5)
	var point:Vector2=map.view.global_position+map.view.pan+centre*map.view.zoom
	await click(point);await frames(8)
	check(host.mode=="lesson","Zoomed chapter still opens")
	tap(KEY_ESCAPE);await frames(4)
	check(host.mode=="home","Esc returns to updated home")
	host.get_window().size=Vector2i(1100,760);await frames(8)
	map.view.fit_content();await frames(5);await capture("home-font-minimum")
	var failed:=results.filter(func(r):return not r.passed).size()
	var f:=FileAccess.open("res://qa/home-font.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"\t"));f.close()
	print("HOME FONT ",results.size()," checks; failures ",failed)
	get_tree().quit(1 if failed else 0)
