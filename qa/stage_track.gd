extends "res://modules/review/qa/sample_check.gd"
func start(host)->void:
	app=host;host.open_review("reading");host.review.open_topic("damage");await frames(15)
	var page=host.review.stability;page.language="zh";page.labels();await frames(5)
	var bar=page.phase_menu
	check(not bar is OptionButton and bar.item_count==page.course.groups.size(),"All stages use linear track")
	await click(bar.global_position+Vector2(bar.cell_width*3.5,40));await frames(8)
	check(page.active_group==3,"Clicking stage label jumps to its first beat")
	await RenderingServer.frame_post_draw;host.get_viewport().get_texture().get_image().save_png("res://qa/stage-track.png")
	page.toggle_language();await frames(6)
	check(bar.selected==3,"F2 preserves selected stage")
	host.get_window().size=Vector2i(1100,760);await frames(6)
	bar.select(bar.item_count-1);await frames(4)
	check(bar.cell_width*bar.item_count-bar.scroll_horizontal<=bar.size.x+2,"Long stages remain reachable in minimum window")
	var out:=FileAccess.open("res://qa/stage-track.json",FileAccess.WRITE);out.store_string(JSON.stringify(results,"  "));out.close();get_tree().quit()

