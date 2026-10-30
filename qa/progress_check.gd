extends "res://qa/formal_check.gd"
func select_node(index:int)->void:
	await click_at(app.progress.global_position+app.progress.point(index))
func start(target)->void:
	app=target;await frames(5)
	for c in app.courses:
		app.lang="zh";await app.open_course(c.id,c.groups[0].beats[0].id);await settle()
		check(app.progress.visible,c.id+" progress visible")
		check(app.progress.steps.size()==app.player.beats.size(),c.id+" one node per beat")
		check(app.stage.get_rect().end.y<app.progress.position.y,c.id+" footer never overlaps model")
		for i in range(app.player.beats.size()):
			check(app.progress.hit(app.progress.point(i))==i,c.id+" distinct clickable node "+str(i))
		for index in [app.player.beats.size()-1,0,int(app.player.beats.size()/2)]:
			await select_node(index);await settle()
			check(app.player.current==index and app.progress.current==index,c.id+" clicked node selects beat "+str(index))
			check(app.store.data.targets[c.id]==app.beat.id,c.id+" jump persists stable identity")
			check(app.player.state==app.player.after[index],c.id+" jump reaches correct state")
			for later in range(index+1,app.player.beats.size()):
				var id:String=app.player.beats[later].id
				check(not app.equations.entries.has(id) or not app.equations.entries[id].box.visible,c.id+" no future record "+id)
		await capture("progress-"+c.id)
	await app.open_course("foundation","B01:width");await settle();go_to("B01:width");await frames(7)
	app.player.complete_busy();app.player.play();app.player.animation.custom_step(.3)
	await select_node(app.player.beats.size()-1)
	var target_id:String=app.beat.id;var initial:Dictionary=app.player.before[app.player.current].duplicate(true)
	check(app.player.state==initial,"Click during animation restores destination starting state")
	await frames(8);check(app.beat.id==target_id and app.player.state==initial,"Cancelled animation cannot overwrite destination")
	tap(KEY_F2);await frames(5)
	check(app.progress.language=="ru" and app.beat.id==target_id,"F2 retains node and changes tooltip language")
	await capture("progress-russian")
	await select_node(0);await settle();tap(KEY_E);await frames(5)
	check(app.progress.current==app.player.current and app.player.current==1,"D updates progress node")
	await settle();tap(KEY_Q);await frames(5)
	check(app.progress.current==0 and app.player.current==0,"A updates progress node")
	tap(KEY_ESCAPE);await frames(5)
	check(app.mode=="home" and not app.progress.visible,"Esc returns home and hides progress")
	check(not "back" in app,"Return button has been removed")
	check(app.get_window().get_flag(Window.FLAG_NO_FOCUS),"QA does not take focus")
	app.lang="ru";await app.open_course("dimensions","T16:pass");app.store.data.language="ru";app.save_progress()
	var output:=FileAccess.open("res://qa/progress-"+("minimum" if "--minimum" in OS.get_cmdline_user_args() else "normal")+".json",FileAccess.WRITE)
	output.store_string(JSON.stringify(results,"\t"));output.close()
	print("PROGRESS ",results.size()," checks")
	get_tree().quit(0 if results.all(func(r):return r.passed) else 1)
