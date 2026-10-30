extends "res://modules/review/qa/topics_check.gd"
const Geometry=preload("res://modules/review/core/module11_math.gd")
func volume(vertices:Array)->float:
	var d:Dictionary=Geometry.geometry()
	var total:=0.
	for f in d.faces:
		var a:Vector3=vertices[f[0]];var b:Vector3=vertices[f[1]];var c:Vector3=vertices[f[2]]
		total+=a.dot(b.cross(c))/6.
	return absf(total)
func actual_hover(field:TextEdit,needle:String)->void:
	var spans:Array=app.term_tooltip.glossary.spans(field.text);var desired:Dictionary={}
	for span in spans:
		if span.entry.ru.contains(needle):desired=span;break
	check(not desired.is_empty(),"Dictionary match "+needle)
	if desired.is_empty():return
	var found:=false
	for y in range(2,int(field.size.y),3):
		for x in range(2,int(field.size.x),3):
			var lc:=field.get_line_column_at_pos(Vector2i(x,y),false,false)
			if lc.y!=0 or lc.x<desired.start or lc.x>=desired.end:continue
			var e:=InputEventMouseMotion.new();e.position=field.global_position+Vector2(x,y);app.get_viewport().push_input(e,true);await frames(2)
			if app.term_tooltip.panel.visible:
				check(app.term_tooltip.words.text.contains(desired.entry.zh),"Native hover Chinese "+needle);found=true;break
		if found:break
	check(found,"Immediate native hover "+needle)
func start(target)->void:
	host=target;app=host.review;page=app.stability
	var minimum:bool="--minimum" in OS.get_cmdline_user_args()
	if minimum:host.get_window().size=Vector2i(1100,760)
	var suffix:="-minimum" if minimum else "-normal"
	await frames(10);await click(host.review_buttons.get_child(0).get_global_rect().get_center());await frames(4)
	var reading=app.reading
	check(reading.entries.size()==62,"62 cards")
	check(reading.topics.size()==9,"9 topics")
	for qid in ["M11Q01","M11Q02","M11Q03","M11Q04","M11Q05","M11Q06","M11Q07","M11Q08"]:
		var index:=-1
		for i in reading.entries.size():
			if reading.entries[i].id==qid:index=i
		check(index>=0,"Card "+qid);reading.select_question(index);await frames(2)
		check(not reading.revealed and not reading.translation.visible,"No answer preview "+qid)
		tap(KEY_F);await frames(3);check(reading.revealed,"Keyboard reveal "+qid)
		if qid=="M11Q03":await actual_hover(reading.question,"шпанго́ут")
		if qid=="M11Q02":check(reading.entries[index].has("condition"),"Source condition adjacent "+qid)
		var expected:String=reading.entries[index].topic
		await click(reading.animation_button.get_global_rect().get_center());await frames(3)
		check(page.course.id==expected,"Shared topic route "+qid)
		tap(KEY_ESCAPE);await frames(3);check(app.mode=="reading" and reading.index==index and reading.revealed,"Esc restores card "+qid)
	var base:Dictionary=Geometry.values({});var round:Dictionary=Geometry.values({"bilge":1.})
	check(round.area<base.area,"Actual bilge area decreases")
	check(is_equal_approx(round.beta,round.area/(26.6*10.88)),"Beta computed from geometric area")
	var affine:Dictionary={"scale_l":1.08,"scale_b":1.12,"scale_t":1.10}
	var changed:Dictionary=Geometry.values(affine)
	check(absf(changed.beta-base.beta)<.000001,"Beta invariant under affine scaling")
	var v0:=volume(Geometry.vertices({}));var v1:=volume(Geometry.vertices(affine))
	check(absf(v1/v0-1.08*1.12*1.10)<.000001,"Signed tetrahedra volume follows lbt")
	var original:Array=Geometry.vertices({});var flared:Array=Geometry.vertices({"flare":1.})
	for i in original.size():
		if original[i].y<=10.88:check(original[i].is_equal_approx(flared[i]),"Flare preserves submerged vertex "+str(i))
	for course_id in ["hullform","freeboard"]:
		await app.open_topic(course_id);await frames(3)
		var active=page.topic_ship.active;var identity:int=active.get_instance_id()
		for i in page.player.beats.size():
			var id:String=page.player.beats[i].id
			if not id.begins_with("M11:"):continue
			page.goto_index(i);await settle_topic()
			if course_id=="hullform" and id in ["M11:M11Q04:waves","M11:M11Q05:closed","M11:M11Q08:prototype"]:
				check(float(active.last_shape.Bulb)==1.,"Bulb retained after teaching "+id)
			check(active.get_instance_id()==identity,"No scene rebuild "+id)
			check(page.bubble.panel.visible,"Current sentence "+id)
			check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"No bubble scrollbar "+id)
			for entry in page.records.entries.values():check(entry.math.render_errors==0 and entry.math.slot_overflows==0,"Formula clarity "+id)
			if id=="M11:M11Q01:formula":
				var meaning_found:=false
				var math=page.records.entries[id].math
				for hint in math.hint_regions:
					if hint.text.contains("丰满系数"):
						meaning_found=math._get_tooltip(hint.rect.get_center()).contains("丰满系数")
				check(meaning_found,"Actual beta glyph meaning")
				check(math.source_rows.size()==1,"Only teacher formula purple; geometric results distinct")
			if id=="M11:M11Q04:grow":
				if page.language!="ru":page.toggle_language()
				await frames(4);await actual_hover(page.bubble.caption,"бульб")
				page.toggle_language();await frames(2)
			var camera_before:Transform3D=active.camera.transform
			var state_before:Dictionary=page.player.state.duplicate(true)
			page.toggle_language();await frames(2)
			check(page.player.state==state_before,"F2 state "+id)
			page.toggle_language();await frames(2)
			check(active.camera.transform.is_equal_approx(camera_before),"Language keeps camera "+id)
			if id in ["M11:foundation:end","M11:foundation_end","M11:M11Q01:formula","M11:M11Q02:concave","M11:M11Q03:U","M11:M11Q04:waves","M11:M11Q05:open","M11:M11Q08:conditions","M11:M11Q06:protect","M11:M11Q07:impact"]:
				page.drawer_open=id in ["M11:M11Q01:formula","M11:M11Q08:conditions"];page.arrange();page.bubble.begin_beat(page.beat.words)
				active.set_camera("topic");if active.camera_tween and active.camera_tween.is_valid():active.camera_tween.custom_step(2)
				await frames(6);await capture("module11-"+id.replace(":","-")+suffix)
		# A real paused midpoint proves morph interpolation, not merely endpoint switching.
		var action_id:String="M11:M11Q01:area" if course_id=="hullform" else "M11:M11Q07:excess"
		select_beat(action_id);await frames(3);page.player.complete_busy();page.player.play();page.player.animation.pause();page.player.animation.custom_step(1.5);await frames(3)
		var parameter:String="bilge" if course_id=="hullform" else "flare"
		check(absf(float(page.current_state[parameter])-.5)<.01,"Actual midpoint "+parameter)
		check(absf(float(active.last_shape.Bilge if course_id=="hullform" else active.last_morph.Flare)-.5)<.01,"Mesh midpoint "+parameter)
		var snapshot:Transform3D=active.camera.transform
		page.player.complete_busy();page.advance();await frames(3)
		check(active.camera.transform.is_equal_approx(snapshot),"A/D camera preserved "+course_id)
		app.go_home();check(not page.player.active and active.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Hidden page stopped "+course_id)
	for factor in [1.25,1.5,2.]:
		host.get_window().content_scale_factor=factor;host.get_window().size=Vector2i(roundi(1100*factor),roundi(760*factor))
		await app.open_topic("hullform");select_beat("M11:M11Q01:formula");await settle_topic()
		for entry in page.records.entries.values():check(entry.math.render_errors==0 and entry.math.slot_overflows==0,"Scaled formula "+str(factor))
		check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"Scaled sentence "+str(factor))
	host.get_window().content_scale_factor=1.
	var failures:Array=results.filter(func(x):return not x.passed)
	var out:=FileAccess.open("res://modules/review/qa/module11"+suffix+".json",FileAccess.WRITE);out.store_string(JSON.stringify({"checks":results.size(),"failures":failures,"results":results},"\t"));out.close()
	print("MODULE11 ",suffix," ",results.size()," checks; failures ",failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
