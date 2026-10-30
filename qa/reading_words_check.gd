extends "res://modules/review/qa/sample_check.gd"
func start(host)->void:
 app=host;host.open_review("reading");await frames(12)
 var page=host.review.reading
 page.store.path="user://review/qa-reading-words-"+str(OS.get_process_id())+".json"
 page.store.data.unknown_words={}
 page.select_question(0);await frames(10)
 var words=page.words
 check(page.listing.visible and not page.nav_button.visible,"Permanent sidebar without toggle")
 check(words.tokens.size()>0 and words.cursor==0,"First Russian word automatically selected")
 check(page.question.get_selected_text()==words.tokens[0].word,"Whole word including accents selected")
 var id:String=page.entries[page.index].id
 tap(KEY_D);await frames(3);check(words.cursor==1 and page.entries[page.index].id==id,"D selects next word not next question")
 tap(KEY_A);await frames(3);check(words.cursor==0,"A selects previous word")
 tap(KEY_F);await frames(10);check(page.revealed,"F reveals answer")
 var first_answer:=-1
 for i in words.tokens.size():
  if words.tokens[i].field!=page.question:first_answer=i;break
 check(first_answer>0,"Question and Russian answer form selection sequence")
 words.cursor=first_answer-1;words.select_current();tap(KEY_D);await frames(3)
 check(words.cursor==first_answer,"D from final question word selects first answer word")
 check(words.tokens[words.cursor].field.get_selected_text()==words.tokens[words.cursor].word,"Answer selection is one full Russian word")
 var picker=page.get_meta("word_picker")
 var answer_token:Dictionary=words.tokens[words.cursor]
 var rects_answer:Array=words.rectangles(answer_token)
 await click(answer_token.field.global_position+rects_answer[0].get_center());await frames(5)
 check(picker.panel.visible and picker.field==answer_token.field,"Russian answer click opens definition-only popup")
 check(picker.text.text.contains(answer_token.word) or picker.text.text.contains(picker.selected.get("ru", "__missing__")),"Answer popup describes clicked word")
 check(picker.panel.find_children("*","Button",true,false).is_empty(),"Word popup contains no unfamiliar button")
 picker.dismiss()
 tap(KEY_R);await frames(5)
 var marked:String=words.tokens[words.cursor].key
 var vocab=host.review.vocabulary
 vocab.path="user://review/qa-word-grades-"+str(OS.get_process_id())+".json"
 check(words.is_unknown(words.tokens[words.cursor]),"R assigns level4 highlighting")
 tap(KEY_SPACE);await frames(4)
 check(host.review.term_tooltip.panel.visible and not host.review.term_tooltip.words.text.is_empty(),"Space opens selected word meaning")
 check(page.revealed,"Space does not toggle answer")
 var tip=host.review.term_tooltip
 # Reproduce a stale span cache left by lookup in another sentence.
 tip.cache_spans=[{"start":0,"end":999,"entry":{"ru":"оши́бка","zh":"错误测试","id":"qa"}}]
 var q:Dictionary=words.tokens[0];var qrect:Array=words.rectangles(q)
 tip.hover(q.field,qrect[0].get_center());await frames(3)
 check(not tip.words.text.contains("错误测试"),"Mouse lookup refreshes spans after keyboard lookup across fields")
 words.show_meaning();await frames(3)
 tap(KEY_SPACE);await frames(3);check(not host.review.term_tooltip.panel.visible,"Space closes keyboard meaning")
 check(page.store.data.unknown_words.has(marked),"R persists unfamiliar word")
 check(words.tokens.filter(func(t):return t.key==marked).all(func(t):return words.is_unknown(t)),"All occurrences share unfamiliar highlight")
 var store=load("res://modules/review/core/reading_store.gd").new();store.path=page.store.path;store.read_file()
 check(store.data.unknown_words.has(marked),"Unfamiliar word survives store reload")
 tap(KEY_T);await frames(5)
 check(not words.is_unknown(words.tokens[words.cursor]),"T clears unfamiliar highlighting")
 check(vocab.marks.get(marked.substr(3),"")=="已掌握","T persists level1 in shared vocabulary grades")
 store.read_file();check(not store.data.unknown_words.has(marked),"T removes legacy unfamiliar marker")
 var sample:Dictionary=words.tokens[words.cursor]
 vocab.record_grade(marked.substr(3),"不熟");await frames(3)
 check(words.is_unknown(sample),"Existing level3 automatically highlights")
 vocab.record_grade(marked.substr(3),"完全不会");await frames(3)
 check(words.is_unknown(sample),"Existing level4 automatically highlights")
 vocab.record_grade(marked.substr(3),"认识");await frames(3)
 check(not words.is_unknown(sample),"Level2 no longer highlights")
 tap(KEY_R);tap(KEY_T);await frames(4)
 check(not words.is_unknown(sample),"R then T immediately clears highlighting")
 tap(KEY_F);await frames(10)
 check(not page.revealed and words.tokens.all(func(t):return t.field==page.question),"Second F hides answer and removes its selection targets")
 tap(KEY_E);await frames(10)
 check(page.entries[page.index].id!=id and words.cursor==0,"E switches question and selects first word")
 tap(KEY_Q);await frames(10);check(page.entries[page.index].id==id,"Q switches back")
 tap(KEY_F);await frames(10)
 words.cursor=0;words.select_current();var at:Vector2=words.centre(words.tokens[0])
 tap(KEY_S);await frames(3)
 check(words.centre(words.tokens[words.cursor]).y>at.y,"S selects word on lower visual row")
 tap(KEY_W);await frames(3)
 check(words.centre(words.tokens[words.cursor]).y<=at.y+3,"W returns to upper visual row")
 tap(KEY_R);await frames(5)
 await RenderingServer.frame_post_draw
 host.get_viewport().get_texture().get_image().save_png("res://qa/reading-words.png")
 host.get_window().size=Vector2i(1100,760);await frames(10)
 check(page.listing.visible and page.panel.position.x>page.listing.get_rect().end.x,"Permanent sidebar fits minimum window")
 var rects:Array=words.rectangles(words.tokens[words.cursor]);check(not rects.is_empty(),"Word highlight has shaped glyph bounds")
 await RenderingServer.frame_post_draw
 host.get_viewport().get_texture().get_image().save_png("res://qa/reading-words-minimum.png")
 tap(KEY_V);await frames(20)
 check(host.review.mode=="stability","V still opens animation")
 var course=host.review.stability
 var old_phase:String=course.player.phase;tap(KEY_E);await frames(4)
 check(course.player.phase!=old_phase or course.player.current>0,"E advances animation")
 tap(KEY_ESCAPE);await frames(8)
 check(host.review.mode=="reading" and page.listing.visible,"Escape returns to permanent question navigation")
 await host.open_course(host.courses[0].id);await frames(10)
 var before_phase:String=host.player.phase;tap(KEY_E);await frames(4)
 check(host.player.phase!=before_phase or host.player.current>0,"Original course E advances")
 tap(KEY_Q);await frames(4);check(host.mode=="lesson","Original course Q remains valid")
 await host.open_bulkheads();await frames(12)
 before_phase=host.bulkheads.player.phase;tap(KEY_E);await frames(4)
 check(host.bulkheads.player.phase!=before_phase or host.bulkheads.player.current>0,"Bulkhead course E advances")
 tap(KEY_Q);await frames(4);check(host.mode=="bulkheads","Bulkhead course Q remains valid")
 var f=FileAccess.open("res://qa/reading-words-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close()
 var failed:int=results.filter(func(r):return not r.passed).size()
 print("Reading words ",results.size()," checks; failures ",failed);get_tree().quit(1 if failed else 0)
