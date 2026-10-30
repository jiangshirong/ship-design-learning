extends Node
var app
var results:Array=[]
func check(ok:bool,n:String)->void:
	results.append({"passed":ok,"name":n})
	if not ok:push_warning(n)
func frames(n:int=5)->void:
	for i in range(n):await get_tree().process_frame
	var main=get_tree().current_scene
	while is_instance_valid(main) and main.get_meta("loading",false):await get_tree().process_frame
func tap(code:int)->void:
	for pressed in [true,false]:
		var e:=InputEventKey.new();e.physical_keycode=code;e.pressed=pressed;app.get_viewport().push_input(e,true)
func click(point:Vector2)->void:
	var move:=InputEventMouseMotion.new();move.position=point;app.get_viewport().push_input(move,true)
	for pressed in [true,false]:
		var e:=InputEventMouseButton.new();e.position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;app.get_viewport().push_input(e,true);await frames(1)
func settle()->void:
	if app.layout_tween and app.layout_tween.is_valid():app.layout_tween.custom_step(2)
	if app.view.camera_tween and app.view.camera_tween.is_valid():app.view.camera_tween.custom_step(2)
	await frames(12);app.player.complete_busy()
	if app.player.phase=="ready":app.player.finish()
	await frames(10)
func capture(name_:String)->void:
	await frames(3);await RenderingServer.frame_post_draw
	app.get_viewport().get_texture().get_image().save_png("res://modules/review/qa/"+name_+".png")
func go(index:int)->void:app.jump(index)
