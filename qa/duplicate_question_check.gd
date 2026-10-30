extends SceneTree
func _initialize()->void:
 var Store=load("res://modules/review/core/reading_store.gd")
 var store=Store.new();store.catalog_path="res://modules/review/content/exam12/question_bank.json"
 assert(store.valid_id("P13_Q30"));assert(store.canonical_id("P13_Q30")=="P12_T03");assert(not store.valid_id("bad-id"))
 var cases=[{"P13_Q30":"known"},{"P13_Q30":"review","P12_T03":"known"},{"P13_Q30":"known","P12_T03":"review"}]
 for i in cases.size():
  var data={"selected":"P13_Q30","marks":cases[i].duplicate(),"word_levels":{"word":4}}
  store.merge_duplicate_progress(data)
  assert(data.selected=="P12_T03");assert(not data.marks.has("P13_Q30"));assert(data.marks.P12_T03==("known" if i==0 else "review"));assert(data.word_levels.word==4)
 var again={"selected":"P12_T03","marks":{"P12_T03":"known"}};store.merge_duplicate_progress(again);assert(again.marks.P12_T03=="known")
 var legacy=Store.new();assert(legacy.canonical_id("P13_Q30")=="P13_Q30")
 var script=GDScript.new();script.source_code=FileAccess.get_file_as_string("D:/桌面文件夹/学习/大学课程/过考试/船舶设计原理/新题目手抄/reader_state.gd")
 assert(script.reload()==OK)
 var phone=script.new();phone.ids=["P12_T03"]
 var saved={"schema":1,"selected":"P13_Q30","grouping":"topic","chinese":true,"font_scale":1.0,"scroll":0}
 assert(phone.valid(phone.migrate(saved)));assert(phone.migrate(saved).selected=="P12_T03");assert(saved.selected=="P13_Q30")
 var f=FileAccess.open("res://qa/duplicate-question-progress.json",FileAccess.WRITE);f.store_string(JSON.stringify({"pass":true,"cases":6,"live_user_files_touched":false}));f.close()
 print("Duplicate progress migration passed");quit()
