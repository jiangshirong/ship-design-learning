extends "res://modules/review/qa/sample_check.gd"
var host
func start(target)->void:
	host=target;app=host.review
	await frames(20)
	check(host.mode=="home" and host.home_map.visible,"Unified startup is chapter tree")
	check(host.review_buttons.get_child_count()==2,"Two study home buttons")
	check(not app.visible and app.process_mode==Node.PROCESS_MODE_DISABLED,"Hidden module disabled")
	await capture("merge-home")
	await click(host.review_buttons.get_child(0).get_global_rect().get_center());await frames(10)
	check(host.mode=="review" and app.mode=="reading","Real reading button")
	var page=app.reading
	page.store.data.filter="all";page.rebuild_filter()
	for dimensions in [Vector2i(1440,900),Vector2i(1100,760)]:
		host.get_window().size=dimensions;await frames(8)
		for i in 25:
			page.select_question(i);await frames(2)
			check(not page.revealed and not page.details.visible,"Hidden answer "+str(i)+str(dimensions))
			tap(KEY_SPACE);await frames(2)
			check(page.revealed and page.details.visible,"Reveal "+str(i)+str(dimensions))
			check(not page.question.full_text.is_empty(),"Complete question "+str(i))
			if i==8:await capture("merge-reading-"+str(dimensions.x))
			if dimensions.x==1440:
				page.scroll.scroll_vertical=37;await frames(2)
				var scroll_before:int=page.scroll.scroll_vertical
				await click(page.animation_button.get_global_rect().get_center());await frames(6)
				check(app.mode in ["lesson","stability"],"Animation route Q"+str(i+1))
				if app.mode=="lesson":
					app.start_reason();await frames(3)
					check(app.player.active and app.player.beats.size()>0,"Animation content Q"+str(i+1))
				else:check(app.stability.player.active,"Stability active Q"+str(i+1))
				tap(KEY_ESCAPE);await frames(6)
				check(app.mode=="reading" and page.index==i and page.revealed,"Esc returns revealed original Q"+str(i+1))
				check(page.scroll.scroll_vertical==scroll_before,"Reading scroll retained Q"+str(i+1))
				check(not app.player.active and not app.stability.player.active,"Animation canceled Q"+str(i+1))
	for i in range(6,10):
		page.select_question(i)
		for kind in ["example","variant"]:
			page.open_exercise(kind);await frames(3);check(not page.revealed,"Exercise hidden")
			page.reveal();await frames(4)
			for formula in page.formula_panels:check(formula.render_errors==0,"Exercise formula renders")
	page.select_question(1);page.reveal();page.mark("known");check(page.store.data.marks.get("Q02")=="known","Mark known")
	page.mark("review");check(page.store.data.marks.Q02=="review","Mark review")
	var read_store=load("res://modules/review/core/reading_store.gd").new();read_store.path=page.store.path;read_store.read_file()
	check(read_store.data==page.store.data,"Reading state reopens")
	tap(KEY_ESCAPE);await frames(5)
	check(host.mode=="home" and not app.visible,"Reading Esc home")
	await click(host.review_buttons.get_child(1).get_global_rect().get_center());await frames(8)
	check(app.vocabulary.menu.visible,"Vocabulary category menu")
	await click(app.vocabulary.menu.get_child(0).get_global_rect().get_center());await frames(5)
	check(app.mode=="vocabulary" and not app.vocabulary.revealed,"Vocabulary button Russian first")
	for entry in app.vocabulary.all_entries:
		check(entry.id not in ["allowed","more","still","which","be","example","first","less"],"Excluded basics "+entry.id)
		check(entry.context.id in app.lessons,"Vocabulary source question "+entry.id)
	var before_word:int=app.vocabulary.index
	for key in [KEY_Q,KEY_R,KEY_F3]:tap(key)
	check(app.vocabulary.index==before_word and app.mode=="vocabulary","Removed voice keys have no action")
	tap(KEY_SPACE);await frames(4);check(app.vocabulary.revealed,"Vocabulary space Chinese")
	tap(KEY_E);await frames(4);check(not app.vocabulary.revealed,"Next word hides Chinese")
	await capture("merge-vocabulary")
	tap(KEY_ESCAPE);await frames(4)
	tap(KEY_ESCAPE);await frames(4)
	for course in host.courses:
		await host.open_course(course.id);await frames(3)
		if course.id=="bulkheads":check(host.mode=="bulkheads" and host.bulkheads.player.active,"Independent bulkhead chapter")
		else:check(host.mode=="lesson" and host.player.active,"Original course "+course.id)
		check(not app.visible and not app.player.active,"Review does not run behind original course")
		tap(KEY_ESCAPE);await frames(3)
	await migration_checks()
	var report:={"checks":results.size(),"failures":results.filter(func(r):return not r.passed),"results":results}
	var out:=FileAccess.open("res://qa/merge-checks.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"\t"));out.close()
	print("MERGE ",results.size()," checks; failures ",report.failures.size());get_tree().quit(0 if report.failures.is_empty() else 1)
func write(path:String,value:String)->void:
	var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(value);f.close()
func migration_checks()->void:
	var base:="user://review/qa-migration-"+str(OS.get_process_id())
	var source:=base+"/old";var dest:=base+"/new"
	DirAccess.make_dir_recursive_absolute(source)
	write(source+"/progress.json",'{"schema_version":1,"targets":{},"selected":"Q03","language":"ru"}')
	write(source+"/reading-review.json","{broken")
	write(source+"/speech.json","must not migrate")
	var migration=load("res://modules/review/core/migration.gd")
	var r:Dictionary=migration.run(false,source,dest)
	check(r.copied.size()==2 and r.errors.is_empty(),"Migration copies exact allowed files")
	check(not FileAccess.file_exists(dest+"/speech.json"),"No credentials migrate")
	check(FileAccess.get_file_as_string(dest+"/reading-review.json")=="{broken","Corrupt original retained")
	var broken=load("res://modules/review/core/reading_store.gd").new();broken.path=dest+"/reading-review.json";broken.read_file()
	check(broken.blocked and not broken.write_file(),"Corrupt progress blocks overwriting")
	write(dest+"/progress.json","newer");r=migration.run(false,source,dest)
	check(FileAccess.get_file_as_string(dest+"/progress.json")=="newer" and r.copied.is_empty(),"Repeated migration preserves target")
