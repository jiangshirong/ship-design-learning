extends Node
# Hit regions follow the same font and baseline as the canvas-drawn labels.
var tip=preload("res://modules/review/view/term_tooltip.gd").new()
var regions:Array=[]
var matches:Dictionary={}
func _ready()->void:
	get_parent().add_child.call_deferred(tip)
func clear_labels()->void:
	regions.clear()
	if is_instance_valid(tip.panel):tip.hide_tip()
func add_label(value:String,baseline:Vector2,font:Font,font_size:int)->void:
	if not matches.has(value):matches[value]=tip.glossary.spans(value)
	for span in matches[value]:
		var left:=font.get_string_size(value.substr(0,span.start),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var right:=font.get_string_size(value.substr(0,span.end),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		regions.append({"rect":Rect2(baseline+Vector2(left,-font.get_ascent(font_size)),Vector2(right-left,font.get_height(font_size))),"entry":span.entry,"surface":value.substr(span.start,span.end-span.start)})
func _input(event:InputEvent)->void:
	if not is_instance_valid(tip.panel):return
	var field:Control=get_parent()
	if not field.is_visible_in_tree():
		tip.hide_tip();return
	if event is InputEventMouseButton:
		tip.hide_tip();return
	if not event is InputEventMouseMotion:return
	if event.button_mask!=0:
		tip.hide_tip();return
	var local:Vector2=field.get_global_transform_with_canvas().affine_inverse()*event.position
	if Rect2(Vector2.ZERO,field.size).has_point(local):
		for region in regions:
			if region.rect.has_point(local):
				tip.owner_field=field;tip.current=region.entry
				tip.words.text=tip.entry_text(region.surface,region.entry)
				tip.place_tip(event.position)
				return
	tip.hide_tip()
