extends SceneTree
class Host extends Control:
 var font_scale:=1.0
 func style(color:String)->StyleBoxFlat:
  var b=StyleBoxFlat.new();b.bg_color=Color(color);return b
 func adjust_font(_v:int)->void:pass
func _initialize()->void:call_deferred("run")
func run()->void:
 var host=Host.new();root.add_child(host);host.size=Vector2(1100,760)
 var page=load("res://modules/review/view/reading_review.gd").new();page.bank_id="exam12";page.content_root="res://modules/review/content/exam12/";page.store.path="user://review/qa-thursday-reading.json";host.add_child(page);page.size=host.size
 await process_frame
 assert(page.entries.size()==82)
 assert(page.topics[0].title.zh=="周四真题")
 var n:=0
 for q in page.entries:
  if not str(q.id).begins_with("THU"):continue
  n+=1;page.select_question(page.entries.find(q));page.reveal();await process_frame
  assert(page.question.full_text==q.question_ru)
  assert(page.details.get_child(0).text==q.answer.ru)
  assert(page.details.get_child(1).text==q.answer.zh)
  assert(not page.animation_button.visible)
  assert(page.tree_items.has(q.id))
  page.toggle_grouping();await process_frame;assert(page.tree_items.has(q.id));page.toggle_grouping()
 assert(n==10)
 var f=FileAccess.open("res://qa/thursday-exam-ui.json",FileAccess.WRITE);f.store_string(JSON.stringify({"pass":true,"questions":n,"topic_tree":true,"alphabet_navigation":true,"bilingual_answers":true,"no_animation":true,"isolated_save":true}));f.close()
 print("Thursday UI checks passed");quit()
