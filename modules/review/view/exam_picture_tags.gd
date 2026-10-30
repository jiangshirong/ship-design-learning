extends Control
var texture:TextureRect
var tags:Array=[]
var panel:PanelContainer
var copy:Label
func _ready()->void:
 mouse_filter=MOUSE_FILTER_PASS
 panel=PanelContainer.new();panel.mouse_filter=MOUSE_FILTER_IGNORE;var style:=StyleBoxFlat.new();style.bg_color=Color("edf6f1");style.set_corner_radius_all(7);style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=9;style.content_margin_bottom=9;panel.add_theme_stylebox_override("panel",style);add_child(panel)
 copy=Label.new();copy.add_theme_color_override("font_color",Color("234a40"));copy.add_theme_font_size_override("font_size",19);panel.add_child(copy);panel.hide();mouse_exited.connect(func():panel.hide())
func image_rect()->Rect2:
 if not texture or not texture.texture:return Rect2()
 var sz:Vector2=texture.texture.get_size();var scale_:float=minf(size.x/sz.x,size.y/sz.y);sz*=scale_;return Rect2((size-sz)*.5,sz)
func _draw()->void:
 var rect:=image_rect()
 for tag in tags:
  var at:Vector2=rect.position+Vector2(tag[0],tag[1])*rect.size;draw_circle(at,6,Color("317b69"));draw_arc(at,9,0,TAU,24,Color.WHITE,1,true)
func _gui_input(event:InputEvent)->void:
 if not event is InputEventMouseMotion:return
 var rect:=image_rect();panel.hide()
 for tag in tags:
  var at:=rect.position+Vector2(tag[0],tag[1])*rect.size
  if at.distance_to(event.position)<24:
   copy.text=tag[2]+"\n"+tag[3];panel.reset_size();panel.position=(event.position+Vector2(14,14)).clamp(Vector2.ZERO,Vector2(maxf(0,size.x-panel.size.x),maxf(0,size.y-panel.size.y)));panel.show();break
