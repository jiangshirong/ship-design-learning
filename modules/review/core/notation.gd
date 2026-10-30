extends RefCounted
var bases:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/notation_bases.json"))
var terms:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://modules/review/content/notation_terms.json"))
func spans(value:String)->Array:
	var regex:=RegEx.new()
	regex.compile("(?<![A-Za-zА-Яа-яЁё])([DpPрРμxzWh])_?(сэу|cэу|сэз|пр\\.вод|гр\\.факт|гр|к|с|c|g|min|пор|зап|[0-9]+)(?![A-Za-zА-Яа-яЁё])")
	var result:Array=[]
	for m in regex.search_all(value):
		var base:String=m.get_string(1);var suffix:String=m.get_string(2)
		var key:String={"р":"p","Р":"P","μ":"\\mu"}.get(base,base)
		var sub:String=suffix.replace("c","с")
		var term:String=terms.get(key+"|"+sub,"")
		if sub=="g" and key in ["x","z"]:term="це́нтр масс\n重心；g为重心坐标的约定标记。"
		if suffix=="c" and key=="z":term="це́нтр величины́\n浮心；c为浮心坐标的约定标记。"
		if suffix=="min" and key=="h":term="минима́льный\n最小值；此处为要求的最小初稳性高。"
		if suffix.is_valid_int():term="но́мер слага́емого\n第 "+suffix+" 项；0为题给初始船舶。"
		if key=="D" and suffix.is_valid_int():term="приближе́ние\n第 "+suffix+" 次近似的排水量。"
		if term.is_empty():continue
		result.append({"start":m.get_start(),"end":m.get_end(),"sub_start":m.get_start(2),"base":base,"suffix":suffix,"base_hint":base+"\n"+bases.get(key,""),"sub_hint":suffix+"\n"+term})
	# A native subscript digit is already laid out by the font. Keep its hover
	# identity without painting a second digit over the source text.
	var native:=RegEx.new();native.compile("D₁")
	for m in native.search_all(value):
		result.append({"start":m.get_start(),"end":m.get_end(),"sub_start":m.get_start()+1,"base":"D","suffix":"1","native_subscript":true,"base_hint":"D\n"+bases.get("D",""),"sub_hint":"1\nприближе́ние\n第一次近似的排水量。"})
	return result
