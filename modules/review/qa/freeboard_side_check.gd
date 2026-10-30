extends "res://modules/review/qa/topics_check.gd"

func start(target)->void:
	host=target;app=host.review;page=app.stability
	await frames(12)
	await click(host.review_buttons.get_child(0).get_global_rect().get_center())
	await frames(5)
	await app.open_topic("freeboard","N13")
	await frames(5)
	for id in ["TOP:N13:measure","TOP:N13:reserve","TOP:N14:full"]:
		select_beat(id)
		await settle_topic()
		var marine=page.topic_ship.active
		check(marine.camera.position.z<0,"Camera faces dimension side "+id)
		var body:Node3D=marine.bodies[0]
		var near:Vector3=body.to_global(Vector3(0,14.89,-13.3))
		var far:Vector3=body.to_global(Vector3(0,14.89,13.3))
		check(marine.camera.global_position.distance_to(near)<marine.camera.global_position.distance_to(far),"Marked deck edge is near edge "+id)
		var deck:Vector2=marine.project(near)
		var water:Vector2=marine.project(Vector3(0,0,-13.3))
		var bottom:Vector2=marine.project(body.to_global(Vector3(0,0,-13.3)))
		check(deck.y<water.y and water.y<bottom.y,"F and T endpoints ordered "+id)
		await capture("freeboard-side-"+id.replace(":","-"))
	var failed:=results.filter(func(r):return not r.passed).size()
	var file:=FileAccess.open("res://modules/review/qa/freeboard-side-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"));file.close()
	print("Freeboard camera: ",results.size()," checks; failures=",failed)
	get_tree().quit(1 if failed else 0)
