extends SceneTree
const Current=preload("res://modules/review/core/stability_math.gd")
const Original=preload("res://qa/performance_reference_math.gd")
func _initialize()->void:
	var comparisons:=0
	var failures:Array=[]
	Current.ensure()
	for route in Current.data.routes:
		for morph in [0.0,.0833123456789,.4167123456789,1.0]:
			for zg in [7.5,8.7,10.1]:
				for heel in [-89.13,-.001,0.0,.000123456789,7.37,67.58,144.2,180.0]:
					for scale in [.5,1.0,1.7]:
						var state:Dictionary={"route":route,"morph":morph,"zg":zg,"heel":heel,"display_scale":scale,"required":1.231456789}
						var actual:Dictionary=Current.values(state)
						var expected:Dictionary=Original.values(state)
						for key in expected:
							comparisons+=1
							if actual[key]!=expected[key]:failures.append([state,key,actual[key],expected[key]])
						var actual_curve:Array=Current.curve(state)
						var expected_curve:Array=Original.curve(state)
						comparisons+=1
						if actual_curve!=expected_curve:failures.append([state,"curve"])
						comparisons+=1
						if Current.curve_extrema(state)!=Original.extrema(expected_curve):failures.append([state,"extrema"])
	if Current.value_cache.size()>256 or Current.curve_cache.size()>32 or Current.extrema_cache.size()>32:
		failures.append("Unbounded cache")
	var output:Dictionary={"comparisons":comparisons,"failures":failures,"value_cache":Current.value_cache.size(),"curve_cache":Current.curve_cache.size(),"extrema_cache":Current.extrema_cache.size(),"exact_equality":true}
	var file:=FileAccess.open("res://qa/performance-math-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"\t"))
	print("PERFORMANCE MATH ",comparisons," exact comparisons; failures=",failures.size())
	quit(1 if not failures.is_empty() else 0)
