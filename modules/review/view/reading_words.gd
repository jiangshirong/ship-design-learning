extends Node
var page
var cursor:=0
var tokens:Array=[]
var fields:Array=[]
var generation:=0
var vocabulary
var glossary=preload("res://modules/review/core/glossary.gd").new()
class Ink extends Control:
 var owner_words
 var field:TextEdit
 func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE;show_behind_parent=true
 func _process(_dt:float)->void:
  if is_visible_in_tree():size=field.size;queue_redraw()
 func _draw()->void:
  for token in owner_words.tokens:
   if token.field!=field or not owner_words.is_unknown(token):continue
   for rect in owner_words.rectangles(token):draw_style_box(owner_words.unknown_style,rect.grow(2))
var unknown_style:=StyleBoxFlat.new()
func _ready()->void:
 unknown_style.bg_color=Color(0,0,0,0);unknown_style.set_corner_radius_all(3)
func normalized(s:String)->String:return s.to_lower().replace("\u0301", "").replace("\u0300", "")
func identity(s:String)->String:
 for match_ in glossary.spans(s):
  if match_.start==0 and match_.end==s.length():return "id:"+str(match_.entry.id)
 return "word:"+normalized(s)
func is_unknown(t:Dictionary)->bool:
 var marks:Dictionary=vocabulary.marks if is_instance_valid(vocabulary) else {}
 if t.key.begins_with("id:") and marks.has(t.key.substr(3)):return marks[t.key.substr(3)] in ["不熟","完全不会"]
 if page.store.data.get("word_levels",{}).has(t.key):return int(page.store.data.word_levels[t.key])>=3
 if page.store.data.get("unknown_words",{}).has(t.key):return true
 for id in t.get("related",[]):
  if marks.get(id,"") in ["不熟","完全不会"]:return true
 return false
func schedule()->void:
 tokens.clear()
 generation+=1;rebuild.call_deferred(generation)
func rebuild(ticket:int)->void:
 await get_tree().process_frame
 await get_tree().process_frame
 if ticket!=generation:return
 vocabulary=page.get_parent().vocabulary
 for f in fields:
  if is_instance_valid(f):f.deselect()
 tokens.clear();fields=[]
 if not page.topic_selected.is_empty() or page.index<0:return
 fields.append(page.question)
 if page.revealed and page.exercise.is_empty() and page.details.get_child_count()>0:fields.append(page.details.get_child(0))
 var rx:=RegEx.new();rx.compile("[А-Яа-яЁё]+[А-Яа-яЁё\u0301\u0300]*(?:[-‐‑][А-Яа-яЁё][А-Яа-яЁё\u0301\u0300]*)*")
 for field in fields:
  if page.has_meta("word_picker"):page.get_meta("word_picker").bind_field(field)
  var spans:Array=glossary.spans(field.text)
  if not field.has_meta("whole_word_navigation"):
   field.set_meta("whole_word_navigation",true)
   field.gui_input.connect(mouse_input.bind(field))
   var ink:=Ink.new();ink.owner_words=self;ink.field=field;field.add_child(ink)
  for m in rx.search_all(field.text):
   var start:int=m.get_start();var end:int=m.get_end()
   var prefix:String=field.text.substr(0,start);var line:int=prefix.count("\n")
   var column:int=start-(prefix.rfind("\n")+1)
   var related:Array=[]
   for span in spans:
    if span.start<=start and span.end>=end:related.append(span.entry.id)
   tokens.append({"related":related,"field":field,"source_text":field.text,"start":start,"end":end,"line":line,"column":column,"word":m.get_string(),"key":identity(m.get_string())})
 cursor=clampi(cursor,0,maxi(tokens.size()-1,0));select_current(false);refresh_ink()
func rectangles(t:Dictionary)->Array:
 var result:Array=[]
 if not is_instance_valid(t.field) or t.field.text!=t.source_text:return result
 if t.line<0 or t.line>=t.field.get_line_count():return result
 if t.column<0 or t.column+t.end-t.start>t.field.get_line(t.line).length():return result
 for c in range(t.column,t.column+t.end-t.start):
  var rect:=Rect2(t.field.get_rect_at_line_column(t.line,c+1))
  if rect.position.x<0 or rect.size.x<=0:continue
  if not result.is_empty() and absf(result[-1].position.y-rect.position.y)<2:result[-1]=result[-1].merge(rect)
  else:result.append(rect)
 return result
func centre(t:Dictionary)->Vector2:
 var rects:=rectangles(t)
 return t.field.global_position+(rects[0].get_center() if not rects.is_empty() else Vector2.ZERO)
func select_current(scroll_to:=true)->void:
 if scroll_to and page.has_meta("word_picker"):page.get_meta("word_picker").dismiss()
 page.get_parent().term_tooltip.hide_tip()
 if tokens.is_empty():return
 for f in fields:
  if is_instance_valid(f):f.deselect()
 var t:Dictionary=tokens[cursor]
 if scroll_to:
  # Keep the selected wrapped row visible inside a long native TextEdit.
  t.field.set_caret_line(t.line);t.field.set_caret_column(t.column)
 t.field.select(t.line,t.column,t.line,t.column+t.end-t.start)
 if scroll_to:
  var box=page.scroll if t.field==page.question else page.answer_scroll
  var bounds:Array=rectangles(t)
  if not bounds.is_empty():
   var y:float=t.field.global_position.y+bounds[0].position.y-box.global_position.y
   if y<12:box.scroll_vertical+=int(y-12)
   elif y+bounds[0].size.y>box.size.y-12:box.scroll_vertical+=int(y+bounds[0].size.y-box.size.y+12)
func navigate(key:int)->void:
 if tokens.is_empty():return
 if key in [KEY_A,KEY_D]:cursor=clampi(cursor+(-1 if key==KEY_A else 1),0,tokens.size()-1)
 else:
  var current:Vector2=centre(tokens[cursor]);var direction:float=-1 if key==KEY_W else 1
  var best:=-1;var score:=INF
  for i in tokens.size():
   var delta:Vector2=centre(tokens[i])-current
   if delta.y*direction<8:continue
   var candidate:float=absf(delta.y)*1000+absf(delta.x)
   if candidate<score:score=candidate;best=i
  if best>=0:cursor=best
 select_current()
func mark_unknown()->void:set_level(4)
func mark_known()->void:set_level(1)
func set_level(level:int)->void:
 if tokens.is_empty():return
 var t:Dictionary=tokens[cursor]
 if t.key.begins_with("id:"):
  if not page.get_parent().vocabulary.record_grade(t.key.substr(3),"完全不会" if level==4 else "已掌握"):
   page.notice.text="词汇等级未能保存，请重试。";return
 if not page.store.data.has("unknown_words"):page.store.data.unknown_words={}
 if not page.store.data.has("word_levels"):page.store.data.word_levels={}
 if level==4:page.store.data.unknown_words[t.key]=true
 else:page.store.data.unknown_words.erase(t.key)
 if not t.key.begins_with("id:"):page.store.data.word_levels[t.key]=level
 else:page.store.data.word_levels.erase(t.key)
 page.save();refresh_ink()
 for f in fields:
  for child in f.get_children():
   if child is Ink:child.queue_redraw()
func refresh_ink()->void:
 for f in fields:
  if not is_instance_valid(f):continue
  var ranges:Array=[]
  for t in tokens:
   if t.field==f and is_unknown(t):ranges.append({"start":t.start,"end":t.end})
  f.set_meta("word_grade_ranges",ranges)
  if f.syntax_highlighter:f.syntax_highlighter.clear_highlighting_cache()
  f.queue_redraw()
func show_meaning()->void:
 if tokens.is_empty():return
 var picker=page.get_meta("word_picker")
 if picker.is_open():picker.dismiss()
 else:picker.open_token(tokens[cursor])
func mouse_input(event:InputEvent,field:TextEdit)->void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:
   var best:=-1
   for i in tokens.size():
    if tokens[i].field!=field:continue
    for rect in rectangles(tokens[i]):
     if rect.grow(2).has_point(event.position):best=i;break
    if best>=0:break
   if best>=0:cursor=best;select_current(false)
  field.accept_event()
 elif event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:field.accept_event()
