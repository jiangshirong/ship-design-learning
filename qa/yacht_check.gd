extends "res://modules/review/qa/topics_check.gd"
func start(target)->void:
	host=target;app=host.review;page=app.stability
	var minimum:bool="--minimum" in OS.get_cmdline_user_args()
	if minimum:host.get_window().size=Vector2i(1100,760)
	await frames(10);host.open_review("reading");await frames(5)
	await app.open_topic("propulsion");await settle_topic()
	var v=page.topic_ship.active
	check(v.get_script().resource_path.ends_with("propulsion_yacht.gd"),"Dedicated real yacht route")
	check(v.parts.size()>100 and v.propellers.size()==2,"Detailed hull and twin propeller train")
	check(v.detailed.scene_file_path.ends_with("planing_yacht.glb"),"Own Blender asset used")
	var before:Transform3D=v.camera.transform
	for i in page.player.beats.size():
		page.goto_index(i);await settle_topic()
		if not v.camera.transform.is_equal_approx(before):print("CAMERA_DIAGNOSTIC ",page.beat.id," before ",before," actual ",v.camera.transform," request ",v.get_meta("last_camera_request",[])," input ",v.get_meta("last_camera_input",""))
		check(v.camera.transform.is_equal_approx(before),"A/D and jumps retain camera "+page.beat.id)
		check(page.bubble.panel.visible,"Sentence visible "+page.beat.id)
		check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"No clipping "+page.beat.id)
		for e in page.records.entries.values():check(e.math.render_errors==0 and e.math.slot_overflows==0,"LaTeX "+page.beat.id)
		if page.beat.id in ["R9:R9Q28:0","R9:R9Q28:1","R9:R9Q28:2","R9:R9Q31:0","R9:R9Q31:1","R9:R9Q31:2","R9:R9Q30:1","R9:R9Q36:1"]:
			await capture("yacht-"+page.beat.id.replace(":","-")+("-minimum" if minimum else ""))
			if v.detail_container.visible:
				var img:Image=v.detail_viewport.get_texture().get_image();var colors:Dictionary={}
				for x in range(0,img.get_width(),8):
					for y in range(0,img.get_height(),8):colors[img.get_pixel(x,y).to_html()]=true
				if colors.size()<=20:
					await frames(6);await RenderingServer.frame_post_draw;img=v.detail_viewport.get_texture().get_image()
					for x in range(0,img.get_width(),8):
						for y in range(0,img.get_height(),8):colors[img.get_pixel(x,y).to_html()]=true
				check(colors.size()>20,"Local camera actually renders hull "+page.beat.id)
	select_beat("R9:R9Q28:0");await settle_topic();var a:Dictionary=v.metrics.duplicate()
	select_beat("R9:R9Q28:2");await settle_topic();var b:Dictionary=v.metrics.duplicate()
	check(b.heave>a.heave and b.area<a.area and b.volume<a.volume,"Actual immersion and rise change together")
	check(is_equal_approx(v.bodies[0].rotation.z,deg_to_rad(b.trim)),"Actual mesh trim matches geometry")
	check(is_equal_approx(b.buoyancy+b.lift,1),"Fixed weight support balance")
	check(v.water.rotation==Vector3.ZERO,"Sea remains horizontal")
	select_beat("R9:R9Q29:1");await frames(3);page.player.complete_busy();page.player.play();page.player.animation.pause();page.player.animation.custom_step(1.75);await frames(3)
	check(absf(page.current_state.p-.5)<.01,"Midpoint teaching state")
	check(v.metrics==load("res://modules/review/core/yacht_math.gd").values(page.current_state),"View shares calculation")
	page.toggle_language();await frames(4);check(v.camera.transform.is_equal_approx(before),"F2 retains camera")
	await capture("yacht-ru"+("-minimum" if minimum else ""));page.toggle_language()
	select_beat("R9:R9Q31:1");await settle_topic()
	check(v.engine_open,"Actual engine bay opens")
	check(v.hatch.visible and absf(v.hatch_hinge.rotation.x)>1.,"Actual Blender hatch rotates open")
	for test in [[.1,"Engine_block_"],[.5,"Shaft_"],[.9,"Propeller_"]]:
		var sample:Dictionary=page.current_state.duplicate(true);sample.p=test[0];page.state_changed(sample)
		var found:=false
		for item in v.material_states:
			if str(item.node.name).begins_with(test[1]) and item.mat.get_shader_parameter("glow"):found=true
		check(found,"Power transmission highlights real part at p="+str(test[0]))
	page.state_changed(page.player.after[page.player.current])
	select_beat("R9:R9Q31:0");await frames(3);page.player.complete_busy();page.player.play();page.player.animation.pause();page.player.animation.custom_step(1.75);await frames(4)
	check(absf(v.bay_opening-.5)<.01 and absf(rad_to_deg(v.hatch_hinge.rotation.x)+50)<.5,"Half-open hatch follows actual animation midpoint")
	await capture("yacht-hatch-mid"+("-minimum" if minimum else ""));page.player.finish();await frames(3)
	var pointer:Vector2=v.global_position+Vector2(v.size.x*.2,230)
	var down:=InputEventMouseButton.new();down.position=pointer;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;app.get_viewport().push_input(down,true)
	var move:=InputEventMouseMotion.new();move.position=pointer;move.relative=Vector2(30,-300);move.button_mask=MOUSE_BUTTON_MASK_LEFT;app.get_viewport().push_input(move,true)
	var up:=InputEventMouseButton.new();up.position=pointer;up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;app.get_viewport().push_input(up,true);await frames(4)
	check(v.camera.position.y<v.turn_target.y,"Actual input can orbit below hull")
	var observed:Transform3D=v.camera.transform
	tap(KEY_E);await frames(3);check(v.camera.transform.is_equal_approx(observed),"D preserves freely chosen camera")
	tap(KEY_Q);await frames(3);check(v.camera.transform.is_equal_approx(observed),"A preserves freely chosen camera")
	select_beat("R9:R9Q31:0");await settle_topic();page.toggle_language();await frames(5)
	check(not app.term_tooltip.glossary.spans(page.bubble.caption.full_text).filter(func(x):return x.entry.ru=="ди́зель").is_empty(),"Diesel word has Chinese lookup")
	check(v.ink.lookup.regions.size()>0,"Projected Russian part label has lookup hit region")
	for region in v.ink.lookup.regions:
		if region.entry.ru!="ди́зель":continue
		var hover:=InputEventMouseMotion.new();hover.position=v.ink.global_position+region.rect.get_center();app.get_viewport().push_input(hover,true);await frames(3)
		check(v.ink.lookup.tip.panel.visible and v.ink.lookup.tip.words.text.contains("柴油机"),"Actual projected diesel hover displays Chinese")
		break
	page.toggle_language()
	v.set_camera("engine",true);await frames(5)
	await capture("yacht-engine-detail"+("-minimum" if minimum else ""))
	var prop:float=v.propellers[0].rotation.x;await frames(6);check(v.propellers[0].rotation.x!=prop,"Real propeller spins")
	app.go_home();await frames(3);var clock:float=v.tick;await frames(8)
	check(v.tick==clock and v.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Hidden yacht stops animation and rendering")
	var failures:Array=results.filter(func(r):return not r.passed)
	var file=FileAccess.open("res://qa/yacht-results"+("-minimum" if minimum else "")+".json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":results.size(),"failures":failures},"  "));file.close()
	print("YACHT ",results.size()," checks; failures ",failures.size());get_tree().quit(0 if failures.is_empty() else 1)
