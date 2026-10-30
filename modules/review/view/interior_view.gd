extends "res://modules/review/view/hold_view.gd"
var tanker:Node3D
var tank_cut=preload("res://view/inspection_cut.gd").new()
func _ready()->void:
	super._ready()
	tanker=load("res://assets/damage_tanker.glb").instantiate();world.add_child(tanker)
	tank_cut.attach(tanker);tanker.scale=Vector3.ONE*.07;tanker.hide()
func apply(state:Dictionary,focus:String,lang:String)->void:
	if not detailed:return
	var s:=state.duplicate(true)
	s.loaded=16 if lesson_id=="Q13" and focus=="intro" else 0
	super.apply(s,focus,lang)
	for label_ in [mass_label,volume_label,limit_label,item_label]:label_.hide()
	for rail in rails:rail.hide()
	if not tanker:return
	var liquid:bool=lesson_id=="Q13" and focus!="intro"
	tanker.visible=liquid;detailed.visible=not liquid
	if liquid:
		tank_cut.window(1,6,24,2.2,14.7,0)
		tank_cut.fill_liquid(2.24+8.5*float(state.get("progress",0)))
		for c in crates:c.hide()
	else:
		inspection.window(1,0,4.22,-.5,1.98,.95,lesson_id=="Q12")
func teach(_focus:String)->void:
	var target:=Vector3(0,.65,0);var span:=9.4;var desired_yaw:=.35;var desired_pitch:=.44
	if lesson_id=="Q12":target=Vector3(0,.15,0);span=5.2;desired_yaw=1.18;desired_pitch=.12
	if lesson_id=="Q13" and phase!="intro":target=Vector3(.4,.6,0);span=8.4;desired_yaw=.2;desired_pitch=.6
	cancel();camera_motion=true
	camera_tween=create_tween().set_parallel(true)
	camera_tween.tween_property(self,"camera_target",target,.55);camera_tween.tween_property(self,"camera_span",span,.55)
	camera_tween.tween_property(self,"yaw",desired_yaw,.55);camera_tween.tween_property(self,"pitch",desired_pitch,.55)
	camera_tween.finished.connect(func():camera_motion=false;update_camera())
func anchor()->Vector2:
	return project(Vector3(0,-.18,.8)) if lesson_id=="Q12" else project(Vector3(0,1,.5))
func obstacles()->Array:
	return [Rect2(size*Vector2(.12,.18),size*Vector2(.76,.48))]
