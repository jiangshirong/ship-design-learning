extends "res://modules/review/qa/sample_check.gd"
func shot(name_:String)->void:
	await frames(6);await RenderingServer.frame_post_draw
	app.get_viewport().get_texture().get_image().save_png("res://qa/font-fix-"+name_+".png")
func start(host)->void:
	app=host;host.lang="zh";host.show_home();await frames(12)
	var map=host.home_map
	await shot("tree")
	for z in [.75,1.0,1.25,2.0,5.0]:
		map.view.restore_view_state({"zoom":z,"center":Vector2(420,85)})
		await frames(4)
		var l:Label=map.captions.basics
		check(l.get_global_transform().get_scale().is_equal_approx(Vector2.ONE),"Native glyph scale at zoom "+str(z))
		check(l.get_theme_font_size("font_size")==roundi(28*z),"Screen pixel font size at zoom "+str(z))
		await shot("zoom-"+str(z))
	host.open_review("reading");var page=host.review.reading;page.select_question(14);page.reveal();await frames(10)
	await shot("question")
	check(page.question.full_text==page.current_question(),"Russian source including combining accents unchanged")
	host.open_review("scientific");var v=host.review.vocabulary
	v.path="user://review/qa-font-fix.json";v.marks={};v.schedule={};v.open_category("单词");v.reveal();await frames(5);await shot("word")
	# Same family shapes Cyrillic letters and combining acute; no CJK fallback for marks.
	var field=page.question
	var font:Font=field.get_theme_font("font")
	check(font is SystemFont and font.font_names[0]=="Arial","Russian UI uses Arial first")
	var original:String=v.russian.full_text
	v.russian.set_content("су́дно · объём · грузовмести́мость\nосто́йчивость · водоизмеще́ние")
	v.arrange();await shot("accents")
	v.russian.set_content(original)
	var out:=FileAccess.open("res://qa/font-fix-results.json",FileAccess.WRITE);out.store_string(JSON.stringify(results,"  "));out.close()
	get_tree().quit()
