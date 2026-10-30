extends SceneTree
func _initialize()->void:
 call_deferred("run")
func run()->void:
 var panel=load("res://modules/review/view/latex_panel.gd").new()
 root.add_child(panel)
 var formulas:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/bulkheads_latex.json"))
 var values={"bh_n":"60","bh_x":"149.89","bh_l1":"24.84","bh_l2":"21.09","bh_pair":"45.93","bh_total":"189.13"}
 var results:Array=[]
 for width in [680,380]:
  panel.size=Vector2(width,2400)
  for language in ["zh","ru"]:
   for id in formulas:
    panel.set_beat(id,values,language)
    await process_frame
    var ok:=true
    for region in panel.hint_regions:
     var hint:String=panel._get_tooltip(region.rect.get_center())
     if hint.is_empty() or region.rect.size.x<=0 or region.rect.size.y<=0:ok=false
    results.append({"id":id,"language":language,"width":width,"regions":panel.hint_regions.size(),"passed":ok and panel.render_errors==0 and panel.slot_overflows==0})
 var f=FileAccess.open("res://qa/bulkhead-symbol-hints.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(results,"  "));f.close()
 print("Bulkhead formula cases: ",results.size()," failures: ",results.filter(func(r):return not r.passed).size())
 quit(1 if results.any(func(r):return not r.passed) else 0)
