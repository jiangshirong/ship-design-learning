extends "res://modules/review/qa/topics_check.gd"

func start(target)->void:
	host=target;app=host.review;page=app.stability
	await frames(12)
	await click(host.review_buttons.get_child(0).get_global_rect().get_center())
	await frames(5);await app.open_topic("freeboard","N15");await frames(5)
	var marine=page.topic_ship.views.marine
	var identity:int=marine.freeboard_ship.get_instance_id()
	check(marine.morph_parts.size()>60,"Detailed Blender components loaded")
	for sample in [["TOP:N15:volume","superstructure","Superstructure"],["TOP:N16:sheer","sheer","Sheer"],["TOP:N16:forecastle","forecastle","Forecastle"]]:
		select_beat(sample[0]);await settle_topic()
		var stable:Dictionary=marine.source_state.duplicate(true)
		for amount in [0.0,0.5,1.0]:
			var state_:Dictionary=stable.duplicate(true);state_[sample[1]]=amount
			marine.apply(state_,page.language);await frames(5)
			check(marine.freeboard_ship.get_instance_id()==identity,"Persistent ship "+sample[1]+str(amount))
			check(not marine.shells[0].visible and not marine.fittings[0].visible,"No duplicate hull "+sample[1]+str(amount))
			for part in marine.morph_parts:
				for i in part.mesh.get_blend_shape_count():
					if str(part.mesh.get_blend_shape_name(i))==sample[2]:
						check(is_equal_approx(part.get_blend_shape_value(i),amount),"Morph "+str(part.name)+str(amount))
			await capture("freeboard-"+sample[1]+"-"+str(amount))
		select_beat(sample[0]);await settle_topic()
		check(marine.freeboard_ship.get_instance_id()==identity,"Jump restores same model")
	select_beat("TOP:N13:measure");await settle_topic()
	for part in marine.morph_parts:
		for i in part.mesh.get_blend_shape_count():check(is_zero_approx(part.get_blend_shape_value(i)),"Returning restores base "+str(part.name))
	tap(KEY_ESCAPE);await frames(3)
	check(not page.player.active,"Exit stops animation")
	var failed:=results.filter(func(r):return not r.passed).size()
	var file:=FileAccess.open("res://modules/review/qa/freeboard-morph-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"));file.close()
	print("Freeboard morph: ",results.size()," checks; failures=",failed)
	get_tree().quit(1 if failed else 0)
