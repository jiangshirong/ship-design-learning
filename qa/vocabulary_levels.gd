extends "res://modules/review/qa/sample_check.gd"
func start(target)->void:
	app=target.review;target.open_review("vocabulary");await frames(10)
	var page=app.vocabulary
	page.path="user://review/qa-vocabulary-test-"+str(OS.get_process_id())+".json";page.marks={};page.schedule={}
	check(page.menu.visible and not page.card.visible,"Two-entry menu first")
	await capture("vocabulary-menu")
	var total:=0
	for category_index in 2:
		await click(page.menu.get_child(category_index).get_global_rect().get_center());await frames(8)
		check(page.category==["单词","词组"][category_index],"Actual category entry")
		total+=page.entries.size()
		for entry in page.entries:check(entry.ru.contains(" ")==bool(category_index),"Separate entry "+entry.id)
		check(not page.revealed and page.chinese.text.is_empty(),"Chinese initially hidden")
		tap(KEY_SPACE);await frames(3);check(not page.chinese.text.is_empty(),"Reveal Chinese")
		var id:String=page.entries[page.index].id
		for i in 4:
			id=page.entries[page.index].id
			tap(KEY_1+i);await frames(3)
			check(page.marks[id]==page.LEVELS[i],"Four grade buttons "+str(i))
			check(page.entries[page.index].id!=id and not page.revealed,"Mark advances and hides answer")
		var data=JSON.parse_string(FileAccess.get_file_as_string(page.path))
		check(data.marks[id]=="完全不会","Saved grade")
		page.marks={};page.schedule={};page.load_marks();check(page.marks[id]=="完全不会","Reload grade")
		page.filter.select(5);page.filter.item_selected.emit(5);await frames(4)
		check(page.entries.all(func(e):return page.marks.get(e.id)=="完全不会"),"Grade filter")
		page.filter.select(2);page.filter.item_selected.emit(2);await frames(4)
		check(page.entries.all(func(e):return page.marks.get(e.id)=="已掌握"),"Mastered filter")
		page.filter.select(0);page.filter.item_selected.emit(0);await frames(4)
		target.get_window().size=Vector2i(1100,760);await frames(8)
		check(page.get_global_rect().end.y<=760,"Fits minimum height")
		await capture("vocabulary-category-"+str(category_index))
		tap(KEY_ESCAPE);await frames(5);check(page.category.is_empty() and page.menu.visible,"Esc back to category menu")
	check(total==page.all_entries.size(),"All existing study items retained")
	tap(KEY_ESCAPE);await frames(4);check(target.mode=="home","Second Esc unified home")
	var bad_path:String=page.path+"-bad";var f:=FileAccess.open(bad_path,FileAccess.WRITE);f.store_string("broken");f.close()
	page.path=bad_path;page.load_marks();check(page.blocked and not page.save_marks(),"Corrupt progress preserved")
	var out:=FileAccess.open("res://qa/vocabulary-levels.json",FileAccess.WRITE);out.store_string(JSON.stringify(results,"\t"));out.close()
	print("VOCABULARY ",results.size()," checks; failures ",results.filter(func(r):return not r.passed).size());get_tree().quit()
