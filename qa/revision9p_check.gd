extends "res://modules/review/qa/topics_check.gd"
func start(target)->void:
	host=target;app=host.review;page=app.stability
	var minimum:bool="--minimum" in OS.get_cmdline_user_args()
	if minimum:host.get_window().size=Vector2i(1100,760)
	await frames(10);host.open_review("reading");await frames(4)
	var reading=app.reading
	check(reading.entries.size()==62,"62 unique cards")
	check(reading.topics.size()==9,"9 continuous topics")
	var sources:Array=[]
	for r in reading.entries:sources.append_array(r.sources)
	check(sources.size()==90,"90 source aliases")
	for n in range(1,42):check(sources.has("9p-"+str(n)),"Source 9p-"+str(n))
	for c in page.courses:
		if c.id not in ["propulsion","arrangement","freeboard"]:continue
		await app.open_topic(c.id);await settle_topic()
		for i in page.player.beats.size():
			var b:Dictionary=page.player.beats[i]
			if not b.id.begins_with("R9:"):continue
			page.goto_index(i);await settle_topic()
			check(page.bubble.panel.visible,"Sentence "+b.id)
			check(page.bubble.caption.get_v_scroll_bar().max_value<=page.bubble.caption.get_v_scroll_bar().page,"No sentence clipping "+b.id)
			for entry in page.records.entries.values():check(entry.math.render_errors==0 and entry.math.slot_overflows==0,"LaTeX "+b.id)
			var active=page.topic_ship.active
			check(is_instance_valid(active.detailed),"Detailed hull "+b.id)
			if b.id.ends_with(":1"):
				page.drawer_open=true;page.arrange();await frames(5)
				await capture("revision9p-"+b.id.replace(":","-")+("-minimum" if minimum else ""))
				page.drawer_open=false;page.arrange();await frames(3)
			var camera:Transform3D=active.camera.transform
			page.toggle_language();await frames(3);check(active.camera.transform.is_equal_approx(camera),"F2 keeps view "+b.id);page.toggle_language()
		app.go_home()
		check(not page.player.active,"Topic stops on exit")
	# Actual card -> animation -> Esc preserves reading state.
	app.open_reading()
	for qid in ["R9Q17","R9Q27","R9Q37"]:
		var idx:=-1
		for i in reading.entries.size():
			if reading.entries[i].id==qid:idx=i
		reading.select_question(idx);await frames(3);tap(KEY_F);await frames(3)
		await click(reading.animation_button.get_global_rect().get_center());await settle_topic()
		tap(KEY_ESCAPE);await frames(5)
		check(app.mode=="reading" and reading.index==idx and reading.revealed,"Esc restores "+qid)
	var failures:Array=results.filter(func(r):return not r.passed)
	var out=FileAccess.open("res://qa/revision9p-results"+("-minimum" if minimum else "")+".json",FileAccess.WRITE);out.store_string(JSON.stringify({"checks":results.size(),"failures":failures},"  "));out.close()
	print("REVISION9P ",results.size()," checks; failures ",failures.size());get_tree().quit(0 if failures.is_empty() else 1)
