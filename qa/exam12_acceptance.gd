extends RefCounted
var checks:Array=[]
var main
func check(ok:bool,label:String)->void:
 checks.append({"check":label,"pass":ok});if not ok:push_error(label)
func frame()->void:await main.get_tree().process_frame
func key(code:int)->void:
 for pressed in [true,false]:
  var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;main.get_viewport().push_input(event,true)
 await frame()
func capture(name_:String)->void:
 for i in 7:await frame()
 await RenderingServer.frame_post_draw
 main.get_viewport().get_texture().get_image().save_png("res://qa/exam12-"+name_+".png")
func run(host)->void:
 main=host
 await frame()
 check(main.review_buttons.get_child_count()==2,"两个题库入口")
 await capture("home")
 main.review_buttons.get_child(1).pressed.emit();await frame();await frame()
 var module=main.review;var page=module.reading
 page.store.data.filter="all";page.store.data.marks.clear();page.rebuild_filter();page.select_question(0)
 check(module.bank_id=="exam12","新入口读取12p配置")
 check(page.entries.size()==73,"67道题及6组识图项")
 check(page.topics.size()==8,"八个专题")
 check(page.entries.filter(func(e):return e.get("kind","")!="figure").size()==67,"真实题干数量")
 await capture("reading")
 var ids:Dictionary={}
 for q in page.entries:
  check(not ids.has(q.id),"唯一题卡 "+q.id);ids[q.id]=true
  page.select_question(page.entries.find(q));page.reveal();await frame()
  check(page.current_question()==q.question_ru,"完整原文 "+q.id)
  if q.get("kind","")!="figure":
   check(page.details.get_child(0).text==q.answer.ru and page.details.get_child(1).text==q.answer.zh,"完整双语回答 "+q.id)
  if q.has("images"):
   check(is_instance_valid(page.picture_panel),"原图显示 "+q.id)
   for pic in q.images:check(ResourceLoader.exists(pic.path),"图片资源 "+str(pic.number))
 await capture("pictures")
 page.select_question(page.entries.find(page.entries.filter(func(e):return e.id=="P12_F01")[0]));await frame();await frame()
 var picture=page.picture_panel
 picture.open_zoom();await frame();await frame()
 check(is_instance_valid(picture.zoom) and picture.zoom.visible,"原图可独立放大")
 var tags=picture.tags;var rect:Rect2=tags.image_rect();var tag:Array=tags.tags[0]
 var motion:=InputEventMouseMotion.new();motion.position=rect.position+Vector2(tag[0],tag[1])*rect.size
 tags._gui_input(motion)
 check(tags.panel.visible and tags.copy.text.contains(tag[3]),"原图标签即时俄汉释义")
 picture.zoom.close_requested.emit();await frame()
 page.select_question(page.entries.find(page.entries.filter(func(e):return e.id=="P12_C02")[0]));page.reveal()
 main.get_window().size=Vector2i(1100,760);await capture("minimum-calculation")
 var symbol_count:=0
 for region in page.question.symbol_regions:
  check(not page.question.notation_hint(region.sub_rect.get_center()).is_empty(),"题干下标释义 "+region.span.suffix)
  check(not page.question.notation_hint(region.base_rect.get_center()).is_empty(),"题干字母释义 "+region.span.base)
  symbol_count+=1
 check(symbol_count>0,"题干下标实际排版")
 page.scroll.ensure_control_visible(page.answer_panel);await capture("minimum-calculation-answer")
 main.get_window().size=Vector2i(1440,900)
 var glossary=load("res://modules/review/core/glossary.gd").new()
 var words:Array=glossary.study_entries("res://modules/review/content/exam12/reading.json")
 check(words.size()>100,"新问答词汇池")
 var old_words:Array=glossary.study_entries()
 var reused:=0
 for w in words:
  if old_words.any(func(a):return a.id==w.id):reused+=1
 check(reused>50,"沿用熟词ID")
 page.select_question(page.entries.find(page.entries.filter(func(e):return e.id=="P12_T17")[0]));page.reveal();await frame()
 main.get_window().size=Vector2i(1100,760)
 page.scroll.ensure_control_visible(page.answer_panel);await capture("reasoned-prototype-minimum")
 var answer_field=page.details.get_child(0)
 check(answer_field.scroll_fit_content_height,"长回答由页面滚动，不裁切正文")
 var form_pos:int=answer_field.text.find("согласова́ть")
 var form_rect:=Rect2(answer_field.get_rect_at_line_column(0,form_pos+2))
 if form_rect.size.x>0:
  var form_hover:=InputEventMouseMotion.new();form_hover.position=form_rect.get_center();answer_field.gui_input.emit(form_hover)
  var live_tip=load("res://modules/review/view/term_tooltip.gd").shared(answer_field)
  check(live_tip.panel.visible and not live_tip.current.is_empty(),"新回答词形实际悬停即时显示")
  await capture("reasoned-word-hover");live_tip.hide_tip()
 page.scroll.scroll_vertical=int(page.scroll.get_v_scroll_bar().max_value);await capture("reasoned-prototype-bottom")
 var answer_zh=page.details.get_child(1)
 check(answer_zh.get_global_rect().end.y<=page.scroll.get_global_rect().end.y+2,"滚动到底可看到完整中文末行")
 var added_forms=glossary.spans("согласова́ть прове́ренные исходны́е")
 check(added_forms.any(func(s):return s.entry.zh.contains("协调")),"新增词形可查原形与中文")
 answer_field.select(0,0,0,answer_field.get_line(0).length())
 check(answer_field.get_selected_text()==answer_field.text,"完整俄语回答可选择复制")
 main.get_window().size=Vector2i(1440,900)
 module.open_vocabulary(true);await frame()
 check(module.vocabulary.all_entries.size()==words.size(),"科学复习只用本题库")
 await capture("vocabulary")
 if not module.vocabulary.entries.is_empty():
  var marked_id:String=module.vocabulary.entries[module.vocabulary.index].id
  await key(KEY_SPACE);await key(KEY_4)
  check(module.vocabulary.marks.get(marked_id)=="完全不会","数字4记录新题词汇等级")
  check(module.vocabulary.entries.is_empty() or module.vocabulary.entries[module.vocabulary.index].id!=marked_id,"标记后自动下一项")
 module.open_reading(true)
 for settle in 10:await frame()
 for topic in page.topics:
  if not topic.get("animation_available",true):continue
  print("EXAM12_TOPIC ",topic.id)
  await module.open_topic(topic.id,topic.questions[0]);await frame();await frame()
  var lesson=module.stability
  check(lesson.store.data.pending==topic.questions[0],"首次基础转接 "+topic.id)
  check(lesson.player.current==0,"首次先到共同基础 "+topic.id)
  lesson.goto_index(1);lesson.player.finish();lesson.advance();await frame()
  check(lesson.store.data.foundation_done,"基础完成标记 "+topic.id)
  check(lesson.beat.id==topic.question_targets[topic.questions[0]],"基础后跳到所选题 "+topic.id)
  for qid in topic.questions:
   var question=page.entries.filter(func(e):return e.id==qid)[0]
   if question.get("animation_available",true):check(topic.question_targets.has(qid),"题目动画定位 "+qid)
  for i in lesson.player.beats.size():
   lesson.goto_index(i);lesson.player.finish();lesson.bubble.caption.visible_characters=-1;await frame()
   check(not lesson.ship.active==null,"动画视图 "+lesson.player.beats[i].id)
  await capture(topic.id)
  var samples:Dictionary={"P12_loads":"P12_C01:xsum","P12_arrangement":"P12_C04:sum","P12_volume":"P12_D01:lengths","P12_stability":"P12_T27:change","P12_resistance":"P12_T16:change","P12_reserve":"P12_T28:change"}
  if samples.has(topic.id):
   for j in lesson.player.beats.size():
    if lesson.player.beats[j].id==samples[topic.id]:
     lesson.goto_index(j);lesson.player.finish();lesson.bubble.caption.visible_characters=-1;lesson.ship.active.set_camera("topic",true);await frame();lesson.drawer_open=topic.id in ["P12_loads","P12_stability"];lesson.arrange();await frame();await capture(topic.id+"-sample")
     if topic.id=="P12_loads":
      var r=lesson.records;var box:Control=r.entries[r.last_record].box
      print("EXAM12_SCROLL ",r.last_record," pending=",r.follow_pending," value=",r.scroll.scroll_vertical," target=",box.global_position.y," scroll=",r.scroll.global_position.y," max=",r.scroll.get_v_scroll_bar().max_value)
      check(box.get_global_rect().intersects(r.scroll.get_global_rect()),"当前计算自动定位可见")
      r.scroll.scroll_vertical=0;var old_scroll:int=r.scroll.scroll_vertical
      lesson.refresh_records()
      for tick in 8:await frame()
      check(r.scroll.scroll_vertical==old_scroll,"静态数值刷新不抢回历史浏览位置")
  if topic.id=="P12_arrangement":
   lesson.toggle_language();lesson.bubble.caption.visible_characters=-1;await capture("rooms-russian")
   main.get_window().size=Vector2i(1100,760);await frame();await capture("minimum-rooms");main.get_window().size=Vector2i(1440,900)
  lesson.goto_index(0);lesson.player.finish();lesson.bubble.caption.visible_characters=-1
  await key(KEY_D);check(lesson.player.current==1,"D推进一段 "+topic.id)
  await key(KEY_A);await key(KEY_A);check(lesson.player.current==0,"A忙碌先完成再回退 "+topic.id)
  var lang_before:String=lesson.language;var state_before:Dictionary=lesson.player.state.duplicate(true);var index_before:int=lesson.player.current
  await key(KEY_F2)
  check(lesson.language!=lang_before and lesson.player.current==index_before and lesson.player.state==state_before,"F2保持当前状态 "+topic.id)
  var cam:Transform3D=lesson.ship.active.camera.transform
  lesson.player.retreat();await frame()
  check(cam==lesson.ship.active.camera.transform,"前后段保持相机 "+topic.id)
  var reveal_before:bool=page.revealed;var scroll_before:int=page.scroll.scroll_vertical
  await key(KEY_ESCAPE);check(module.mode=="reading","Esc返回阅读 "+topic.id)
  check(page.revealed==reveal_before and page.scroll.scroll_vertical==scroll_before,"返回保留揭晓和浏览位置 "+topic.id)
  if is_instance_valid(lesson.ship.active):check(lesson.ship.active.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"隐藏视口停止渲染 "+topic.id)
 var Calc=load("res://modules/review/core/exam12_math.gd")
 for row in [["P12_C01",1150.,112000.,6500.],["P12_C02",1000.,83950.,4970.],["P12_C03",1350.,126000.,7100.]]:
  var v:Dictionary=Calc.values({"qid":row[0],"load":1.});check(is_equal_approx(v.D,row[1]) and is_equal_approx(v.mx,row[2]) and is_equal_approx(v.mz,row[3]),"独立质量矩核对 "+row[0])
 var midway:Dictionary=Calc.values({"qid":"P12_C01","load":.5})
 check(is_equal_approx(midway.D,1050.) and is_equal_approx(midway.mx,102000.) and is_equal_approx(midway.mz,6200.),"装载中途质量与质量矩一致")
 var left:Dictionary=Calc.lcb(-1.);var right:Dictionary=Calc.lcb(1.)
 check(left.xc<right.xc and is_equal_approx(left.volume,right.volume),"艏艉容积分配：保体积且浮心方向正确")
 check(is_equal_approx(Calc.drawing_x(-49.79)-Calc.drawing_x(-98.),60.) and is_equal_approx(Calc.drawing_x(30.55)-Calc.drawing_x(-49.79),37.5) and absf(Calc.drawing_x(101.421)-Calc.drawing_x(30.55)-52.5)<.0001,"150米船模分段映射")
 print("EXAM12_FILTER_START")
 page.select_question(0);page.revealed=true;page.mark("known");page.bank_filter.pressed.emit();await frame()
 check(page.store.data.filter=="pending" and 0 not in page.filtered,"待复习排除已会题")
 page.bank_filter.pressed.emit();await frame();check(0 in page.filtered,"全部恢复已会题")
 print("EXAM12_TOPIC_ENTRY_START")
 page.select_question(0);var group:TreeItem=page.tree_items[page.entries[0].id].get_parent();group.select(0);await frame()
 check(page.topic_button.visible and page.topic_selected==page.topics[0].id,"专题节点可开始或继续连续学习")
 await module.open_topic(page.topic_selected);await frame();await key(KEY_ESCAPE)
 check(module.mode=="reading" and page.topic_selected==page.topics[0].id,"专题入口Esc回专题页面")
 page.select_question(0)
 var common_id:String=""
 for w in words:
  if old_words.any(func(a):return a.id==w.id):common_id=w.id;break
 module.vocabulary.record_grade(common_id,"认识");var expected_due:Dictionary=module.vocabulary.schedule[common_id].duplicate()
 page.mark("review");page.save()
 var fresh=load("res://modules/review/core/reading_store.gd").new();fresh.catalog_path=page.store.catalog_path;fresh.path=page.store.path;fresh.read_file()
 check(fresh.data.selected==page.store.data.selected and fresh.data.marks==page.store.data.marks,"新阅读进度重读一致")
 var corrupt_path:="user://review/qa-exam12-corrupt.json";var corrupt:=FileAccess.open(corrupt_path,FileAccess.WRITE);corrupt.store_string("{broken");corrupt.close();fresh.path=corrupt_path;fresh.read_file();check(fresh.blocked and not fresh.write_file() and FileAccess.get_file_as_string(corrupt_path)=="{broken","损坏存档保留且阻止覆盖")
 main.show_home();main.open_review("reading");await frame()
 main.review.open_vocabulary(true);await frame()
 check(main.review.vocabulary.marks.get(common_id)=="认识" and main.review.vocabulary.schedule.get(common_id)==expected_due,"两题库共用词汇等级和复习时间")
 main.review.open_reading(true);await frame()
 check(main.review.bank_id=="legacy","旧入口仍是原题库")
 check(main.review.reading.entries.size()==62,"旧题卡数量保持62")
 for q in main.review.reading.entries:
  main.review.reading.select_question(main.review.reading.entries.find(q));main.review.reading.reveal();await frame()
  check(main.review.reading.details.get_child(0).text==q.answer.ru and q.get("answer_version","")=="reasoned-2026-10-27","旧题完整回答 "+q.id)
 check(main.review.reading.store.path!=page.store.path,"阅读存档隔离")
 await capture("legacy")
 main.show_home()
 await main.open_course("basics");await frame();main.player.finish();await frame()
 check(main.mode=="lesson" and main.course.id=="basics","原作业讲解仍可从主程序打开")
 await key(KEY_ESCAPE);check(main.mode=="home","原作业Esc返回首页")
 var f:=FileAccess.open("res://qa/exam12-results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"new_words":words.size(),"shared_words":reused,"pass":checks.all(func(c):return c.pass)},"  "));f.close()
 print("EXAM12_QA_FINISHED checks=",checks.size())
 main.get_tree().quit()
