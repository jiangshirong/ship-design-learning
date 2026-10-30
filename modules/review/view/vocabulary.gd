extends Control
signal changed
signal grade_changed(id:String,level:String)
const Schedule=preload("res://modules/review/core/review_schedule.gd")
const UI=preload("res://modules/review/mobile_ui/theme.gd")
const Icons=preload("res://modules/review/mobile_ui/ui_icons.gd")
const Choice=preload("res://modules/review/mobile_ui/choice_button.gd")
const LEVELS=["已掌握","认识","不熟","完全不会"]
var schedule:Dictionary={}
var marks:Dictionary={}
var path:="user://review/vocabulary.json"
var blocked:=false
var scientific:=false
var session_total:=0
var clock_override:=-1.0
var reading_path:="res://modules/review/content/reading.json"
var all_entries:Array=[]
var entries:Array=[]
var index:=0
var revealed:=false
var category:="单词"
var selected_filters:Array=["未标记"]+LEVELS
var filter_buttons:Dictionary={}
var kind_tabs:TabBar
var header:Label
var badge
var font_minus:Button
var font_plus:Button
var list_scroll:ScrollContainer
var list_view
var card:PanelContainer
var card_scroll:ScrollContainer
var card_copy:VBoxContainer
var russian
var chinese:Label
var reveal_button:Button
var previous:Button
var next_button:Button
var grade_buttons:Array=[]
var grades:HBoxContainer
var filters:HBoxContainer
var notice:Label
var continue_button:Button
var counter:Label
var menu:Control
var filter:OptionButton
var page_title:Label
func _ready()->void:
 theme=UI.make()
 if "--qa" in OS.get_cmdline_user_args():path="user://review/qa-vocabulary.json"
 all_entries=preload("res://modules/review/core/glossary.gd").new().study_entries(reading_path);load_marks()
 header=Label.new();header.text="词汇";header.add_theme_font_size_override("font_size",25);add_child(header);page_title=header
 badge=preload("res://modules/review/mobile_ui/progress_badge.gd").new();add_child(badge)
 font_minus=button("字号-",func():get_parent().adjust_font(-1));font_plus=button("字号+",func():get_parent().adjust_font(1))
 kind_tabs=TabBar.new();kind_tabs.scrolling_enabled=false;kind_tabs.add_tab("单词");kind_tabs.add_tab("词组");add_child(kind_tabs)
 for state in ["tab_selected","tab_unselected","tab_hovered","tab_focus"]:
  var style:=StyleBoxFlat.new();style.bg_color=Color.TRANSPARENT;style.content_margin_left=22;style.content_margin_right=22;style.content_margin_top=10;style.content_margin_bottom=10
  if state=="tab_selected":style.border_width_bottom=2;style.border_color=Color("1f514a")
  kind_tabs.add_theme_stylebox_override(state,style)
 kind_tabs.add_theme_color_override("font_selected_color",Color("1f514a"));kind_tabs.add_theme_color_override("font_unselected_color",Color("7c897e"));kind_tabs.tab_changed.connect(func(i):open_category("单词" if i==0 else "词组"))
 filters=HBoxContainer.new();filters.add_theme_constant_override("separation",8);add_child(filters)
 var prefix:=VBoxContainer.new();prefix.alignment=BoxContainer.ALIGNMENT_CENTER;prefix.custom_minimum_size.x=58;filters.add_child(prefix)
 var icon:=TextureRect.new();icon.texture=Icons.texture("list-filter");icon.modulate=Color("558575");icon.custom_minimum_size=Vector2(23,23);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;prefix.add_child(icon)
 var caption:=Label.new();caption.text="筛选：";caption.add_theme_font_size_override("font_size",14);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;prefix.add_child(caption)
 for i in 5:
  var key:String=(["未标记"]+LEVELS)[i];var b=Choice.new();b.caption=key;b.icon_name="circle-dashed" if i==0 else Icons.GRADE_ICONS[i-1];b.ink=Color("7c897e" if i==0 else Icons.GRADE_COLORS[i-1]);b.fill=Color(["edf0e9","e8efe5","eaf0e9","f7efdf","f6e9e4"][i]);b.vertical=true;b.dense=true;b.dense_font_size=14;b.toggle_mode=true;b.selected=key in selected_filters;filters.add_child(b);b.set_pressed_no_signal(b.selected);filter_buttons[key]=b;b.toggled.connect(func(enabled):set_filter(key,enabled))
 list_scroll=ScrollContainer.new();list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(list_scroll)
 list_view=preload("res://modules/review/mobile_ui/word_list_view.gd").new();list_scroll.add_child(list_view);list_view.activated.connect(open_entry)
 card=PanelContainer.new();add_child(card);var style:=UI.box("fffefa","e1dbc8",22);style.shadow_color=Color(.4,.28,.06,.06);style.shadow_size=10;style.shadow_offset=Vector2(0,5);card.add_theme_stylebox_override("panel",style)
 card_scroll=ScrollContainer.new();card_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;card.add_child(card_scroll)
 card_copy=VBoxContainer.new();card_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card_copy.size_flags_vertical=Control.SIZE_EXPAND_FILL;card_copy.alignment=BoxContainer.ALIGNMENT_CENTER;card_copy.add_theme_constant_override("separation",30);card_scroll.add_child(card_copy)
 russian=preload("res://modules/review/view/selectable_text.gd").new();card_copy.add_child(russian);russian.add_theme_color_override("font_readonly_color",Color("273d36"));russian.add_theme_constant_override("line_spacing",8)
 chinese=Label.new();chinese.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;chinese.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;chinese.add_theme_color_override("font_color",Color("558575"));chinese.custom_minimum_size.y=64;card_copy.add_child(chinese)
 grades=HBoxContainer.new();grades.add_theme_constant_override("separation",10);add_child(grades)
 for i in LEVELS.size():
  var b=Choice.new();b.caption=str(i+1)+" "+LEVELS[i];b.icon_name=Icons.GRADE_ICONS[i];b.ink=Color(Icons.GRADE_COLORS[i]);b.fill=Color(["e8efe5","eaf0e9","f7efdf","f6e9e4"][i]);b.vertical=true;b.custom_minimum_size.y=80;grades.add_child(b);grade_buttons.append(b);b.pressed.connect(mark.bind(LEVELS[i]))
 previous=button("上一项 · Q",func():move(-1));next_button=button("下一项 · E",func():move(1));reveal_button=button("显示释义 · 空格",reveal);UI.primary(reveal_button)
 notice=Label.new();notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice.add_theme_color_override("font_color",Color("996d30"));notice.add_theme_font_size_override("font_size",16);add_child(notice)
 continue_button=button("继续复习",func():open_category(category));counter=Label.new();add_child(counter);counter.hide();menu=Control.new();add_child(menu);menu.hide();filter=OptionButton.new();add_child(filter);filter.hide()
 resized.connect(arrange);open_menu()
func button(text:String,call:Callable)->Button:
 var b:=Button.new();b.text=text;b.custom_minimum_size.y=48;add_child(b);b.pressed.connect(call);return b
func kind(entry:Dictionary)->String:return "词组" if entry.ru.strip_edges().contains(" ") else "单词"
func now()->float:return clock_override if clock_override>=0 else Time.get_unix_time_from_system()
func needs_review(id:String)->bool:return not marks.has(id) or Schedule.due(id,schedule,now())
func open_menu()->void:
 load_marks()
 open_category(category if not category.is_empty() else "单词")
func open_category(value:String)->void:
 category=value;kind_tabs.set_current_tab(0 if value=="单词" else 1);index=0;revealed=false;rebuild();session_total=entries.size();refresh();list_scroll.scroll_vertical=0
func set_filter(key:String,enabled:bool)->void:
 if enabled:
  if key not in selected_filters:selected_filters.append(key)
 else:selected_filters.erase(key)
 for id in filter_buttons:
  filter_buttons[id].selected=id in selected_filters;filter_buttons[id].set_pressed_no_signal(id in selected_filters);filter_buttons[id].update_style()
 rebuild();refresh();list_scroll.scroll_vertical=0
func rebuild()->void:
 entries=[]
 for entry in all_entries:
  if kind(entry)!=category:continue
  if scientific and not needs_review(entry.id):continue
  if not scientific and marks.get(entry.id,"未标记") not in selected_filters:continue
  entries.append(entry)
 if scientific:
  var original:Dictionary={}
  for i in all_entries.size():original[all_entries[i].id]=i
  entries.sort_custom(func(a,b):
   if marks.has(a.id)!=marks.has(b.id):return not marks.has(a.id)
   var ra:int=LEVELS.find(marks.get(a.id,"完全不会"));var rb:int=LEVELS.find(marks.get(b.id,"完全不会"))
   return ra>rb if ra!=rb else original[a.id]<original[b.id])
  if entries.size()>20:entries.resize(20)
 index=clampi(index,0,maxi(0,entries.size()-1))
func refresh()->void:
 if not is_node_ready():return
 var valid:=not entries.is_empty()
 header.text="科学复习" if scientific else "词汇"
 badge.visible=scientific and valid;header.visible=not badge.visible
 badge.set_progress(session_total-entries.size()+index+1,session_total)
 list_scroll.visible=not scientific;filters.visible=not scientific;card.visible=scientific
 if not scientific:list_view.set_entries(entries,marks,roundi(25*get_parent().font_scale))
 russian.set_content(entries[index].ru if valid else ("本轮完成" if session_total>0 else "暂无到期词条"))
 chinese.text=entries[index].zh if valid and revealed else "";chinese.modulate.a=1 if revealed else 0
 reveal_button.text="收起释义 · 空格" if revealed else "显示释义 · 空格"
 for b in [previous,next_button,reveal_button]:b.visible=scientific;b.disabled=not valid
 grades.visible=scientific and revealed and valid
 for i in grade_buttons.size():
  grade_buttons[i].disabled=not valid or blocked;grade_buttons[i].selected=valid and marks.get(entries[index].id,"")==LEVELS[i];grade_buttons[i].update_style()
 continue_button.visible=scientific and not valid;notice.text="记录损坏，已保留原文件，本次不覆盖。" if blocked else ("暂无符合条件的词条" if not scientific and not valid else "")
 arrange.call_deferred();changed.emit()
func refresh_notice()->void:refresh()
func reveal()->void:
 if not scientific or entries.is_empty():return
 revealed=not revealed;refresh()
func move(direction:int)->void:
 if not scientific or entries.is_empty():return
 index=posmod(index+direction,entries.size());revealed=false;refresh()
func mark(level:String)->void:
 if entries.is_empty() or blocked or not revealed or not scientific:return
 var id:String=entries[index].id
 if not record_grade(id,level):notice.text="等级未能保存，请重试。";return
 entries.remove_at(index);index=mini(index,maxi(0,entries.size()-1));revealed=false;refresh()
func open_entry(id:String)->void:
 for entry in all_entries:
  if entry.id==id:get_parent().open_dictionary_entry(entry);return
func record_grade(id:String,level:String)->bool:
 if blocked or id.is_empty() or level not in LEVELS:return false
 var old_marks:Dictionary=marks.duplicate(true);var old_schedule:Dictionary=schedule.duplicate(true)
 marks[id]=level;schedule[id]=Schedule.next_review(level,now())
 if not save_marks():
  marks=old_marks;schedule=old_schedule;return false
 grade_changed.emit(id,level)
 return true
func load_marks()->void:
 if not FileAccess.file_exists(path):return
 var parser:=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK:blocked=true;return
 var parsed=parser.data
 if not parsed is Dictionary or (parsed.get("version")!=1 and parsed.get("version")!=2) or not parsed.get("marks") is Dictionary:blocked=true;return
 for id in parsed.marks:
  if not id is String or parsed.marks[id] not in LEVELS:blocked=true;return
 if parsed.version==2 and not Schedule.valid(parsed.get("schedule")):blocked=true;return
 marks=parsed.marks;schedule=parsed.get("schedule",{})
 for id in schedule:
  if marks.has(id):schedule[id].due_at=minf(schedule[id].due_at,schedule[id].reviewed_at+Schedule.INTERVALS[marks[id]])
func save_marks()->bool:
 if blocked:return false
 var f:=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if not f:return false
 f.store_string(JSON.stringify({"version":2,"marks":marks,"schedule":schedule}));f.flush();var ok:=f.get_error()==OK;f.close()
 if not ok:return false
 if FileAccess.file_exists(path):
  if FileAccess.file_exists(path+".bak"):DirAccess.remove_absolute(path+".bak")
  if DirAccess.rename_absolute(path,path+".bak")!=OK:return false
 if DirAccess.rename_absolute(path+".tmp",path)==OK:return true
 if FileAccess.file_exists(path+".bak"):DirAccess.rename_absolute(path+".bak",path)
 return false

func arrange()->void:
 if not is_instance_valid(list_scroll):return
 var width:float=minf(960,size.x-80);var x:float=(size.x-width)*.5;var scale:float=get_parent().font_scale
 header.position=Vector2(x,26);badge.position=Vector2(x,24)
 font_plus.position=Vector2(x+width-82,24);font_plus.size=Vector2(82,46);font_minus.position=Vector2(x+width-172,24);font_minus.size=Vector2(82,46);font_minus.disabled=scale<=.8;font_plus.disabled=scale>=1.6
 kind_tabs.position=Vector2(x,88);kind_tabs.size=Vector2(220,45)
 filters.position=Vector2(x,146);filters.size=Vector2(width,72)
 list_scroll.position=Vector2(x,234);list_scroll.size=Vector2(width,maxf(80,size.y-258))
 var card_height:float=maxf(250,size.y-(340 if grades.visible else 260))
 card.position=Vector2(x,148);card.size=Vector2(width,card_height)
 russian.add_theme_font_size_override("font_size",roundi(38*scale));russian.custom_minimum_size.x=minf(width-80,maxf(100,russian.get_theme_font("font").get_string_size(russian.full_text,HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(38*scale)).x+20));russian.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;russian.measure();chinese.add_theme_font_size_override("font_size",roundi(25*scale))
 grades.position=Vector2(x,size.y-172);grades.size=Vector2(width,80)
 var middle:float=size.x*.5
 previous.position=Vector2(middle-350,size.y-76);previous.size=Vector2(150,50);reveal_button.position=Vector2(middle-190,size.y-76);reveal_button.size=Vector2(380,50);next_button.position=Vector2(middle+200,size.y-76);next_button.size=Vector2(150,50)
 notice.position=Vector2(x,112 if scientific else size.y-38);notice.size=Vector2(width,40)
 continue_button.position=Vector2(middle-110,size.y-132);continue_button.size=Vector2(220,48)
