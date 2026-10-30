extends Control
# Typeset runs use real smaller, shifted glyphs. Copy preserves linear notation.
var text:=""
var full_text:=""
var runs:Array=[]
var font:SystemFont
var base_size:=24
var intrinsic_width:=false
var popup:PopupMenu
static func notation(value:String)->String:
	var s:=value.replace("Σ(Pz)","Σ(P_i · z_i)").replace("Σ(Px)","Σ(P_i · x_i)")
	s=s.replace("ΣPz","Σ(P_i · z_i)").replace("ΣPx","Σ(P_i · x_i)").replace("Pz","P · z").replace("Px","P · x")
	for name in ["zG","xG"]:s=s.replace(name,name[0]+"_{G}")
	var subs:="₀₁₂₃₄₅₆₇₈₉ᵢⱼₖₙₜₓ";var plain:="0123456789ijkntx"
	var supers:="⁰¹²³⁴⁵⁶⁷⁸⁹";var digits:="0123456789"
	var out:="";var i:=0
	while i<s.length():
		if subs.contains(s[i]) or supers.contains(s[i]):
			var is_sub:bool=subs.contains(s[i]);var chars:String=subs if is_sub else supers;var vals:String=plain if is_sub else digits;var word:=""
			while i<s.length() and chars.contains(s[i]):word+=vals[chars.find(s[i])];i+=1
			out+=("_{" if is_sub else "^{")+word+"}"
		else:out+=s[i];i+=1
	return out
func _init()->void:
	font=SystemFont.new();font.font_names=PackedStringArray(["Cambria Math","Segoe UI","Microsoft YaHei"])
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	popup=PopupMenu.new();add_child(popup);popup.add_item("复制公式 / Копи́ровать",0)
	popup.id_pressed.connect(copy_formula)
	resized.connect(arrange);arrange()
func copy_formula(_id:int)->void:
	DisplayServer.clipboard_set(text)
	set_meta("copied",text)
func set_content(value:String)->void:
	var next:=notation(value)
	if text==next:return
	text=next;full_text=text;arrange()
func arrange()->void:
	runs.clear()
	var x:=0.0;var y:=30.0;var max_width:=0.0;var i:=0
	var limit:float=10000 if intrinsic_width else maxf(size.x,120)
	while i<text.length():
		if text[i]=="\n":max_width=maxf(max_width,x);x=0;y+=43;i+=1;continue
		var kind:="base";var token:=text[i];i+=1
		if token in ["_","^"] and i<text.length():
			kind="sub" if token=="_" else "super";token=""
			if text[i] in ["{","("]:
				var end:String="}" if text[i]=="{" else ")";i+=1
				while i<text.length() and text[i]!=end:token+=text[i];i+=1
				if i<text.length():i+=1
			else:token=text[i];i+=1
		var fs:int=base_size if kind=="base" else int(base_size*.67)
		var width:float=font.get_string_size(token,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		if x+width>limit and x>0:max_width=maxf(max_width,x);x=0;y+=43
		var offset:float=7 if kind=="sub" else (-11 if kind=="super" else 0)
		runs.append({"text":token,"position":Vector2(x,y+offset),"size":fs,"kind":kind})
		x+=width
	max_width=maxf(max_width,x)
	custom_minimum_size=Vector2(max_width if intrinsic_width else 0,y+16)
	queue_redraw()
func _draw()->void:
	for run in runs:draw_string(font,run.position,run.text,HORIZONTAL_ALIGNMENT_LEFT,-1,run.size,Color("dbeaf2"))
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		popup.position=Vector2i(global_position+event.position);popup.popup();accept_event()
