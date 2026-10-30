extends SceneTree
func _initialize()->void:
 call_deferred("run")
func frames(n:int)->void:
 for i in n:await process_frame
func run()->void:
 var script=load("D:/桌面文件夹/学习/大学课程/过考试/船舶设计原理/船舶原理学习/qa/export_host.gd")
 var host=script.new();root.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
  root.get_texture().get_image().save_png("D:/桌面文件夹/学习/大学课程/过考试/船舶设计原理/船舶原理学习/qa/export-"+id.replace(":","-")+".png")
 print("EXPORT_SMOKE_PASS");quit()
