extends "res://modules/review/qa/sample_check.gd"
func start(host)->void:
	app=host;host.open_review("reading");await frames(8)
	var page=host.review.reading
	page.select_question(0);await frames(3)
	check(not page.page_title.visible,"Redundant title hidden")
	check(page.known_button.icon!=null and page.review_button.icon!=null,"Mark buttons reuse status icons")
	check(page.listing.visible,"Sidebar opened through real button")
	check(not page.nav_button.visible,"Navigation toggle removed")
	var initial:int=page.index
	tap(KEY_E);await frames(4)
	check(page.index!=initial and page.nav_open and page.listing.visible,"D advances without closing sidebar")
	tap(KEY_Q);await frames(4)
	check(page.index==initial and page.listing.visible,"A returns without closing sidebar")
	tap(KEY_F);await frames(4)
	await click(page.known_button.get_global_rect().get_center());await frames(3)
	var item:TreeItem=page.tree_items[page.entries[page.index].id]
	check(item.get_text(1).is_empty() and item.get_icon(1)!=null and item.get_tooltip_text(1)=="会了","Known icon replaces status copy")
	tap(KEY_E);await frames(4);tap(KEY_F);await frames(4)
	await click(page.review_button.get_global_rect().get_center());await frames(3)
	item=page.tree_items[page.entries[page.index].id]
	check(item.get_icon(1)!=null and item.get_tooltip_text(1)=="稍后再看","Review icon and meaning")
	page.store.data.marks.erase(page.entries[page.filtered[2]].id);page.rebuild_filter()
	item=page.tree_items[page.entries[page.filtered[2]].id]
	check(item.get_icon(1)!=null and item.get_tooltip_text(1)=="未标记","Unmarked icon and meaning")
	check(page.listing.visible,"Marking keeps sidebar open")
	check(page.panel.position.x>page.listing.get_rect().end.x and page.answer_panel.position.x>page.listing.get_rect().end.x,"Open sidebar does not cover question or answer")
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png("res://qa/reading-sidebar.png")
	host.get_window().size=Vector2i(1100,760);await frames(8)
	tap(KEY_E);await frames(4)
	check(page.listing.visible and page.listing.get_global_rect().end.y<760,"Sidebar persists within small window")
	check(page.panel.position.x>page.listing.get_rect().end.x,"Small window question stays beside sidebar")
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png("res://qa/reading-sidebar-small.png")
	await frames(3)
	tap(KEY_E);await frames(3)
	check(page.listing.visible,"Permanent sidebar cannot be closed")
	tap(KEY_V);await frames(20)
	check(host.review.mode=="stability","V opens question animation")
	tap(KEY_ESCAPE);await frames(8)
	check(host.review.mode=="reading","Animation Escape returns to question")
	var failed:int=results.filter(func(r):return not r.passed).size()
	var file:=FileAccess.open("res://qa/reading-sidebar.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"));file.close()
	print("Reading sidebar: ",results.size()," checks; failures=",failed)
	get_tree().quit(1 if failed else 0)
