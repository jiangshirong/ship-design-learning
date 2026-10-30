extends Node
var app
var results:Array=[]
var samples:=0
func check(ok:bool,label:String)->void:
	results.append({"passed":ok,"name":label})
	if not ok:push_warning(label)
func tap(code:int)->void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed
		app.get_viewport().push_input(event,true)
func observe(label:String,n:int=24,fixed:=false)->void:
	var initial:Vector2=app.concept.size
	var full:=true
	var stationary:=true
	var started:int=Time.get_ticks_msec()
	var frame_count:=0
	# Offscreen rendering may run much faster than the monitor refresh rate.
	while frame_count<n or Time.get_ticks_msec()-started<400:
		await RenderingServer.frame_post_draw
		frame_count+=1
		samples+=1
		full=full and app.concept.size.is_equal_approx(app.ship.size)
		stationary=stationary and app.concept.size.is_equal_approx(initial)
	check(full,label+": every rendered frame fills left canvas")
	if fixed:check(stationary,label+": diagram bounds never move")
func start(target)->void:
	app=target
	check(app.get_window().get_flag(Window.FLAG_NO_FOCUS),"Offscreen no-focus window")
	check(app.store.path=="user://qa-continuity.json","Independent continuity save")
	for dimensions in [Vector2i(1440,900),Vector2i(1100,760)]:
		var tag:String=str(dimensions.x)
		app.get_window().size=dimensions
		for i in range(4):await get_tree().process_frame
		app.lang="zh";await app.open_course("foundation","B01:area")
		await observe(tag+" entering section",40)
		for id in ["B01:area","B01:width","B01:draft","B01:rectangle","B01:ratio","B01:meaning"]:
			check(app.beat.id==id,tag+" D reaches "+id)
			# Use actual D press/release events; do not fast-forward layout tweens.
			if app.player.phase=="typing":tap(KEY_E)
			if app.player.phase=="ready":
				tap(KEY_E)
				await observe(tag+" "+id+" action",24,true)
				if app.player.phase=="playing":tap(KEY_E)
			await observe(tag+" "+id+" hold",6,true)
			if id!="B01:meaning":
				tap(KEY_E)
				check(not (app.layout_tween and app.layout_tween.is_running()),tag+" same split has no tween "+id)
				await observe(tag+" "+id+" next",24,true)
				if id=="B01:rectangle":app.get_viewport().get_texture().get_image().save_png("res://qa/continuity-transition-"+tag+".png")
		app.get_viewport().get_texture().get_image().save_png("res://qa/continuity-settled-"+tag+".png")
		tap(KEY_F2);await observe(tag+" F2",24,true)
		tap(KEY_Q);await observe(tag+" A",24,true)
		check(app.beat.id=="B01:ratio",tag+" A returns to ratio")
		# A window relayout must also keep the diagram full height immediately.
		app.layout();check(app.concept.size==app.ship.size,tag+" synchronous relayout")
	var file:=FileAccess.open("res://qa/continuity.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"samples":samples,"checks":results},"\t"));file.close()
	print("CONTINUITY: ",samples," rendered frames; ",results.size()," checks")
	get_tree().quit(0 if results.all(func(r):return r.passed) else 1)
