extends "res://modules/review/qa/sample_check.gd"
const Schedule=preload("res://modules/review/core/review_schedule.gd")
func start(host)->void:
	app=host.review;await frames(10)
	check(host.review_buttons.get_child_count()==2,"Only two home entries")
	check(host.review_buttons.get_child(0).text=="题目","Question entry renamed")
	await click(host.review_buttons.get_child(1).get_global_rect().get_center());await frames(8)
	var page=app.vocabulary
	check(page.scientific and page.menu.visible,"Actual scientific entry opens categories")
	page.path="user://review/qa-scientific-"+str(OS.get_process_id())+".json"
	page.clock_override=1000000;page.marks={};page.schedule={}
	for level in Schedule.INTERVALS:
		var record:Dictionary=Schedule.next_review(level,page.now())
		check(record.due_at-page.now()==Schedule.INTERVALS[level],"Interval "+level)
		check(not Schedule.due("test",{"test":record},record.due_at-1),"Not yet due "+level)
		check(Schedule.due("test",{"test":record},record.due_at),"Exact deadline "+level)
	for entry in page.all_entries:
		page.schedule[entry.id]=Schedule.next_review("已掌握",page.now())
		page.marks[entry.id]="已掌握"
	var words:Array=page.all_entries.filter(func(e):return page.kind(e)=="单词")
	var levels:Array=["已掌握","认识","不熟","完全不会"]
	for i in 4:
		page.schedule.erase(words[i].id);page.marks[words[i].id]=levels[i]
	await click(page.menu.get_child(0).get_global_rect().get_center());await frames(8)
	check(page.entries.size()==4,"Only due words included")
	for i in 4:check(page.entries[i].id==words[3-i].id,"Deterministic severity order "+str(i))
	check(not page.filter.visible,"Scientific queue has no manual grade filter")
	await capture("scientific-review")
	for i in 4:
		var id:String=page.entries[page.index].id
		tap(KEY_SPACE);await frames(2)
		tap(KEY_1+i);await frames(3)
		check(page.entries.size()==3-i,"Rating consumes one due item")
		check(page.marks[id]==levels[i] and not page.revealed,"Saved and next answer hidden")
	check(page.russian.full_text=="本轮复习完成" and page.reveal_button.disabled,"Session terminates without looping")
	check(not page.notice.text.is_empty(),"Next due time visible")
	page.open_category("单词");await frames(3)
	check(page.entries.is_empty(),"Reentry does not repeat early")
	page.marks={};page.schedule={};page.load_marks();page.open_category("单词")
	check(page.entries.is_empty(),"Reload respects persisted due dates")
	page.clock_override+=120;page.open_category("单词")
	check(page.entries.size()==1,"Forgotten word returns after two minutes")
	page.open_menu();page.open_category("词组");check(page.entries.is_empty(),"Separate phrase due queue")
	var phrase:Dictionary=page.all_entries.filter(func(e):return page.kind(e)=="词组")[0]
	page.schedule.erase(phrase.id);page.open_category("词组");check(page.entries.size()==1 and page.entries[0].id==phrase.id,"Unscheduled phrase included")
	host.get_window().size=Vector2i(1100,760);await frames(8);check(page.get_global_rect().end.y<=760,"Minimum window")
	tap(KEY_ESCAPE);await frames(3);check(page.menu.visible,"Esc categories")
	tap(KEY_ESCAPE);await frames(3);check(host.mode=="home","Esc home")
	var f:=FileAccess.open(page.path,FileAccess.WRITE);f.store_string(JSON.stringify({"version":1,"marks":{words[0].id:"认识"}}));f.close()
	page.load_marks();check(page.marks[words[0].id]=="认识" and page.schedule.is_empty(),"V1 ratings preserved; unknown times due")
	page.open_category("单词");check(page.entries.size()==20,"Cramming rounds capped at twenty")
	check(page.entries.all(func(e):return not page.marks.has(e.id)),"Unmarked items fill round before rated items")
	check(page.entries[0].id==words[1].id,"Unmarked items preserve source order")
	var first_order:Array=page.entries.map(func(e):return e.id);page.open_category("单词")
	check(page.entries.map(func(e):return e.id)==first_order,"Round order deterministic")
	host.open_review("scientific");page.open_category("单词")
	page.reveal()
	var before_count:int=page.entries.size()
	var event:=InputEventKey.new();event.physical_keycode=KEY_KP_1;event.pressed=true;app.get_viewport().push_input(event,true)
	await frames(2);check(page.entries.size()==before_count-1,"Numpad grades one item")
	app.get_viewport().push_input(event,true);event.echo=true;app.get_viewport().push_input(event,true)
	await frames(2);check(page.entries.size()==before_count-1,"Held and echo do not skip items")
	event.echo=false;event.pressed=false;app.get_viewport().push_input(event,true)
	page.open_menu();var old_marks:Dictionary=page.marks.duplicate(true);tap(KEY_2)
	check(page.marks==old_marks,"Number keys inert on category menu")
	check(not Schedule.valid({"bad":{"due_at":-1,"reviewed_at":0}}),"Invalid due dates rejected")
	# Mixed queues: unknown items lead, then due rated items by severity.
	for kind_ in ["单词","词组"]:
		for entry in page.all_entries:
			page.marks[entry.id]="已掌握";page.schedule[entry.id]=Schedule.next_review("已掌握",page.now())
		var pool:Array=page.all_entries.filter(func(e):return page.kind(e)==kind_)
		page.marks[pool[0].id]="完全不会";page.schedule.erase(pool[0].id)
		page.marks.erase(pool[2].id);page.marks.erase(pool[1].id)
		# Even orphaned timing data must not hide an unmarked entry.
		page.open_category(kind_)
		check(page.entries.map(func(e):return e.id)==[pool[1].id,pool[2].id,pool[0].id],"New before weak; fixed source order "+kind_)
		page.reveal();page.mark("认识")
		check(page.entries[page.index].id==pool[2].id,"Rating advances to next unmarked "+kind_)
		page.reveal();page.mark("不熟")
		check(page.entries[page.index].id==pool[0].id,"Due words follow initial assessment "+kind_)
	var out:=FileAccess.open("res://qa/scientific-review.json",FileAccess.WRITE);out.store_string(JSON.stringify(results,"\t"));out.close()
	var failures:=results.filter(func(r):return not r.passed).size()
	print("SCIENTIFIC ",results.size()," checks; failures ",failures);get_tree().quit(1 if failures else 0)
