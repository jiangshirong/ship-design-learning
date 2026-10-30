extends Node
# Generic renderer-free lesson player. No UI, model paths or subject knowledge here.
signal prepared(beat:Dictionary,index:int)
signal characters(count:int)
signal phase_changed(value:String)
signal state_changed(value:Dictionary)
signal closed
signal navigation_requested
const M=preload("res://modules/review/core/state_math.gd")
var active:=false
var phase:="idle"
var lesson:Dictionary={}
var beats:Array=[]
var before:Array=[]
var after:Array=[]
var routes:Array=[]
var current:=0
var state:Dictionary={}
var epoch:=0
var animation:Tween
var preparation_running:=false
var schedule:Array[float]=[]
var clock:=0.0
var count:=0
var held:Dictionary={}
var display_text:=""
var presentation_ready:=true
var glyph_ends:Array[int]=[]
func set_display_text(value:String,complete:=false)->void:
	display_text=value;schedule.clear();glyph_ends.clear();clock=0;count=0
	var elapsed:=0.0
	for i in range(value.length()):
		var code:=value.unicode_at(i)
		if code>=0x0300 and code<=0x036f:
			if not glyph_ends.is_empty():glyph_ends[-1]=i+1
			continue
		elapsed+=1.0/float(lesson.get("characters_per_second",24));schedule.append(elapsed);glyph_ends.append(i+1)
		if value[i] in "，。；：！？,.!?;:":elapsed+=.15
	if complete:
		characters.emit(-1)
		if phase=="typing":set_phase(text_phase())

func open(value:Dictionary,resume_id:="")->void:
	close(false);lesson=value;beats.clear();before.clear();after.clear();routes.clear()
	var stable:Dictionary=value.initial.duplicate(true)
	for g in range(value.groups.size()):
		for raw in value.groups[g].beats:
			var b:Dictionary=raw.duplicate(true);b["group"]=g
			stable=M.patch(stable,{"params":b.get("start_params",{})})
			beats.append(b);before.append(stable.duplicate(true))
			var route:Array=[];var intermediate:Dictionary=stable
			for frame in b.get("action",{}).get("keyframes",[]):
				intermediate=M.patch(intermediate,frame);route.append({"at":float(frame.at),"state":intermediate})
			routes.append(route);stable=M.patch(intermediate,b.get("action",{}));after.append(stable.duplicate(true))
	active=true;current=0
	var target:String=lesson.get("resume_aliases",{}).get(resume_id,resume_id)
	for i in range(beats.size()):
		if beats[i].id==target:current=i;break
	prepare()
func cancel_animation()->void:
	epoch+=1
	if animation and animation.is_valid():animation.kill()
	preparation_running=false
func set_phase(value:String)->void:phase=value;phase_changed.emit(value)
func apply(value:Dictionary)->void:state=value;state_changed.emit(state)
func prepare()->void:
	cancel_animation();apply(before[current].duplicate(true));clock=0;count=0;schedule.clear()
	set_display_text(str(beats[current].text))
	prepared.emit(beats[current],current);characters.emit(0);set_phase("typing")
	if beats[current].get("kind","normal")=="problem" and has_action():play(true)
func has_action()->bool:
	if before[current]!=after[current]:return true
	for frame in routes[current]:
		if frame.state!=before[current]:return true
	return false
func stable_phase()->String:return "complete" if current==beats.size()-1 else "settled"
func text_phase()->String:
	if preparation_running:return "playing"
	if beats[current].get("kind","normal")=="problem" or not has_action():return stable_phase()
	return "ready"
func _process(delta:float)->void:
	if not active or phase!="typing" or not presentation_ready:return
	clock+=delta
	while count<schedule.size() and clock>=schedule[count]:
		count+=1;characters.emit(glyph_ends[count-1])
	if count==schedule.size() and (schedule.is_empty() or clock>=schedule[-1]+.18):set_phase(text_phase())
func play(parallel:=false)->void:
	preparation_running=parallel
	if not parallel:set_phase("playing")
	var captured:=epoch
	animation=create_tween()
	animation.tween_method(func(t:float):
		if active and captured==epoch:apply(M.sample(before[current],after[current],routes[current],t))
	,0.0,1.0,float(beats[current].get("action",{}).get("duration",1.6)))
	animation.finished.connect(func():if active and captured==epoch:finish())
func finish()->void:
	var writing:=phase=="typing" and preparation_running
	cancel_animation();apply(after[current].duplicate(true))
	if not writing:set_phase(stable_phase())
func complete_busy()->bool:
	if phase not in ["typing","playing"]:return false
	if lesson.get("busy_policy","finish")=="lock":return true
	if phase=="typing":
		count=schedule.size();characters.emit(-1)
		if preparation_running:finish();set_phase(stable_phase())
		else:set_phase(text_phase())
	else:finish()
	return true
func advance()->void:
	if not active:return
	navigation_requested.emit()
	if complete_busy():return
	if phase=="ready":play();return
	if current<beats.size()-1:current+=1;prepare()
func retreat()->void:
	if not active:return
	navigation_requested.emit()
	if complete_busy():return
	if current>0:current-=1;prepare()
func jump(group:int)->void:
	if not active or (lesson.get("busy_policy","finish")=="lock" and phase in ["typing","playing"]):return
	navigation_requested.emit()
	for i in range(beats.size()):
		if beats[i].group==group:current=i;prepare();return
func handle_key(event:InputEventKey)->void:
	var key:int=event.physical_keycode if event.physical_keycode else event.keycode
	if not event.pressed:held.erase(key);return
	if not active or event.echo or held.has(key) or event.ctrl_pressed or event.alt_pressed or event.shift_pressed or event.meta_pressed:return
	if key not in [KEY_Q,KEY_E]:return
	held[key]=true
	if key==KEY_Q:retreat()
	else:advance()
func close(notify:=true)->void:
	var was_active:=active;cancel_animation();active=false;held.clear();set_phase("idle")
	if notify and was_active:closed.emit()
func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:held.clear()
