extends Node
func frames(n:int)->void:
 for i in n:await get_tree().process_frame
func start(host)->void:
 await frames(15)
 print("EXPORT_HOME_OK")
 host.open_review("reading");await frames(15)
 print("EXPORT_QUESTIONS ",host.review.reading.entries.size())
 await host.review.open_topic("freeboard","M11Q06");await frames(20)
 var page=host.review.stability
 for id in ["M11:M11Q06:before","M11:M11Q06:protect","M11:M11Q07:impact"]:
  for i in page.player.beats.size():
   if page.player.beats[i].id==id:page.goto_index(i);break
  await frames(8);page.player.complete_busy()
  if page.player.phase=="ready":page.player.finish()
  await frames(12)
  var marine=page.topic_ship.views.marine
  print("EXPORT_SEA ",id," ",marine.water.visible)
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://qa/export-"+id.replace(":","-")+".png")
 print("EXPORT_SMOKE_PASS");get_tree().quit()
