extends "res://modules/review/qa/sample_check.gd"
var page
func select_beat(id:String)->void:
	for i in page.player.beats.size():
		if page.player.beats[i].id==id:page.goto_index(i);break
	await frames(5)
	page.player.complete_busy()
	if page.player.phase=="ready":page.player.finish()
	var marine=page.topic_ship.views.marine
	if marine.camera_tween and marine.camera_tween.is_valid():marine.camera_tween.custom_step(2)
	await frames(8)
func shot(name_:String)->void:
	await RenderingServer.frame_post_draw
	app.get_viewport().get_texture().get_image().save_png("res://qa/ocean-"+name_+".png")
func start(host)->void:
	app=host
	host.open_review("reading")
	host.review.open_topic("freeboard")
	page=host.review.stability
	await frames(12)
	await select_beat("TOP:N13:measure")
	var marine=page.topic_ship.views.marine
	var sea=marine.water
	check(sea.material_override is ShaderMaterial,"Ocean shader is active")
	check(sea.mesh.get_surface_count()>0 and not sea.mesh is PlaneMesh,"Blender authored ocean geometry")
	check(sea.mesh.get_aabb().size.y>0.001,"Spectral waves have real geometry")
	check(is_zero_approx(sea.position.y),"Mean sea level remains zero")
	check(sea.material_override.get_shader_parameter("inspection")==0.0,"Exterior sea has full appearance")
	await shot("freeboard")
	marine.cancel();marine.camera.position=Vector3(140,115,180);marine.camera.look_at(Vector3.ZERO);marine.camera.size=210;marine.user_camera=true
	await frames(12);await shot("whole-ship")
	var state:Dictionary=marine.source_state.duplicate(true)
	var transform:Transform3D=marine.camera.transform
	await get_tree().create_timer(.8).timeout
	check(marine.source_state==state and marine.camera.transform.is_equal_approx(transform),"Sea motion does not change lesson or camera")
	await shot("whole-ship-later")
	marine.camera.position=Vector3(100,-65,160);marine.camera.look_at(Vector3(0,-3,0))
	await frames(8);await shot("underwater")
	host.review.open_topic("damage");await frames(8)
	await select_beat("TOP:Q22:water")
	check(sea.material_override.get_shader_parameter("inspection")>0.9,"Cutaway water remains transparent near hull")
	await shot("cutaway")
	host.get_window().size=Vector2i(1100,760);await frames(12);await shot("small")
	host.show_home();await frames(4)
	check(host.ship.water.material_override is ShaderMaterial,"Original coursework also uses ocean")
	await host.open_course(str(host.courses[0].id));await frames(8)
	if host.ship.camera_tween and host.ship.camera_tween.is_valid():host.ship.camera_tween.custom_step(2)
	check(host.ship.water.position.y==float(host.state.get("draft",10.0)),"Original draft sets sea reference level")
	await frames(10);await shot("original")
	var file:=FileAccess.open("res://qa/ocean-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "));file.close()
	get_tree().quit()
