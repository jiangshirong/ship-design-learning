extends RefCounted
var main
var checks:Array=[]
const Index=preload("res://modules/review/core/question_alphabet.gd")
func check(ok:bool,label:String)->void:
	checks.append({"check":label,"pass":ok})
	if not ok:push_error(label)
func frame()->void:await main.get_tree().process_frame
func key(code:int)->void:
	for pressed in [true,false]:
		var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;main.get_viewport().push_input(e,true)
	await frame()
func capture(name_:String)->void:
	for i in 6:await frame()
	await RenderingServer.frame_post_draw
	main.get_viewport().get_texture().get_image().save_png("res://qa/alphabet-"+name_+".png")
func find(page,id:String)->int:
	for i in page.entries.size():
		if page.entries[i].id==id:return i
	return -1
func run(host)->void:
	main=host;await frame()
	for row in [["Почему́ при измене́нии…","П"],["Почему́ в пе́рвом…","В"],["Почему́ э́пюру…","Э"],["Почему́ ёмкость…","Ё"],["В чём смысл…","В"],["Для чего́…","Д"],["Что тако́е…","Ч"],["Как определя́ется…","К"],["ПОЧЕМУ, по́сле…","П"]]:
		check(Index.info({"question_ru":row[0]}).letter==row[1],"分类规则 "+row[0])
	check(Index.rank("Е")<Index.rank("Ё") and Index.rank("Ё")<Index.rank("Ж"),"俄语字母顺序含Ё")
	main.review_buttons.get_child(1).pressed.emit();await frame();await frame()
	var module=main.review;var page=module.reading
	page.store.path="user://review/qa-alphabet-"+str(OS.get_process_id())+".json"
	page.store.data.filter="all";page.store.data.marks.clear();page.grouping="topic";page.rebuild_filter()
	page.select_question(find(page,"P13_Q07"));page.reveal();await frame()
	check(page.grouping_button.visible and page.grouping=="topic","新题左上角提供分类切换")
	var question_id:String=page.entries[page.index].id;var displayed_question:String=page.question.text;var displayed_answer:String=page.current_answer()
	page.grouping_button.pressed.emit();await frame();await frame()
	check(page.grouping=="alphabet" and page.entries[page.index].id==question_id,"按钮切换保持当前题")
	check(page.revealed and page.question.text==displayed_question and page.current_answer()==displayed_answer,"切换保持题意、答案和揭晓状态")
	check(page.tree_items.size()==page.entries.size(),"全部67问答和6识图可定位")
	var fixture:Array=["П","В","П","П","Д","П","П","В","Ч","П","П","Э","В","В","К","Д","П","В","П","Д","К","П","П","У","В","П","Р","Д","П","П"]
	for n in 30:
		var qid:String="P13_Q%02d"%(n+1)
		check(page.tree_items[qid].get_parent().get_text(0)==fixture[n],"13a人工逐题分类 "+qid)
	for i in page.entries.size():
		var q:Dictionary=page.entries[i]
		check(page.tree_items[q.id].get_metadata(0)==q.id,"保留原题ID "+q.id)
		if q.get("kind","")=="figure":check(page.tree_items[q.id].get_parent().get_text(0)=="识图","无题干识图不按助手提示句分类 "+q.id)
	var root=page.listing.get_root();var letter_group=root.get_first_child();var previous_rank:=-1
	while letter_group:
		var current_rank:int=Index.rank(letter_group.get_text(0))
		check(current_rank>=previous_rank,"字母目录排序 "+letter_group.get_text(0));previous_rank=current_rank
		var child=letter_group.get_first_child();var previous_sort:=""
		while child:
			var current_sort:String=page.alphabet_info[child.get_metadata(0)].sort
			check(previous_sort<=current_sort,"同字母内按剩余俄语题干排序 "+str(child.get_metadata(0)))
			previous_sort=current_sort;child=child.get_next()
		letter_group=letter_group.get_next()
	await capture("wide")
	main.get_window().size=Vector2i(1100,760);await capture("minimum")
	var controls:Array=[page.grouping_button,page.badge,page.source_label,page.bank_filter,page.topic_select,page.font_minus,page.font_plus]
	for i in controls.size():
		for j in range(i+1,controls.size()):check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()),"最小窗口顶部控件不重叠 %d/%d"%[i,j])
	page.topic_select.pressed.emit();await frame();await capture("minimum-directory")
	check(page.listing.visible and page.topic_select.text=="字母","窄窗口可打开字母目录")
	var first_group=page.listing.get_root().get_first_child();first_group.select(0);await frame()
	check(page.topic_selected.is_empty() and page.category(page.index)==first_group.get_text(0),"点字母进入该组第一道题")
	var group_before:String=page.category(page.index);await key(KEY_E)
	check(page.category(page.index)==group_before and not page.revealed,"字母模式E在组内切题并收起答案")
	page.reveal();page.mark("known");var known_id:String=page.entries[page.index].id
	page.bank_filter.pressed.emit();await frame()
	check(not page.tree_items.has(known_id) and page.store.data.filter=="pending","字母模式兼容待复习筛选")
	page.bank_filter.pressed.emit();await frame()
	var Store=load("res://modules/review/core/reading_store.gd");var restored=Store.new();restored.path=page.store.path;restored.catalog_path=page.store.catalog_path;restored.read_file()
	check(not restored.blocked and restored.data.grouping=="alphabet" and restored.data.marks.get(known_id)=="known","模式偏好与题目掌握标记可重读")
	page.store.data.expanded["letter:П"]=true;page.save()
	var active_id:String=page.entries[page.index].id;page.grouping_button.pressed.emit();await frame()
	check(page.grouping=="topic" and page.entries[page.index].id==active_id,"可切回原专题目录")
	check(page.store.data.expanded.get("letter:П",false),"两套目录展开记录独立保留")
	main.get_window().size=Vector2i(1440,900)
	main.show_home();main.open_review("reading");await frame()
	check(main.review.reading.grouping_button==null and main.review.reading.grouping=="topic","旧题复习无新增按钮，维持专题模式")
	check(main.review.reading.entries.size()==62,"旧题库数量保持")
	var old_page=main.review.reading
	old_page.store.path="user://review/qa-alphabet-legacy-"+str(OS.get_process_id())+".json"
	old_page.select_question(find(old_page,"Q01"));await key(KEY_E)
	check(old_page.entries[old_page.index].id=="Q05","旧专题内切题顺序保持")
	old_page.tree_items["Q02"].get_parent().select(0);await frame()
	check(old_page.entries[old_page.index].id=="Q02","旧专题节点仍进入原首题")
	check(module._stability==null,"切换目录不创建船模或动画")
	var f:=FileAccess.open("res://qa/alphabet-results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"pass":checks.all(func(c):return c.pass),"checks":checks},"  "));f.close()
	print("ALPHABET_QA_FINISHED checks=",checks.size());main.get_tree().quit()
