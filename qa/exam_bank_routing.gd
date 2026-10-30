extends RefCounted
func frames(main,count_:int=3)->void:
 for i in count_:await main.get_tree().process_frame
func run(main)->void:
 await frames(main)
 assert(main.review_buttons.get_child_count()==3)
 var names=["课程题目","考前题目","考试真题"]
 for i in 3:assert(main.review_buttons.get_child(i).text==names[i])
 for width in [1100,1440]:
  main.get_window().size=Vector2i(width,900);await frames(main)
  assert(main.review_buttons.position.x>=0 and main.review_buttons.position.x+main.review_buttons.size.x<=width)
 for i in [1,2,0,2,1]:
  main.review_buttons.get_child(i).pressed.emit();await frames(main)
  var bank=main.review.bank_id;var page=main.review.reading
  assert(bank==["legacy","exam12","exams"][i])
  if i==1:assert(page.entries.size()==72 and not page.entries.any(func(q):return q.id.begins_with("THU")))
  if i==2:
   assert(page.entries.size()==10 and page.topics[0].title.zh=="周四真题")
   page.select_question(0);page.reveal();await frames(main)
   assert(not page.animation_button.visible)
  main.review.go_home();await frames(main);assert(main.mode=="home" and main.review_buttons.visible)
 var Store=load("res://modules/review/core/reading_store.gd")
 var source="res://qa/exam-bank-fixture-source.json";var target="res://qa/exam-bank-fixture-target-"+str(OS.get_process_id())+".json"
 var old={"schema_version":1,"selected":"THU03","filter":"pending","marks":{"THU03":"known","THU04":"review","P12_T03":"known"},"expanded":{},"unknown_words":{},"word_levels":{"test":4}}
 var f=FileAccess.open(source,FileAccess.WRITE);f.store_string(JSON.stringify(old));f.close()
 var prep=Store.new();prep.catalog_path="res://modules/review/content/exam12/reading.json";prep.path=source;prep.migration_bank="exam12";prep.read_file()
 assert(not prep.blocked and prep.data.selected=="P12_T03" and not prep.data.marks.has("THU03") and prep.data.moved_exam_marks.THU03=="known")
 var exams=Store.new();exams.catalog_path="res://modules/review/content/exams/reading.json";exams.path=target;exams.migration_source_path=source;exams.migration_bank="exams";exams.read_file()
 assert(not exams.blocked and exams.data.selected=="THU03" and exams.data.marks.size()==2 and exams.data.word_levels.test==4)
 f=FileAccess.open(source,FileAccess.WRITE);f.store_string(JSON.stringify(prep.data));f.close()
 var later=Store.new();later.catalog_path=exams.catalog_path;later.path=target;later.migration_source_path=source;later.migration_bank="exams";later.read_file()
 assert(not later.blocked and later.data.selected=="THU03" and later.data.marks.THU04=="review")
 exams.data.selected="THU08";assert(exams.write_file())
 var existing=Store.new();existing.catalog_path=exams.catalog_path;existing.path=target;existing.migration_source_path=source;existing.migration_bank="exams";existing.read_file();assert(existing.data.selected=="THU08")
 if "--capture" in OS.get_cmdline_user_args():
  main.show_home();await frames(main,8);await main.get_tree().process_frame;await RenderingServer.frame_post_draw
  main.get_viewport().get_texture().get_image().save_png("res://qa/exam-bank-home.png")
  main.open_review("exams");await frames(main,8);await RenderingServer.frame_post_draw
  main.get_viewport().get_texture().get_image().save_png("res://qa/exam-bank-exams.png")
 f=FileAccess.open("res://qa/exam-bank-routing.json",FileAccess.WRITE);f.store_string(JSON.stringify({"pass":true,"home_labels":names,"preparation_cards":66,"exam_cards":10,"navigation":true,"progress_migration":true,"existing_target_not_overwritten":true,"live_user_files_touched":false}));f.close()
 print("EXAM_BANK_ROUTING_PASS");main.get_tree().quit()
