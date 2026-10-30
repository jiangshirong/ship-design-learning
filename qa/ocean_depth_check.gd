extends "res://modules/review/qa/topics_check.gd"
func start(target)->void:
 host=target;app=host.review;page=app.stability
 await frames(10);await click(host.review_buttons.get_child(0).get_global_rect().get_center());await frames(4)
 await app.open_topic("freeboard","M11Q06");await frames(8)
 select_beat("M11:M11Q06:protect");await settle_topic()
 var marine=page.topic_ship.views.marine
 check(marine.ocean_medium.ocean_extent>=16000,"Ocean extends beyond all observation bounds")
 check(marine.camera.far>=10000,"Far clip supports continuous ocean")
 var diagnostic={"local_aabb":str(marine.water.mesh.get_aabb()),"transform":str(marine.water.global_transform),"shader":marine.water.material_override.shader.resource_path,"inspection":marine.water.material_override.get_shader_parameter("inspection"),"has_alpha":marine.water.material_override.shader.code.contains("ALPHA")}
 var diag=FileAccess.open("res://qa/ocean-medium-diagnostic.json",FileAccess.WRITE);diag.store_string(JSON.stringify(diagnostic,"  "));diag.close()
 check(not diagnostic.has_alpha,"Near sea uses opaque material")
 var stable:Dictionary=marine.source_state.duplicate(true)
 for amount in [.25,.5,1.0]:
  var state:Dictionary=stable.duplicate(true);state.forecastle=amount;marine.apply(state,page.language)
  marine.set_camera("topic",true);await frames(5);await capture("forecastle-connected-"+str(amount))
 marine.apply(stable,page.language)
 for item in [["wide",Vector3(180,200,-200),Vector3.ZERO,240.],["opposite",Vector3(150,50,150),Vector3(65,5,0),110.],["underwater",Vector3(100,-18,-25),Vector3(80,-3,0),65.],["upward",Vector3(100,-10,-25),Vector3(80,10,0),55.],["deep",Vector3(100,-110,-25),Vector3(80,-60,0),80.]]:
  marine.camera.position=item[1];marine.camera.look_at(item[2]);marine.camera.size=item[3];marine.ocean_medium.update_medium();await frames(6)
  check(marine.ocean_medium.underwater==(item[1].y<0),"Water medium follows camera "+item[0])
  await capture("ocean-depth-"+item[0])
 host.get_window().size=Vector2i(1100,760);await frames(6);await capture("ocean-depth-minimum")
 tap(KEY_ESCAPE);await frames(5)
 check(not marine.is_visible_in_tree(),"Exit hides ocean view")
 var file=FileAccess.open("res://qa/ocean-depth-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "));file.close()
 print("Ocean/forecastle ",results.size()," checks, failures ",results.filter(func(r):return not r.passed).size());get_tree().quit()
