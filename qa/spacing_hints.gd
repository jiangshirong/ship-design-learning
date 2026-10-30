extends SceneTree
func _initialize()->void:
 call_deferred("run")
func run()->void:
 var panel=load("res://modules/review/view/latex_panel.gd").new()
 root.add_child(panel);panel.size=Vector2(680,700)
 await process_frame
 var results:Array=[]
 for language in ["zh","ru"]:
  for id in ["BH:normal","BH:peakspacing"]:
   panel.set_beat(id,{},language)
   await process_frame
   var normal:=false;var practical:=false
   for region in panel.hint_regions:
    var hint:String=panel._get_tooltip(region.rect.get_center())
    if hint.contains("正常肋距"):normal=true
    if hint.contains("实际采用的普通肋距"):practical=true
   results.append({"id":id,"language":language,"passed":normal and (practical if id=="BH:peakspacing" else true)})
 for id in ["BH:webvalues","BH:webengine","BH:webtransition","BH:webfore","BH:webaft"]:
  panel.set_beat(id,{},"zh")
  await process_frame
  var found:=false
  for region in panel.hint_regions:
   if panel._get_tooltip(region.rect.get_center()).contains("强肋骨间距"):found=true
  results.append({"id":id,"passed":found})
 var f=FileAccess.open("res://qa/spacing-hints.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(results,"  "));f.close()
 print(results)
 quit(1 if results.any(func(r):return not r.passed) else 0)
