extends CanvasLayer
# Shared desktop adaptation of the confirmed mobile word/phrase sheet.
const UI=preload("res://modules/review/mobile_ui/theme.gd")
const Icons=preload("res://modules/review/mobile_ui/ui_icons.gd")
const Choice=preload("res://modules/review/mobile_ui/choice_button.gd")
const LEVELS=["已掌握","认识","不熟","完全不会"]
var controller
var field:TextEdit
var tip
var panel:PanelContainer
var shield:ColorRect
var scroll:ScrollContainer
var column:VBoxContainer
var text:RichTextLabel
var selected:Dictionary={}
var chosen_word:=""
var candidates:Array=[]
var dictionary:Dictionary={}
var press:=Vector2.ZERO
var armed:=false
var closing:=false
func _ready()->void:
 layer=31
 for e in tip.glossary.entries:dictionary[e.id]=e
 shield=ColorRect.new();shield.color=Color(.1,.15,.12,.35);add_child(shield);shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shield.gui_input.connect(outside_input)
 panel=PanelContainer.new();panel.theme=UI.make();add_child(panel);panel.add_theme_stylebox_override("panel",UI.box("fffefa","d4ddce",23))
 scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
 column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",16);scroll.add_child(column);column.minimum_size_changed.connect(func():fit.call_deferred())
 bind_field(field);dismiss();get_viewport().size_changed.connect(fit)
func bind_field(target:TextEdit)->void:
 if target.has_meta("picker_bound"):return
 target.set_meta("picker_bound",true);target.gui_input.connect(on_field_input.bind(target))
func dismiss()->void:
 panel.hide();shield.hide();selected={};candidates=[];armed=false;closing=false
func is_open()->bool:return panel.visible
func _process(_dt:float)->void:
 if panel.visible:
  tip.hide_tip()
  if not controller.page.get_parent().is_visible_in_tree() or controller.page.get_parent().mode not in ["reading","vocabulary"]:dismiss()
func outside_input(event:InputEvent)->void:
 if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT):
  get_viewport().set_input_as_handled()
  if not event.pressed and not closing:close_after_gesture()
func close_after_gesture()->void:
 closing=true
 await get_tree().process_frame
 await get_tree().process_frame
 if closing:dismiss()
func on_field_input(event:InputEvent,target:TextEdit)->void:
 if panel.visible:return
 field=target
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:press=event.position;armed=true
  else:
   var choose:bool=armed and press.distance_to(event.position)<5.;armed=false
   if choose:pick(event.position)
 elif event is InputEventMouseMotion and armed and press.distance_to(event.position)>=5.:armed=false
func pick(point:Vector2)->void:
 if panel.visible:return
 for i in controller.tokens.size():
  var token:Dictionary=controller.tokens[i]
  if token.field!=field:continue
  for rect in controller.rectangles(token):
   if rect.grow(2).has_point(point):
    controller.cursor=i;controller.select_current(false);open_token(token);return
func open_token(token:Dictionary)->void:
 field=token.field
 var ids:Array=[]
 for span in tip.glossary.spans(token.word):
  if span.start==0 and span.end==token.word.length():ids.append(span.entry.id)
 for id in token.get("related",[]):
  if dictionary.has(id) and dictionary[id].ru.contains(" ") and id not in ids:ids.append(id)
 open_entries(token.word,ids)
func phrase_entry(e:Dictionary)->bool:return e.ru.contains(" ") and not e.ru.contains(" / ")
func open_entries(word:String,ids:Array)->void:
 if panel.visible:return
 chosen_word=word;candidates=[];var seen:Dictionary={}
 for phrase in [false,true]:
  for id in ids:
   if not dictionary.has(id):continue
   var e:Dictionary=dictionary[id]
   if phrase_entry(e)!=phrase:continue
   var normalized:String=e.ru.to_lower().replace("\u0301","")
   if seen.has(normalized):continue
   seen[normalized]=true;candidates.append(e)
 if candidates.is_empty() or phrase_entry(candidates[0]):
  candidates.push_front({"id":"word:"+controller.normalized(word),"ru":word,"zh":"暂无该词的释义。"})
 selected=candidates[0];refresh();shield.show();panel.show();fit.call_deferred()
func copy(parent:Node,value:String,fs:int,color:=Color("273d36"))->Label:
 var l:=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",roundi(fs*controller.page.get_parent().font_scale));l.add_theme_color_override("font_color",color);parent.add_child(l);return l
func current_grade(id:String)->String:
 if id.begins_with("word:"):
  var level:int=int(controller.page.store.data.get("word_levels",{}).get(id,0));return LEVELS[level-1] if level>=1 and level<=4 else ""
 return controller.page.get_parent().vocabulary.marks.get(id,"")
func refresh()->void:
 var old_offset:int=scroll.scroll_vertical
 for child in column.get_children():column.remove_child(child);child.queue_free()
 for entry in candidates:
  var phrase:bool=phrase_entry(entry);var combined:bool=candidates.size()>1
  var col:=VBoxContainer.new();col.add_theme_constant_override("separation",14);col.set_meta("entry_id",entry.id)
  if phrase and combined:
   var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",UI.box("eef3eb","d8e4d6",18));column.add_child(card);card.add_child(col)
  else:column.add_child(col)
  if combined:
   var row:=HBoxContainer.new();col.add_child(row)
   if phrase:
    var icon:=TextureRect.new();icon.texture=Icons.texture("link");icon.modulate=Color("558575");icon.custom_minimum_size=Vector2(18,18);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(icon)
   var tag:=copy(row,"固定词组" if phrase else "单词",14,Color("558575"));tag.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  copy(col,entry.ru,26 if not phrase else 24)
  copy(col,entry.zh,20)
  var grades:=HBoxContainer.new();grades.add_theme_constant_override("separation",8);col.add_child(grades)
  for i in LEVELS.size():
   var b=Choice.new();b.caption=LEVELS[i];b.icon_name=Icons.GRADE_ICONS[i];b.ink=Color(Icons.GRADE_COLORS[i]);b.fill=Color(["e8efe5","eaf0e9","f7efdf","f6e9e4"][i]);b.vertical=true;b.dense=true;b.dense_font_size=14;b.selected=current_grade(entry.id)==LEVELS[i];b.set_meta("entry_id",entry.id);b.set_meta("grade",LEVELS[i]);grades.add_child(b);b.pressed.connect(rate.bind(entry.id,LEVELS[i]))
 scroll.scroll_vertical=old_offset;fit.call_deferred()
func rate(id:String,level:String)->void:
 var host=controller.page.get_parent()
 if id.begins_with("word:"):
  var previous:Dictionary=controller.page.store.data.duplicate(true)
  controller.page.store.data.get_or_add("word_levels",{})[id]=LEVELS.find(level)+1
  if LEVELS.find(level)>=2:controller.page.store.data.get_or_add("unknown_words",{})[id]=true
  else:controller.page.store.data.get_or_add("unknown_words",{}).erase(id)
  if not controller.page.store.write_file():controller.page.store.data=previous;return
 elif not host.vocabulary.record_grade(id,level):return
 controller.refresh_ink();refresh()
func fit()->void:
 if not panel:return
 var extent:=get_viewport().get_visible_rect().size
 var width:=minf(700,extent.x-48);panel.size=Vector2(width,minf(column.get_combined_minimum_size().y+40,extent.y*.80));panel.position=(extent-panel.size)*.5
