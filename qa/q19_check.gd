extends "res://modules/review/qa/topics_check.gd"
func start(target)->void:
 host=target;app=host.review
 host.open_review("reading");await frames(3)
 await app.open_topic("stability","Q19");page=app.stability
 var group:Dictionary={}
 for g in page.course.groups:
  if g.id=="Q19":group=g
 check(group.beats.size()==7,"Q19 has seven nonduplicate segments")
 check(group.title.zh=="最大力臂","No question number in stage title")
 for b in group.beats:
  select_beat(b.id);await settle_topic()
  check(page.player.phase in ["settled","complete"],"Stable "+b.id)
  if b.id=="ST:peak_lower":
   check(is_equal_approx(float(page.current_state.morph),1.0),"Lower hull state retained for explanation")
  if b.id=="ST:peak_G":
   check(is_equal_approx(float(page.current_state.zg),7.7),"Independent G comparison retained")
  if b.id=="ST:Q19:answer":
   check(not b.has("action"),"Conclusion does not replay lowering")
   check(is_equal_approx(float(page.current_state.zg),7.7),"Conclusion keeps last demonstration state")
   await capture("q19-deduplicated")
 var Store=load("res://modules/review/core/topic_store.gd")
 var saved=Store.new();saved.path="user://review/qa-q19-migration.json"
 var file:=FileAccess.open(saved.path,FileAccess.WRITE)
 file.store_string(JSON.stringify({"version":1,"topics":{"stability":{"beat":"TOP:Q19:answer","foundation_done":true,"pending":"","language":"ru"}}}));file.close()
 saved.read_file();check(saved.data.topics.stability.beat=="ST:Q19:answer","Removed old final step maps to retained conclusion")
 tap(KEY_F2);await frames(3);check(page.beat.id=="ST:Q19:answer","Language switch keeps final step")
 tap(KEY_Q);await frames(3);tap(KEY_Q);await frames(3)
 check(page.beat.id in ["ST:peak_G","ST:peak_lower"],"Backward navigation remains valid")
 tap(KEY_ESCAPE);await frames(3);check(not page.player.active,"Exit stops lesson")
 var out:=FileAccess.open("res://qa/q19-deduplicated.json",FileAccess.WRITE);out.store_string(JSON.stringify(results,"\t"));out.close()
 print("Q19 ",results.size()," checks; failures ",results.filter(func(r):return not r.passed).size());get_tree().quit()
