extends Control
var segments:Array=[]
var measures:Array=[]
var reference_lines:Array=[]
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw()->void:
	for line in reference_lines:
		draw_line(line[0],line[1],line[2],line[3],true)
		draw_circle(line[1],4,line[2],true,-1,true)
	for segment in segments:
		draw_line(segment[0],segment[1],Color(.72,.9,.94,.75),1.1,true)
		draw_circle(segment[0],2.3,Color("bce6eb"),true,-1,true)
	for pair in measures:
		var a:Vector2=pair[0];var b:Vector2=pair[1];var normal:Vector2=(b-a).normalized().orthogonal()*5
		draw_line(a,b,Color("f3cb76"),1.7,true)
		for end in [a,b]:draw_line(end-normal,end+normal,Color("f3cb76"),1.7,true)
