extends "res://modules/review/qa/sample_check.gd"
const M=preload("res://core/bulkhead_math.gd")
var page
func show_step(id:String)->void:
	page.drawer_open=true;page.layout()
	for i in page.player.beats.size():
		if page.player.beats[i].id==id:page.jump_index(i);break
	page.player.complete_busy();page.player.finish()
	if page.ship.camera_tween and page.ship.camera_tween.is_valid():page.ship.camera_tween.custom_step(2)
	await frames(10)
func start(host)->void:
	app=host;await frames(5)
	var before:Dictionary=app.store.data.targets.duplicate(true)
	await app.open_course("bulkheads","BH:opening");page=app.bulkheads;await frames(10)
	page.lang="zh";page.menus();await show_step("BH:opening");await capture("bulkheads-opening")
	check(app.mode=="bulkheads","New chapter opens")
	check(M.integer_range(.05*M.L,.08*M.L,.6)==Vector2i(16,25),"Fore integer bounds")
	check(M.integer_range(.04*M.L,.08*M.L,.6)==Vector2i(13,25),"Aft integer bounds")
	check(M.integer_range(.14*M.L,.17*M.L,1.7)==Vector2i(16,18),"Engine integer bounds")
	var computed:=M.calculate()
	check(is_equal_approx(computed.nominal_spacing,.85826),"Nominal spacing calculated")
	check(is_equal_approx(computed.cargo_length,127.53),"Cargo length calculated")
	check(is_equal_approx(computed.transition_length,23.426) and computed.transition_reconciled,"Transition reconciled")
	check(is_equal_approx(computed.deadweight,32143) and is_equal_approx(computed.central_width,8.83),"Deadweight and central width")
	check(computed.double_bottom>computed.double_bottom_min and computed.double_side>=computed.double_side_calc,"Adopted inner boundaries")
	check(page.ship.walls.size()==9 and page.ship.ribs.size()==244,"Nine physical walls and frame map")
	for i in 9:check(is_equal_approx(page.ship.walls[i].position.x,[174.73,13.2,43.8,47.2,149.89,128.8,108.4,88.0,67.6][i]),"Physical wall exact coordinate %d"%i)
	for n in [58,60,61]:
		var rows:=M.rows(n);var total:=0.0
		for row in rows:total+=row.length
		check(is_equal_approx(total,189.13) and is_equal_approx(rows[1].length+rows[2].length,45.93),"Length conserved at %d"%n)
	for id in ["BH:wall","BH:four","BH:fore_place"]:
		await show_step(id);await capture("bulkheads-sample-"+id.replace(":","-"))
	for language in ["zh","ru"]:
		page.lang=language;page.menus()
		for i in page.player.beats.size():
			page.jump_index(i);page.player.complete_busy();page.player.finish()
			if page.ship.camera_tween and page.ship.camera_tween.is_valid():page.ship.camera_tween.custom_step(2)
			await frames(5)
			check(page.ship.state==page.current_state,"Shared state "+language+" "+page.beat.id)
			check(page.speech.panel.visible and page.speech.panel.get_rect().end.x<=page.ship.size.x+1 and page.speech.panel.get_rect().end.y<=page.ship.size.y+1,"Bubble fits "+language+" "+page.beat.id)
			for entry in page.record.entries.values():check(entry.math.render_errors==0 and entry.math.slot_overflows==0,"Formula "+language+" "+entry.math.current_id)
	page.lang="zh";page.menus();await show_step("BH:drag");await capture("bulkheads-layout")
	var p:Vector2=page.ship.global_position+page.ship.candidate_point(60)
	var down:=InputEventMouseButton.new();down.position=p;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;app.get_viewport().push_input(down,true)
	var move:=InputEventMouseMotion.new();move.position=page.ship.global_position+page.ship.candidate_point(61);move.button_mask=MOUSE_BUTTON_MASK_LEFT;app.get_viewport().push_input(move,true)
	check(page.current_state.bh_frame==60 and page.ship.preview_frame==61,"Drag preview does not commit before release")
	down.position=move.position;down.pressed=false;app.get_viewport().push_input(down,true);await frames(5)
	check(page.current_state.bh_frame==61,"Viewport drag snaps to 61")
	check(is_equal_approx(page.ship.walls[4].position.x,M.x(61)),"Displayed wall uses mapped metres")
	await click(page.reset.global_position+page.reset.size*.5);check(page.current_state.bh_frame==60,"Reset restores 60")
	await click(page.progress.global_position+page.progress.point(0));await frames(4)
	check(page.beat.id=="BH:numbering","Bottom node jumps within current phase")
	for id in ["BH:transition","BH:pump","BH:longitudinal","BH:central","BH:recheck","BH:finish"]:
		await show_step(id)
		if id=="BH:finish":page.drawer_open=false;page.layout()
		page.speech.focus_requested.emit();page.ship.camera_tween.custom_step(2);await frames(5);await capture("bulkheads-"+id.replace(":","-"))
	tap(KEY_F2);await frames(5);check(page.lang=="ru","F2 language")
	await capture("bulkheads-russian")
	var saved:String=app.store.data.targets.bulkheads
	app.get_window().size=Vector2i(1100,760);await frames(8)
	for id in ["BH:dbformula","BH:webvalues","BH:multiple"]:
		await show_step(id)
		check(page.speech.panel.get_rect().end.x<=page.ship.size.x+1 and page.speech.panel.get_rect().end.y<=page.ship.size.y+1,"Minimum long step fits "+id)
		for entry in page.record.entries.values():
			for drawing in entry.math.drawings:check(drawing.rect.end.x<=entry.math.size.x+1,"Minimum formula width "+entry.math.current_id)
	await show_step("BH:longitudinal");await capture("bulkheads-minimum")
	check(page.speech.panel.get_rect().end.x<=page.ship.size.x and page.speech.panel.get_rect().end.y<=page.ship.size.y,"Minimum bubble inside viewport")
	await show_step("BH:drag");await capture("bulkheads-minimum-drag")
	for scale in [1.25,1.5,2.0]:
		for entry in page.record.entries.values():entry.math.min_render_scale=scale;entry.math.arrange()
		await frames(4);await capture("bulkheads-formula-scale-"+str(scale))
	app.get_window().size=Vector2i(1440,900);await frames(5);saved=app.store.data.targets.bulkheads
	tap(KEY_ESCAPE);await frames(4);check(app.mode=="home" and not page.player.active,"Esc cancels and home")
	await app.open_course("bulkheads");await frames(4);check(page.beat.id==saved,"Resume stable step")
	tap(KEY_E);await frames(3);check(page.player.phase!="typing","E finishes current text")
	page.player.current=1;page.player.prepare();page.player.complete_busy();page.player.advance();await frames(3)
	check(page.player.phase=="playing","Action starts after text")
	page.player.jump(3);await frames(3);check(page.beat.id=="BH:fore_range" and page.player.phase=="typing","Stage jump cancels animation")
	tap(KEY_ESCAPE);await frames(3)
	var hidden_step:int=page.player.current;tap(KEY_E);check(page.player.current==hidden_step,"Hidden chapter ignores keyboard")
	app.lang="zh";app.build_home();await capture("bulkheads-home")
	await click(app.home_map.cards.bulkheads.get_global_rect().get_center());await frames(5)
	check(app.mode=="bulkheads" and page.beat.id=="BH:fore_range","Real tree click resumes recorded step")
	var disk=load("res://core/safe_store.gd").new();disk.path=app.store.path;disk.read_file()
	check(disk.data.targets.bulkheads==page.beat.id,"Stable ID persisted to isolated QA save")
	for key in before:if key!="bulkheads":check(app.store.data.targets[key]==before[key],"Old progress "+key)
	var out:=FileAccess.open("res://qa/bulkheads-check.json",FileAccess.WRITE);out.store_string(JSON.stringify(results,"\t"));out.close()
	print("BULKHEADS ",results.size()," checks; failures ",results.filter(func(r):return not r.passed).size());get_tree().quit(0 if results.all(func(r):return r.passed) else 1)
