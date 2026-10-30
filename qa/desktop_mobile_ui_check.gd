extends "res://modules/review/qa/sample_check.gd"
var host
var page
var module
var picker
var metrics:Dictionary={}
func shot(name:String)->void:
 await RenderingServer.frame_post_draw
 host.get_viewport().get_texture().get_image().save_png("res://qa/desktop-mobile-ui-20261026/"+name+".png")
func select(id:String)->void:
 for i in page.entries.size():
  if page.entries[i].id==id:page.select_question(i);break
 await frames(8)
func start(target)->void:
 host=target;app=host
 check(host.review_buttons.get_child_count()==1,"Home has only one review entry")
 check(host.review_buttons.get_child(0).text=="题目复习","Home reading entry renamed")
 await click(host.review_buttons.get_child(0).get_global_rect().get_center());await frames(15);module=host.review;page=module.reading;picker=page.get_meta("word_picker")
 check(module.mode=="reading" and page.visible and module.bottom_bar.current==0,"Home review entry defaults to question tab")
 page.store.path="user://review/qa-desktop-mobile-reading-"+str(OS.get_process_id())+".json"
 module.vocabulary.path="user://review/qa-desktop-mobile-grades-"+str(OS.get_process_id())+".json";module.vocabulary.marks={};module.vocabulary.schedule={}
 page.store.data.unknown_words={};page.store.data.word_levels={}
 check(page.entries.size()==62,"All 62 original question cards")
 check(module.bottom_bar.buttons.size()==3,"Three directly connected bottom destinations")
 await select("N01")
 var ratio_field=page.question
 var ratio_line:int=-1
 for line in ratio_field.get_line_count():
  if not ratio_field.fractions(ratio_field.get_line(line)).is_empty():ratio_line=line;break
 check(ratio_line>=0,"Relative stability question contains inline ratio")
 if ratio_line>=0:
  var at:int=ratio_field.fractions(ratio_field.get_line(ratio_line))[0].get_start();var offset:=0
  for line in ratio_line:offset+=ratio_field.get_line(line).length()+1
  ratio_field.set_meta("word_grade_ranges",[{"start":offset+at,"end":offset+at+1},{"start":offset+at+2,"end":offset+at+3}])
  ratio_field.syntax_highlighter.clear_highlighting_cache()
  var ink:Dictionary=ratio_field.syntax_highlighter.get_line_syntax_highlighting(ratio_line)
  check(ink.has(at) and ink[at].color.a==0 and not ink.has(at+1) and not ink.has(at+2),"Grade coloring cannot expose native slash or denominator over LaTeX fraction")
  ratio_field.set_meta("word_grade_ranges",[]);ratio_field.syntax_highlighter.clear_highlighting_cache()
 await frames(5);await shot("11-inline-fraction-fixed")
 await select("Q01")
 check(not page.revealed and not page.translation.visible,"Initial Russian-only question")
 await click(page.chinese_button.get_global_rect().get_center());await frames(8)
 check(page.translation.visible and page.translation.full_text==page.entries[page.index].translation,"Chinese control reveals only question meaning")
 check(not page.revealed,"Chinese control does not reveal answer")
 await click(page.chinese_button.get_global_rect().get_center());await frames(6)
 check(not page.translation.visible,"Chinese meaning independently hidden")
 await shot("01-question")
 tap(KEY_F);await frames(8);check(page.revealed,"F reveals answer")
 await shot("02-answer")
 var topic:String=page.entries[page.index].topic;var start_id:String=page.entries[page.index].id
 tap(KEY_E);await frames(8);check(page.entries[page.index].id!=start_id and page.entries[page.index].topic==topic,"E moves in topic order")
 check(page.words.cursor==0,"Question change selects first full word")
 tap(KEY_Q);await frames(8);check(page.entries[page.index].id==start_id,"Q returns within same topic")
 tap(KEY_D);await frames(3);check(page.words.cursor==1,"D still navigates whole Russian words")
 tap(KEY_A);await frames(3);check(page.words.cursor==0,"A still navigates whole Russian words")
 tap(KEY_R);await frames(5);check(page.words.is_unknown(page.words.tokens[0]),"R still marks level4")
 tap(KEY_T);await frames(5);check(not page.words.is_unknown(page.words.tokens[0]),"T still marks level1")
 for e in page.entries:
  if e.question_ru.contains("документа"):await select(e.id);break
 var index:=-1
 for i in page.words.tokens.size():
  if page.words.normalized(page.words.tokens[i].word).begins_with("документа"):index=i;break
 check(index>=0,"Context word available")
 page.words.cursor=index;page.words.select_current();tap(KEY_SPACE);await frames(10)
 check(picker.panel.visible,"Space opens unified word sheet")
 check(picker.candidates.size()>=2,"Word and fixed phrase displayed together")
 var printed:Array=[]
 for e in picker.candidates:printed.append(e.ru)
 var unique:Dictionary={}
 for ru in printed:unique[ru]=true
 check(printed.size()==unique.size(),"No duplicate displayed Russian entries")
 var word_id:String=picker.candidates[0].id;var phrase_id:String=""
 for e in picker.candidates:
  if picker.phrase_entry(e):phrase_id=e.id;break
 check(not phrase_id.is_empty(),"Related phrase has independent identity")
 picker.rate(word_id,"已掌握");await frames(8)
 picker.rate(phrase_id,"不熟");await frames(8)
 check(module.vocabulary.marks[word_id]=="已掌握" and module.vocabulary.marks[phrase_id]=="不熟","Word and phrase independently graded")
 check(picker.panel.visible,"Grading does not dismiss word sheet")
 await shot("03-dictionary")
 var original:int=page.index
 await click(page.next_button.get_global_rect().get_center());await frames(8)
 check(not picker.panel.visible and page.index==original,"Outside click only dismisses; no underlying navigation")
 page.words.show_meaning();await frames(6)
 var outside:Vector2=page.next_button.get_global_rect().get_center()
 for token in page.words.tokens:
  var point:Vector2=page.words.centre(token)
  if not picker.panel.get_global_rect().has_point(point) and page.panel.get_global_rect().has_point(point):outside=point;break
 await click(outside);await frames(8)
 check(not picker.panel.visible,"Click another word dismisses without reopening")
 page.words.show_meaning();await frames(6)
 var p:Vector2=page.next_button.get_global_rect().get_center()
 var down:=InputEventScreenTouch.new();down.index=0;down.position=p;down.pressed=true;host.get_viewport().push_input(down,true)
 var up:=InputEventScreenTouch.new();up.index=0;up.position=p;up.pressed=false;host.get_viewport().push_input(up,true)
 var mouse:=InputEventMouseButton.new();mouse.device=InputEvent.DEVICE_ID_EMULATION;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=p;mouse.pressed=true;host.get_viewport().push_input(mouse,true);mouse=mouse.duplicate();mouse.pressed=false;host.get_viewport().push_input(mouse,true)
 await frames(8);check(page.index==original and not picker.panel.visible,"Touch plus emulated mouse gesture cannot penetrate modal")
 tap(KEY_F);await frames(8);var shown:bool=page.revealed
 page.words.show_meaning();await frames(6);tap(KEY_ESCAPE);await frames(6)
 check(module.mode=="reading" and not picker.panel.visible and page.revealed==shown,"Escape closes modal before leaving question")
 var changed_topic:String=""
 for i in page.entries.size():
  if page.entries[i].topic!=page.entries[page.index].topic:changed_topic=page.entries[i].topic;page.select_question(i);break
 await frames(8);tap(KEY_E);await frames(8);check(page.entries[page.index].topic==changed_topic,"Question navigation stays in chosen topic")
 # Exercise every original card and each original formula, without altering data.
 for i in page.entries.size():
  page.select_question(i);await frames(4);tap(KEY_F);await frames(5)
  check(page.question.full_text==page.entries[i].question_ru,"Unchanged Russian question "+page.entries[i].id)
  check(page.details.get_child(0).full_text==page.entries[i].answer.ru,"Unchanged Russian answer "+page.entries[i].id)
  if page.entries[i].has("condition"):
   var texts:Array=[]
   for child in page.details.get_children():
    if child is TextEdit:texts.append(child.full_text)
   check(page.entries[i].condition.zh in texts,"Original necessary condition retained "+page.entries[i].id)
  for math in page.formula_panels:check(math.render_errors==0 and math.light_mode,"Clear light-theme formula "+page.entries[i].id)
 await select("Q09");tap(KEY_F);await frames(8)
 check(page.example_button.visible and page.variant_button.visible,"Original example and variant entry points retained")
 page.scroll.ensure_control_visible(page.variant_button);await frames(8)
 await click(page.variant_button.get_global_rect().get_center());await frames(7);tap(KEY_F);await frames(8)
 check(page.exercise=="variant" and page.revealed and page.formula_panels.size()>0,"Calculation variant still reveals full solution")
 await shot("07-calculation")
 # Font limits and narrow topic drawer.
 module.font_scale=1.6;page.arrange();await frames(8)
 check(page.font_plus.disabled and page.font_plus.get_theme_color("font_disabled_color").a>0.9,"Font-limit button remains readable")
 module.font_scale=1.;host.get_window().size=Vector2i(1100,760);await frames(8)
 check(not page.listing.visible,"Narrow screen uses topic entry instead of permanent sidebar")
 await click(page.topic_select.get_global_rect().get_center());await frames(5)
 check(page.listing.visible and page.topic_shade.visible,"Narrow topic drawer opens")
 page.topic_open=false;page.arrange();await frames(5)
 await shot("08-question-small")
 host.get_window().size=Vector2i(1440,900);module.switch_tab("词汇");await frames(20)
 var vocab=module.vocabulary
 check(not vocab.scientific and vocab.list_scroll.visible and not vocab.card.visible,"Vocabulary is a continuous list")
 check(vocab.filter_buttons.size()==5 and vocab.filter_buttons.keys().has("未标记"),"Five multi-select grade filters")
 check(vocab.list_view.get_child_count()==0,"Cached list does not create one widget per word")
 check(vocab.list_view.drawn_rows<vocab.entries.size(),"Only visible list rows drawn")
 await shot("04-vocabulary")
 var durations:Array=[]
 for repeat in 10:
  var begin:=Time.get_ticks_usec();vocab.open_category("词组" if repeat%2==0 else "单词");durations.append((Time.get_ticks_usec()-begin)/1000.)
  await frames(2)
 durations.sort();metrics.list_switch_median_ms=durations[durations.size()/2]
 vocab.open_category("单词");await frames(8)
 check(vocab.entries.size()==vocab.all_entries.filter(func(e):return vocab.kind(e)=="单词").size(),"Entire word collection remains accessible")
 var last:Dictionary=vocab.entries[-1];vocab.list_scroll.scroll_vertical=int(vocab.list_view.custom_minimum_size.y);await frames(8)
 check(vocab.list_view.row_rect(last.id).intersects(vocab.list_scroll.get_global_rect()),"Last row is reachable by scrolling")
 vocab.list_scroll.scroll_vertical=0;await frames(5)
 var entry:Dictionary=vocab.entries[0]
 await click(vocab.list_view.row_rect(entry.id).get_center());await frames(8)
 check(picker.panel.visible and picker.candidates[0].id==entry.id,"Vocabulary row opens same dictionary sheet")
 picker.rate(entry.id,"完全不会");await frames(8)
 check(vocab.marks[entry.id]=="完全不会","List grading shares original grade store")
 picker.dismiss()
 for key in vocab.filter_buttons:if key!="完全不会" and key in vocab.selected_filters:vocab.set_filter(key,false)
 await frames(8)
 check(vocab.entries.all(func(e):return vocab.marks.get(e.id,"")=="完全不会"),"Multi-select filters reflect new grades immediately")
 for key in vocab.filter_buttons:vocab.set_filter(key,true)
 vocab.open_category("词组");await frames(8)
 check(vocab.entries.all(func(e):return vocab.kind(e)=="词组"),"Word/phrase categories stay separate")
 # Reuse exact fixed review schedule and ordering.
 vocab.marks.clear();vocab.schedule.clear();vocab.clock_override=10000
 module.switch_tab("科学复习");await frames(15)
 check(vocab.scientific and vocab.entries.size()<=20 and not vocab.filters.visible,"Scientific review keeps round cap without filter/algorithm copy")
 check(not vocab.grades.visible,"Review rating appears only after reveal")
 await shot("05-review")
 tap(KEY_SPACE);await frames(8)
 check(vocab.revealed and vocab.grades.visible,"Space reveals review meaning and grade actions")
 await shot("06-review-answer")
 var reviewed:String=vocab.entries[vocab.index].id;tap(KEY_3);await frames(8)
 check(vocab.marks.get(reviewed)=="不熟" and not vocab.revealed,"Numeric grading saves and advances review")
 check(vocab.schedule[reviewed].due_at==10600,"Existing ten-minute level3 interval retained")
 check(vocab.entries.all(func(e):return e.id!=reviewed),"Graded item removed from current due queue")
 for i in vocab.LEVELS.size():
  vocab.record_grade("qa-grade-"+str(i),vocab.LEVELS[i])
  check(vocab.schedule["qa-grade-"+str(i)].due_at==10000+[7200,1800,600,120][i],"Original review interval "+str(i+1))
 host.get_window().size=Vector2i(1100,760);module.font_scale=1.6
 var candidates:Array=vocab.all_entries.filter(func(e):return vocab.kind(e)==vocab.category)
 var longest:Dictionary=candidates[0]
 for e in candidates:
  if e.ru.length()+e.zh.length()>longest.ru.length()+longest.zh.length():longest=e
 vocab.entries=[longest];vocab.index=0;vocab.revealed=true;vocab.refresh();await frames(12)
 check(vocab.card.get_global_rect().end.y<vocab.grades.position.y,"Long review content does not push card over grades")
 check(vocab.reveal_button.get_global_rect().end.y<module.bottom_bar.position.y,"Large-font review navigation stays above tab bar")
 await shot("09-review-small-large-font")
 module.switch_tab("词汇");await frames(12);vocab.open_entry(longest.id);await frames(12)
 check(picker.panel.get_global_rect().end.y<host.size.y and picker.panel.size.x<=host.size.x-40,"Large-font dictionary remains inside minimum window")
 await shot("10-dictionary-small-large-font")
 picker.dismiss();module.font_scale=1.;host.get_window().size=Vector2i(1440,900);await frames(8)
 var loaded=load("res://modules/review/view/vocabulary.gd").new();loaded.path=vocab.path;loaded.load_marks()
 check(loaded.marks[reviewed]=="不熟" and loaded.schedule[reviewed].due_at==10600,"Compatible grade and due-time file reload")
 loaded.free()
 module.switch_tab("题目");await frames(15)
 check(page.exercise=="variant" and page.revealed,"Direct tab switch restores reading state")
 await select("Q16");tap(KEY_V);await frames(20)
 check(module.mode=="stability" and not module.bottom_bar.visible,"Original 3D stability animation retained")
 var course=module.stability;var old_phase:String=course.player.phase;tap(KEY_E);await frames(5)
 check(course.player.phase!=old_phase or course.player.current>0,"Animation Q/E still active")
 tap(KEY_ESCAPE);await frames(10)
 check(module.mode=="reading" and page.entries[page.index].id=="Q16","Animation Escape restores original question")
 for tab in ["题目","词汇","科学复习"]:
  host.open_review("reading");await frames(5);module.switch_tab(tab);await frames(8)
  tap(KEY_ESCAPE);await frames(8)
  check(host.mode=="home" and module.mode=="inactive" and not module.visible,"Escape returns home from bottom tab "+tab)
 await host.open_course(host.courses[0].id);await frames(15)
 check(host.mode=="lesson","Original course tree still opens original lesson")
 var f=FileAccess.open("res://qa/desktop-mobile-ui-20261026/results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":results,"metrics":metrics},"  "));f.close()
 print("Desktop mobile UI ",results.size()," checks; failures ",results.filter(func(r):return not r.passed).size());get_tree().quit()
