extends "res://modules/review/qa/sample_check.gd"
func start(host)->void:
	app=host;host.open_review("reading");host.review.open_topic("stability")
	var page=host.review.stability
	await frames(8)
	for i in page.player.beats.size():
		if page.player.beats[i].id=="ST:radius":page.goto_index(i);break
	page.player.complete_busy()
	if page.player.phase=="ready":page.player.finish()
	if page.ship.camera_tween and page.ship.camera_tween.is_valid():page.ship.camera_tween.custom_step(2)
	await frames(15)
	for language in ["zh","ru"]:
		if page.language!=language:page.toggle_language()
		await frames(8)
		var field=page.bubble.caption
		check(not field.symbol_regions.is_empty(),"Caption has actual subscript ink "+language)
		var span=field.notation.spans(field.full_text)
		check(span.size()==1 and span[0].suffix=="c","Recognizes Latin c in z_c "+language)
		var region:Dictionary=field.symbol_regions[0]
		check(field.notation_hint(region.sub_rect.get_center()).contains("浮心"),"Subscript hover meaning "+language)
		await RenderingServer.frame_post_draw
		host.get_viewport().get_texture().get_image().save_png("res://qa/notation-bubble-"+language+".png")
	var notation=preload("res://modules/review/core/notation.gd").new()
	check(notation.spans("h_min z_g p_сэу").size()==3,"Other lesson subscripts recognized")
	var f:=FileAccess.open("res://qa/notation-bubble.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close();get_tree().quit()
