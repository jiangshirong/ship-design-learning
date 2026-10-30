extends "res://modules/review/view/stability_ship.gd"
var source_state:Dictionary={}
var original_picture
var picture_index:=-1
func _ready()->void:
 super._ready()
 original_picture=preload("res://modules/review/view/exam_picture.gd").new();add_child(original_picture);original_picture.position=Vector2(20,110);original_picture.size=Vector2(320,350);original_picture.setup([{"number":2,"path":"res://modules/review/assets/exam12/image2.png"}]);original_picture.hide()
static func hydro_state(s:Dictionary)->Dictionary:
 var roll:bool=s.get("concept","")=="roll"
 return {"route":"base","morph":0.,"zg":float(s.get("zg",8.7)),"heel":float(s.get("heel",0)),"show":"roll" if roll else "arm","plot":"time" if roll else "arm","clock":float(s.get("progress",0))*18.,"amplitude":6.,"sweep":not str(s.get("qid","")).begins_with("P12_F"),"compare":roll,"reference_zg":8.7}
func apply(s:Dictionary,lang:String,evaluation:Dictionary={})->void:
 source_state=s.duplicate(true);super.apply(hydro_state(s),lang,evaluation)
 var next:int=int(s.get("image_index",0));original_picture.visible=next>0
 if next>0 and next!=picture_index:
  picture_index=next;original_picture.pictures=[{"number":next,"path":"res://modules/review/assets/exam12/image%d.png"%next}];original_picture.current=0;original_picture.refresh()
func obstacles()->Array:
 var result:=super.obstacles()
 if is_instance_valid(original_picture) and original_picture.visible:result.append(Rect2(original_picture.position,original_picture.size))
 return result
func set_camera(_preset:String,instant:=false)->void:super.set_camera("front",instant)
