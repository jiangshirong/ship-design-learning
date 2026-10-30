extends RefCounted
var main
var checks:Array=[]
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
	main.get_viewport().get_texture().get_image().save_png("res://qa/exam13/"+name_+".png")
func find(page,id:String)->int:
	for i in page.entries.size():
		if page.entries[i].id==id:return i
	return -1
func run(host)->void:
	main=host;await frame()
	main.review_buttons.get_child(1).pressed.emit();await frame();await frame()
	var module=main.review;var page=module.reading
	page.store.data.filter="all";page.store.data.marks.clear();page.rebuild_filter()
	check(module.bank_id=="exam12" and page.entries.size()==73,"原新题入口：67问答＋6识图")
	check(page.topics.size()==8,"八个知识专题")
	for q in page.entries:
		if not q.id.begins_with("P13_"):continue
		page.select_question(find(page,q.id));await frame()
		check(not page.revealed and page.details.get_child_count()==0,"新题初始隐藏答案 "+q.id)
		await key(KEY_F)
		check(page.revealed and page.details.get_child(0).text==q.answer.ru and page.details.get_child(1).text==q.answer.zh,"F揭晓完整双语回答 "+q.id)
		check(not page.animation_button.visible and page.animation_button.disabled,"无模型动画入口 "+q.id)
		await key(KEY_V)
		check(module.mode=="reading" and module._stability==null,"V不会创建三维场景 "+q.id)
		if q.has("formula_id"):
			check(not page.formula_panels.is_empty() and not page.formula_panels[0].rows.is_empty(),"真正LaTeX公式 "+q.id)
		check(page.tree_items.has(q.id),"题号与树定位 "+q.id)
	page.select_question(find(page,"P13_Q02"));await frame();await frame()
	check(page.question.symbol_regions.any(func(s):return s.span.base=="D" and s.span.suffix=="1"),"D₁下标正确且指向第一次近似")
	await capture("question")
	var group=page.tree_items["P13_Q02"].get_parent();group.select(0);await frame()
	check(page.entries[page.index].id=="P13_Q02" and page.topic_selected.is_empty(),"纯阅读专题节点直接进入第一道题")
	page.select_question(find(page,"P13_Q08"));await key(KEY_F)
	main.get_window().size=Vector2i(1100,760);await capture("norman-minimum")
	page.scroll.scroll_vertical=int(page.scroll.get_v_scroll_bar().max_value);await capture("norman-formulas")
	check(page.formula_panels[0].render_errors==0 and page.formula_panels[0].slot_overflows==0,"最小窗口分式无排版错误")
	page.select_question(find(page,"P13_Q30"));page.reveal();await capture("volume-coordinates")
	check(page.question.symbol_regions.any(func(s):return s.span.base=="x") and page.question.symbol_regions.any(func(s):return s.span.base=="z"),"坐标下标与释义区域")
	page.select_question(find(page,"P13_Q08"));page.reveal();await frame()
	page.scroll.scroll_vertical=0;await frame()
	var answer=page.details.get_child(0);var word:="перепроекти́ровании";var position:int=answer.text.find(word)
	var rect:=Rect2(answer.get_rect_at_line_column(0,position+2));var motion:=InputEventMouseMotion.new();motion.position=rect.get_center();answer.gui_input.emit(motion)
	var tip=load("res://modules/review/view/term_tooltip.gd").shared(answer)
	check(position>=0 and tip.panel.visible and tip.current.get("zh","").contains("重新设计"),"新词实际悬停显示原形与中文")
	await capture("word-hover");tip.hide_tip()
	var previous_id:String=page.entries[page.index].id;await key(KEY_E)
	check(not page.revealed and page.entries[page.index].id!=previous_id,"E切题后隐藏答案")
	await key(KEY_Q);check(page.entries[page.index].id==previous_id,"Q回上一题")
	page.reveal();page.mark("known");var saved_id:String=page.entries[page.index].id
	var Store=load("res://modules/review/core/reading_store.gd");var reopened=Store.new();reopened.path=page.store.path;reopened.catalog_path=page.store.catalog_path;reopened.read_file()
	check(not reopened.blocked and reopened.data.selected==saved_id and reopened.data.marks.get(saved_id)=="known","新增题掌握标记和阅读位置可重开")
	page.bank_filter.pressed.emit();await frame();check(find(page,saved_id) not in page.filtered,"待复习筛选排除已会新题")
	page.bank_filter.pressed.emit();await frame()
	main.get_window().size=Vector2i(1440,900)
	page.select_question(find(page,"P12_T17"));page.reveal();await capture("prototype-focused")
	check(page.entries[page.index].answer.zh=="一艘母型通常不能满足新船的全部要求，借来的方案仍需协调、调整并通过计算验证。","已有新题回答去掉铺垫，保留因果")
	check(page.animation_button.visible and not page.animation_button.disabled,"已有题动画入口保留")
	var glossary=load("res://modules/review/core/glossary.gd").new();var words:Array=glossary.study_entries(page.content_root+"reading.json")
	check(words.any(func(w):return w.ru=="перепроекти́рование"),"新增问答词汇进入科学复习")
	var excluded:Array=["мочь","нужно","можно","больше","меньше","какой","быть","ещё","например","сначала"]
	check(not words.any(func(w):return w.ru.replace("\u0301","") in excluded),"既有基础词排除有效")
	module.open_vocabulary(true);await frame();check(module.vocabulary.all_entries.size()==words.size(),"科学复习使用新题库词汇")
	await key(KEY_ESCAPE);check(main.mode=="home","Esc回首页")
	main.open_review("reading");await frame()
	check(main.review.reading.entries.size()==62,"旧入口仍为62题")
	check(module._stability==null,"整条阅读复习路径未加载船模")
	var f:=FileAccess.open("res://qa/exam13/ui-results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"pass":checks.all(func(c):return c.pass),"checks":checks,"word_count":words.size()},"  "));f.close()
	print("EXAM13_QA_FINISHED checks=",checks.size())
	main.get_tree().quit()
