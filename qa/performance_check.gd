extends Node
var host
var rows:Array=[]
func frames(n:int)->void:
	for i in n:await get_tree().process_frame
func ready_page()->void:
	while host.get_meta("loading",false):await frames(1)
	await frames(8)
func inventory(node:Node,result:Dictionary)->void:
	result.nodes+=1
	if node is MeshInstance3D:result.meshes+=1
	if node is SubViewport:
		result.viewports+=1
		if node.render_target_update_mode!=SubViewport.UPDATE_DISABLED:result.enabled_viewports+=1
	for child in node.get_children():inventory(child,result)
func snapshot()->Dictionary:
	var result:Dictionary={"nodes":0,"meshes":0,"viewports":0,"enabled_viewports":0}
	inventory(host,result)
	result.static_mb=Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0
	result.render_mb=Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0
	result.draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	result.resources=Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	result.objects=Performance.get_monitor(Performance.OBJECT_COUNT)
	result.orphans=Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	return result
func settle()->void:
	if host.mode=="review" and host.review.mode=="stability":
		var page=host.review.stability
		page.player.complete_busy()
		if page.player.phase=="ready":page.player.finish()
	elif host.mode=="lesson":
		host.player.complete_busy()
		if host.player.phase=="ready":host.player.finish()
	elif host.mode=="bulkheads":
		host.bulkheads.player.complete_busy()
		if host.bulkheads.player.phase=="ready":host.bulkheads.player.finish()
func measure(name_:String,opened:int)->void:
	await ready_page()
	var opening_ms:=float(Time.get_ticks_usec()-opened)/1000.0
	settle();await frames(10)
	var elapsed:Array=[];var process:Array=[]
	var previous:=Time.get_ticks_usec()
	for i in 180:
		await frames(1)
		var now:=Time.get_ticks_usec()
		elapsed.append(float(now-previous)/1000.0);previous=now
		process.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
	elapsed.sort();process.sort()
	var row:=snapshot()
	row.name=name_;row.open_ms=opening_ms;row.frame_p50_ms=elapsed[90];row.frame_p95_ms=elapsed[171]
	row.process_p50_ms=process[90];row.process_p95_ms=process[171];rows.append(row)
func start(target)->void:
	host=target
	if "--perf-stress" in OS.get_cmdline_user_args():await stress();return
	var startup_ms:=Time.get_ticks_msec()
	host.lang="zh";host.build_home();host.refresh_chrome();host.review.language="zh"
	await measure("home",Time.get_ticks_usec())
	rows[-1].startup_ms=startup_ms
	var t:=Time.get_ticks_usec();host.open_review("reading");await measure("reading",t)
	t=Time.get_ticks_usec();host.open_review("scientific");await measure("scientific",t)
	t=Time.get_ticks_usec();await host.open_course("load","L06:x");await measure("loads",t)
	t=Time.get_ticks_usec();await host.open_bulkheads("BH:opening");await measure("bulkheads",t)
	for id in ["stability","damage","freeboard"]:
		t=Time.get_ticks_usec();host.open_review("reading");await ready_page()
		host.review.open_topic(id);await ready_page()
		var page=host.review.stability
		if id=="stability":page.goto_index(page.player.beats.size()-3)
		await measure(id,t)
		page.drawer_open=true;page.arrange();await measure(id+"_records",Time.get_ticks_usec())
		if id=="stability":
			var samples:Array=[]
			var frame_samples:Array=[]
			for i in 90:
				var s:Dictionary=page.current_state.duplicate(true);s.heel=float(i)*.4
				var start:=Time.get_ticks_usec();page.state_changed(s)
				samples.append(float(Time.get_ticks_usec()-start)/1000.0)
				await frames(1)
				frame_samples.append(float(Time.get_ticks_usec()-start)/1000.0)
			samples.sort()
			frame_samples.sort()
			rows.append({"name":"stability_state_updates","p50_ms":samples[45],"p95_ms":samples[85],"frame_p50_ms":frame_samples[45],"frame_p95_ms":frame_samples[85]})
	# Revisit the same paths; record stable resource footprint, not just cold loading.
	var cycles:Array=[]
	for i in 20:
		host.show_home();host.open_review("reading");await ready_page()
		t=Time.get_ticks_usec()
		host.review.open_topic(["damage","freeboard","stability"][i%3]);await ready_page()
		var revisit_ms:=float(Time.get_ticks_usec()-t)/1000.0
		settle();await frames(2);host.show_home();await frames(2)
		var cycle:=snapshot();cycle.revisit_ms=revisit_ms;cycle.topic=["damage","freeboard","stability"][i%3]
		cycles.append(cycle)
	var suffix:="before" if "--perf-before" in OS.get_cmdline_user_args() else "after"
	var f:=FileAccess.open("res://qa/performance-"+suffix+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"rows":rows,"cycles":cycles,"window":host.size,"engine":Engine.get_version_info().string},"\t"));f.close()
	print("PERFORMANCE ",suffix," ",JSON.stringify(rows))
	get_tree().quit()

func stress()->void:
	var rounds:Array=[];var failures:Array=[]
	for i in 20:
		for page in ["home","reading","scientific","loads","bulkheads","stability","damage","freeboard"]:
			match page:
				"home":host.show_home()
				"reading","scientific":host.open_review(page)
				"loads":await host.open_course("load","L06:x")
				"bulkheads":await host.open_bulkheads("BH:opening")
				_:
					host.open_review("reading");await host.review.open_topic(page)
			await ready_page();settle();await frames(2)
			var current:=snapshot()
			if current.viewports>2:failures.append([i,page,"viewport cache exceeded",current.viewports])
			if page in ["home","reading","scientific"] and current.enabled_viewports!=0:failures.append([i,page,"background viewport active"])
		host.show_home();await frames(8)
		rounds.append(snapshot())
	var output:=FileAccess.open("res://qa/performance-stress.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"rounds":rounds,"failures":failures,"page_visits":160},"\t"))
	print("PERFORMANCE STRESS 20 full rounds, 160 page visits; failures=",failures.size())
	get_tree().quit(1 if not failures.is_empty() else 0)
