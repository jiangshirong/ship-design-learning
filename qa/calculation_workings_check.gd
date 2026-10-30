extends SceneTree
const Math=preload("res://modules/review/core/exam12_math.gd")
const State=preload("res://modules/review/core/state_math.gd")
var checks:Array=[]
func check(ok:bool,label:String)->void:
 checks.append({"check":label,"pass":ok})
 if not ok:push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var entries:Array=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/exam12/reading.json"))
 var courses:Array=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/exam12/topics.json"))
 var player=load("res://modules/review/core/lesson_player.gd").new();root.add_child(player)
 var panel=load("res://modules/review/view/latex_panel.gd").new();root.add_child(panel);panel.light_mode=true
 var notes:Array=[]
 var layouts:Dictionary={}
 for q in entries:
  if q.id not in ["P12_C01","P12_C02","P12_C03","P12_C04"]:continue
  var course:Dictionary={}
  for c in courses:
   if c.id==q.topic:course=c.duplicate(true)
  course.groups=course.groups.filter(func(g):return g.id==q.id)
  player.open(course)
  for j in player.beats.size():
   var beat:Dictionary=player.beats[j]
   for t in [0.0,0.25,0.5,0.75,1.0]:
    var s:Dictionary=State.sample(player.before[j],player.after[j],player.routes[j],t)
    var v:Dictionary=Math.values(s)
    var sum:=0.0;var mx:=0.0;var mz:=0.0
    for r in v.rows:sum+=r[1];mx+=r[1]*r[2];mz+=r[1]*r[3]
    check(is_equal_approx(sum,v.D) and is_equal_approx(mx,v.mx) and is_equal_approx(mz,v.mz),beat.id+" mass/moments t="+str(t))
    if beat.id.contains(":row") and q.id!="P12_C04":
     var i:int=s.row_index;var row:Array=q.example_data.rows[i]
     var fraction:float=clampf(float(s.load)*q.example_data.rows.size()-i,0,1)
     check(is_equal_approx(v.rows[i][1],row[1]*fraction),beat.id+" current mass shares animation state")
    for lang in ["zh","ru"]:
     for width in [330,430]:
      panel.size.x=width;panel.set_beat(beat.id,Math.formatted(s),lang)
      check(not panel.text.contains("@ex_"),beat.id+" all dynamic values bound "+lang)
      for drawing in panel.drawings:check(drawing.rect.end.x<=width+1,beat.id+" formula fits "+str(width))
   if beat.id.ends_with(":sum") and q.id!="P12_C04":
    var v:Dictionary=Math.values(player.after[j]);check(is_equal_approx(v.D,q.example_data.total),q.id+" final mass")
  panel.size.x=430;panel.set_beat(q.formula_id,{},"zh")
  check(panel.rows.size()>=3,q.id+" reading full solution")
  layouts[q.id]={"width":430,"height":panel.custom_minimum_size.y,"drawings":panel.drawings.duplicate(true),"text":panel.text}
  notes.append({"id":q.id,"formula_rows":panel.rows.size(),"height_at_430":panel.custom_minimum_size.y})
 player.close(false)
 check(is_equal_approx(State.blend({"load":0.0},{"load":1.0},0.5).load,0.5),"load interpolates with model and moments")
 check(panel.slot_overflows==0,"no dynamic number overflow")
 check(panel.render_errors==0,"no formula rendering errors")
 var layout_file=FileAccess.open("res://qa/calculation-notation/workings-layout.json",FileAccess.WRITE);layout_file.store_string(JSON.stringify(layouts));layout_file.close()
 var report={"pass":checks.all(func(c):return c.pass),"checks":checks,"solutions":notes}
 var file=FileAccess.open("res://qa/calculation-notation/workings-engine.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("WORKINGS_CHECK ",report.pass," checks=",checks.size())
 quit(0 if report.pass else 1)
