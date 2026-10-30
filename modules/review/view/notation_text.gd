extends "res://modules/review/view/selectable_text.gd"
# Retain the exact native, selectable source text. Only suffix ink is replaced;
# draw each suffix as one shaped run, never as individually spaced characters.
var notation=preload("res://modules/review/core/notation.gd").new()
var symbol_regions:Array=[]
const Formula=preload("res://modules/review/view/latex_panel.gd")
var inline_textures:Dictionary={}
static func fractions(value:String)->Array:
	var regex:=RegEx.new();regex.compile("h/[ВНТBHT]")
	return regex.search_all(value)
class SuffixInk extends SyntaxHighlighter:
	var notation=preload("res://modules/review/core/notation.gd").new()
	func _get_line_syntax_highlighting(line:int)->Dictionary:
		var result:Dictionary={}
		var offset:=0
		for previous in line:offset+=get_text_edit().get_line(previous).length()+1
		for span in get_text_edit().get_meta("word_grade_ranges",[]):
			if span.start>=offset and span.start<offset+get_text_edit().get_line(line).length():
				result[span.start-offset]={"color":Color("946318")};result[span.end-offset]={"color":get_text_edit().get_theme_color("font_readonly_color")}
		var phrase:String=get_text_edit().get_meta("source_phrase","")
		var start:int=get_text_edit().get_line(line).find(phrase) if not phrase.is_empty() else -1
		if start>=0:
			result[start]={"color":Color("694199")}
			result[start+phrase.length()]={"color":get_text_edit().get_theme_color("font_readonly_color")}
		for span in notation.spans(get_text_edit().get_line(line)):
			if span.get("native_subscript",false):continue
			# A word/phrase color boundary must not reveal part of the source
			# suffix (including the underscore) under the replacement glyph.
			for boundary in result.keys():
				if boundary>span.start+1 and boundary<span.end:result.erase(boundary)
			# TextEdit treats zero-alpha highlighting as "use the normal ink".
			# A positive subpixel alpha suppresses the source without that sentinel.
			result[span.start+1]={"color":Color(0,0,0,.001)}
			result[span.end]={"color":get_text_edit().get_theme_color("font_readonly_color")}
		var regex:=RegEx.new();regex.compile("h/[ВНТBHT]")
		for match_ in regex.search_all(get_text_edit().get_line(line)):
			# Word-grade boundaries can fall inside the native formula source.
			# Keep that entire source hidden beneath the typeset replacement.
			for boundary in result.keys():
				if boundary>match_.get_start() and boundary<match_.get_end():result.erase(boundary)
			result[match_.get_start()]={"color":Color(0,0,0,.001)}
			result[match_.get_end()]={"color":get_text_edit().get_theme_color("font_readonly_color")}
		# TextEdit consumes runs in column order. Grade boundaries are added
		# before notation masks, so insertion order is not necessarily sorted.
		var ordered:Dictionary={};var columns:Array=result.keys();columns.sort()
		for column in columns:ordered[column]=result[column]
		return ordered
func _ready()->void:
	super._ready();syntax_highlighter=SuffixInk.new()
	text_changed.connect(queue_redraw);text_changed.connect(update_fraction_spacing);resized.connect(queue_redraw)
func update_fraction_spacing()->void:
	add_theme_constant_override("line_spacing",int(get_theme_font_size("font_size")*.4) if not fractions(text).is_empty() else 0)
func _draw()->void:
	symbol_regions.clear()
	if not is_node_ready():return
	var font:=get_theme_font("font");var fs:=get_theme_font_size("font_size")
	var phrase:String=get_meta("source_phrase","")
	if not phrase.is_empty():
		for line in get_line_count():
			var begin:=get_line(line).find(phrase)
			if begin<0:continue
			for i in range(begin,mini(begin+phrase.length(),get_line(line).length())):
				var a:=Vector2(get_pos_at_line_column(line,i+1))
				var b:=Vector2(get_pos_at_line_column(line,mini(i+2,get_line(line).length())))
				if a.x>=0 and b.y==a.y and b.x>a.x:draw_line(a+Vector2(0,2),b+Vector2(0,2),Color("694199"),1,true)
	var sub_size:=maxi(17,roundi(fs*.76));var color:=get_theme_color("font_readonly_color")
	for line in get_line_count():
		for match_ in fractions(get_line(line)):
			var key:String={"В":"B","Н":"H","Т":"T"}.get(match_.get_string()[-1],match_.get_string()[-1])
			Formula.ensure_bundle()
			var rows:Array=Formula.bundle.lessons.get("_inline:ratio"+key,{}).get("zh",[])
			if rows.is_empty():continue
			var asset:Dictionary=Formula.bundle.assets[rows[0].pieces[0]]
			if not inline_textures.has(key):inline_textures[key]=DPITexture.create_from_string(asset.svg,1)
			var start:=Vector2(get_pos_at_line_column(line,match_.get_start()+1))
			var end:=Vector2(get_pos_at_line_column(line,mini(match_.get_end()+1,get_line(line).length())))
			if start.x<0 or start.y<0:continue
			var factor:float=minf(1,float(fs)*1.55/float(asset.height))
			var extent:=Vector2(asset.width,asset.height)*factor
			var p:=start+Vector2(3,-get_line_height()+1)
			draw_texture_rect(inline_textures[key],Rect2(p,extent),false,color)
			var meaning:String={"B":"шири́на\n船宽；约定符号。","H":"высота́ бо́рта\n型深；约定符号。","T":"оса́дка\n吃水；约定符号。"}[key]
			symbol_regions.append({"base_rect":Rect2(p,Vector2(extent.x,extent.y*.5)),"sub_rect":Rect2(p+Vector2(0,extent.y*.5),Vector2(extent.x,extent.y*.5)),"span":{"base_hint":"метацентри́ческая высота́\n初稳性高；约定符号。","sub_hint":meaning}})
		for span in notation.spans(get_line(line)):
			if span.get("native_subscript",false):
				var base_rect:=Rect2(get_rect_at_line_column(line,span.start+1))
				var sub_rect:=Rect2(get_rect_at_line_column(line,span.sub_start+1))
				symbol_regions.append({"base_rect":base_rect,"sub_rect":sub_rect,"span":span,"line":line,"font_size":fs})
				continue
			# At a cluster boundary Godot 4.7's position query returns the previous
			# glyph. Query inside these single-code-point notation glyphs instead.
			var start:=Vector2(get_pos_at_line_column(line,span.start+1))
			var end:=Vector2(get_pos_at_line_column(line,span.start+2))
			if start.x<0 or start.y<0:continue
			var base_rect:=Rect2(start-Vector2(0,get_line_height()),Vector2(end.x-start.x,get_line_height()))
			var baseline:=start.y-font.get_descent(fs)+fs*.17
			var position:=Vector2(end.x,baseline)
			draw_string(font,position,span.suffix,HORIZONTAL_ALIGNMENT_LEFT,-1,sub_size,color)
			var width:=font.get_string_size(span.suffix,HORIZONTAL_ALIGNMENT_LEFT,-1,sub_size).x
			var sub_rect:=Rect2(position-Vector2(0,font.get_ascent(sub_size)),Vector2(width,font.get_height(sub_size)))
			symbol_regions.append({"base_rect":base_rect,"sub_rect":sub_rect,"span":span,"line":line,"font_size":sub_size})
func notation_hint(point:Vector2)->String:
	for region in symbol_regions:
		if region.sub_rect.has_point(point):return region.span.sub_hint
		if region.base_rect.has_point(point):return region.span.base_hint
	return ""
